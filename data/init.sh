#! /bin/bash
set -x

echo "### INSTALL PACKAGES"
yum update -y
yum install -y amazon-efs-utils aws-cli

echo "### INSTALL SSM AGENT"
cd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

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
    route_tables="$(aws ec2 describe-route-tables --query RouteTables[*].RouteTableId --filters "Name=tag:Scheme,Values=private" --output text)"
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

    echo "### enable IP forwarding and NAT"
    sysctl -q -w net.ipv4.ip_forward=1
    sysctl -q -w net.ipv4.conf.eth0.send_redirects=0
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
       
    echo "### wait for network connection"
    curl --retry 20 http://www.google.com
    
    echo "### reestablish connections"
    systemctl restart amazon-ssm-agent

else
    echo "### Determine the network id in the zone"
    timeout=600
    time_count=0
    zone_name="$(/opt/aws/bin/ec2-metadata -z | cut -d' ' -f2)"
    eni_id=$(aws ec2 describe-network-interfaces --query NetworkInterfaces[*].NetworkInterfaceId --filters "Name=status,Values=available" "Name=tag:Function,Values=NAT-instance" "Name=availability-zone,Values=$zone_name" --output text)
    
    while [ -z $eni_id ]; do
        let time_count++
        sleep 1
        eni_id=$(aws ec2 describe-network-interfaces --query NetworkInterfaces[*].NetworkInterfaceId --filters "Name=status,Values=available" "Name=tag:Function,Values=NAT-instance" "Name=availability-zone,Values=$zone_name" --output text)
        if [ $time_count -eq $timeout ]; then
            echo "No network interface available to instance"
            shutdown -h now
        fi
    done
    
    echo "### Attach network interface"
    aws ec2 attach-network-interface \
      --region "$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')" \
      --instance-id "$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)" \
      --device-index 1 \
      --network-interface-id "$eni_id"

    while ! ip link show dev eth1; do
        sleep 1
    done

    echo "### enable IP forwarding and NAT"
    sysctl -q -w net.ipv4.ip_forward=1
    sysctl -q -w net.ipv4.conf.eth1.send_redirects=0
    iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

    echo "### switch the default route to eth1"
    ip route del default dev eth0

    echo "### wait for network connection"
    curl --retry 20 http://www.google.com

    echo "### reestablish connections"
    systemctl restart amazon-ssm-agent

fi