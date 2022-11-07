SHELL=/usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: im-check-env im-vars im-help im-test im-test-install im-test-uninstall im-test-reinstall infra-check-env playbooks orch
.DEFAULT_GOAL := help

DATACENTRE ?=
ENVIRONMENT ?=
SERVICE ?=
TF_HTTP_USERNAME ?=
TF_LINT_TARGETS?=$(shell find ./datacentres -name 'terraform.tf' | grep -v ".make" | sed 's/.terraform.tf//' | sort | uniq )

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
TF_ROOT_DIR?=$(ENVIRONMENT_ROOT_DIR)/$(SERVICE)/orchestration
TF_HTTP_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state
TF_HTTP_LOCK_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state/lock
TF_HTTP_UNLOCK_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state/lock
PLAYBOOKS_ROOT_DIR?=$(ENVIRONMENT_ROOT_DIR)/installation
TF_INVENTORY_DIR?=$(PLAYBOOKS_ROOT_DIR)
INVENTORY?=$(PLAYBOOKS_ROOT_DIR)
ANSIBLE_CONFIG?=$(PLAYBOOKS_ROOT_DIR)/ansible.cfg
ANSIBLE_SSH_ARGS?=-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config
ANSIBLE_COLLECTIONS_PATHS?=$(BASE_PATH)/ska-ser-ansible-collections

TF_EXTRA_VARS ?= DATACENTRE="$(DATACENTRE)" \
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
	TF_INVENTORY_DIR="$(TF_INVENTORY_DIR)" \
	INVENTORY="$(INVENTORY)" \
	ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ANSIBLE_COLLECTIONS_PATHS="$(ANSIBLE_COLLECTIONS_PATHS)" \
	AZUREAD_CLIENT_ID=$(AZUREAD_CLIENT_ID) \
	AZUREAD_CLIENT_SECRET=$(AZUREAD_CLIENT_SECRET) \
	AZUREAD_COOKIE_SECRET=$(AZUREAD_COOKIE_SECRET) \
	AZUREAD_TENANT_ID=$(AZUREAD_TENANT_ID) \
	SLACK_API_URL=$(SLACK_API_URL) \
	SLACK_API_URL_USER=$(SLACK_API_URL_USER) \
	PROM_OS_AUTH_URL=$(PROM_OS_AUTH_URL) \
	PROM_OS_USERNAME=$(PROM_OS_USERNAME) \
	PROM_OS_PASSWORD=$(PROM_OS_PASSWORD) \
	PROM_OS_PROJECT_ID=$(PROM_OS_PROJECT_ID) \
	GITLAB_TOKEN=$(GITLAB_TOKEN) \
	KUBECONFIG=$(KUBECONFIG) \
	CA_CERT_PASSWORD=$(CA_CERT_PASSWORD) \
	PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS) \
	ELASTICSEARCH_PASSWORD=$(ELASTICSEARCH_PASSWORD)

BATS_TESTS_DIR ?= $(ENVIRONMENT_ROOT_DIR)/tests
SKIP_BATS_TESTS = $(shell [ ! -d $(BATS_TESTS_DIR) ] && echo "true" || echo "false")
BATS_TEST_TARGETS ?= "unit e2e"
BATS_CORE_VERSION = v1.8.0

im-vars:  ### Current variables
	@echo "BASE_PATH=$(BASE_PATH)"

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
	@echo "OK."

export-as-envs: infra-check-env ## Print export of TF_EXTRA_VARS
	@echo 'export $(TF_EXTRA_VARS)'

ifeq ($(SKIP_BATS_TESTS),true)
im-test: infra-check-env
	@echo "No tests found for '$(ENVIRONMENT)'"
else
im-test: infra-check-env
	@if [ ! -d $(BATS_TESTS_DIR)/scripts/bats-core ]; then make --no-print-directory test-install; fi
	@$(TF_EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) BATS_TEST_TARGETS=$(BATS_TEST_TARGETS) $(MAKE) --no-print-directory bats-test
endif

im-test-install: infra-check-env
	@$(TF_EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-install

im-test-uninstall: infra-check-env
	@$(TF_EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-uninstall

im-test-reinstall: im-test-uninstall im-test-install

im-help:  ## Show Help
	@echo "";
	@echo -e "\033[32mBase Vars:\033[0m"
	@make vars;
	@echo "";
	@echo -e "\033[32mOrchestration Vars:\033[0m";
	@cd ska-ser-orchestration && make vars;
	@echo "";
	@echo -e "\033[32mInstallation Vars:\033[0m";
	@cd ska-ser-ansible-collections && make ac-vars-recursive;
	@echo "";
	@echo -e "\033[32mMain Targets:\033[0m"
	@make help-print-targets
	@echo "";
	@echo -e "\033[32mOrchestration Targets - make orch <target>:\033[0m";
	@cd ska-ser-orchestration && make help-print-targets;
	@echo "";
	@echo -e "\033[32mInstallation Targets - make playbooks <target>:\033[0m";
	@cd ska-ser-ansible-collections && make help-print-targets;
