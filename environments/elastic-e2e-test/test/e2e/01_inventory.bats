setup_file() {
    REQUIRED_ENV_VARS="BASE_PATH PLAYBOOKS_ROOT_DIR"
    for VAR in ${REQUIRED_ENV_VARS}; do
        if [ -z $(printenv ${VAR}) ]; then
            echo "Environment variable '${VAR}' is not set"
            exit 1   
        fi
    done

    # Start with a clean inventory
    rm -f ${PLAYBOOKS_ROOT_DIR}/inventory.yml ${PLAYBOOKS_ROOT_DIR}/ssh.config
}

setup() {
    load "../scripts/bats-file/load"
    load "../scripts/bats-support/load"
    load "../scripts/bats-assert/load"

    TEST_FILE=$(basename ${BATS_TEST_FILENAME})
    if grep -q "${TEST_FILE}" <<< "${BATS_SKIP_TESTS}"; then
        skip
    fi
}

@test 'INVENTORY: Generate inventory' {
    cd ${BASE_PATH}
    run make orch generate-inventory
    assert_success
}

@test 'INVENTORY: Ansible inventory exists' {
    assert_exist ${PLAYBOOKS_ROOT_DIR}/inventory.yml
}

@test 'INVENTORY: SSH config exists' {
    assert_exist ${PLAYBOOKS_ROOT_DIR}/ssh.config
}

@test 'INVENTORY: Failure to ping unknown group' {
    cd ${BASE_PATH}
    export PLAYBOOKS_HOSTS="some_unknown_group"
    run make playbooks ping
    assert_failure
}

@test 'INVENTORY: Ping all instances' {
    cd ${BASE_PATH}
    run make playbooks ping
    assert_success
}