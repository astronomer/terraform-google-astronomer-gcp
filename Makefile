# Defaults
REV:=$(shell git rev-parse --short HEAD)
DATE:=$(shell date +%Y.%m.%d-%H.%M.%S)
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT:=$(MODULE)_$(INFRA_VALUES)_$(DATE)_$(REV)

CURRENT_DIR_PATH:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Inputs
REGION ?= ${REGION}
PROJECT_ID ?= ${PROJECT_ID}
DEPLOYMENT_ID ?= ${DEPLOYMENT_ID}
ZONAL ?= ${ZONAL}

TF_STATE_BUCKET ?= ${TF_STATE_BUCKET}

# Terraform Setup
TF_MODULE_PATH:=test
TF_PLAN_FILE:=test_$(DEPLOYMENT_ID)_$(REV)

.PHONY: clean

pre-commit: clean
	pre-commit install
	pre-commit install-hooks
	pre-commit run --all-files --show-diff-on-failure

install:
	tfenv install

init: clean
	terraform -chdir=$(TF_MODULE_PATH) init \
		-backend=true \
		-backend-config='bucket=$(TF_STATE_BUCKET)' \
		-backend-config='prefix=$(DEPLOYMENT_ID)/terraform.tfstate'

upgrade: clean
	terraform -chdir=$(TF_MODULE_PATH) init \
		-backend=true \
		-bucket='bucket=cloud2-dev-terraform' \
		-prefix='prefix=$(DEPLOYMENT_ID)/terraform.tfstate'
		-upgrade

validate:
	terraform -chdir=$(TF_MODULE_PATH) validate

plan: validate
	terraform -chdir=$(TF_MODULE_PATH) plan \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)' \
		-out=$(TF_PLAN_FILE).tfplan

plan-destroy: validate
	terraform -chdir=$(TF_MODULE_PATH) plan \
		-destroy \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)' \
		-out=$(TF_PLAN_FILE).tfplan

apply: validate
	terraform -chdir=$(TF_MODULE_PATH) apply \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

apply-auto-approve: validate
	terraform -chdir=$(TF_MODULE_PATH) apply \
		-auto-approve \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

apply-plan:
	terraform -chdir=$(TF_MODULE_PATH) apply $(TF_PLAN_FILE).tfplan

destroy: validate
	terraform -chdir=$(TF_MODULE_PATH) destroy \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

destroy-auto-approve: validate
	terraform -chdir=$(TF_MODULE_PATH) destroy \
		-auto-approve \
		-var 'project_id=$(PROJECT_ID)' \
		-var 'region=$(REGION)' \
		-var 'deployment_id=$(DEPLOYMENT_ID)' \
		-var 'zonal=$(ZONAL)'

clean:
	find . -name "*.terraform" -type d -exec rm -rf {} + || true
	find . -name "*.terraform.lock.hcl" -type f -delete || true
	find . -name "*.tfplan" -type f -delete || true
