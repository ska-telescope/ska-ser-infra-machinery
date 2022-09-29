# SKA Infrastructure Machinery

The Infra Machinery is an umbrella of multiple repositories to manage the infrastructure 
supervise by the SYSTEM & BANG teams. It uses [Terraform](https://www.terraform.io/) 
for orchestration and [Ansible](https://www.ansible.com/) for installation/configuration.

# Prerequisites

It does not have any direct dependencies but check the READMEs of 
each submodule for an updated list of requirements:
* [SKA Orchestration](./ska-ser-orchestration/README.md#prerequisites)
* [SKA Ansible Collections](./ska-ser-ansible-collections/README.md#requirements)
* [SKA Makefile](./.make/README.md)

# Setup

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

## Environment Variables

Like the submodules for Terraform and Ansible, this repository does not have any default 
variables when running the Makefile targets to avoid any deployment/installation on the
wrong cluster my mistake.

So, the first variable to setup is the **ENVIRONMENT**. Like the name suggest, it points 
to the environment we want to work with.

```
export ENVIRONMENT="stfc-techops"
```

If this variable is empty, the Makefile targets will not run for security reasons.

### Terraform

Next, we need to configure the Terraform specifics variables for the 
Gitlab's backend:

```
export GITLAB_PROJECT_ID="<project-id>"
export TF_HTTP_USERNAME="<gitlab-username>"
export TF_HTTP_PASSWORD="<user-token>"
export TF_HTTP_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state"
export TF_HTTP_LOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
export TF_HTTP_UNLOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
```

Follow this [link](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token)
to create the Gitlab User token.

Now, we need to pinpoint where are the Terraform files are located:

```
export BASE_PATH="$(cd "$(dirname "$1")"; pwd -P)"
export TF_ROOT_DIR="${BASE_PATH}/environments/${ENVIRONMENT}/orchestration"
```

This way the directory is absolute and always based on the environment.

## Ansible

Following the same rationale, we need to specify where the ansible files/variables 
are placed:

```
export PLAYBOOKS_ROOT_DIR="${BASE_PATH}/environments/${ENVIRONMENT}/installation"
export ANSIBLE_CONFIG="${BASE_PATH}/environments/${ENVIRONMENT}/installation/ansible.cfg"
export ANSIBLE_COLLECTIONS_PATHS="${BASE_PATH}/ska-ser-ansible-collections"
```

The PLAYBOOKS_ROOT_DIR indicated where is the inventory file and the respective 
group variables.

# How to use

The umbrella makefile only redirects to the corresponding submodule Makefile. This means
that orchestration and installation are completely independent.

For Terraform make targets we must use **orch** as first argument and **playbooks**
, for Ansible. All the shell env variables are saved and the command arguments are 
carried over.

For example, we are required to specify which hosts to run the playbooks to install 
ElasticSearch cluster. For that, we need to setup the variable **PLAYBOOKS_HOSTS**. 
It is possible to define before running the command.

```
export PLAYBOOKS_HOSTS="central-logging"
make playbooks elastic install
```

Or as command line argument:

```
make playbooks elastic install PLAYBOOKS_HOSTS="central-logging"
```

Always check the READMEs for [orchestration](./ska-ser-orchestration/README.md)
and [installation](./ska-ser-ansible-collections/README.md) for up-to-date variable
requirements.
