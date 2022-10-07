setup_file() {
    REQUIRED_ENV_VARS="BASE_PATH ENVIRONMENT ANSIBLE_COLLECTIONS_PATHS PLAYBOOKS_ROOT_DIR"
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
    load "../src/functions"

    shouldSkipTest "${BATS_TEST_FILENAME}" "${BATS_TEST_NAME}"

    ELASTICSEARCH_CLUSTER_NAME=${ENVIRONMENT}
}

@test 'ELASTICSEARCH: Cluster hosts are reachable' {
    cd ${BASE_PATH}
    export PLAYBOOKS_HOSTS="${ELASTICSEARCH_CLUSTER_NAME}"
    run make playbooks ping 
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch installs' {
    cd ${BASE_PATH}
    export PLAYBOOKS_HOSTS="${ELASTICSEARCH_CLUSTER_NAME}"
    run make playbooks elastic install
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch is healthy' {
    run ansible-playbook \
        -l "${ELASTICSEARCH_CLUSTER_NAME}-master" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/cluster-health.yml
    assert_success
}

@test 'ELASTICSEARCH: Client works with cluster' {
    run ansible-playbook \
        -l "${ELASTICSEARCH_CLUSTER_NAME}-client" \
        -e "elasticsearch_node_groups=${ELASTICSEARCH_CLUSTER_NAME}-master" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/client-health.yml
    assert_success
}

@test 'ELASTICSEARCH: Index CRUD and post events work' {
    run ansible-playbook \
        -l "${ELASTICSEARCH_CLUSTER_NAME}-client" \
        -e "elasticsearch_node_groups=${ELASTICSEARCH_CLUSTER_NAME}-master" \
        -e "elasticsearch_index=${ELASTICSEARCH_CLUSTER_NAME}-idx" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/index-crud.yml
    assert_success
}