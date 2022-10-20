# ---------------------- Config ---------------------- #
terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~>1.48.0"
    }
  }

  # Requires the following environment variables:
  # export ENVIRONMENT="<environment name>"
  # export GITLAB_PROJECT_ID="<gitlab project id>"
  # export TF_HTTP_USERNAME="<gitlab username>"
  # export TF_HTTP_PASSWORD="<gitlab user access token>"
  # export TF_HTTP_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state"
  # export TF_HTTP_LOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"
  # export TF_HTTP_UNLOCK_ADDRESS="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${ENVIRONMENT}-terraform-state/lock"

  backend "http" {
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
    retry_wait_max = 30
  }
}
# --------------------------------------------------- #

# -------------------- Providers -------------------- #
provider "openstack" {
  cloud       = var.openstack.cloud
  tenant_id   = var.openstack.project_id
  max_retries = 12 // 2 minutes
}
# --------------------------------------------------- #
