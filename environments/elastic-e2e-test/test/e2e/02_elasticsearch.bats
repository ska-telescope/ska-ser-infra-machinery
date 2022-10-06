setup_file() {
    REQUIRED_ENV_VARS="BASE_PATH ENVIRONMENT PLAYBOOKS_ROOT_DIR"
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

    TEST_FILE=$(basename ${BATS_TEST_FILENAME})
    if grep -q "${TEST_FILE}" <<< "${BATS_SKIP_TESTS}"; then
        skip
    fi

    ELASTICSEARCH_CLUSTER_GROUP=${ENVIRONMENT}
}

@test 'ELASTICSEARCH: Cluster hosts are reachable' {
    cd ${BASE_PATH}
    export PLAYBOOKS_HOSTS="${ELASTICSEARCH_CLUSTER_GROUP}"
    run make playbooks ping 
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch installs' {
    cd ${BASE_PATH}
    export PLAYBOOKS_HOSTS="${ELASTICSEARCH_CLUSTER_GROUP}"
    run make playbooks elastic install
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch is healthy' {
    cd ${PLAYBOOKS_ROOT_DIR}
    run ansible-playbook \
        -l "${ELASTICSEARCH_CLUSTER_GROUP}" \
        ./playbooks/health.yml
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch is accessible by clients' {
    cd ${PLAYBOOKS_ROOT_DIR}
    run ansible-playbook \
        -l "${ENVIRONMENT}-client" \
        -e "elasticsearch_node_group=${ENVIRONMENT}" \
        ./playbooks/client_access.yml
    assert_success
}