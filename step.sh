#!/bin/bash
set -ex

state=$devops_pr_state
description=$devops_description

if [[ "$state" == "auto" ]]
then
    state="failed"

    if [[ $BITRISE_BUILD_STATUS -eq 0 ]]
    then
        state="succeeded"
    fi
fi

if [[ -z "$description" ]]
then
    description="${BITRISE_APP_TITLE} build #${BITRISE_BUILD_NUMBER} ${state}"
fi


ITERATIONS_URL="https://dev.azure.com/${organization_name}/${project_name}/_apis/git/repositories/${repository_name}/pullRequests/${BITRISE_PULL_REQUEST}/iterations?api-version=7.0"


HTTP_STATUS=$(
    curl -u :${azure_pat} -s -o response.json -w "%{http_code}" $ITERATIONS_URL \
    -H "Content-Type: application/json"
)


if [ $HTTP_STATUS != "200" ]; 
then
    echo "Error [HTTP status: $HTTP_STATUS]"
    exit 1
fi

echo "Server returned:  "

cat response.json | jq

ITERATIONS_COUNT=$(jq .count response.json)   


UPDATE_PR_STATUS_URL="https://dev.azure.com/${organization_name}/${project_name}/_apis/git/repositories/${repository_name}/pullRequests/${BITRISE_PULL_REQUEST}/iterations/${ITERATIONS_COUNT}/statuses?api-version=7.0"


HTTP_STATUS=$(
    curl -u :${azure_pat} -s -o response.json -w "%{http_code}" $UPDATE_PR_STATUS_URL \
    -H "Content-Type: application/json" \
    -d @- <<EOF
    {
        "state": "${state}",
        "description": "${description}",
        "targetUrl": "${BITRISE_BUILD_URL}",
        "context": {
            "name": "${context_name}",
            "genre": "${context_genre}"
        }
    }
EOF
)

if [ $HTTP_STATUS != "200" ]; 
then
    echo "Error [HTTP status: $HTTP_STATUS]"
    exit 1
fi

cat response.json | jq

exit 0