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
ANSIBLE_CONFIG?="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg"
ANSIBLE_SSH_ARGS?=-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config
ANSIBLE_COLLECTIONS_PATHS?=$(BASE_PATH)/ska-ser-ansible-collections

EXTRA_VARS ?= DATACENTRE="$(DATACENTRE)" \
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

export-as-envs: infra-check-env ## Print export of EXTRA_VARS
	@echo 'export $(EXTRA_VARS)'

# If the first argument is "install"...
ifeq (playbooks,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "playbooks"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

playbooks: im-check-env ## Access Ansible Collections submodule targets
	@cd ska-ser-ansible-collections && $(EXTRA_VARS) $(MAKE) $(TARGET_ARGS)
	
# If the first argument is "orch"...
ifeq (orch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "orch"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

orch: im-check-env ## Access Orchestration submodule targets
	@echo $(TF_INVENTORY_DIR);
	@cd ska-ser-orchestration && $(EXTRA_VARS) $(MAKE) $(TARGET_ARGS)


## Testing
TEST_ENVIRONMENT=e2e
TEST_TF_ROOT_DIR=$(BASE_PATH)/ska-ser-orchestration/tests/e2e/$(SERVICE)
TEST_TF_HTTP_USERNAME="user"
TEST_TF_HTTP_PASSWORD="pass"
TEST_TF_HTTP_ADDRESS=""
TEST_TF_HTTP_LOCK_ADDRESS=""
TEST_TF_HTTP_UNLOCK_ADDRESS=""
TEST_PLAYBOOKS_ROOT_DIR=$(BASE_PATH)/ska-ser-ansible-collections/ansible_collections/ska_collections/$(SERVICE)/tests/e2e
TEST_TF_INVENTORY_DIR=$(TEST_PLAYBOOKS_ROOT_DIR)
TEST_INVENTORY=$(TEST_PLAYBOOKS_ROOT_DIR)
TEST_ANSIBLE_CONFIG=$(TEST_PLAYBOOKS_ROOT_DIR)/ansible.cfg
TEST_ANSIBLE_SSH_ARGS=-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(TEST_PLAYBOOKS_ROOT_DIR)/ssh.config
TEST_ELASTICSEARCH_PASSWORD=elastic_e2e
TEST_ELASTIC_HAPROXY_STATS_PASSWORD=elastic_e2e
TEST_KIBANA_VIEWER_PASSWORD=elastic_e2e

TEST_EXTRA_VARS ?= $(EXTRA_VARS) \
	OS_CLOUD=$(DATACENTRE) \
	ENVIRONMENT=$(TEST_ENVIRONMENT) \
	TF_HTTP_USERNAME=$(TEST_TF_HTTP_USERNAME) \
	TF_HTTP_PASSWORD=$(TEST_TF_HTTP_PASSWORD) \
	TF_ROOT_DIR="$(TEST_TF_ROOT_DIR)" \
	TF_HTTP_ADDRESS=$(TEST_TF_HTTP_ADDRESS) \
	TF_HTTP_LOCK_ADDRESS=$(TEST_TF_HTTP_LOCK_ADDRESS) \
	TF_HTTP_UNLOCK_ADDRESS=$(TEST_TF_HTTP_UNLOCK_ADDRESS) \
	PLAYBOOKS_ROOT_DIR=$(TEST_PLAYBOOKS_ROOT_DIR)  \
	TF_INVENTORY_DIR=$(TEST_TF_INVENTORY_DIR) \
	INVENTORY=$(TEST_INVENTORY) \
	ANSIBLE_CONFIG=$(TEST_ANSIBLE_CONFIG) \
	ANSIBLE_SSH_ARGS="$(TEST_ANSIBLE_SSH_ARGS)" \
	ELASTICSEARCH_PASSWORD="$(TEST_ELASTICSEARCH_PASSWORD)" \
	ELASTIC_HAPROXY_STATS_PASSWORD="$(TEST_ELASTIC_HAPROXY_STATS_PASSWORD)" \
	KIBANA_VIEWER_PASSWORD="$(TEST_KIBANA_VIEWER_PASSWORD)" \
	
# End-to-end variables
BATS_TESTS_DIR ?= $(BASE_PATH)/tests/e2e
SKIP_BATS_TESTS = $(shell [ ! -d $(BATS_TESTS_DIR) ] && echo "true" || echo "false")
BATS_TEST_TARGETS := "unit $(SERVICE)"
BATS_CORE_VERSION = v1.8.0

check-test-env:
ifeq ($(SKIP_BATS_TESTS),true)
	@echo "No tests found on $(BATS_TESTS_DIR)"
endif
ifndef SERVICE
	$(error SERVICE is undefined);
endif

test: check-test-env
	@if [ ! -d $(BATS_TESTS_DIR)/scripts/bats-core ]; then make --no-print-directory test-install; fi

	@$(TEST_EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) BATS_TEST_TARGETS=$(BATS_TEST_TARGETS) $(MAKE) --no-print-directory bats-test

test-install: check-test-env
	@$(EXTRA_VARS) BASE_DIR=$(BATS_TESTS_DIR) $(MAKE) --no-print-directory bats-install

test-uninstall: check-test-env
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
