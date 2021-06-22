gcloud compute networks subnets list --format="value(name,region)" |
while read name region
do 
	echo "################################################################################"
	echo "Subnet: $name"
	gcloud compute networks subnets describe $name --region $region | grep enableFlowLogs
done
echo "################################################################################"
