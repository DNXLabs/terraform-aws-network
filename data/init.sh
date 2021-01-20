#! /bin/bash
set -x

echo "### CONFIG NETWORK INTERFACE"
echo "### Determine the region"
export AWS_DEFAULT_REGION="$(/opt/aws/bin/ec2-metadata -z | sed 's/placement: \(.*\).$/\1/')"

echo "### Determine the instance id"
instance_id="$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"

echo "### Disable source dest check"
aws ec2 modify-instance-attribute --instance-id "$instance_id" --source-dest-check "{\"Value\": false}"

echo "### Determine the count of EIP id"
eip_id="$(aws ec2 describe-addresses --query Addresses[*].AllocationId --filters "Name=tag:Function,Values=NAT-instance" --output text)"

if [ $(echo "$eip_id" |wc -w) -eq 1 ]; then
    echo "### Attach the EIP"
    aws ec2 associate-address --instance-id "$instance_id" --allocation-id "$eip_id"

    echo "### Change the private route tables"
    route_tables="$(aws ec2 describe-route-tables --filters "Name=tag:Scheme,Values=private" |grep RouteTableId |cut -d ':' -f2 |sed 's/[\", ]//g' |uniq)"
    for route_id in $(echo "$route_tables")
    do
        route_internet="$(aws ec2 describe-route-tables --route-table-ids "$route_id" |grep -c "0.0.0.0/0")"
        if [ "$route_internet" -eq 0 ]
        then
            aws ec2 create-route --route-table-id "$route_id" --destination-cidr-block 0.0.0.0/0 --instance-id "$instance_id"
        else
            aws ec2 replace-route --route-table-id "$route_id" --destination-cidr-block 0.0.0.0/0 --instance-id "$instance_id"
        fi
    done
else
    echo "### Determine the network id in the zone"
    zone_name="$(/opt/aws/bin/ec2-metadata -z | cut -d' ' -f2)"
    eni_id=$(aws ec2 describe-network-interfaces --query NetworkInterfaces[*].NetworkInterfaceId --filters "Name=status,Values=available" "Name=tag:Function,Values=NAT-instance" "Name=availability-zone,Values=$zone_name" --output text)

    aws ec2 attach-network-interface \
      --region "$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')" \
      --instance-id "$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)" \
      --device-index 1 \
      --network-interface-id "$eni_id"
fi