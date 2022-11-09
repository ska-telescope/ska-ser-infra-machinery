load "../resources/core"
shouldAbortTest ${BATS_TEST_TMPDIR} ${BATS_SUITE_TEST_NUMBER}

setup_file() {
    REQUIRED_ENV_VARS="BASE_DIR BASE_PATH GITLAB_PROJECT_ID TF_ROOT_DIR TF_INVENTORY_DIR TF_VAR_group_name"
    for VAR in ${REQUIRED_ENV_VARS}; do
        if [ -z $(printenv ${VAR}) ]; then
            echo "Environment variable '${VAR}' is not set"
        exit 1   
        fi
    done

    TEST_FILE=$(basename ${BATS_TEST_FILENAME})
    TEST_TMP_DIR=${BASE_DIR}/build/tmp/$(echo ${TEST_FILE} | md5sum | head -c 8)
    mkdir -p ${TEST_TMP_DIR}
}

setup() {
    load "../scripts/bats-file/load"
    load "../scripts/bats-support/load"
    load "../scripts/bats-assert/load"
    load "../resources/utils"

    shouldSkipTest "${BATS_TEST_FILENAME}" "${BATS_TEST_NAME}"
    prepareTest

    TEST_FILE=$(basename ${BATS_TEST_FILENAME})
    TEST_TMP_DIR=${BASE_DIR}/build/tmp/$(echo ${TEST_FILE} | md5sum | head -c 8)
    PLAN_OUTPUT=${TEST_TMP_DIR}/plan
    PLAN_OUTPUT_TXT=${TEST_TMP_DIR}/plan.out

    TEST_STATE_JSON=${BASE_PATH}/build/states/${TF_VAR_group_name}.json
}

@test 'ORCHESTRATION: Clean' {
    cd ${BASE_PATH}
    run make orch clean
    assert_success
}

@test 'ORCHESTRATION: Init' {
    cd ${BASE_PATH}
    export TF_ARGUMENTS="-input=false"
    run make orch init
    assert_success
}

@test 'ORCHESTRATION: Plan' {
    cd ${BASE_PATH}
    export TF_ARGUMENTS="-input=false -no-color -out=${PLAN_OUTPUT}"
    run make orch plan
    echo "$output" > ${PLAN_OUTPUT_TXT}
    eval $(parsePlan ${PLAN_OUTPUT_TXT})

    # Allow nothing to be added if infrastructure is up to date
    # or only to be added, if it is non existing.
    assert_equal ${PLAN_TO_UPDATE} 0
    assert_equal ${PLAN_TO_DESTROY} 0
}

@test 'ORCHESTRATION: Apply' {
    cd ${BASE_PATH}
    export TF_ARGUMENTS="-input=false -no-color"
    export TF_AUTO_APPROVE=true
    run make orch apply
    assert_success
}

@test 'ORCHESTRATION: Plan is idempotent' {
    cd ${BASE_PATH}
    export TF_ARGUMENTS="-input=false -no-color -out=${PLAN_OUTPUT}"
    run make orch plan
    echo "$output" > ${PLAN_OUTPUT_TXT}
    eval $(parsePlan ${PLAN_OUTPUT_TXT})

    # Allow nothing to be added, changed or destroyed
    assert_equal ${PLAN_TO_ADD} 0
    assert_equal ${PLAN_TO_UPDATE} 0
    assert_equal ${PLAN_TO_DESTROY} 0
}

@test 'ORCHESTRATION: Generate JSON tfstate' {
    cd ${BASE_PATH}
    mkdir -p build/states
    cat "${TF_ROOT_DIR}/terraform.tfstate" > ${TEST_STATE_JSON}
    assert_success
}

teardown() {
    finalizeTest
}

teardown_file() {
    rm -rf ${TEST_TMP_DIR}
}