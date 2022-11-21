# Defaults
REV:=$(shell git rev-parse --short HEAD)
DATE:=$(shell date +%Y.%m.%d-%H.%M.%S)
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT:=$(MODULE)_$(INFRA_VALUES)_$(DATE)_$(REV)

CURRENT_DIR_PATH:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Inputs
REGION:=NO_REGION
PROJECT_ID:=PROJECT_ID
DEPLOYMENT_ID:=NO_DEPLOYMENT_ID
ZONAL:=NO_ZONAL

TF_STATE_BUCKET:=NO_TF_STATE_BUCKET

# Terraform Setup
TF_MODULE_PATH:=test
TF_PLAN_FILE:=test_$(DEPLOYMENT_ID)_$(REV)


.PHONY: help
help: ## Print Makefile help.
	@grep -Eh '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-29s\033[0m %s\n", $$1, $$2}'

.PHONY: pre-commit
pre-commit: ## It will run pre-commit target. It will run target `install`, `install-hooks` and then `run`.
	pre-commit install
	pre-commit install-hooks
	pre-commit run --all-files --show-diff-on-failure

.PHONY: install
install: ## It will install terraform version defined into `.terraform-version` file.
	tfenv install

.PHONY: init
init: clean ## It will run Terraform init. Required params are `DEPLOYMENT_ID` and `TF_STATE_BUCKET`.
	terraform -chdir=$(TF_MODULE_PATH) init \
		-backend=true \
		-backend-config='bucket=$(TF_STATE_BUCKET)' \
		-backend-config='prefix=$(DEPLOYMENT_ID)/terraform.tfstate'

.PHONY: upgrade
upgrade: clean ## It will run Terraform init with `-upgrade` flag. Required params are `DEPLOYMENT_ID` and `TF_STATE_BUCKET`.
	terraform -chdir=$(TF_MODULE_PATH) init \
		-backend=true \
		-bucket='bucket=cloud2-dev-terraform' \
		-prefix='prefix=$(DEPLOYMENT_ID)/terraform.tfstate'
		-upgrade

.PHONY: validate
validate: ## It will run Terraform validate. Required params are `DEPLOYMENT_ID` and `TF_STATE_BUCKET`.
	terraform -chdir=$(TF_MODULE_PATH) validate

.PHONY: plan
plan: validate ## It will run Terraform plan. Required params are `PROJECT_ID`, `REGION`, `DEPLOYMENT_ID` and `ZONAL`.
	terraform -chdir=$(TF_MODULE_PATH) plan \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)' \
		-out=$(TF_PLAN_FILE).tfplan

.PHONY: plan-destroy
plan-destroy: validate ## It will run Terraform plan with `-destroy` flag to generate cleanup plan. Required params are `PROJECT_ID`, `REGION`, `DEPLOYMENT_ID` and `ZONAL`.
	terraform -chdir=$(TF_MODULE_PATH) plan \
		-destroy \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)' \
		-out=$(TF_PLAN_FILE).tfplan

.PHONY: apply
apply: validate ## It will run Terraform apply. Required params are `PROJECT_ID`, `REGION`, `DEPLOYMENT_ID` and `ZONAL`.
	terraform -chdir=$(TF_MODULE_PATH) apply \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

.PHONY: apply-auto-approve
apply-auto-approve: validate ## It will run Terraform apply with `-auto-approve` flag. Required params are `PROJECT_ID`, `REGION`, `DEPLOYMENT_ID` and `ZONAL`.
	terraform -chdir=$(TF_MODULE_PATH) apply \
		-auto-approve \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

.PHONY: apply-plan
apply-plan: ## It will run Terraform apply to plan.
	terraform -chdir=$(TF_MODULE_PATH) apply $(TF_PLAN_FILE).tfplan

.PHONY: destroy
destroy: validate ## It will run Terraform destroy. Required params are `PROJECT_ID`, `REGION`, `DEPLOYMENT_ID` and `ZONAL`.
	terraform -chdir=$(TF_MODULE_PATH) destroy \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

.PHONY: destroy-auto-approve
destroy-auto-approve: validate ## It will run Terraform destroy with `-auto-approve` flag. Required params are `PROJECT_ID`, `REGION`, `DEPLOYMENT_ID` and `ZONAL`.
	terraform -chdir=$(TF_MODULE_PATH) destroy \
		-auto-approve \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

.PHONY: clean
clean: ## Remove  terraform init file and dir
	find . -name "*.terraform" -type d -exec rm -rf {} + || true
	find . -name "*.terraform.lock.hcl" -type f -delete || true
	find . -name "*.tfplan" -type f -delete || true
