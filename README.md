# SKA Infrastructure Machinery

The Infra Machinery is an umbrella of multiple repositories to manage the infrastructure
supervised by SKAO. It uses [Terraform](https://www.terraform.io/)
for orchestration and [Ansible](https://www.ansible.com/) for installation/configuration.

# Prerequisites

It does not have any direct dependencies but check the READMEs of
each submodule for an updated list of requirements:
* [SKA Orchestration](https://gitlab.com/ska-telescope/sdi/ska-ser-orchestration/-/blob/main/README.md#prerequisites)
* [SKA Ansible Collections](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/main/README.md#requirements)
* [SKA Makefile](https://gitlab.com/ska-telescope/sdi/ska-cicd-makefile/-/blob/main/README.md)

# Setup

## TLDR

The Makefile has a help target to show all available targets:

```
make im-help
```

And all available variables:

```
make im-vars
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

### Secrets management

Currently we are refactoring the playbooks in *ska-ser-ansible-collections* to only use variables defined within the playbook's default variables and ansible group_vars/host_vars. Also, for increased security and easability of use, we've introduced new mechanisms to use secret variables in ansible. The particular provider to use, is set by the variable `ANSIBLE_SECRETS_PROVIDER`. This works independently of **environment variables**, that only get used if we use to the following variable-setting pattern:

```
some_variable: "{{ lookup('ansible.builtin.env', 'SOME_VARIABLE', default=secrets['some_variable']) | mandatory }}"
```

This way, we can guarantee that mandatory variables have a value, and we can set its value both with an environment variable (suits better CI environments) and PrivateRules.mak (or in the future, secrets.yml files) variables. Whether we define `SOME_VARIABLE` as an environment variable, or `SOME_VARIABLE=value` in PrivateRules.mak (using the legacy provider), we can pass secrets without declaring them in any Makefile, which is scalable. Using the **mandatory** filter, also makes Ansible throw an error if it is not defined. Below are the supported secrets providers:

* **legacy** (default) - Converts variables in PrivateRules.mak to an yaml file (in `ANSIBLE_SECRETS_PATH`) and adds it as extra vars to ansible-playbook calls. The variables will be under the "umbrella" value of "**secrets**".
* plain-text - Adds as extra vars to ansible-playbook calls the file specified by `ANSIBLE_SECRETS_PATH`. The variables are **expected** to be under the "umbrella" value of "secrets".
* ansible-vault - Adds as extra vars to ansible-playbook calls the file specified by `ANSIBLE_SECRETS_PATH`, protected by the password specified by `ANSIBLE_SECRETS_PASSWORD`. Ansible will decrypt the secrets file at the time of usage, so that it is not exposed. The variables are **expected** to be under the "umbrella" value of "secrets".

Any of these providers will inject variables under the **secrets** umbrella value, that can be used in a pattern as show above.

The PLAYBOOKS_ROOT_DIR/INVENTORY indicates where is the inventory file and the respective group variables. Also, with the introduction of datacentre, environment and service notions, as well as secrets, the following variables are also critical: 

```
ANSIBLE_SECRETS_PROVIDER?=legacy
ANSIBLE_SECRETS_PATH?=$(BASE_PATH)/secrets.yml
ANSIBLE_SECRETS_PASSWORD?=
ANSIBLE_EXTRA_VARS?=--extra-vars 'ska_datacentre=$(DATACENTRE) ska_environment=$(ENVIRONMENT) ska_service=$(SERVICE) ska_ci_pipeline_id=$(CI_PIPELINE_ID)'
```

If using secrets with datacentre or environment as keys, we can generically describe them and use the values injected here. With the introduction of these
variables (datacentre, environment and service), we've also added them to Terraform, and they are injected as environment variables. That way we can
standardize a bit more our Terraform code and require less changes, and be less error prone, as the values are those of the **environment variables**.
Note that `ska_ci_pipeline_id` is only used for testing. It is also available as a Terraform variable, as we are going to see below.

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
│   │   │   ├── orchestration
|   |   |   |   ├── <service>
│   │   │   │   │   ├── *.tf
│   │   │   │   │   ├── clouds.yaml
│   │   │   │   │   └── terraform.tfvars
|   |   └── ...
|   └── ... 
├── tests
│   └── e2e
|   |   ├── unit
|   |   |   ├── *.bats
|   |   ├── cleanup
|   |   |   ├── *.bats
|   |   ├── setup
|   |   |   ├── *.bats
|   |   ├── logging
|   |   |   ├── *.bats
|   |   ├── resources
|   |   |   ├── *.sh
├── resources
│   └── keys
|   |   ├── *.pem
├── ska-ser-ansible-collections
└── ska-ser-orchestration
```


## Environment tests

We've added a make target - **im-test** - to trigger a set of [BATS](https://github.com/bats-core) tests
to test an environment. This allows us to, either manually or in a scheduled pipeline, run checks
against a fresh or an existing environment. With this strategy, we can test every step from orchestration,
installation to services.

Currently, the following test environments are available:

| Cluster           | Environment   | Service    | Folder PATH                           | Goal                                                                   |
| ----------------- | ------------- | ---------- |---------------------------------------|------------------------------------------------------------------------|
| STFC TechOps      | e2e           | logging    | datacentres/stfc-techops/e2e/orchestration/logging | Deploy an elasticsearch cluster and test the API and cluster integrity |

To trigger tests, do:

```
make im-test
```

As we mean to run tests in CI pipelines in parallel, we need our infrastructure to be named after the CI pipeline creating it.
For that we've created `CI_PIPELINE_ID` Makefile variable. This variable is used as `TF_VAR_ci_pipeline_id` to pass it as a
Terraform variable (see https://developer.hashicorp.com/terraform/language/values/variables#environment-variables) and is also
passed to Ansible as `ska_ci_pipeline_id`. That way, we can use the same variable to name our infrastructure and to refer to it
when running Ansible code.

By default, this will run the tests in - relative to *tests/* - the **unit/**, **setup/** and **cleanup/** directories. Before the
*cleanup* (of the infrastructure), the tests named after the **SERVICE** will also be executed.
We can trigger tests targeting individual targets, both relative to **tests/** or by specifying absolute paths in
*BATS_TEST_TARGETS*, using a comma separated list:

```
make im-test BATS_TEST_TARGETS="<test file name>.bats,[other targets]"
```

We can skip any test files in the runnable test targets by setting *BATS_SKIP_TESTS* using a comma separated list. This
supports both filenames and test case names:

```
make im-test BATS_SKIP_TESTS="<test case name>,<test file name>.bats,[other targets]"

# example: make im-test BATS_SKIP_TESTS="INVENTORY: Ansible inventory exists,99_orchestration_teardown.bats"
```

We can also run specific test cases using included in the runnable targets. This can be achieved by adding its name
(full or short name) by setting *BATS_RUN_TESTS* in a comma separated list:

```
make im-test BATS_RUN_TESTS="<test case name>,[other targets]"
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
purposes) to do manual Ansible work, you can set up your shell and issue Ansible commands from any working directory
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

Currently, we are generating the inventory assuming that the source machine is either within the network (ie, runner or dev machine)
or using the environment's VPN. If that is the case, we can also bypass the jumphost usage by using:

```
GENERATE_INVENTORY_ARGS="--no-jumphost" make orch generate-inventory
```

Note that for some VPNs, the property `vpn_cidr_blocks` has to be updated with the proper CIDR block for the VPN (eg, EngageSKA) to allow
SSH access. If we are outside of the VPN/network we must use a jumphost, and for that, the inventory should be generated using:

```
GENERATE_INVENTORY_ARGS="--prefer-floating-ip" make orch generate-inventory
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
To create API keys, simply define them in an appropriate ansible variable file:

```
elasticsearch_api_keys:
    some_key:
        duration: <optional duration, defaults to infinity>
        description: <some appropriate description of the api key>
        role_descriptiors: <set of roles to restrict the permissions of the api key>
```

This is a declarative approach, therefore keys present will be created, keys removed will be deleted (invalidated). Also, keys genereated outside of this target (without the appropriate metadata) are not considered. To do that, run:

`make playbooks logging update-api-keys PLAYBOOKS_HOSTS=<elasticsearch cluster group>`

When running this target, make sure you note down the api-key, as it is only visible once. To list the managed keys, do:

`make playbooks logging list-api-keys PLAYBOOKS_HOSTS=<elasticsearch cluster group>`

## How to Contribute

### Add/Update an Datacentre/Environment/Service
Any changes to the repository should follow the structured defined on the section "Project Structured". Go to the *./collections* folder to find multiple examples of
deployments for the various combinations of deployments.

Developers can have a development (**datacentres/\**/dev) environment to develop and/or test their changes but **should not** be merge to the main branch.

### Add/Update new variables

Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory directory (*PLAYBOOKS_ROOT_DIR*).

For the secret variables, follow the detailed topic "Secrets management". To assign proper values to these variables, please use a `PrivateRules.mak` file.
