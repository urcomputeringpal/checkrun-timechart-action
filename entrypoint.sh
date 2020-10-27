#!/bin/bash
set -e

if [ -z "${INPUT_SHA:-$GITHUB_SHA}" ]; then
    echo "Neither INPUT_SHA or GITHUB_SHA present" 2>&1
    exit 1
fi

export BT_DISABLE_CPUSAMPLE=1
export BT_SMALLSTATS=1
. /app/bt.sh

rm -f /tmp/bt*

# Account for replication delay
sleep $INPUT_DELAY

curl -s \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.github.antiope-preview+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${INPUT_SHA:-$GITHUB_SHA}/check-runs" \ |
    jq -r '.check_runs[] | [.id, .name, .started_at, .completed_at] | @tsv' | \
    sort -n > /tmp/checkruns

first=$(head -n 1 /tmp/checkruns | cut -f 1)
bt_init "${INPUT_TRACE_START:-$first}"

# Record traces for each completed check run
while IFS="" read -r checkrun || [ -n "$checkrun" ]
do
    id=$(echo "$checkrun" | cut -f 1)
    name=$(echo "$checkrun" | cut -f 2)
    started_at=$(echo "$checkrun" | cut -f 3)
    completed_at=$(echo "$checkrun" | cut -f 4)
    bt_start "$name https://github.com/${GITHUB_REPOSITORY}/runs/$id" "$started_at"
    bt_end "$name https://github.com/${GITHUB_REPOSITORY}/runs/$id" "${completed_at:-$started_at}"
done < /tmp/checkruns

# display the results
last=$(tail -n 1 /tmp/checkruns | cut -f 2)
bt_cleanup "$last"