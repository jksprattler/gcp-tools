#!/bin/bash
# To be run from within a specific gcp project using cloudshell or locally with `gcloud config set project <project>`
# Captures all buckets that do not have versioning enabled and compiles list of buckets into text file
# Prompts user whether or not to enable bucket versioning with lifecycle policy of 3+ versions and applies config to list of buckets

set -euo pipefail

project=$(echo "$DEVSHELL_PROJECT_ID")
now=$(date +"%m_%d_%H_%M_%Y")
touch "$project"-versioning-buckets-"$now".txt
chmod 777 "$project"-versioning-buckets-"$now".txt

bucketnover_func () {
echo -e "The following $project buckets do not have versioning enabled:\r\n"
for bucket in $(gsutil ls)
do 
  nover_bucket="$(gsutil versioning get "$bucket" | awk '{print $2}' )"
  if [ "$nover_bucket" == 'Suspended' ]
    then echo "$bucket" >> "$project"-versioning-buckets-"$now".txt
    echo "$bucket"
  fi
done  < "$project"-versioning-buckets-"$now".txt
}

bucketver_func () {
echo -e "\r\nWould you like to enable versioning all of these buckets (y/n)?"
while read -r answer
do
  if [ "$answer" != "${answer#[Yy]}" ]
    then echo -e "\r\nYou answered Yes, proceeding to enable bucket versioning and lifecycle policy on above buckets also captured in:\r\n$project-versioning-buckets-$now.txt\r\n"
      while read -r line 
      do
      echo -e "\r\nENABLING $line VERSIONING AND APPLYING LIFECYCLE POLICY NOW!"
      gsutil versioning set on "$line"
      gsutil lifecycle set lifecycle_numnewver_config.json "$line"
      done < "$project"-versioning-buckets-"$now".txt
      echo -e "\r\nVERSIONING ENABLED AND LIFECYCLE POLICY APPLIED ON BUCKETS, COMPLETE!\r\n"
      exit 1
    else echo -e "\r\nYou answered No, exiting script\r\n"
    exit 1    
  fi
done
}

bucketnover_func
if [ ! -s "$project"-versioning-buckets-"$now".txt ]
  then echo -e "All buckets in $project have versioning enabled, exiting script\r\n"
  exit 1
fi
bucketver_func
