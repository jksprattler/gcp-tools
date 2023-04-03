#!/bin/bash
# Ad-hoc script to be used in place of `gcp_committed_resources.sh` in case of gcloud crash
# which may occur due to commitment and/or CPU quota limits set in certain regions
# Loops through array of specified regions needing committed resources
# Update region array, PROJECT_ID, vcpu, memory, type `m`, etc for your use case

set -euo pipefail
dry_run=1

while [[ "$#" -gt 0 ]]; do
    case "$1" in
	--go) dry_run=0; shift;;
    esac
done

m=e2-standard-2

declare -a region=(
    "asia-south2"
    "europe-central2"
    "northamerica-northeast2"
    "southamerica-west1"
)

PROJECT_ID=my-project

function dry_run ()
{
    for r in "${region[@]}"
    do
        COMMITMENT_NAME="$m"-"$r"-"$RANDOM"
        echo "###########################################"
        echo "Commitment Name:  $COMMITMENT_NAME"
        echo "Region:           $r"
        echo "Project:          $PROJECT_ID"
        echo "Resources:        vcpu=2,memory=8"
        echo "Plan:             12-month"
        echo "Type:             general-purpose-e2"
    done
    echo "###########################################"
}

function create_commitments ()
{
    for r in "${region[@]}"
    do
        COMMITMENT_NAME="$m"-"$r"-"$RANDOM"
        echo "###########################################"
        echo "Commitment Name:  $COMMITMENT_NAME"
        gcloud compute commitments create "$COMMITMENT_NAME" \
            --region "$r" \
            --project "$PROJECT_ID" \
            --resources vcpu="2",memory="8" \
            --plan 12-month \
            --type "general-purpose-e2"
    done
    echo "###########################################"
}

function main ()
{
    if [[ "$dry_run" = 1 ]]
        then
            dry_run
    elif [[ "$dry_run" = 0 ]]
        then
            create_commitments
    fi
}

main
