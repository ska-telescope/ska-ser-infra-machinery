load "../src/core"
shouldAbortTest ${BATS_TEST_TMPDIR} ${BATS_SUITE_TEST_NUMBER}

setup_file() {
    TEST_FILE=$(basename ${BATS_TEST_FILENAME})
    TEST_TMP_DIR=${BASE_DIR}/build/tmp/$(echo ${TEST_FILE} | md5sum | head -c 8)
    mkdir -p ${TEST_TMP_DIR}
}

setup() {
    load "../scripts/bats-file/load"
    load "../scripts/bats-support/load"
    load "../scripts/bats-assert/load"
    load "../src/utils"

    shouldSkipTest "${BATS_TEST_FILENAME}" "${BATS_TEST_NAME}"
    prepareTest

    TEST_FILE=$(basename ${BATS_TEST_FILENAME})
    TEST_TMP_DIR=${BASE_DIR}/build/tmp/$(echo ${TEST_FILE} | md5sum | head -c 8)
    PLAN_OUTPUT_TXT=${TEST_TMP_DIR}/plan.out
}

@test 'FUNCTIONS: parsePlan no changes' {
    echo "No changes. Your infrastructure matches the configuration" > ${PLAN_OUTPUT_TXT}
    eval $(parsePlan ${PLAN_OUTPUT_TXT})
    assert_equal ${PLAN_TO_ADD} 0
    assert_equal ${PLAN_TO_UPDATE} 0
    assert_equal ${PLAN_TO_DESTROY} 0
}

@test 'FUNCTIONS: parsePlan changes' {
    echo "Plan: 1 to add, 22 to change, 333 to destroy." > ${PLAN_OUTPUT_TXT}
    eval $(parsePlan ${PLAN_OUTPUT_TXT})
    assert_equal ${PLAN_TO_ADD} 1
    assert_equal ${PLAN_TO_UPDATE} 22
    assert_equal ${PLAN_TO_DESTROY} 333
}

teardown() {
    finalizeTest
}

teardown_file() {
    rm -rf ${TEST_TMP_DIR}
}