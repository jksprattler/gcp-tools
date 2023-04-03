#!/bin/bash
# Script to purchase 12-month committed resources in a specified GCP project.
# Caution should be used as you cannot backout of purchasing committed resources!
# Commitments are allocated to all running instances based on their machine type.
# Script performs checks against a required set of options and their arguments to
# perform either a dry run or the creation of commitments.
# Dry run displays the values intended to be used for the commitment execution and should
# be run prior to implementation to ensure all conditionals pass and errors are resolved.
# Uncomment out conditionals to protect against purchasing vcpu/mem resources outside the scope

set -euo pipefail
dry_run=1

declare -a Types=(
    "accelerator-optimized"
    "compute-optimized"
    "compute-optimized-c2d"
    "compute-optimized-c3"
    "general-purpose"
    "general-purpose-e2"
    "general-purpose-n2"
    "general-purpose-n2d"
    "general-purpose-t2d"
    "memory-optimized"
    "memory-optimized-m3"
)

function usage()
{
    echo "################################################################################"
    echo "Option descriptions:"
    echo "-p            Sets project-id"
    echo "-m            Sets machine type of current running instances for commitments. Double check as gcloud filter is not exact match!"
    echo "-t            Sets Commitment Type, for available options run -T"
    echo "-v            Sets the amount of vcpu's for each committed resource per zone"
    echo "-M            Sets the amount of Memory for each committed resource per zone, default is GB if not specified"
    echo "-G            Caution! Creates the commitments. Always perform a dry run first without this option!"
    echo "-P            Lists all existing project-id's to select from"
    echo "-L            Lists all instances in set project and includes machine type, vm name & zone"
    echo "-T            Lists possible commitment type options, for details see: https://cloud.google.com/compute/docs/instances/signing-up-committed-use-discounts#commitment_types"
    echo "-C            Lists current compute commitments"
    echo "Usage:        [-p project-id] [-m machine-type] [-t commitment-type] [-v vcpus] [-M memory] [-G create-commitments]"
    echo "Dry run ex.:  $0 -p my-project -m e2-standard-2 -t general-purpose-e2 -v 2 -M 8"
    echo "Creation ex.: $0 -p my-project -m e2-standard-2 -t general-purpose-e2 -v 2 -M 8 -G"
    echo "NOTE:         Check Quotas on Commitments against your regions w/ Limit: 0 vcpu's and submit requests for increases here or you'll encounter gcloud crashed (TypeError)"
}

if [[ "$#" == 0 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    usage
    exit 0
fi

while getopts ":p:m:t:v:M:PLTCG" option; do
    case $option in
        p)
            p=$OPTARG
            gcloud config set project "${p}"
            echo "Project set to: $p"
        ;;
        m)
            m=$OPTARG
        ;;
        t)
            t=$OPTARG
            echo "${Types[@]}" | grep -w "$t" > /dev/null &&
            echo "$t is a matching Type" >/dev/null ||
            echo "Incorrect commitment type, check -T output for options"
            #if [[ $t != "general-purpose-e2" ]]; then
            #    echo "Commitment Type should be general-purpose-e2 unless we're committing against new machine types."
            #    echo "Validate $t type and update this conditional if necessary"
            #    usage
            #    exit 1
            #fi
        ;;
        v)
            v=$OPTARG
            #if [[ $v != 2 ]] && [[ $v != 8 ]]; then
            #    echo "vcpu's should be 2 or 8 unless we're committing against new machine types."
            #    echo "Validate $v size and update this conditional if necessary"
            #    usage
            #    exit 1
            #fi
        ;;
        M)
            M=$OPTARG
            #if [[ $M != 8 ]]; then
            #    echo "Memory should be 8 unless we're committing against new machine types."
            #    echo "Validate $M size and update this conditional if necessary"
            #    usage
            #    exit 1
            #fi
        ;;
        P)
            gcloud projects list --format="table(projectId)"
        ;;
        L)
            gcloud compute instances list --format='table(machineType,name,zone)' | sort
        ;;
        T)
            printf "%s\n" "${Types[@]}"
        ;;
        C)
            gcloud compute commitments list
        ;;
        G)
            dry_run=0
        ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 2
        ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            exit 1
        ;;
    esac
done
shift "$((OPTIND-1))"

function dry_run ()
{
    PROJECT_ID="$(gcloud config get-value project)"
    gcloud compute instances list --filter='machineType:"'"$m"'"' --format='table(zone)' \
        | rev | cut -c3- | rev | sed '1d' | sort |
    while read -r region
    do
        COMMITMENT_NAME="$m"-"$region"-"$RANDOM"
        echo "###########################################"
        echo "Commitment Name:  $COMMITMENT_NAME"
        echo "Region:           $region"
        echo "Project:          $PROJECT_ID"
        echo "Resources:        vcpu=$v,memory=$M"
        echo "Plan:             12-month"
        echo "Type:             $t"
    done
    echo "###########################################"
}

function create_commitments ()
{
    PROJECT_ID="$(gcloud config get-value project)"
    gcloud compute instances list --filter='machineType:"'"$m"'"' --format='table(zone)' \
        | rev | cut -c3- | rev | sed '1d' | sort |
    while read -r region
    do
        COMMITMENT_NAME="$m"-"$region"-"$RANDOM"
        echo "###########################################"
        echo "Commitment Name:  $COMMITMENT_NAME"
        gcloud compute commitments create "$COMMITMENT_NAME" \
            --region "$region" \
            --project "$PROJECT_ID" \
            --resources vcpu="$v",memory="$M" \
            --plan 12-month \
            --type "$t"
    done
    echo "###########################################"
}

function main ()
{
    set +u
    if [[ "$dry_run" = 1 ]] && [[ -n "$m" && -n "$t" && -n "$v" && -n "$M" ]]
        then
            dry_run
    elif [[ "$dry_run" = 0 ]] && [[ -n "$m" && -n "$t" && -n "$v" && -n "$M" ]]
        then
            create_commitments
    else
        echo "################################################################################"
        echo "Missing required option(s) for either dry run or commitment creation"
        usage
        exit 1
    fi
}

main
