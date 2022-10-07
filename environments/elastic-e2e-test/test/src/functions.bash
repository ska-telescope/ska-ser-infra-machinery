parsePlan() {
    PLAN="PLAN_TO_ADD=0 PLAN_TO_UPDATE=0 PLAN_TO_DESTROY=0"
    PLAN_SUMMARY=$(grep -Eo "^Plan: .*$" ${1} || echo "")
    if [ "${PLAN_SUMMARY}" != "" ]; then
        PLAN=$(echo "${PLAN_SUMMARY}" | sed "s/.* \([0-9]\+\) .* \([0-9]\+\) .* \([0-9]\+\).*/PLAN_TO_ADD=\1 PLAN_TO_UPDATE=\2 PLAN_TO_DESTROY=\3/")
    fi

    echo "export ${PLAN}"
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