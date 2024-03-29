#!/bin/bash
set -eo pipefail

if [ "${INPUT_DEBUG}" == "true" ]; then
    set -x
    date
fi

if [ -z "${INPUT_SHA:-$GITHUB_SHA}" ]; then
    echo "Neither INPUT_SHA or GITHUB_SHA present" 2>&1
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BT_TEMP="${SCRIPT_DIR}/tmp"
mkdir -p ${BT_TEMP}
export BT_DIR="$(mktemp -d ${BT_TEMP}/bt-$$-XXXXXXX)"

export BT_DISABLE_CPUSAMPLE=1
export BT_SMALLSTATS=1
. ./bt.sh
. ./lib.sh

rm -f ${BT_DIR}/bt*

# Account for replication delay
sleep $INPUT_DELAY

bt_init "${INPUT_TRACE_START:-$first}"

bt_start "bt.sh"

curl -s --retry 5 --retry-all-errors --retry-max-time 30 \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.github.antiope-preview+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${INPUT_SHA:-$GITHUB_SHA}/check-runs" | \
    tee ${BT_TEMP}/checkruns.json | \
    jq -r '.check_runs[] | [.started_at, .id, .name, .conclusion, .completed_at] | @tsv' | \
    sort -n > ${BT_TEMP}/checkruns.tsv

first=$(head -n 1 ${BT_TEMP}/checkruns.tsv | cut -f 1)
last=$(cat ${BT_TEMP}/checkruns.json | \
    jq -r '.check_runs[] | [.completed_at] | @tsv' | \
    grep -E '[0-9]' | \
    sort -rn | \
    tee ${BT_TEMP}/completed_at.tsv | \
    head -n 1)

if [ "${INPUT_DEBUG}" == "true" ]; then
    set +e
    find ${BT_TEMP} -name '*.tsv' -o -name '*.json' | xargs -n 1 -t cat
    date
    set -e
fi


# Record traces for each completed check run
while IFS="" read -r checkrun || [ -n "$checkrun" ]
do
    started_at=$(echo "$checkrun" | cut -f 1)
    id=$(echo "$checkrun" | cut -f 2)
    name=$(echo "$checkrun" | cut -f 3)
    conclusion=$(echo "$checkrun" | cut -f 4)
    completed_at=$(echo "$checkrun" | cut -f 5)

    if [ "$conclusion" == "skipped" ]; then
        continue
    fi

    bt_start "$(echo -e "$name\\thttps://github.com/${GITHUB_REPOSITORY}/runs/$id")" "$started_at"
    if [ -n "$completed_at" ]; then
        bt_end "$(echo -e "$name\\thttps://github.com/${GITHUB_REPOSITORY}/runs/$id")" "$completed_at"
    fi
done < ${BT_TEMP}/checkruns.tsv

if [ "${INPUT_DEBUG}" == "true" ]; then
    date
fi

bt_end "bt.sh"

# display the results
if [ -n "$INPUT_SUMMARY" ]; then
    output="$(bt_cleanup "${last}")"
    echo -e "\`\`\`\n${output}\n\`\`\`" >> "$GITHUB_STEP_SUMMARY"
else
    bt_cleanup "${last}"
fi
