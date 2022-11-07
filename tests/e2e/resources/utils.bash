parsePlan() {
    PLAN="PLAN_TO_ADD=0 PLAN_TO_UPDATE=0 PLAN_TO_DESTROY=0"
    PLAN_SUMMARY=$(grep -Eo "^Plan: .*$" ${1} || echo "")
    if [ "${PLAN_SUMMARY}" != "" ]; then
        PLAN=$(echo "${PLAN_SUMMARY}" | sed "s/.* \([0-9]\+\) .* \([0-9]\+\) .* \([0-9]\+\).*/PLAN_TO_ADD=\1 PLAN_TO_UPDATE=\2 PLAN_TO_DESTROY=\3/")
    fi

    echo "export ${PLAN}"
}