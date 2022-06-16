#!/bin/bash
# To be run from within a specific gcp project using cloudshell or locally with `gcloud config set project <project>`
# List all empty buckets within the gcp project and prompt user to delete them
# If an empty storage bucket should be kept then prompts user on applying a placeholder.txt file to the bucket and rerun script to bypass the bucket deletion
# Empty buckets with versioning enabled may not delete due to deleted versions of object in place for protection. Check "Show deleted data" for these scenarios. 
# Ensure to run this cleanup script prior to running the `gcp_enable_bucket_ver.sh` script.

set -euo pipefail

project=$(echo "$DEVSHELL_PROJECT_ID")
now=$(date +"%m_%d_%H_%M_%Y")
touch "$project"-empty-buckets-"$now".txt
chmod 777 "$project"-empty-buckets-"$now".txt

bucketlist_func () {
echo -e "The following $project buckets are empty:\r\n"
for bucket in $(gsutil ls)
do 
  empty_bucket="$(gsutil du -s -a "$bucket" | awk '{print $1}' )"
  if [ "$empty_bucket" == 0 ]
    then echo "$bucket" >> "$project"-empty-buckets-"$now".txt
    echo "$bucket"
  fi
done  < "$project"-empty-buckets-"$now".txt
}

bucketdel_func () {
echo -e "\r\nWould you like to delete all of these empty buckets (y/n)?"
while read -r answer
do
  if [ "$answer" != "${answer#[Yy]}" ]
    then echo -e "\r\nYou answered Yes, proceeding to delete above empty buckets also captured in:\r\n$project-empty-buckets-$now.txt\r\n"
      while read -r line 
      do
      echo -e "\r\nDELETING $line NOW!"
      gsutil rm -r "$line"
      done < "$project"-empty-buckets-"$now".txt
      echo -e "\r\nEMPTY BUCKET CLEANUP COMPLETE!\r\n"
      exit 1
    else echo -e "\r\nYou answered No, add a placeholder file to the above empty bucket in order to bypass deletion and rerun the script:\r\ngsutil cp placeholder.txt gs://your-bucket/\r\n"
    exit 1    
  fi
done
}

bucketlist_func
if [ ! -s "$project"-empty-buckets-"$now".txt ]
  then echo -e "There are no empty buckets in $project, exiting script\r\n"
  exit 1
fi
bucketdel_func
