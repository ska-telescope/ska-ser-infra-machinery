.DEFAULT_GOAL := help
SHELL=/usr/bin/env bash

.PHONY: vars help check-env playbooks orch
.DEFAULT_GOAL := help

ENVIRONMENT ?=
GITLAB_PROJECT_ID ?=
TF_ROOT_DIR ?=
PLAYBOOKS_ROOT_DIR ?=
ANSIBLE_COLLECTIONS_PATHS ?=
ANSIBLE_CONFIG ?=

vars:  ## Current variables
	@echo "Current variable settings:"
	@echo "ENVIRONMENT=$(ENVIRONMENT)"
	@echo "GITLAB_PROJECT_ID=$(GITLAB_PROJECT_ID)"
	@echo "TF_ROOT_DIR=$(TF_ROOT_DIR)"
	@echo "PLAYBOOKS_ROOT_DIR=$(PLAYBOOKS_ROOT_DIR)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"

check-env: ## Check ENVIRONMENT variable
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

# If the first argument is "install"...
ifeq (playbooks,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "playbooks"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

playbooks: check-env ## Access Ansible Collections submodule targets
	cd ska-ser-ansible-collections && $(MAKE) $(TARGET_ARGS)
	
# If the first argument is "orch"...
ifeq (orch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "orch"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

orch: check-env ## Access Orchestration submodule targets
	cd ska-ser-orchestration && $(MAKE) $(TARGET_ARGS)

help:  ## Show Help
	@echo "make targets:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""; 
	@make vars
