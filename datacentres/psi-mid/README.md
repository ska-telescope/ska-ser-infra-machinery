## PSI-Mid Environment

To setup access to the PSI-Mid inventory, please make sure:

### PSI Instances
* Your **personal** SSH key has been added to user 'svc_skadev_ansible' in **all** PSI-Mid instances
* Your **personal** SSH key is in one of the following paths (note the name psi-mid.pem):

  * \<ska-ser-infra-machinery path\>/resources/keys/psi-mid.pem
  * ~/.ssh/psi-mid.pem

### Certificate Authority Instance
* You have **ska-techops.pem** SSH key in one of the following paths:

  * \<ska-ser-infra-machinery path\>/resources/keys/ska-techops.pem
  * ~/.ssh/ska-techops.pem
