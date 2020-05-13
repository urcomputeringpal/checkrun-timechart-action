export BT_DISABLE_CPUSAMPLE=1
export BT_SMALLSTATS=1
. /app/bt.sh

# Initialize a trace a short while in the past
bt_init "${INPUT_TRACE_START:-$TRACE_START}"

curl -s \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.github.antiope-preview+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${INPUT_SHA:-$SHA}/check-runs" \ |
    jq -r '.check_runs[] | [.started_at, .completed_at, .name] | @tsv' | \
    sort -n > /tmp/checkruns

# Record traces for each completed check run
while IFS="" read -r checkrun || [ -n "$checkrun" ]
do
    name=$(echo "$checkrun" | cut -f 3-)
    bt_start "$name" "$(echo "$checkrun" | cut -f 1)"
    bt_end "$name" "$(echo "$checkrun" | cut -f 2)"
done < /tmp/checkruns

# display the results
bt_cleanup
