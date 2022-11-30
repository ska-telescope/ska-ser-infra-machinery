SHELL=/usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: im-check-env im-setup-secrets im-get-secrets im-edit-secrets im-rotate-secrets-password im-vars export-as-envs playbooks orch im-check-test-env im-test im-test-install im-test-uninstall im-test-reinstall im-help
.DEFAULT_GOAL := help

DATACENTRE ?=
ENVIRONMENT ?=
SERVICE ?=
TF_LINT_TARGETS?=$(shell find ./datacentres -name 'terraform.tf' | grep -v ".make" | sed 's/.terraform.tf//' | sort | uniq )
GITLAB_USERNAME ?=
GITLAB_TOKEN ?=
PYTHON ?= python3
PRIVATE_RULES ?= $(BASE_PATH)/PrivateRules.mak

-include .make/base.mk
-include .make/bats.mk
-include .make/terraform.mk
-include .make/python.mk

BASE_PATH?=$(shell cd "$(dirname "$1")"; pwd -P)

# Include environment specific vars and secrets
-include $(BASE_PATH)/PrivateRules.mak

# must include infra after Private Vars
-include .make/infra.mk

GITLAB_PROJECT_ID?=39377838
ENVIRONMENT_ROOT_DIR?=$(BASE_PATH)/datacentres/$(DATACENTRE)/$(ENVIRONMENT)
TF_ROOT_DIR?=$(ENVIRONMENT_ROOT_DIR)/orchestration/$(SERVICE)
TF_HTTP_USERNAME?=$(GITLAB_USERNAME)
TF_HTTP_PASSWORD?=$(GITLAB_TOKEN)
TF_HTTP_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state
TF_HTTP_LOCK_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state/lock
TF_HTTP_UNLOCK_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state/lock
PLAYBOOKS_ROOT_DIR?=$(ENVIRONMENT_ROOT_DIR)/installation
TF_INVENTORY_DIR?=$(PLAYBOOKS_ROOT_DIR)
INVENTORY?=$(PLAYBOOKS_ROOT_DIR)
ANSIBLE_CONFIG?="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg"
ANSIBLE_SSH_ARGS?=-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config
ANSIBLE_COLLECTIONS_PATHS?=$(BASE_PATH)/ska-ser-ansible-collections
CI_PIPELINE_ID ?= $(shell echo "local-$$(whoami)" | head -c 16)

DEFAULT_TEXT_EDITOR?=vi
ANSIBLE_EXTRA_VARS?=--extra-vars 'ska_datacentre=$(DATACENTRE) ska_environment=$(ENVIRONMENT) ska_service=$(SERVICE) ska_ci_pipeline_id=$(CI_PIPELINE_ID)'

ANSIBLE_SECRETS_PATH?=$(BASE_PATH)/secrets.yml
ANSIBLE_SECRETS_PASSWORD?=

ANSIBLE_EXTRA_VARS += --extra-vars @$(ANSIBLE_SECRETS_PATH) --vault-password-file $(BASE_PATH)/secrets.password

VAULT_ADDR?=
CI_JOB_JWT?=
VAULT_TOKEN?=
ifneq ($(CI_JOB_JWT),)
VAULT_AUTH?=auth_method=jwt token=$(CI_JOB_JWT)
else
VAULT_AUTH?=auth_method=token token=$(VAULT_TOKEN)
endif

# Include environment specific vars and secrets
-include $(BASE_PATH)/PrivateRules.mak

im-check-env: ## Check environment configuration variables
ifndef DATACENTRE
	$(error DATACENTRE is undefined)
endif
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif
ifndef TF_HTTP_USERNAME
	$(error TF_HTTP_USERNAME is undefined)
endif
ifndef TF_HTTP_PASSWORD
	$(error TF_HTTP_PASSWORD is undefined)
endif

im-setup-secrets: ## Loads secrets as ansible variables
	@$(PYTHON) -u $(BASE_PATH)/scripts/get-secrets.py \
	--output $(ANSIBLE_SECRETS_PATH) \
	--password-output $(BASE_PATH)/secrets.password \
	--password $(ANSIBLE_SECRETS_PASSWORD) \
	--source 'type=file path=$(PRIVATE_RULES)' \
	--source 'type=vault address=$(VAULT_ADDR) $(VAULT_AUTH) paths=/ip-gitlab-test/shared/shared_value@banana.$$key' \
	--source 'type=vault address=$(VAULT_ADDR) $(VAULT_AUTH) paths=/ip-gitlab-test/shared/shared_value@banana.$$key_copy'

