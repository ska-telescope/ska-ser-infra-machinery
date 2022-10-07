.DEFAULT_GOAL := help
SHELL=/usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: vars help check-env playbooks orch
.DEFAULT_GOAL := help

ENVIRONMENT ?=
GITLAB_PROJECT_ID ?=
TF_ROOT_DIR ?=
TF_HTTP_USERNAME ?=
PLAYBOOKS_ROOT_DIR ?=
TF_INVENTORY_DIR ?=
ANSIBLE_COLLECTIONS_PATHS ?=
ANSIBLE_CONFIG ?=
PLAYBOOKS_HOSTS ?=

vars:  ### Current variables
	@echo "ENVIRONMENT=$(ENVIRONMENT)"
	@echo "GITLAB_PROJECT_ID=$(GITLAB_PROJECT_ID)"
	@echo "TF_HTTP_USERNAME=$(TF_HTTP_USERNAME)"
	@echo "TF_ROOT_DIR=$(TF_ROOT_DIR)"
	@echo "TF_INVENTORY_DIR=$(TF_INVENTORY_DIR)"
	@echo "TF_TARGET=$(TF_TARGET)"
	@echo "PLAYBOOKS_ROOT_DIR=$(PLAYBOOKS_ROOT_DIR)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

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
	@cd ska-ser-ansible-collections && $(MAKE) $(TARGET_ARGS)
	
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
