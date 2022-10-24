.DEFAULT_GOAL := help
SHELL=/usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: vars help check-env playbooks orch
.DEFAULT_GOAL := help

ENVIRONMENT ?=
TF_HTTP_USERNAME ?=
TF_INVENTORY_DIR ?=
PLAYBOOKS_HOSTS ?=

-include .make/terraform.mk
-include .make/python.mk
-include PrivateRules.mak

BASE_PATH?="$(shell cd "$(dirname "$1")"; pwd -P)"
GITLAB_PROJECT_ID?="39377838"
TF_ROOT_DIR?="${BASE_PATH}/environments/${ENVIRONMENT}/orchestration"
TF_HTTP_ADDRESS?="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state"
TF_HTTP_LOCK_ADDRESS?="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
TF_HTTP_UNLOCK_ADDRESS?="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
TERRAFORM_LINT_TARGET:=$(shell find environments -name 'terraform.tf' | grep -v ".make" | sed 's/.terraform.tf//' | sort | uniq )
PLAYBOOKS_ROOT_DIR?="${BASE_PATH}/environments/${ENVIRONMENT}/installation"
ANSIBLE_CONFIG?="${BASE_PATH}/environments/${ENVIRONMENT}/installation/ansible.cfg"
ANSIBLE_COLLECTIONS_PATHS?="${BASE_PATH}/ska-ser-ansible-collections"

EXTRA_VARS ?= ENVIRONMENT="$(ENVIRONMENT)" \
	TF_HTTP_USERNAME="$(TF_HTTP_USERNAME)" \
	TF_HTTP_PASSWORD="$(TF_HTTP_PASSWORD)" \
	BASE_PATH="$(BASE_PATH)" \
	GITLAB_PROJECT_ID="$(GITLAB_PROJECT_ID)" \
	TF_ROOT_DIR="$(TF_ROOT_DIR)" \
	TF_HTTP_ADDRESS="$(TF_HTTP_ADDRESS)" \
	TF_HTTP_LOCK_ADDRESS="$(TF_HTTP_LOCK_ADDRESS)" \
	TF_HTTP_UNLOCK_ADDRESS="$(TF_HTTP_UNLOCK_ADDRESS)" \
	PLAYBOOKS_ROOT_DIR="$(PLAYBOOKS_ROOT_DIR)" \
	ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ANSIBLE_COLLECTIONS_PATHS="$(ANSIBLE_COLLECTIONS_PATHS)" \
	AZUREAD_CLIENT_ID=$(AZUREAD_CLIENT_ID) \
	AZUREAD_CLIENT_SECRET=$(AZUREAD_CLIENT_SECRET) \
	AZUREAD_COOKIE_SECRET=$(AZUREAD_COOKIE_SECRET) \
	AZUREAD_TENANT_ID=$(AZUREAD_TENANT_ID) \
	INVENTORY_FILE=$(INVENTORY_FILE) \
	SLACK_API_URL=$(SLACK_API_URL) \
	SLACK_API_URL_MVP=$(SLACK_API_URL_MVP) \
	PROM_OS_AUTH_URL=$(PROM_OS_AUTH_URL) \
	PROM_OS_USERNAME=$(PROM_OS_USERNAME) \
	PROM_OS_PASSWORD=$(PROM_OS_PASSWORD) \
	PROM_OS_PROJECT_ID=$(PROM_OS_PROJECT_ID) \
	GITLAB_TOKEN=$(GITLAB_TOKEN) \
	KUBECONFIG=$(KUBECONFIG) \
	CA_CERT_PASSWORD=$(CA_CERT_PASSWORD)

vars:  ### Current variables
	@echo "BASE_PATH=$(BASE_PATH)"

check-env: ## Check ENVIRONMENT variable
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif
ifndef TF_HTTP_USERNAME
	$(error TF_HTTP_USERNAME is undefined)
endif
ifndef TF_HTTP_PASSWORD
	$(error TF_HTTP_PASSWORD is undefined)
endif

# If the first argument is "install"...
ifeq (playbooks,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "playbooks"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

playbooks: check-env ## Access Ansible Collections submodule targets
	@cd ska-ser-ansible-collections && $(EXTRA_VARS) $(MAKE) $(TARGET_ARGS)
	
# If the first argument is "orch"...
ifeq (orch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "orch"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

orch: check-env ## Access Orchestration submodule targets
	@cd ska-ser-orchestration && $(EXTRA_VARS) $(MAKE) $(TARGET_ARGS)

print_targets:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {p=index($$1,":")} {printf "\033[36m%-30s\033[0m %s\n", substr($$1,p+1), $$2}';

help:  ## Show Help
	@echo "";
	@echo -e "\033[32mBase vars:\033[0m"
	@make vars;
	@echo "";
	@echo -e "\033[32mOrchestration Vars:\033[0m";
	@cd ska-ser-orchestration && make vars;
	@echo "";
	@echo -e "\033[32mInstallation Vars:\033[0m";
	@cd ska-ser-ansible-collections && make vars_recursive;
	@echo "";
	@echo -e "\033[32mMain targets:\033[0m"
	@make print_targets
	@echo "";
	@echo -e "\033[32mOrchestration targets - make orch <target>:\033[0m";
	@cd ska-ser-orchestration && make print_targets;
	@echo "";
	@echo -e "\033[32mInstallation targets - make orch <target>:\033[0m";
	@cd ska-ser-ansible-collections && make print_targets;
