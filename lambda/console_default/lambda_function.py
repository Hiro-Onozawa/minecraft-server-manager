import re
import json
import boto3
import instance_describe
import instance_create
import list_archive

def get_param(e, name, defval=''):
    if name in e:
        return e[name]

    param = e.get('queryStringParameters')
    if not param:
        return defval

    if name in param:
        return param[name]
    else:
        return defval

def get_lambda_url(e):
    return 'https://%s/' % e['requestContext']['domainName']

def invalid_operation():
    return ('Invalid Operation', '', '', '')

def make_node(name, text, attributes=None):
    attr = '' if attributes is None else ' ' + ' '.join(map(lambda kvp: ('%s' % kvp[0]) if kvp[1] is None else '%s="%s"' % (kvp[0], kvp[1]), attributes.items()))
    if text is None:
        return '<%s%s>' % (name, attr)
    else:
        return '<%s%s>%s</%s>' % (name, attr, text, name)

def make_html(headContents, bodyContents):
    return '<!DOCTYPE html>' + make_node('html', ''.join([make_node('head', ''.join(headContents)), make_node('body', ''.join(bodyContents))]))

def main(name, lambda_url, common_settings, mode):
    version = ""
    html = ""
    script = ""
    style = ""
    with open('res/txt/version.txt') as f:
        version = f.read()
    with open('main.html') as f:
        html = f.read()
    with open('script.js') as f:
        script = f.read()
    with open('style.css') as f:
        style = f.read()

    replace_obj = {
        'server_name': name,
        'style': style,
        'script': script,
        'version': version,
        'describe_url': lambda_url,
        'create_instance_url': lambda_url,
        'list_archive_url': lambda_url,
        'server_version': ''.join([ '<option value="%s">%s</option>' % (x['value'], x['name']) for x in common_settings['versions'] ]),
        'admin_capacity': ''.join([ '<option value="%d">%s</option>' % (x['value'], x['name']) for x in common_settings['capacities'] if x['only_admin'] ]),
        'user_capacity': ''.join([ '<option value="%d">%s</option>' % (x['value'], x['name']) for x in common_settings['capacities'] if not x['only_admin'] ]),
        'admin_update_plugins_check': '<br><label for="update_plugins">プラグインの更新を実行する</label><input name="update_plugins" value="true" type="checkbox">',
        'admin_button': '<button id="admin_start" onclick="Start(this)" type="submit" name="action" value="CreateInstanceAsAdmin">管理者として起動する</button>'
    }
    if mode != 'admin':
        for key in {key for key in replace_obj.keys() if re.match(r'^admin_', key)}:
            replace_obj[key] = ''
    for m in re.findall(r'/\*\$\{\{([a-z_]+)\}\}\*/', html):
        html = html.replace('/*${{%s}}*/' % m, replace_obj[m] if m in replace_obj else '(undefined)')
    return html

def do_action(event):
    with open('res/json/default_settings.json') as f:
        default_settings = json.load(f)

    server = default_settings['prop_name']
    action = get_param(event, 'action', 'main')

    with open('res/json/common_settings.json') as f:
        common_settings = json.load(f)
    with open('res/json/server_settings.json') as f:
        setting = json.load(f)

    if action == 'admin':
        name = setting['server']['Name']
        lambda_url = get_lambda_url(event)
        return {
            'statusCode': 200,
            'headers': { 'Content-Type': 'text/html; charset=UTF-8' },
            'body': main(name, lambda_url, common_settings, 'admin'),
        }

    try:
        if action == 'main':
            name = setting['server']['Name']
            lambda_url = get_lambda_url(event)
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/html; charset=UTF-8' },
                'body': main(name, lambda_url, common_settings, 'user'),
            }
        if action == "Describe":
            name = setting['server']['Name']
            regions = [ 'ap-northeast-1', 'ap-south-1' ]
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_describe.describe_action(name, regions),
            }
        elif action == "CreateInstance":
            region = get_param(event, 'region')
            branch_name = default_settings['branch_name']
            name = setting['server']['Name']
            server_name = setting['server']['ServerName']
            bucket_name = setting['server']['BucketName']
            version = get_param(event, 'mcversion')
            open_jdk_ver = [ x['open_jdk'] for x in common_settings['versions'] if x['value'] == version ][0]
            capacity = get_param(event, 'capacity')
            instance_type, max_user = [ (x['instance_type'], x['value']) for x in common_settings['capacities'] if str(x['value']) == capacity ][0]
            update_plugins = get_param(event, 'update_plugins', 'false')
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_create.create_action(region, branch_name, name, server_name, bucket_name, version, open_jdk_ver, instance_type, max_user, 'user', update_plugins),
            }
        elif action == "CreateInstanceAsAdmin":
            region = get_param(event, 'region')
            branch_name = default_settings['branch_name']
            name = setting['server']['Name']
            server_name = setting['server']['ServerName']
            bucket_name = setting['server']['BucketName']
            version = get_param(event, 'mcversion')
            open_jdk_ver = [ x['open_jdk'] for x in common_settings['versions'] if x['value'] == version ][0]
            capacity = get_param(event, 'capacity')
            instance_type, max_user = [ (x['instance_type'], x['value']) for x in common_settings['capacities'] if str(x['value']) == capacity ][0]
            update_plugins = get_param(event, 'update_plugins', 'false')
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_create.create_action(region, branch_name, name, server_name, bucket_name, version, open_jdk_ver, instance_type, max_user, 'admin', update_plugins),
            }
        elif action == "SyncInstanceRuning":
            region = get_param(event, 'region')
            instance_id = get_param(event, 'instance_id')
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_create.sync_action(region, instance_id),
            }
        elif action == "ListArchive":
            bucket_name = setting['server']['BucketName']
            server_name = setting['server']['ServerName']
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': list_archive.list_action(bucket_name, server_name),
            }
        else:
            raise NotImplementedError
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': { 'Content-Type': 'text/html; charset=UTF-8' },
            'body': make_html('Internal Server Error', ['例外を検出しました', str(e)]),
        }        


def lambda_handler(event, context):
    print(event, context)
    return do_action(event)
