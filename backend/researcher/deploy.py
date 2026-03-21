#!/usr/bin/env python3
"""
Deploy researcher service to AWS App Runner
Cross-platform deployment script for Mac/Windows/Linux
"""

import subprocess
import sys
import os
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(override=True)


def run_command(cmd, capture_output=False, shell=False):
    """Run a command and handle errors."""
    try:
        result = subprocess.run(
            cmd, shell=shell, capture_output=capture_output, text=True, check=True
        )
        if capture_output:
            return result.stdout.strip()
        return None
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        if e.stderr:
            print(f"Error details: {e.stderr}")
        sys.exit(1)


def get_ecr_repository_url(repository_name, region):
    """Get the ECR repository URI, or return None if the repository does not exist."""
    result = subprocess.run(
        [
            "aws",
            "ecr",
            "describe-repositories",
            "--repository-names",
            repository_name,
            "--region",
            region,
            "--query",
            "repositories[0].repositoryUri",
            "--output",
            "text",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        return None

    repository_url = result.stdout.strip()
    if not repository_url or repository_url == "None":
        return None

    return repository_url


def main():
    print("Agent Researcher Service - Docker Deployment")
    print("===========================================")

    # Get AWS account ID
    print("\nGetting AWS account details...")
    account_id = run_command(
        ["aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text"],
        capture_output=True,
    )

    region = os.environ.get("DEFAULT_AWS_REGION")
    if not region:
        print("Error: DEFAULT_AWS_REGION not found in your .env file.")
        sys.exit(1)

    ecr_repository = os.environ.get("ECR_REPOSITORY_NAME", "agent-researcher")
    app_runner_service_name = os.environ.get("APP_RUNNER_SERVICE_NAME", "agent-researcher")

    print(f"AWS Account: {account_id}")
    print(f"Region: {region}")

    # Get ECR repository URL from AWS ECR directly so CI does not depend on Terraform state.
    print("\nGetting ECR repository URL...")
    ecr_url = os.environ.get("ECR_REPOSITORY_URL") or get_ecr_repository_url(
        ecr_repository, region
    )

    if not ecr_url:
        print(f"Error: ECR repository '{ecr_repository}' not found in region {region}.")
        sys.exit(1)

    print(f"ECR Repository: {ecr_url}")

    # Login to ECR
    print("\nLogging in to ECR...")
    password = run_command(
        ["aws", "ecr", "get-login-password", "--region", region], capture_output=True
    )

    login_cmd = ["docker", "login", "--username", "AWS", "--password-stdin", ecr_url]
    login_process = subprocess.Popen(
        login_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    stdout, stderr = login_process.communicate(input=password)

    if login_process.returncode != 0:
        print(f"Error logging into ECR: {stderr}")
        sys.exit(1)

    print("Login successful!")

    # Generate a unique tag using timestamp
    import time

    timestamp = int(time.time())
    image_tag = f"deploy-{timestamp}"

    # Build Docker image
    print(f"\nBuilding Docker image for linux/amd64 with tag: {image_tag}")
    print("(This ensures compatibility with AWS App Runner)")
    run_command(
        [
            "docker",
            "build",
            "--platform",
            "linux/amd64",
            "-t",
            f"{ecr_repository}:{image_tag}",
            # Removed --no-cache to use Docker layer caching for faster builds
            ".",
        ]
    )

    # Tag for ECR with both unique tag and latest
    print("\nTagging image for ECR...")
    run_command(["docker", "tag", f"{ecr_repository}:{image_tag}", f"{ecr_url}:{image_tag}"])
    run_command(["docker", "tag", f"{ecr_repository}:{image_tag}", f"{ecr_url}:latest"])

    # Push to ECR
    print("\nPushing image to ECR...")
    run_command(["docker", "push", f"{ecr_url}:{image_tag}"])
    run_command(["docker", "push", f"{ecr_url}:latest"])

    print("\n✅ Docker image pushed successfully!")
    print(
        "\nNext step: Ensure the App Runner service exists, then update it to use this image."
    )

    # Get App Runner service ARN
    print("\nGetting App Runner service details...")
    try:
        services = run_command(
            [
                "aws",
                "apprunner",
                "list-services",
                "--region",
                region,
                "--query",
                f"ServiceSummaryList[?ServiceName=='{app_runner_service_name}'].ServiceArn",
                "--output",
                "json",
            ],
            capture_output=True,
        )

        if services:
            service_arns = json.loads(services)
            if service_arns:
                service_arn = service_arns[0]
                print(f"Found service: {service_arn}")

                # Get the current service configuration to preserve the access role
                print("\nGetting current service configuration...")
                service_details = run_command(
                    [
                        "aws",
                        "apprunner",
                        "describe-service",
                        "--service-arn",
                        service_arn,
                        "--region",
                        region,
                        "--query",
                        "Service.SourceConfiguration.AuthenticationConfiguration.AccessRoleArn",
                        "--output",
                        "text",
                    ],
                    capture_output=True,
                )

                # Update the service to use the new image with unique tag
                print(f"\nUpdating service to use new image: {ecr_url}:{image_tag}")
                run_command(
                    [
                        "aws",
                        "apprunner",
                        "update-service",
                        "--service-arn",
                        service_arn,
                        "--region",
                        region,
                        "--source-configuration",
                        json.dumps(
                            {
                                "ImageRepository": {
                                    "ImageIdentifier": f"{ecr_url}:{image_tag}",
                                    "ImageConfiguration": {
                                        "Port": "8000",
                                        "RuntimeEnvironmentVariables": {
                                            "OPENAI_API_KEY": os.environ.get("OPENAI_API_KEY", ""),
                                            "AGENT_API_KEY": os.environ.get("AGENT_API_KEY", ""),
                                            "AGENT_API_ENDPOINT": os.environ.get(
                                                "AGENT_API_ENDPOINT", ""
                                            ),
                                        },
                                    },
                                    "ImageRepositoryType": "ECR",
                                },
                                "AuthenticationConfiguration": {"AccessRoleArn": service_details},
                                "AutoDeploymentsEnabled": False,
                            }
                        ),
                    ],
                    capture_output=True,
                )
                print("✅ Service updated with new image!")

                # Wait for deployment to complete
                print("\nWaiting for deployment to complete (this may take 5-10 minutes)...")
                import time

                max_attempts = 120  # 10 minutes with 5-second intervals
                attempts = 0

                while attempts < max_attempts:
                    status = run_command(
                        [
                            "aws",
                            "apprunner",
                            "describe-service",
                            "--service-arn",
                            service_arn,
                            "--region",
                            region,
                            "--query",
                            "Service.Status",
                            "--output",
                            "text",
                        ],
                        capture_output=True,
                    )

                    # Strip any whitespace that might be causing comparison issues
                    status = status.strip()

                    if status == "RUNNING":
                        print("\n✅ Deployment complete! Service is running.")

                        # Get and display the service URL
                        service_url = run_command(
                            [
                                "aws",
                                "apprunner",
                                "describe-service",
                                "--service-arn",
                                service_arn,
                                "--region",
                                region,
                                "--query",
                                "Service.ServiceUrl",
                                "--output",
                                "text",
                            ],
                            capture_output=True,
                        )

                        print(f"\n🚀 Your service is available at:")
                        print(f"   https://{service_url}")
                        print(f"\nTest it with:")
                        print(f"   curl https://{service_url}/health")
                        break
                    elif status == "OPERATION_IN_PROGRESS":
                        # Check operation status for more details
                        operation_status = run_command(
                            [
                                "aws",
                                "apprunner",
                                "list-operations",
                                "--service-arn",
                                service_arn,
                                "--region",
                                region,
                                "--query",
                                "OperationSummaryList[0].Status",
                                "--output",
                                "text",
                            ],
                            capture_output=True,
                        ).strip()

                        if operation_status == "SUCCEEDED":
                            # Operation completed but service status might not be updated yet
                            print("\n⏳ Operation succeeded, checking service status...")
                            time.sleep(2)
                            continue
                        elif operation_status == "FAILED":
                            print(f"\n❌ Deployment failed!")
                            print("Check the AWS Console for error details.")
                            break
                        else:
                            print(".", end="", flush=True)
                            # Show progress every 30 seconds
                            if attempts > 0 and attempts % 6 == 0:
                                elapsed_minutes = (attempts * 5) / 60
                                print(
                                    f" ({elapsed_minutes:.1f} minutes elapsed)", end="", flush=True
                                )
                            time.sleep(5)
                            attempts += 1
                    else:
                        print(f"\n⚠️ Unexpected status: {status}")
                        print("Check the AWS Console for more details.")
                        break
                else:
                    print("\n⚠️ Deployment is taking longer than expected.")
                    print("Check the status in the AWS Console.")
            else:
                print(
                    "\nApp Runner service not found. You may need to run 'terraform apply' first."
                )
                print("\nTo manually deploy:")
                print("  1. Go to AWS Console > App Runner")
                print(f"  2. Select '{app_runner_service_name}' service")
                print("  3. Click 'Deploy' to pull the latest image")
    except Exception as e:
        print(f"\nCouldn't automatically start deployment: {e}")
        print("\nTo manually deploy:")
        print("  1. Go to AWS Console > App Runner")
        print(f"  2. Select '{app_runner_service_name}' service")
        print("  3. Click 'Deploy' to pull the latest image")


if __name__ == "__main__":
    main()
