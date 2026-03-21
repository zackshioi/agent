ENVIRONMENT ?= dev
TFVARS_FILE := $(ENVIRONMENT).tfvars
GITHUB_REPOSITORY := zackshioi/agent
GITHUB_ACTIONS_TARGETS := \
	-target=aws_iam_role.github_actions \
	-target=aws_iam_role_policy_attachment.github_lambda \
	-target=aws_iam_role_policy_attachment.github_s3 \
	-target=aws_iam_role_policy_attachment.github_apigateway \
	-target=aws_iam_role_policy_attachment.github_bedrock \
	-target=aws_iam_role_policy_attachment.github_sagemaker \
	-target=aws_iam_role_policy_attachment.github_eventbridge \
	-target=aws_iam_role_policy_attachment.github_dynamodb \
	-target=aws_iam_role_policy.github_additional \
	-target=aws_iam_role_policy_attachment.github_s3_vectors
GITHUB_ACTIONS_TARGETS_WITH_OIDC := \
	-target=aws_iam_openid_connect_provider.github \
	$(GITHUB_ACTIONS_TARGETS)

.PHONY: remote-backend-setup
remote-backend-setup:
	terraform workspace select default
	terraform init
	terraform apply \
		-target=aws_s3_bucket.terraform_state \
		-target=aws_s3_bucket_versioning.terraform_state \
		-target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
		-target=aws_s3_bucket_public_access_block.terraform_state \
		-target=aws_dynamodb_table.terraform_locks

.PHONY: init
init:
	AWS_REGION=$${DEFAULT_AWS_REGION:-ap-southeast-2}; \
	if [ -z "$(ENVIRONMENT)" ]; then \
		echo "ENVIRONMENT must be set, for example: make init ENVIRONMENT=dev"; \
		exit 1; \
	fi; \
	terraform init \
		-reconfigure \
		-backend-config="bucket=zackshioi-agent-terraform-state" \
		-backend-config="key=$(ENVIRONMENT)/terraform.tfstate" \
		-backend-config="region=$${AWS_REGION}" \
		-backend-config="dynamodb_table=agent-terraform-locks" \
		-backend-config="encrypt=true"

.PHONY: github-oidc-setup
github-oidc-setup:
	@cd initializing
	terraform workspace select default
	OIDC_PROVIDER_ARN=$$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text); \
	if [ -n "$${OIDC_PROVIDER_ARN}" ]; then \
		if terraform state list | grep -q '^aws_iam_openid_connect_provider\.github$$'; then \
			echo "aws_iam_openid_connect_provider.github is already in Terraform state, skipping import"; \
		else \
			AWS_ACCOUNT_ID=$$(aws sts get-caller-identity --query Account --output text); \
			terraform import aws_iam_openid_connect_provider.github arn:aws:iam::$${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com; \
		fi; \
		terraform apply $(GITHUB_ACTIONS_TARGETS) -var="github_repository=$(GITHUB_REPOSITORY)"; \
	else \
		terraform apply $(GITHUB_ACTIONS_TARGETS_WITH_OIDC) -var="github_repository=$(GITHUB_REPOSITORY)"; \
	fi
	terraform output github_actions_role_arn

.PHONY: validate
validate:
	$(MAKE) init ENVIRONMENT=$(ENVIRONMENT)
	if terraform workspace select $(ENVIRONMENT); then \
		echo "Using existing workspace: $(ENVIRONMENT)"; \
	else \
		terraform workspace new $(ENVIRONMENT); \
	fi
	terraform validate

.PHONY: plan
plan:
	$(MAKE) init ENVIRONMENT=$(ENVIRONMENT)
	if terraform workspace select $(ENVIRONMENT); then \
		echo "Using existing workspace: $(ENVIRONMENT)"; \
	else \
		terraform workspace new $(ENVIRONMENT); \
	fi
	terraform plan -var-file="$(TFVARS_FILE)" 

.PHONY: deploy
deploy:
	$(MAKE) init ENVIRONMENT=$(ENVIRONMENT)
	if terraform workspace select $(ENVIRONMENT); then \
		echo "Using existing workspace: $(ENVIRONMENT)"; \
	else \
		terraform workspace new $(ENVIRONMENT); \
	fi
	terraform apply -auto-approve -var-file="$(TFVARS_FILE)"
