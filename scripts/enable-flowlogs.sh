#!/bin/bash
# Enable VPC flow logs on every subnet in every VPC of a specified GCP project ID
# with 10 min agg set option for logging all metadata needs to be specified as: include or exclude
set -eou pipefail

function usage()
{
    echo
    echo "Usage: $0 [project-id] [logging-metadata]"
    echo
    echo "Option for project-id could be one of:"
    echo "${PROJECTS}"
    echo
    echo "Option for logging-metadata could be one of: include|exclude"
    echo
}

PROJECTS=$(gcloud projects list --format="table(projectId)")

if [ "--help" == "${1-}" ] || [ "-h" == "${1-}" ]; then
    usage
    exit 0
fi

if [ -z "${1:-}" ] || [ "$1" = "include" ] || [ "$1" = "exclude" ]; then
    echo "No project-id specified"
    usage
    exit 1
fi

project="$1"
gcloud config set project "${project}"

if [ -z "${2:-}" ]; then
    echo "No option specified for logging-metadata"
    usage
    exit 1
fi

loggingmetadata=$2

gcloud compute networks subnets list --format="value(name,region)" |
while read -r name region
do
    echo "################################################################################"
    echo "Subnet: $name     Region: $region"
    gcloud compute networks subnets update "$name" \
    --region "$region" \
    --enable-flow-logs \
    --logging-aggregation-interval=INTERVAL_10_MIN \
    --logging-metadata="${loggingmetadata}"-all
    gcloud compute networks subnets describe "$name" \
    --region "$region" \
    --format="flattened(logConfig.enable, logConfig.metadata)"
done
echo "################################################################################"
