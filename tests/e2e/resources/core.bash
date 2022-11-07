log() {
    echo $@ >&3
}

prepareTest(){
    STDERR_BEGIN_TEST_MARK=$(stat -L -c %y /proc/self/fd/2)
}

finalizeTest() {
    # Workaround for $status carrying the run <command> status and not the test
    # execution status. If data goes to STDERR, then the test failed
    STDERR_END_TEST_MARK=$(stat -L -c %y /proc/self/fd/2)
    if [ "$STDERR_BEGIN_TEST_MARK" = "$STDERR_END_TEST_MARK" ]; then
        echo "0" > ${BATS_TEST_TMPDIR}.result
    else
        TEST_STATUS=1
        if [ $status -ne 0 ]; then
            TEST_STATUS=$status
        fi
        echo $TEST_STATUS > ${BATS_TEST_TMPDIR}.result
    fi

    if grep -Eo "^${BATS_TEST_NAME}.*" ${BATS_TEST_SOURCE} | grep -q "bats-ignore-failure"; then
        touch ${BATS_TEST_TMPDIR}.ignore_failure
    fi
}

shouldAbortTest() {
    if [ "${1}" == "" ]; then
        return 0
    fi

    TEST_DIR=$(dirname ${1})
    if [ -f ${TEST_DIR}/aborted ]; then
        exit 1
    fi

    TEST_NUMBER=${2}
    PREVIOUS_TEST_NUMBER=$((${TEST_NUMBER}-1))
    if [ ${PREVIOUS_TEST_NUMBER} -ge 1 ]; then
        PREVIOUS_TEST_STATUS=1
        if [ -f ${TEST_DIR}/${PREVIOUS_TEST_NUMBER}.result ]; then
           PREVIOUS_TEST_STATUS=$(cat ${TEST_DIR}/${PREVIOUS_TEST_NUMBER}.result)
        fi
        IGNORE_PREVIOUS_TEST_FAILURE=${TEST_DIR}/${PREVIOUS_TEST_NUMBER}.ignore_failure
        if [ -f ${IGNORE_PREVIOUS_TEST_FAILURE} ] && [ $PREVIOUS_TEST_STATUS -ne 0 ]; then
            log "bats-core: Ignoring test failure from $(cat ${TEST_DIR}/${PREVIOUS_TEST_NUMBER}.name) [STATUS ${PREVIOUS_TEST_STATUS}]"
        elif [ $PREVIOUS_TEST_STATUS -ne 0 ]; then
            log "bats-core: Aborting tests due to failure from $(cat ${TEST_DIR}/${PREVIOUS_TEST_NUMBER}.name) [STATUS ${PREVIOUS_TEST_STATUS}]"
            touch ${TEST_DIR}/aborted
            exit 1
        fi
    fi

    return 0
}

shouldSkipTest() {
    # Skip test based on filename
    TEST_FILE_NAME=$(basename ${1})
    if grep -q "${TEST_FILE_NAME}" <<< "${BATS_SKIP_TESTS}"; then
        skip
    fi

    # Skip test based test name
    ENCODED_TEST_NAME=$((sed 's#_#%20#g' <<< "${2}") | sed 's#-\([0-9a-zA-Z]*%20\)#%\1#' | sed 's/+/ /g;s/%\(..\)/\\x\1/g')
    TEST_FULL_NAME=$(printf "%b" "${ENCODED_TEST_NAME}" | sed 's/^test//')
    TEST_SHORT_NAME=$(printf "%b" "${ENCODED_TEST_NAME}" | sed 's/^test.*: //')
    if grep -q "${TEST_FULL_NAME}" <<< "${BATS_SKIP_TESTS}"; then
        skip
    fi
    if grep -q "${TEST_SHORT_NAME}" <<< "${BATS_SKIP_TESTS}"; then
        skip
    fi

    # Skip tests if not in test cases to run
    if [ "${BATS_RUN_TESTS}" != "" ]; then
        SKIP=1
        for RUN_TEST in $(echo $BATS_RUN_TESTS | sed 's# #_#g' | tr "," "\n"); do
            if grep -q "$(sed 's#_# #g' <<< ${RUN_TEST})" <<< "${TEST_FULL_NAME}"; then
                SKIP=0
            fi
        done

        if [ $SKIP -eq 1 ]; then
            skip
        fi
    fi
}