im-get-secrets:
	@ansible-vault view $(ANSIBLE_SECRETS_PATH) --vault-password-file $(BASE_PATH)/secrets.password

im-edit-secrets:
	@echo "*** Warning: This will only update secrets on your local environment ***"
	@sleep 1
	@ansible-vault edit $(ANSIBLE_SECRETS_PATH) --vault-password-file $(BASE_PATH)/secrets.password

im-rotate-secrets-password:
	@echo "Rekeying $(ANSIBLE_SECRETS_PATH)"
	@echo "New secrets password: "; read -s SECRETS_PASSWORD; \
		echo "$$SECRETS_PASSWORD" | sed 's#\(.\{3\}\)\(.*\)\(.\{3\}\)#\1*************\3#'; \
		echo "$$SECRETS_PASSWORD" > $(BASE_PATH)/new-secrets.password && chmod 600 $(BASE_PATH)/new-secrets.password; \
		echo "Please update ANSIBLE_SECRETS_PASSWORD to the contents of $(BASE_PATH)/new-secrets.password";
	@ansible-vault rekey --vault-password-file $(BASE_PATH)/secrets.password --new-vault-password-file $(BASE_PATH)/new-secrets.password

ENV_VARS ?= DATACENTRE="$(DATACENTRE)" \
	ENVIRONMENT="$(ENVIRONMENT)" \
	SERVICE="$(SERVICE)" \
	TF_HTTP_USERNAME="$(TF_HTTP_USERNAME)" \
	TF_HTTP_PASSWORD="$(TF_HTTP_PASSWORD)" \
	BASE_PATH="$(BASE_PATH)" \
	GITLAB_PROJECT_ID="$(GITLAB_PROJECT_ID)" \
	ENVIRONMENT_ROOT_DIR="$(ENVIRONMENT_ROOT_DIR)" \
	TF_ROOT_DIR="$(TF_ROOT_DIR)" \
	TF_HTTP_ADDRESS="$(TF_HTTP_ADDRESS)" \
	TF_HTTP_LOCK_ADDRESS="$(TF_HTTP_LOCK_ADDRESS)" \
	TF_HTTP_UNLOCK_ADDRESS="$(TF_HTTP_UNLOCK_ADDRESS)" \
	PLAYBOOKS_ROOT_DIR="$(PLAYBOOKS_ROOT_DIR)" \
	TF_INVENTORY_DIR=$(TF_INVENTORY_DIR) \
	INVENTORY="$(INVENTORY)" \
	ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ANSIBLE_COLLECTIONS_PATHS="$(ANSIBLE_COLLECTIONS_PATHS)" \
	ANSIBLE_EXTRA_VARS="$(ANSIBLE_EXTRA_VARS)" \
	TF_VAR_datacentre="$(DATACENTRE)" \
	TF_VAR_environment="$(ENVIRONMENT)" \
	TF_VAR_service="$(SERVICE)"

test: im-check-env im-setup-secrets
	@echo ""
	

