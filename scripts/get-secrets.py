#!/usr/bin/env -S python3 -u
"""This script creates an ansible-vault protected secrets file from multiple
sources
"""

import logging
import os
import pathlib
import hvac
from argparse import ArgumentParser
from ansible.parsing.vault import VaultLib, VaultSecret

import re
import yaml

LOGGING_LEVEL = os.environ.get("LOGGING_LEVEL", "INFO")
LOGGING_FORMAT = (
    "%(asctime)s [level=%(levelname)s] "
    "[module=%(module)s] [line=%(lineno)d]: %(message)s"
)
logging.basicConfig(level=LOGGING_LEVEL, format=LOGGING_FORMAT)
log = logging.getLogger("get-secrets")
log.debug("Logging level is: %s", LOGGING_LEVEL)


def get_env(variables, default=None):
    """
    Returns the first defined environment variable value for a set of
    variables. If none of the variables are found, returns a default.
    """
    for k in variables:
        value = os.environ.get(k, None)
        if value is not None:
            return value

    return default

def secure_opener(path, flags):
    return os.open(path, flags, 0o600)

def is_excluded(value):
    if value in ["DATACENTRE", "ENVIRONMENT", "SERVICE", "ANSIBLE_SECRETS_PASSWORD"]:
        return True
    
    if value.startswith("VAULT_"):
        return True
    
    return False

def strip_quotes(value):
    if value[0] in ['"', "'"] and value[-1] == value[0]:
        return value[1:len(value)-1]

    return value

def get_config(config, config_name, first=True):
    search = re.findall(config_name + r"[ ]*=[ ]*(\S+)", config)
    if search is None or len(search) == 0:
        return None

    return search[0] if first else search

def set_dict_path_value(d, path, value):
    keys = path.split(".")
    for k in keys[:-1]:
        if not k in d: d[k] = {}
        d = d[k]            
    d[keys[-1]] = value

def get_secrets_from_file(config):
    path = get_config(config, "path")
    if path is None:
        log.error("File path missing. Please provide it by setting path=<file path>")
        exit(1)

    if not os.path.isfile(path):
        log.error("Failed to parse secrets from '%s'", path)
        exit(2)

    log.info("Parsing secrets from file from '%s'", path)
    secrets = {}
    pattern = re.compile(r"(^[a-zA-Z0-9_-]+)[ ]*(=|\?=|:=)[ ]*(.*$)")
    with open(path, "r") as f:
        for line in f.readlines():
            line = line.strip()
            if len(line) == 0 or "=" not in line:
                continue
            
            match = pattern.match(line)
            key = match.group(1)
            if is_excluded(key):
                continue

            secrets[match.group(1).lower()] = strip_quotes(match.group(3))

    return secrets

def get_secrets_from_vault(config):
    vault_addr = get_config(config, "address")
    if vault_addr is None:
        log.error("Vault address missing. Please provide it by setting address=<vault address>")
        exit(1)

    vault_auth_method = get_config(config, "auth_method")
    if vault_auth_method is None:
        log.error("Vault auth method missing. Please provide it by setting auth_method=<auth method>")
        exit(1)

    log.info("Parsing secrets from vault at '%s' using '%s' authentication", vault_addr, vault_auth_method)
    client: hvac.Client = hvac.Client(vault_addr)
    vault_token = None
    if vault_auth_method == "token":
        vault_token = get_config(config, "token")
    elif vault_auth_method == "jwt":
        jwt_token = get_config(config, "token")
        #client.login("")
    elif vault_auth_method == "basic":
        vault_username = get_config(config, "username")
        vault_password = get_config(config, "password")
        #client.login()       

    else:
         log.error("Vault auth method not supported: '%s'", vault_auth_method)
         return None

    client.token = vault_token
    client.renew_token(token=vault_token)

    vault_paths = get_config(config, "paths", first=False)
    if vault_paths is None:
        log.error("Vault paths missing. Please provide it by setting paths=<path>,<path>")
        exit(1)

    secrets = {}
    vault_paths = ",".join(vault_paths).split(",")
    for path in vault_paths:
        if len(path) == 0:
            continue

        if path.startswith("/"):
            path = path[1:]

        leveled_path_parts = path.split("@")
        path_parts = leveled_path_parts[0].split("/")
        if len(path_parts) < 2 or len(path_parts) > 3:
            log.error("Invalid vault path format. Please use <engine>/<secret>[/<key>][@<relocation expression>]")
            exit(1)
        
        engine = path_parts[0]
        secret = path_parts[1]
        key = None if len(path_parts) == 2 else path_parts[2]
        data = client.secrets.kv.v2.read_secret(secret, mount_point=engine)
        relocation_expression = "" if len(leveled_path_parts) == 1 else leveled_path_parts[1]
        if relocation_expression.isnumeric():
            set_levels = [secret, engine][:int(relocation_expression)]
            set_levels.reverse()
            relocation_expression = ".".join(set_levels)

        relocation_expression = relocation_expression.replace("$engine", engine).replace("$secret", secret)
        for secret_key, secret_value in data.get("data", {}).get("data", {}).items():
            if key is None or key == "" or key == secret_key:
                expression = (relocation_expression if relocation_expression != "" else secret_key).replace("$key", secret_key)
                set_dict_path_value(secrets, path=expression, value=secret_value)

    return secrets

SOURCE_TYPE_HANDLERS = {
    "file": get_secrets_from_file,
    "vault": get_secrets_from_vault
}

parser = ArgumentParser(
    description="Ansible secrets generator tool"
)
parser.add_argument(
    "-o", "--output",
    dest="output",
    required=True,
    default="secrets.yml",
    help="output file",
)
parser.add_argument(
    "-s", "--source",
    action='append',
    dest="sources",
    required=True,
    default=[],
    help="set of secret sources to pull from",
)
parser.add_argument(
    "-p", "--password",
    dest="password",
    required=True,
    help="password for generated ansible-vaulted file",
)
parser.add_argument(
    "--password-output",
    dest="password_output",
    required=True,
    default="secrets.password",
    help="password output file",
)
args = parser.parse_args()

# Create output directories
pathlib.Path(os.path.dirname(os.path.abspath(args.output))).mkdir(parents=True, exist_ok=True)
pathlib.Path(os.path.dirname(os.path.abspath(args.password_output))).mkdir(parents=True, exist_ok=True)

# Write ansible-vault password file
with open(args.password_output, 'w+', opener=secure_opener) as f:
    f.write(args.password) 

secrets_store = {}
for source in args.sources:
    source_type = get_config(source, "type")
    handler = SOURCE_TYPE_HANDLERS.get(source_type, None)
    if handler is None:
        log.error("Unrecognized source type '%s'", source_type)
        continue

    secrets = handler(source)
    if secrets is not None:
        secrets_store = {**secrets_store, **secrets}

with open(args.output + ".raw", "w+", opener=secure_opener) as f:
    f.write(yaml.safe_dump({"secrets": secrets_store}, indent=2))

# Output secrets
with open(args.output, "wb+", opener=secure_opener) as f:
    f.write(VaultLib().encrypt(yaml.safe_dump({"secrets": secrets_store}, indent=2), secret=VaultSecret(args.password.encode())))
    log.info("Secrets password at %s", args.password_output)
    log.info("Secrets at %s", args.output)
