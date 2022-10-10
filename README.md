# SKA Infrastructure Machinery

The Infra Machinery is an umbrella of multiple repositories to manage the infrastructure 
supervise by SKAO. It uses [Terraform](https://www.terraform.io/) 
for orchestration and [Ansible](https://www.ansible.com/) for installation/configuration.

# Prerequisites

It does not have any direct dependencies but check the READMEs of 
each submodule for an updated list of requirements:
* [SKA Orchestration](./ska-ser-orchestration/README.md#prerequisites)
* [SKA Ansible Collections](./ska-ser-ansible-collections/README.md#requirements)
* [SKA Makefile](./.make/README.md)

# Setup

## TLDR

We already create the **setenv.sh** script with every variable mandatory.
 Just change the first three variables and source the file on your terminal.

```
source setenv.sh
```

The Makefile has a help target to print these variables and all available targets:

```
make help
```

## Environment Variables

Like the submodules for Terraform and Ansible, this repository does not have any default 
variables when running the Makefile targets to avoid any deployment/installation on the
wrong cluster my mistake.

So, the first variable to setup is the **ENVIRONMENT**. Like the name suggest, it points 
to the environment we want to work with.

```
export ENVIRONMENT="stfc-techops"
export TF_HTTP_USERNAME="<gitlab-username>" # Gitlab User token with the API scope
export TF_HTTP_PASSWORD="<user-token>"
```

Follow this [link](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token) to create the Gitlab User token with the API scope. If this variable is empty, the Makefile targets will not run for security reasons.

### Other important variables

For Terraform the following specifics variables for the Gitlab's backend are already set in the Makefile:

```
BASE_PATH="$(shell cd "$(dirname "$1")"; pwd -P)"
GITLAB_PROJECT_ID="39377838"
TF_ROOT_DIR="${BASE_PATH}/environments/${ENVIRONMENT}/orchestration"
TF_HTTP_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state"
TF_HTTP_LOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
TF_HTTP_UNLOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
PLAYBOOKS_ROOT_DIR="${BASE_PATH}/environments/${ENVIRONMENT}/installation"
ANSIBLE_CONFIG="${BASE_PATH}/environments/${ENVIRONMENT}/installation/ansible.cfg"
ANSIBLE_COLLECTIONS_PATHS="${BASE_PATH}/ska-ser-ansible-collections"
```

Change them carefully if you really need it. 

The PLAYBOOKS_ROOT_DIR indicated where is the inventory file and the respective  group variables.

# How to use

## Make Targets

The Makefile available in this repository has two main targets which redirect 
to the two different functionalities that this repository provide.

For [Terraform make targets](./ska-ser-orchestration/Makefile) we must use **orch** 
as first argument and **playbooks** , for [Ansible Targets](./ska-ser-ansible-collections/Makefile).
All the shell env variables are saved and the command arguments are 
carried over.

Always check the READMEs for [orchestration](./ska-ser-orchestration/README.md#Getting&#32;started)
and [installation](./ska-ser-ansible-collections/README.md#Usage) 
for up-to-date setup and how to use recommendations.

## Project Structured

 This a single repository that can manage multiple environments, so the first step is
 to select which one we want. Inside the **./environments/** folder, we have all the 
 configurations and variables separated by cluster.

| Cluster           | Folder Name   |
| ----------------- | -------       |
| STFC TechOps      | stfc-techops  |
| STFC TechSDH&P    | stfc-techsdhp |
| EngageSKA         | engage        |
| PSI Low           | psi-low       |
| PSI Mid           | psi-mid       |

Inside each cluster subdirectory, we divide the config files for Terraform (orchestration)
and Ansible (installation). Like the example bellow:

 ```
environments/
│     
└─── stfc-techops/
│   │   
│   └─── orchestration
│   │       *.tf
│   │       clouds.yaml
│   │       ...
│   └─── installation
│       │   ansible.cfg
│       │   inventory.yml
│       │   ssf.config
│       └─── groups_vars
│           │    all.yml
│           │    ...
│    
└─── ...
```

## Orchestration on Openstack

Any Terraform files (*.tf) inside the orchestration folder will be 
analysed and applied. So every service/VM is described there and use the modules
on the **ska-ser-orchestration** submodule.

The **clouds.yaml** file should also be on this folder along the Terraform files.
This is the only supported authentication for Openstack API. Go to the Openstack
Web interface and created a new credencial on *Identity > Application Credentials*
page.

Finally, you just have to init Terraform locally and apply the changes:

```
make orch init
make orch apply 
```
Recommendation: Setup the **TF_TARGET** to only apply/destroy to a specific 
service/VM. The module name should be name on the first line of the module 
definition:

```
make orch init
make orch apply TF_TARGET="module.<your-module-name>"
```

## Installation via Ansible

The **ssf.config** and **inventory.yml** files automatically generated using:

```
make orch generate-inventory
```

This target call a script to retrieve the TF state from Gitlab and compiles the
data to generate those two files and automatically moves them to the 
**$PLAYBOOKS_ROOT_DIR**.

Finally, run the installation make targets of your choosing.

