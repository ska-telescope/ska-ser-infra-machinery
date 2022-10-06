# Edit with your config
export ENVIRONMENT="stfc-techops"
export TF_HTTP_USERNAME="sawdyj"
export TF_HTTP_PASSWORD="glpat-3N_e9AFk6xw7zhC3SJ3r" #https://gitlab.com/-/profile/personal_access_tokens


# Do not change these variables
export BASE_PATH="$(cd "$(dirname "$1")"; pwd -P)"
export GITLAB_PROJECT_ID="39377838"
export TF_ROOT_DIR="${BASE_PATH}/environments/${ENVIRONMENT}/orchestration"
export TF_HTTP_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state"
export TF_HTTP_LOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
export TF_HTTP_UNLOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
export PLAYBOOKS_ROOT_DIR="${BASE_PATH}/environments/${ENVIRONMENT}/installation"
export ANSIBLE_CONFIG="${BASE_PATH}/environments/${ENVIRONMENT}/installation/ansible.cfg"
export ANSIBLE_COLLECTIONS_PATHS="${BASE_PATH}/ska-ser-ansible-collections"