.DEFAULT_GOAL := help
SHELL=/usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: vars help check-env playbooks orch
.DEFAULT_GOAL := help

DATACENTER ?=
ENVIRONMENT ?=
SERVICE ?=
TF_HTTP_USERNAME ?=
TF_INVENTORY_DIR ?=
PLAYBOOKS_HOSTS ?=

-include PrivateRules.mak

BASE_PATH?="$(shell cd "$(dirname "$1")"; pwd -P)"
GITLAB_PROJECT_ID?=39377838
TF_ROOT_DIR?=${BASE_PATH}/environments/${DATACENTER}/${ENVIRONMENT}/${SERVICE}/orchestration
TF_HTTP_ADDRESS?=https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${DATACENTER}-${ENVIRONMENT}-${SERVICE}-terraform-state
TF_HTTP_LOCK_ADDRESS?=https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${DATACENTER}-${ENVIRONMENT}-${SERVICE}-terraform-state/lock
TF_HTTP_UNLOCK_ADDRESS?=https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${DATACENTER}-${ENVIRONMENT}-${SERVICE}-terraform-state/lock
PLAYBOOKS_ROOT_DIR?=${BASE_PATH}/environments/${DATACENTER}/${ENVIRONMENT}/${SERVICE}/installation
ANSIBLE_CONFIG?=${BASE_PATH}/environments/${DATACENTER}/${ENVIRONMENT}/${SERVICE}/installation/ansible.cfg
ANSIBLE_COLLECTIONS_PATHS?=${BASE_PATH}/ska-ser-ansible-collections

EXTRA_VARS ?= DATACENTER="$(DATACENTER)" \
	ENVIRONMENT="$(ENVIRONMENT)" \
	SERVICE="$(SERVICE)" \
	TF_HTTP_USERNAME="$(TF_HTTP_USERNAME)" \
	TF_HTTP_PASSWORD="$(TF_HTTP_PASSWORD)" \
	BASE_PATH="$(BASE_PATH)" \
	GITLAB_PROJECT_ID="$(GITLAB_PROJECT_ID)" \
	TF_ROOT_DIR="$(TF_ROOT_DIR)" \
	TF_ROOT_DIR="$(TF_ROOT_DIR)" \
	TF_HTTP_ADDRESS="$(TF_HTTP_ADDRESS)" \
	TF_HTTP_LOCK_ADDRESS="$(TF_HTTP_LOCK_ADDRESS)" \
	TF_HTTP_UNLOCK_ADDRESS="$(TF_HTTP_UNLOCK_ADDRESS)" \
	PLAYBOOKS_ROOT_DIR="$(PLAYBOOKS_ROOT_DIR)" \
	ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ANSIBLE_COLLECTIONS_PATHS="$(ANSIBLE_COLLECTIONS_PATHS)"

vars:  ### Current variables
	@echo "ENVIRONMENT=$(ENVIRONMENT)"
	@echo "GITLAB_PROJECT_ID=$(GITLAB_PROJECT_ID)"
	@echo "TF_HTTP_USERNAME=$(TF_HTTP_USERNAME)"
	@echo "TF_ROOT_DIR=$(TF_ROOT_DIR)"
	@echo "PLAYBOOKS_ROOT_DIR=$(PLAYBOOKS_ROOT_DIR)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "BASE_PATH=$(BASE_PATH)"
	@echo "TF_HTTP_ADDRESS=$(TF_HTTP_ADDRESS)"
	@echo "TF_HTTP_LOCK_ADDRESS=$(TF_HTTP_LOCK_ADDRESS)"
	@echo "TF_HTTP_UNLOCK_ADDRESS=$(TF_HTTP_UNLOCK_ADDRESS)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "TF_INVENTORY_DIR=$(TF_INVENTORY_DIR)"
	@echo "TF_TARGET=$(TF_TARGET)"

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

help:  ## Show Help
	@echo "Vars:";
	@make vars;
	@echo "";
	@echo "Main targets:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "";
	@echo "Orchestration targets - make orch <target>:";
	@cd ska-ser-orchestration && grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}';
	@echo "";
	@echo "Installation targets - make orch <target>:";
	@cd ska-ser-ansible-collections && make help-from-submodule;
