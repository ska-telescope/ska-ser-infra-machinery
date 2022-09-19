check-env:
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

# If the first argument is "install"...
ifeq (playbooks,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "bifrost"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

playbooks: check-env
	cd ska-ser-ansible-collections && $(MAKE) $(TARGET_ARGS)
	
# If the first argument is "orch"...
ifeq (orch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "bifrost"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

orch: check-env
	cd ska-ser-orchestration && $(MAKE) $(TARGET_ARGS) 

# elasticstack: ## call the Makefile in the elasticstack sub-project
# 	export ANSIBLE_SSH_ARGS="-o ForwardAgent=yes -F $(THIS_BASE)/ssh.config " && \
# 	cd elasticstack && make $(TARGET_ARGS) \
# 		PRIVATE_VARS=$(THIS_BASE)/$(ELASTICSTACK_VARS) CLUSTER_KEYPAIR=$(CLUSTER_KEYPAIR) \
# 		INVENTORY_FILE=$(THIS_BASE)/inventory_elasticstack LOGGING_INVENTORY_FILE=$(THIS_BASE)/inventory_elasticstack CLUSTER_INVENTORY=$(ELASTICSTACK_CLUSTER_INVENTORY) \
# 		RUN_TAGS=$(ELASTICSTACK_RUN_TAGS) EXTRA_VARS=$(BIFROST_EXTRA_VARS)