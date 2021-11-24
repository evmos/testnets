#!/bin/bash
# set -x
ALL_OPEN_PRS=$(gh pr list -L 3000 --state open --json number | jq ".[].number")
SUCCESSFUL_PRS=""

for pr in $ALL_OPEN_PRS
do 
    contains_failure=$(gh pr view "$pr" --json statusCheckRollup | jq -r '.[] | .[] | select(.name == "verify-gentx") | .conclusion' | grep -c FAILURE)
    if [[ $contains_failure -eq 0 ]]; then
        SUCCESSFUL_PRS+=" ${pr}"
    else
        echo "contains failure ${pr}"
    fi
done

for success in $SUCCESSFUL_PRS
do 
    # TODO: check that addition is a new JSON file
    deletion_count=$(gh pr view "$success" --json deletions | jq .deletions)
    formatted_suspiciously=$(gh pr view "$success" --json title | grep -iF -e "Create " -e "ADD" -c)

    if [[ $deletion_count -eq 0 && $formatted_suspiciously -eq 0 ]]; then 
        echo "no deletion found. pr looks okay. merging the pr. $success"
        gh pr review --approve "$success"
        gh pr merge "$success" -s --auto -d -b "Auto-merging"
        echo $?
    else
        echo "skipping $success; there are deletion in the PR"
    fi
done
