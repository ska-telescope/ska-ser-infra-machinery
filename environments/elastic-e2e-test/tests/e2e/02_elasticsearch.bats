load "../resources/core"
shouldAbortTest ${BATS_TEST_TMPDIR} ${BATS_SUITE_TEST_NUMBER}

setup_file() {
    REQUIRED_ENV_VARS="BASE_PATH ENVIRONMENT ANSIBLE_COLLECTIONS_PATHS PLAYBOOKS_ROOT_DIR CA_CERT_PASS ELASTIC_PASSWORD"
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

# TODO: 
# * Move test playbooks in installation/playbooks to elastic collection/tests
# * Create make target on elastic job called "test" that runs the test playbooks against the cluster
# * Remove all tests below
# * Create a single test here calling the test make target, like:
# @test 'ELASTICSEARCH: Elasticsearch works' {
#     cd ${BASE_PATH}
#    export PLAYBOOKS_HOSTS="${ELASTICSEARCH_CLUSTER_NAME}"
#    run make playbooks elastic test
#    assert_success
# }

@test 'ELASTICSEARCH: Elasticsearch is healthy' {
    run ansible-playbook \
        -e "target_hosts=${ELASTICSEARCH_CLUSTER_NAME}" \
        -e "elastic_password=${ELASTIC_PASSWORD}" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/cluster-health.yml
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch API access is configured' {
    run ansible-playbook \
        -e "target_hosts=${ELASTICSEARCH_CLUSTER_NAME}" \
        -e "elastic_password=${ELASTIC_PASSWORD}" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/client-health.yml
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch loadbalancer is healthy' {
    run ansible-playbook \
        -e "target_hosts=${ELASTICSEARCH_CLUSTER_NAME}" \
        -e "elastic_password=${ELASTIC_PASSWORD}" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/client-health.yml
    assert_success
}

@test 'ELASTICSEARCH: Elasticsearch index CRUD and post events work' {
    run ansible-playbook \
        -e "target_hosts=${ELASTICSEARCH_CLUSTER_NAME}" \
        -e "elastic_password=${ELASTIC_PASSWORD}" \
        ${PLAYBOOKS_ROOT_DIR}/playbooks/index-crud.yml
    assert_success
}

teardown() {
    finalizeTest
}