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

    PROMETHEUS_NODE=${DATACENTRE}-${ENVIRONMENT}-${SERVICE}-prometheus-${TF_VAR_ci_pipeline_id}
    THANOS_NODE=${DATACENTRE}-${ENVIRONMENT}-${SERVICE}-thanos-${TF_VAR_ci_pipeline_id}
}

@test 'MONITORING: Cluster hosts are reachable' {
    cd ${BASE_PATH}
    run make playbooks ac-ping PLAYBOOKS_HOSTS="${PROMETHEUS_NODE},${THANOS_NODE}"
    assert_success
}

@test 'MONITORING: prometheus node common init' {
    cd ${BASE_PATH}
    run make playbooks common init PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: thanos node common init' {
    cd ${BASE_PATH}
    run make playbooks common init PLAYBOOKS_HOSTS="${THANOS_NODE}"
    assert_success
}

@test 'MONITORING: prometheus node oci docker' {
    cd ${BASE_PATH}
    run make playbooks oci docker PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: thanos node oci docker' {
    cd ${BASE_PATH}
    run make playbooks oci docker PLAYBOOKS_HOSTS="${THANOS_NODE}"
    assert_success
}

@test 'MONITORING: deploy node-exporter on prometheus node' {
    cd ${BASE_PATH}
    run make playbooks monitoring node-exporter PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: deploy node-exporter on thanos node' {
    cd ${BASE_PATH}
    run make playbooks monitoring node-exporter PLAYBOOKS_HOSTS="${THANOS_NODE}"
    assert_success
}

@test 'MONITORING: generate targets for prometheus' {
    cd ${BASE_PATH}
    run make playbooks monitoring update_targets PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: deploy prometheus' {
    cd ${BASE_PATH}
    run make playbooks monitoring prometheus PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: deploy alertmanager' {
    cd ${BASE_PATH}
    run make playbooks monitoring alertmanager PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: deploy grafana' {
    cd ${BASE_PATH}
    run make playbooks monitoring grafana PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: deploy thanos' {
    cd ${BASE_PATH}
    run make playbooks monitoring thanos PLAYBOOKS_HOSTS="${THANOS_NODE}"
    assert_success
}

@test 'MONITORING: e2e tests prometheus node' {
    cd ${BASE_PATH}
    run make playbooks monitoring test-prometheus PLAYBOOKS_HOSTS="${PROMETHEUS_NODE}"
    assert_success
}

@test 'MONITORING: e2e tests thanos node' {
    cd ${BASE_PATH}
    run make playbooks monitoring test-thanos PLAYBOOKS_HOSTS="${THANOS_NODE}"
    assert_success
}

teardown() {
    finalizeTest
}
