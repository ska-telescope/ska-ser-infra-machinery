SHELL=/usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: im-check-env im-setup-vault im-get-vault im-edit-vault im-rotate-vault-secret vars export-as-envs playbooks orch im-check-test-env im-test im-test-install im-test-uninstall im-test-reinstall im-help
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
TF_ROOT_DIR?=$(ENVIRONMENT_ROOT_DIR)/orchestration/$(SERVICE)
TF_HTTP_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state
TF_HTTP_LOCK_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state/lock
TF_HTTP_UNLOCK_ADDRESS?=https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT_ID)/terraform/state/$(DATACENTRE)-$(ENVIRONMENT)-$(SERVICE)-terraform-state/lock
PLAYBOOKS_ROOT_DIR?=$(ENVIRONMENT_ROOT_DIR)/installation
TF_INVENTORY_DIR?=$(PLAYBOOKS_ROOT_DIR)
INVENTORY?=$(PLAYBOOKS_ROOT_DIR)
ANSIBLE_CONFIG?="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg"
ANSIBLE_SSH_ARGS?=-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config
ANSIBLE_COLLECTIONS_PATHS?=$(BASE_PATH)/ska-ser-ansible-collections

## ANSIBLE_VAULT_PROVIDER must be one of: plain-text, ansible-vault or hashicorp-vault
DEFAULT_TEXT_EDITOR?=vim
ANSIBLE_VAULT_EXTRA_ARGS?=
ANSIBLE_VAULT_PROVIDER?=ansible-vault
ANSIBLE_VAULT_PATH?=$(BASE_PATH)/vault.yml
ANSIBLE_VAULT_PASSWORD?=

# Include environment specific vars and secrets
-include $(BASE_PATH)/PrivateRules.mak

ENVIRONMENT_VARIABLES ?= DATACENTRE="$(DATACENTRE)" \
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
	ANSIBLE_VAULT_EXTRA_ARGS="$(ANSIBLE_VAULT_EXTRA_ARGS)"

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

im-setup-vault: ## Loads vault as ansible variables
# plain-text provider
ifndef ANSIBLE_VAULT_PROVIDER
	$(error ANSIBLE_VAULT_PROVIDER is undefined)
endif
ifeq ($(ANSIBLE_VAULT_PROVIDER),plain-text)
ifeq ($(ANSIBLE_VAULT_PATH),)
	$(error ANSIBLE_VAULT_PATH is undefined)
endif
ANSIBLE_VAULT_EXTRA_ARGS := --extra-vars @$(ANSIBLE_VAULT_PATH)
$(shell chmod 600 $(ANSIBLE_VAULT_PATH))
im-get-vault:
	@cat $(ANSIBLE_VAULT_PATH)
im-edit-vault:
	@$(DEFAULT_TEXT_EDITOR) $(ANSIBLE_VAULT_PATH)
endif
# ansible-vault provider
ifeq ($(ANSIBLE_VAULT_PROVIDER),ansible-vault)
ifeq ($(ANSIBLE_VAULT_PATH),)
	$(error ANSIBLE_VAULT_PATH is undefined)
endif
ifeq ($(ANSIBLE_VAULT_PASSWORD),)
	$(error ANSIBLE_VAULT_PASSWORD is undefined)
endif
ANSIBLE_VAULT_EXTRA_ARGS := --extra-vars @$(ANSIBLE_VAULT_PATH) --vault-password-file $(BASE_PATH)/vault.password
$(shell echo "$(ANSIBLE_VAULT_PASSWORD)" > $(BASE_PATH)/vault.password && chmod 600 $(BASE_PATH)/vault.password)
im-get-vault:
	@ansible-vault view $(ANSIBLE_VAULT_PATH) --vault-password-file $(BASE_PATH)/vault.password
im-edit-vault:
	@ansible-vault edit $(ANSIBLE_VAULT_PATH) --vault-password-file $(BASE_PATH)/vault.password
im-rotate-vault-secret:
	@echo "Rekeying $(ANSIBLE_VAULT_PATH)"
	@echo "New vault password: "; read -s VAULT_PASSWORD; \
		echo "$$VAULT_PASSWORD" | sed 's#\(.\{3\}\)\(.*\)\(.\{3\}\)#\1*************\3#'; \
		echo "$$VAULT_PASSWORD" > $(BASE_PATH)/new-vault.password && chmod 600 $(BASE_PATH)/new-vault.password; \
		echo "Please update ANSIBLE_VAULT_PASSWORD to the contents of $(BASE_PATH)/new-vault.password";
	@ansible-vault rekey --vault-password-file $(BASE_PATH)/vault.password --new-vault-password-file $(BASE_PATH)/new-vault.password
