import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': { 'Content-Type': 'text/html; charset=UTF-8' },
        'body': open('./res/index.html').read()
    }
