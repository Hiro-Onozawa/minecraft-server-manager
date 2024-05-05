import boto3
import requests

def describe_action(name, regions):
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
        ret['HealthCheck'] = False
        if 'PublicIpAddress' in instance:
            ret['PublicIpAddress'] = instance['PublicIpAddress']
            try:
                r = requests.get('http://' + instance['PublicIpAddress'] + ':18080/', timeout=0.05)
                if r.status_code == requests.codes.ok:
                    ret['HealthCheck'] = True
            except:
                None
        if 'State' in instance and 'Name' in instance['State']:
            ret['State'] = instance['State']['Name']
        if 'BlockDeviceMappings' in instance:
            ret['Devices'] = list(map(lambda x: parse_device_mapping(x), instance['BlockDeviceMappings']))
        return ret
    def parse_reservation(reservation):
        return parse_instance(reservation['Instances'][0])

    results = []
    for region in regions:
        ec2 = boto3.client('ec2', region_name=region)
        response = ec2.describe_instances(Filters=[
            {
                'Name': 'tag:Name',
                'Values': [name],
            },
        ])
        results += list(map(lambda x: parse_reservation(x), response['Reservations']))

    return {'instances': results}