endif
# hashicorp-vault provider
ifeq ($(ANSIBLE_VAULT_PROVIDER),hashicorp-vault)
	$(error Vault provider 'hashicorp-vault' is undefined)
endif

vars:  ### Current variables
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
	@echo "ANSIBLE_VAULT_PATH=$(ANSIBLE_VAULT_PATH)"
	@echo "";
	@echo -e "\033[32mOrchestration vars:\033[0m";
	@cd ska-ser-orchestration && $(ENVIRONMENT_VARIABLES) $(MAKE) vars;
	@echo "";
	@echo -e "\033[32mInstallation vars:\033[0m";
	@cd ska-ser-ansible-collections && $(ENVIRONMENT_VARIABLES) $(MAKE) vars;
	@echo "";

export-as-envs: im-check-env
	@echo 'export $(ENVIRONMENT_VARIABLES)'

# If the first argument is "install"...
ifeq (playbooks,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "playbooks"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

playbooks: im-check-env setup-vault ## Access Ansible Collections submodule targets
	@cd ska-ser-ansible-collections && $(ENVIRONMENT_VARIABLES) $(MAKE) $(TARGET_ARGS)
	
# If the first argument is "orch"...
ifeq (orch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "orch"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

orch: im-check-env ## Access Orchestration submodule targets
	@cd ska-ser-orchestration && $(ENVIRONMENT_VARIABLES) $(MAKE) $(TARGET_ARGS)

## Testing
RANDOM_STRING ?= $(shell echo $$RANDOM | md5sum | head -c 3; echo)
TF_VAR_group_name ?= $(DATACENTRE)-e2e-$(SERVICE)-local-$(RANDOM_STRING)

TEST_EXTRA_VARS ?= $(EXTRA_VARS) \
	OS_CLOUD=$(DATACENTRE) \
	TF_HTTP_USERNAME="" \
	TF_HTTP_PASSWORD="" \
	ELASTICSEARCH_PASSWORD=elastic_e2e \
	ELASTIC_HAPROXY_STATS_PASSWORD=elastic_e2e \
	KIBANA_VIEWER_PASSWORD=elastic_e2e \
	TF_VAR_group_name="$(TF_VAR_group_name)" \
	
# End-to-end variables
BATS_TESTS_DIR ?= $(BASE_PATH)/tests/e2e
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
	@if [ ! -d $(BATS_TESTS_DIR)/scripts/bats-core ]; then make --no-print-directory test-install; fi

	@$(TEST_EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) BATS_TEST_TARGETS="unit $(SERVICE) cleanup" $(MAKE) --no-print-directory bats-test
	
test-cleanup: check-test-env
	@if [ ! -d $(BATS_TESTS_DIR)/scripts/bats-core ]; then make --no-print-directory test-install; fi

	@$(TEST_EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) BATS_TEST_TARGETS="cleanup" $(MAKE) --no-print-directory bats-test

im-test-install: im-check-test-env
	@$(EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-install

im-test-uninstall: im-check-test-env
	@$(EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-uninstall

im-test-reinstall: im-test-uninstall im-test-install

im-help:  ## Show Help
	@echo "";
	@echo -e "\033[32mBase Vars:\033[0m"
	@make im-vars;
	@echo "";
	@echo -e "\033[32mOrchestration Vars:\033[0m";
	@cd ska-ser-orchestration && $(EXTRA_VARS) make vars;
	@echo "";
	@echo -e "\033[32mInstallation Vars:\033[0m";
	@cd ska-ser-ansible-collections && $(EXTRA_VARS) make ac-vars-recursive;
	@echo "";
	@echo -e "\033[32mMain Targets:\033[0m"
	@make help-print-targets
	@echo "";
	@echo -e "\033[32mOrchestration targets - make orch <target>:\033[0m";
	@cd ska-ser-orchestration && make help-print-targets;
	@echo "";
	@echo -e "\033[32mInstallation targets - make playbooks <target>:\033[0m";
	@cd ska-ser-ansible-collections && make help-print-targets;
