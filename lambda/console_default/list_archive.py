import boto3

def list_action(bucket_name, server_name):
    def parse_content(content):
        ret = {}

        key = content['Key'] if 'Key' in content else None

        if key is None or key.endswith('/'):
            return None

        ret['Key'] = key
        if 'LastModified' in content:
            ret['LastModified'] = content['LastModified'].timestamp()*1000
        if 'Size' in content:
            ret['Size'] = content['Size']
        if 'StorageClass' in content:
            ret['StorageClass'] = content['StorageClass']
        return ret

    s3 = boto3.client('s3')
    response = s3.list_objects(
        Bucket=bucket_name,
        Prefix=server_name
    )
    results = [ x for x in list(map(lambda x: parse_content(x), response['Contents'])) if x is not None ]

    return {'archives': results}