im-vars:  ### Current variables
	@echo "";
	@echo -e "\033[32mMain vars:\033[0m"
	@echo "BASE_PATH=$(BASE_PATH)"
	@echo "DATACENTRE=$(DATACENTRE)"
	@echo "ENVIRONMENT=$(ENVIRONMENT)"
	@echo "SERVICE=$(SERVICE)"
	@echo "TF_HTTP_USERNAME=$(TF_HTTP_USERNAME)"
	@echo "TF_HTTP_PASSWORD=$(TF_HTTP_PASSWORD)"
	@echo "GITLAB_PROJECT_ID=$(GITLAB_PROJECT_ID)"
	@echo "ENVIRONMENT_ROOT_DIR=$(ENVIRONMENT_ROOT_DIR)"
	@echo "TF_ROOT_DIR=$(TF_ROOT_DIR)"
	@echo "TF_HTTP_ADDRESS=$(TF_HTTP_ADDRESS)"
	@echo "TF_HTTP_LOCK_ADDRESS=$(TF_HTTP_LOCK_ADDRESS)"
	@echo "TF_HTTP_UNLOCK_ADDRESS=$(TF_HTTP_UNLOCK_ADDRESS)"
	@echo "PLAYBOOKS_ROOT_DIR=$(PLAYBOOKS_ROOT_DIR)"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "ANSIBLE_SECRETS_PATH=$(ANSIBLE_SECRETS_PATH)"
	@echo "";
	@echo -e "\033[32mOrchestration vars:\033[0m";
	@cd ska-ser-orchestration && $(ENV_VARS) $(MAKE) vars;
	@echo "";
	@echo -e "\033[32mInstallation vars:\033[0m";
	@cd ska-ser-ansible-collections && $(ENV_VARS) $(MAKE) vars;
	@echo "";

export-as-envs: im-check-env
	@echo 'export $(ENV_VARS)'

# If the first argument is "install"...
ifeq (playbooks,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "playbooks"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

playbooks: im-check-env im-setup-secrets ## Access Ansible Collections submodule targets
	@cd ska-ser-ansible-collections && $(ENV_VARS) $(MAKE) $(TARGET_ARGS)
	
# If the first argument is "orch"...
ifeq (orch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "orch"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

orch: im-check-env ## Access Orchestration submodule targets
	@cd ska-ser-orchestration && $(ENV_VARS) $(MAKE) $(TARGET_ARGS)

## Testing
# TF_VAR_ci_pipeline_id automatically populates ci_pipeline_id Terraform variable
# that is used as a suffix in the Terraform resource names
TEST_ENV_VARS ?= $(ENV_VARS) \
	TF_HTTP_USERNAME="username" \
	TF_HTTP_PASSWORD="password" \
	TF_VAR_ci_pipeline_id="$(CI_PIPELINE_ID)"
	
# End-to-end variables
BATS_TESTS_DIR ?= $(BASE_PATH)/tests/e2e
BATS_TEST_SUITES ?= unit setup $(SERVICE) cleanup
SKIP_BATS_TESTS = $(shell [ ! -d $(BATS_TESTS_DIR) ] && echo "true" || echo "false")
BATS_CORE_VERSION = v1.8.0

im-check-test-env:
ifeq ($(SKIP_BATS_TESTS),true)
	@echo "No tests found on $(BATS_TESTS_DIR)"
endif
ifndef SERVICE
	$(error SERVICE is undefined);
endif
ifndef DATACENTRE
	$(error DATACENTRE is undefined)
endif
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

im-test: im-check-test-env
	@if [ ! -d $(BATS_TESTS_DIR)/scripts/bats-core ]; then make --no-print-directory im-test-install; fi
	@$(TEST_ENV_VARS) BASE_DIR=$(BATS_TESTS_DIR) BATS_TEST_TARGETS="$(BATS_TEST_SUITES)" $(MAKE) --no-print-directory bats-test
	
im-test-cleanup: im-check-test-env
	@if [ ! -d $(BATS_TESTS_DIR)/scripts/bats-core ]; then make --no-print-directory im-test-install; fi
	@$(TEST_ENV_VARS) BASE_DIR=$(BATS_TESTS_DIR) BATS_TEST_TARGETS="cleanup" $(MAKE) --no-print-directory bats-test

im-test-install: im-check-test-env
	@$(TEST_ENV_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-install

im-test-uninstall: im-check-test-env
	@$(TEST_ENV_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-uninstall

im-test-reinstall: im-test-uninstall im-test-install

im-help:  ## Show Help
	@echo "";
	@echo -e "\033[32mBase Vars:\033[0m"
	@make im-vars;
	@echo "";
	@echo -e "\033[32mMain Targets:\033[0m"
	@make help
	@echo "";
	@echo -e "\033[32mOrchestration targets - make orch <target>:\033[0m";
	@cd ska-ser-orchestration && make help-print-targets;
	@echo "";
	@echo -e "\033[32mInstallation targets - make playbooks <target>:\033[0m";
	@cd ska-ser-ansible-collections && make help-print-targets;
