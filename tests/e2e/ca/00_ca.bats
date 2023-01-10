load "../resources/core"
shouldAbortTest ${BATS_TEST_TMPDIR} ${BATS_SUITE_TEST_NUMBER}

setup_file() {
    REQUIRED_ENV_VARS="BASE_PATH ANSIBLE_COLLECTIONS_PATHS INVENTORY PLAYBOOKS_ROOT_DIR DATACENTRE ENVIRONMENT SERVICE TF_VAR_ci_pipeline_id"
    for VAR in ${REQUIRED_ENV_VARS}; do
        if [ -z $(printenv ${VAR}) ]; then
            echo "Environment variable '${VAR}' is not set"
            exit 1
        fi
    done
}

setup() {
    load "../scripts/bats-file/load"
    load "../scripts/bats-support/load"
    load "../scripts/bats-assert/load"

    shouldSkipTest "${BATS_TEST_FILENAME}" "${BATS_TEST_NAME}"
    prepareTest

    CA_INSTANCE_NAME=${DATACENTRE}-${ENVIRONMENT}-${SERVICE}-${TF_VAR_ci_pipeline_id}
}

@test 'CA: Cluster hosts are reachable' {
    cd ${BASE_PATH}
    run make playbooks ac-ping PLAYBOOKS_HOSTS="${CA_INSTANCE_NAME}"
    assert_success
}

@test 'CA: CA installs' {
    cd ${BASE_PATH}
    run make playbooks common init PLAYBOOKS_HOSTS="${CA_INSTANCE_NAME}"
    assert_success
    run make playbooks common setup-ca PLAYBOOKS_HOSTS="${CA_INSTANCE_NAME}"
    assert_success
}

@test 'CA: CA e2e tests' {
    cd ${BASE_PATH}
    run make playbooks common test-ca PLAYBOOKS_HOSTS="${CA_INSTANCE_NAME}"
    assert_success
}

teardown() {
    finalizeTest
}