# SKA Infrastructure Machinery

The Infra Machinery is an umbrella of multiple repositories to manage the infrastructure
supervised by SKAO. It uses [Terraform](https://www.terraform.io/)
for orchestration and [Ansible](https://www.ansible.com/) for installation/configuration.

# Prerequisites

It does not have any direct dependencies but check the READMEs of
each submodule for an updated list of requirements:
* [SKA Orchestration](https://gitlab.com/ska-telescope/sdi/ska-ser-orchestration/-/blob/main/README.md#prerequisites)
* [SKA Ansible Collections](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/main/README.mdska-ser-ansible-collections/README.md#requirements)
* [SKA Makefile](https://gitlab.com/ska-telescope/sdi/ska-cicd-makefile/-/blob/master/README.md)

# Setup

## TLDR

The Makefile has a help target to print these variables and all available targets:

```
make help
```

## Environment Variables

Like the submodules for Terraform and Ansible, this repository does not have any default
variables when running the Makefile targets to avoid any deployment/installation on the
wrong cluster by mistake.

So, the first variables to setup are the **DATACENTRE**, **ENVIRONMENT**, and **SERVICE**. Like the name suggest, they point 
to the datacentre, environment and service we want to work with. These map to the folder structure under [datacentres](datacentres/) (`datacentres/<datacentre>/<environment>/<service>`), which contains the orchestration configuration files. At `datacentres/<datacentre>/<environment>/installation` you can find the environment's inventories you can configure using Ansible.

Please add a PrivateRules.mak with the following variables:

```
DATACENTRE="<datacentre>"
ENVIRONMENT="<environment>"
SERVICE="<service>"
TF_HTTP_USERNAME="<gitlab-username>" # Gitlab User token with the API scope
TF_HTTP_PASSWORD="<user-token>"
```

Follow this [link](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token) to create the Gitlab User token with the **API scope**. If this variable is empty, the Makefile targets will not run for security reasons.

### Other important variables

For Terraform the following specifics variables for the Gitlab's backend are already set in the Makefile:

```
BASE_PATH?=$(shell cd "$(dirname "$1")"; pwd -P)
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
```

Change them carefully if you really need it. 

The PLAYBOOKS_ROOT_DIR indicated where is the inventory file and the respective  group variables.

# How to use

## Make Targets

The Makefile available in this repository has two main targets which redirect
to the two different functionalities that this repository provide.

For [Terraform make targets](https://gitlab.com/ska-telescope/sdi/ska-ser-orchestration/-/blob/main/Makefile) we must use **orch**
as first argument and **playbooks** , for [Ansible Targets](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/main/Makefile).
All the shell env variables are saved and the command arguments are
carried over.

Always check the READMEs for [orchestration](https://gitlab.com/ska-telescope/sdi/ska-ser-orchestration/-/blob/main/README.md)
and [installation](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/main/README.md)
for up-to-date setup and how to use recommendations.

## Project Structure

This a single repository that can manage multiple datacentres, environments and services, so the first step is
to select which one we want. Inside the **./datacentres/** folder, we have all the 
configurations and variables separated by datacentre (cluster), environment and service.


| Cluster           | Environment   | Service    | Folder Path                                      |
| ----------------- | ------------- | ---------- | ------------------------------------------------ |
| STFC TechOps      | production    | monitoring | datacentres/stfc-techops/production/monitoring   |
| STFC TechOps      | production    | logging    | datacentres/stfc-techops/production/logging      |
| STFC TechOps      | production    | gitlab-runner | datacentres/stfc-techops/production/gitlab-runner|
| STFC TechOps      | e2e           | logging    | datacentres/stfc-techops/e2e/logging          |
| STFC TechOps      | dev           | ceph       | datacentres/stfc-techops/dev/ceph                |
| EngageSKA         | dev           | -          | datacentres/engage/  |
| PSI Mid           | production    | -          | datacentres/psi-mid/  |

Inside each cluster subdirectory, we divide the config files for Terraform (orchestration)
and Ansible (installation). Like the example bellow:

```
.
├── Makefile
├── datacentres
|   ├── <datacentre>
|   |   ├──<environment>
│   │   │   ├── installation
│   │   │   │   │   ├── ansible.cfg
│   │   │   │   │   ├── group_vars
│   │   │   │   │   │   └── *.yml
│   │   │   │   │   ├── inventory.yml
│   │   │   │   │   ├── playbooks
│   │   │   │   │   │   └── *.yml
│   │   │   │   │   └── ssh.config
|   |   |   ├── <service>    
│   │   │   │   ├── orchestration
│   │   │   │   │   ├── *.tf
│   │   │   │   │   ├── clouds.yaml
│   │   │   │   │   └── terraform.tfvars
│   │   │   ├── tests
│   │   │   │   ├── e2e # End-to-end tests
│   │   │   │   │   └── *.bats
│   │   │   │   ├── src # Custom functions to use in bats
│   │   │   │   │   └── *.bash
│   │   │   │   └── unit # Unit tests of functions in src/
│   │   │   │       └── *.bats
│   │   │   └── ...
|   |   └── ...
|   └── ... 
├── resources
│   └── keys
|   |   ├── *.pem
├── ska-ser-ansible-collections
└── ska-ser-orchestration
```

## Environment tests

We've added a make target - **test** - to trigger a set of [BATS](https://github.com/bats-core) tests
to test an environment. This allows us to, either manually or in a scheduled pipeline, run checks
against a fresh or an existing environment. With this strategy, we can test every step from orchestration,
installation to services.

Currently, the following test environments are available:

| Cluster           | Environment   | Service    | Folder PATH                           | Goal                                                                   |
| ----------------- | ------------- | ---------- |---------------------------------------|------------------------------------------------------------------------|
| STFC TechOps      | e2e           | logging    | datacentres/stfc-techops/e2e/logging | Deploy an elasticsearch cluster and test the API and cluster integrity |

To trigger tests, do:

```
make test
```

By default, this will run the tests in - relative to *tests/* - the environment's **unit/** and **e2e/** directories.
We can trigger tests targeting individual targets, both relative to **tests/** or by specifying absolute paths in
*BATS_TEST_TARGETS*, using a comma separated list:

```
make test BATS_TEST_TARGETS="<test file name>.bats,[other targets]"
```

We can skip any test files in the runnable test targets by setting *BATS_SKIP_TESTS* using a comma separated list. This
supports both filenames and test case names:

```
make test BATS_SKIP_TESTS="<test case name>,<test file name>.bats,[other targets]"

# example: make test BATS_SKIP_TESTS="INVENTORY: Ansible inventory exists,99_orchestration_teardown.bats"
```

We can also run specific test cases using included in the runnable targets. This can be achieved by adding its name
(full or short name) by setting *BATS_RUN_TESTS* in a comma separated list:

```
make test BATS_RUN_TESTS="<test case name>,[other targets]" 
```

Also, to overcome some bats-core lack of functionality - for instance, stopping execution of tests when a test case fails -
we've created a set of core functions to handle that. For that reason, to write a test file, one **NEEDS** to use
the following boilerplate code:

```
load "../resources/core"
shouldAbortTest ${BATS_TEST_TMPDIR} ${BATS_SUITE_TEST_NUMBER} # evaluates if it should abort test based on previous tests

setup_file() {
    # Write code here that should be executed once per test file
    # before running tests
}

setup() {
    # Load modules for tests in this file
    load "../scripts/bats-file/load"
    load "../scripts/bats-support/load"
    load "../scripts/bats-assert/load"
    # Add other modules
    # e.g: load "../resources/core"

    shouldSkipTest "${BATS_TEST_FILENAME}" "${BATS_TEST_NAME}" $ checks if test should be skipped based on the name
    prepareTest # prepares to evaluate test outcome

    # Write code here that should be executed once per test case
    # before running test
}

@test '<test file id>: <test case name>' {
    # Write test case code
}

teardown() {
    finalizeTest # stores test outcome

    # Write code here that should be executed once per test case
    # after running test
}

teardown_file() {
    # Write code here that should be executed once per test case
    # after running tests
}
```

## Ad hoc

The instances are meant to be worked with using the provided make targets. In the event that you need (e.g, development
purposes) to do manual ansible work, you can set up your shell and issue ansible commands from any working directory
against the environment's inventory. Please, use with caution:

```
eval $(make export-as-envs)
```

## Orchestration on Openstack

Any Terraform files (*.tf) inside the orchestration folder will be
analysed and applied. So every service/VM is described there and use the modules
on the **ska-ser-orchestration** submodule.

The **clouds.yaml** file should also be on this folder along the Terraform files.
This is the only supported authentication for Openstack API. To get this file, go 
to the Openstack Web interface and created a new credential on 
*Identity > Application Credentials* page.

Finally, you just have to init Terraform locally and apply the changes:

```
make orch init
make orch apply
```
Recommendation: Set up the **TF_TARGET** to only apply/destroy to a specific
service/VM. The module name should be the name on the first line of the module
definition:

```
make orch init
make orch apply TF_TARGET="module.<your-module-name>"
```

## Installation via Ansible

The **ssh.config** and **inventory.yml** files automatically generated using:

```
make orch generate-inventory
```

This target call a script to retrieve the TF state from Gitlab and compiles the
data to generate those two files and automatically moves them to the
**$PLAYBOOKS_ROOT_DIR**.

If you want to generate the complete inventory of an environment, please unset **SERVICE**. SERVICE can also be set, but only the service-specific inventory will be present.

We can also generate the inventory bypassing the **jump_host**, by calling:

```
GENERATE_INVENTORY_ARGS="--no-jumphost" make orch generate-inventory
```

To use this option, please make sure the orchestration is well configured following [this](https://gitlab.com/ska-telescope/sdi/ska-ser-orchestration/-/blob/main/README.md).

Finally, run the installation make targets of your choosing.

## Utilities

### Elasticsearch API Key creation and query

A set of make targets were created to help with the creation and query of Elasticsearch API keys.
These targets are defined on a makefile named `elastic.mk` in the `ska-cicd-makefile` repo, `.make` submodule.

The available `make` targets can be called with the command `make playbooks elastic` and are as follows:

- `check`: Check the status of the Elasticsearch cluster.
- `key-list`: List all the existing API keys.
- `key-new KEY_NAME=somename [KEY_expiration=10d]`: Create a new API key with the given name and optional expiration time.
- `key-info KEY_ID=keyid`: Display the information of the given API key using the key id.
- `key-invalidate KEY_ID=keyid`: Invalidate the given API key using the key id.
- `key-query KEY=encodedkey`: Query test for the Elasticsearch cluster health status using the encoded API key.

These make targets need the following environment variables to be set:
- `ELASTICSEARCH_PASSWORD`: Password for the `elastic` user.

Under `.ska-ser-ansible-collections/resources/jobs/elastic.mk` there is a section with the default values for the environment variables as well. These are all set to the default values and will work for the STFC cluster inside STFC VPN.
If you are using a different cluster, you will need to change the values of the environment variables.

```
ELASTIC_USER ?= elastic
LOGGING_URL ?= https://logging.stfc.skao.int:9200
LOADBALANCER_IP ?= logging.stfc.skao.int
CA_CERT ?= /etc/pki/tls/private/ca-certificate.crt
CERT ?= /etc/pki/tls/private/ska-techops-logging-central-prod-loadbalancer.crt
CERT_KEY ?= /etc/pki/tls/private/ska-techops-logging-central-prod-loadbalancer.key
PEM_FILE ?= ~/.ssh/ska-techops.pem
```
