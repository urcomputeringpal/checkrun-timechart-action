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
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${INPUT_SHA:-$GITHUB_SHA}/check-runs" | \
    tee /tmp/checkruns.json | \
    jq -r '.check_runs[] | [.started_at, .id, .name, .conclusion, .completed_at] | @tsv' | \
    sort -n > /tmp/checkruns.tsv

first=$(head -n 1 /tmp/checkruns.tsv | cut -f 1)
bt_init "${INPUT_TRACE_START:-$first}"

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

    bt_start "$name https://github.com/${GITHUB_REPOSITORY}/runs/$id" "$started_at"
    if [ -n "$completed_at" ]; then
        bt_end "$name https://github.com/${GITHUB_REPOSITORY}/runs/$id" "$completed_at"
    fi
done < /tmp/checkruns.tsv

# display the results
last_completed=$(cat /tmp/checkruns.json | \
    jq -r '.check_runs[] | [.completed_at] | @tsv' | \
    grep -Eo '[0-9]+' | \
    sort -rn | \
    tee /tmp/completed_at.tsv | \
    head -n 1)
bt_cleanup "${last_completed}"

find /tmp -name '*.tsv' -o -name '*.json' | xargs -n 1 -t cat