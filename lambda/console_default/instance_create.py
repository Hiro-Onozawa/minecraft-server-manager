import base64
import boto3

def create_action(region, name, server_name, bucket_name, version, open_jdk_ver, instance_type, max_user, script_arg, update_plugins):
    print(region, version, instance_type, script_arg)

    def parse_device_mapping(mapping):
        ret = {}
        if 'DeviceName' in mapping:
            ret['DeviceName'] = mapping['DeviceName']
        if 'Ebs' in mapping:
            ebs = mapping['Ebs']
            if 'Status' in ebs:
                ret['Status'] = ebs['Status']
            if 'VolumeId' in ebs:
                ret['VolumeId'] = ebs['VolumeId']
        return ret
    def parse_instance(instance):
        ret = {}
        if 'InstanceId' in instance:
            ret['InstanceId'] = instance['InstanceId']
        if 'PublicIpAddress' in instance:
            ret['PublicIpAddress'] = instance['PublicIpAddress']
        if 'State' in instance and 'Name' in instance['State']:
            ret['State'] = instance['State']['Name']
        if 'BlockDeviceMappings' in instance:
            ret['Devices'] = list(map(lambda x: parse_device_mapping(x), instance['BlockDeviceMappings']))
        return ret

    def to_base64(script):
        return base64.b64encode(script.encode()).decode()
    def get_script(arg_value, version, server_name, bucket_name, max_user, open_jdk_ver, update_plugins):
        user_data = ""
        with open('res/bash/user_data.sh') as f:
            user_data = f.read()
        return user_data.replace('%%ON_MOUNT_ARG%%', '%s %s %s %s %s %s %s' % (arg_value, version, server_name, bucket_name, max_user, open_jdk_ver, update_plugins))

    def get_ami_image(client):
        response = client.describe_images(
            Filters=[
                {
                    'Name': 'root-device-type',
                    'Values': [ 'ebs' ]
                },
                {
                    'Name': 'architecture',
                    'Values': [ 'x86_64' ]
                },
                {
                    'Name': 'state',
                    'Values': [ 'available' ]
                },
                {
                    'Name': 'name',
                    'Values': [ 'ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' ]
                }
            ],
            Owners=[ 'amazon' ]
        )
        return sorted(response['Images'], key=lambda x: x['DeprecationTime'], reverse=True)[0]
    def get_ami_image_id(image):
        return image['ImageId']
    def get_block_device_mappings(image, volume_size = 8):
        volumes = [ x for x in image['BlockDeviceMappings'] if 'VirtualName' not in x ]
        root_volume_idx = [ i for i, _x in enumerate(volumes) if _x['DeviceName'] == '/dev/sda1' ][0]

        volumes[root_volume_idx]['Ebs']['DeleteOnTermination'] = True
        volumes[root_volume_idx]['Ebs']['VolumeSize'] = max(volumes[root_volume_idx]['Ebs']['VolumeSize'] or 8, volume_size)
        # volumes[root_volume_idx]['Ebs']['Iops'] = 3000
        # volumes[root_volume_idx]['Ebs']['Throughput'] = 125
        return volumes
    def get_supported_availability_zones(client, instance_type):
        response = client.describe_instance_type_offerings(
            LocationType='availability-zone',
            Filters=[
                {
                    'Name': 'instance-type',
                    'Values': [instance_type]
                }
            ]
        )
        return [ x['Location'] for x in response['InstanceTypeOfferings'] if x['LocationType'] == 'availability-zone' and x['InstanceType'] == instance_type ]
    def get_default_vpc_id(client):
        response = client.describe_vpcs()
        return response['Vpcs'][0]['VpcId']
    def get_subnet_id(client, availability_zones, vpc_id):
        response = client.describe_subnets(
            Filters=[
                {
                    'Name': 'availability-zone',
                    'Values': availability_zones
                },
                {
                    'Name': 'vpc-id',
                    'Values': [ vpc_id ]
                }
            ]
        )
        return response['Subnets'][0]['SubnetId']
    def get_security_group_id(client):
        response = client.describe_security_groups(
            Filters=[
                {
                    'Name': 'tag:Name',
                    'Values': [
                        'MinecraftDefaultSecurityGroup',
                    ]
                }
            ]
        )
        return response['SecurityGroups'][0]['GroupId']

    def get_instance_profile_arn(client):
        response = client.get_instance_profile(
            InstanceProfileName='Minecraft_Server_Instance_Role'
        )
        return response['InstanceProfile']['Arn']

    jsonParam = ''
    ec2 = boto3.client('ec2', region_name=region)
    iam = boto3.client('iam')
    ami_image = get_ami_image(ec2)
    resp = ec2.run_instances(
        MaxCount=1, MinCount=1,
        ImageId=get_ami_image_id(ami_image),
        InstanceType=instance_type,
        KeyName='MinecraftDefaultKeyPair',
        EbsOptimized=True,
        InstanceInitiatedShutdownBehavior='terminate',
        BlockDeviceMappings=get_block_device_mappings(ami_image),
        UserData=to_base64(get_script(script_arg, version, server_name, bucket_name, max_user, open_jdk_ver, update_plugins)),
        NetworkInterfaces=[
            {
                'SubnetId': get_subnet_id(ec2, get_supported_availability_zones(ec2, instance_type), get_default_vpc_id(ec2)),
                'AssociatePublicIpAddress': True,
                'DeviceIndex': 0,
                'Groups': [ get_security_group_id(ec2) ]
            }
        ],
        IamInstanceProfile={
            'Arn': get_instance_profile_arn(iam)
        },
        CreditSpecification={
            'CpuCredits': 'unlimited'
        },
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': name
                    }
                ]
            }
        ],
        MetadataOptions={
            'HttpEndpoint': 'enabled',
            'HttpPutResponseHopLimit': 2,
            'HttpTokens': 'required'
        },
        PrivateDnsNameOptions={
            'HostnameType': 'ip-name',
            'EnableResourceNameDnsARecord': True,
            'EnableResourceNameDnsAAAARecord': False
        }
    )

    return parse_instance(resp['Instances'][0])

def sync_action(region, instance_id):
    ec2 = boto3.client('ec2', region_name=region)
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[instance_id])
    return {'State': 'running', 'InstanceId': instance_id}
