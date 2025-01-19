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

def validate_minecraft_settings(is_admin, minecraft_settings):
    if is_admin:
        return None

    [ (x['instance_type'], x['value']) for x in common_settings['capacities'] if str(x['value']) == capacity ][0]
    if next(filter(lambda x: str(x['value']) == minecraft_settings['max_user'], common_settings['capacities']), {'only_admin': True})['only_admin']:
        return 'try to setting max_user as %s, but lambda is running as user.' % minecraft_settings['max_user']

    if next(filter(lambda x: str(x['value']) == minecraft_settings['difficulty'], common_settings['difficulty']), {'only_admin': True})['only_admin']:
        return 'try to setting difficulty as %s, but lambda is running as user.' % minecraft_settings['difficulty']

    if next(filter(lambda x: str(x['value']) == minecraft_settings['gamemode'], common_settings['gamemode']), {'only_admin': True})['only_admin']:
        return 'try to setting gamemode as %s, but lambda is running as user.' % minecraft_settings['gamemode']

    if minecraft_settings['world_size'] is not None:
        return 'try to setting world_size, but lambda is running as user.'

    if minecraft_settings['hardcore'] is not None:
        return 'try to setting hardcore, but lambda is running as user.'

    return None

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
        'admin_difficulty': ''.join([ '<option value="%s">%s</option>' % (x['value'], x['name']) for x in common_settings['difficulty'] if x['only_admin'] ]),
        'user_difficulty': ''.join([ '<option value="%s">%s</option>' % (x['value'], x['name']) for x in common_settings['difficulty'] if not x['only_admin'] ]),
        'admin_gamemode': ''.join([ '<option value="%s">%s</option>' % (x['value'], x['name']) for x in common_settings['gamemode'] if x['only_admin'] ]),
        'user_gamemode': ''.join([ '<option value="%s">%s</option>' % (x['value'], x['name']) for x in common_settings['gamemode'] if not x['only_admin'] ]),
        'admin_world_size_edit': '<label for="world_size">ワールドサイズ</label><input name="world_size" value="8192" type="number" min="1" max="29999984"><br>',
        'admin_hardcore_check': '<label for="hardcore">ハードコアモードで起動する</label><input name="hardcore" value="false" type="checkbox"><br>',
        'admin_update_plugins_check': '<label for="update_plugins">プラグインの更新を実行する</label><input name="update_plugins" value="true" type="checkbox"><br>',
        'admin_create_instance_button': '<button id="admin_start" onclick="Start(this, true)" type="submit" name="action" value="CreateInstance">管理者として起動する</button>'
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

    with open('res/txt/function_type.txt') as f:
        mode = f.read()

    server = default_settings['prop_name']
    action = get_param(event, 'action', 'main')

    with open('res/json/common_settings.json') as f:
        common_settings = json.load(f)
    with open('res/json/server_settings.json') as f:
        setting = json.load(f)

    try:
        request_as_admin = get_param(event, 'request_as_admin', 'false')
        if request_as_admin == 'true' and mode != 'admin':
            raise 'request as admin, but lambda is running as user.'

        if action == 'main':
            name = setting['server']['name']
            lambda_url = get_lambda_url(event)
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/html; charset=UTF-8' },
                'body': main(name, lambda_url, common_settings, mode),
            }
        if action == "Describe":
            name = setting['server']['name']
            regions = [ setting['aws']['region'] ]
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_describe.describe_action(name, regions),
            }
        elif action == "CreateInstance":
            branch_name = default_settings['branch_name']
            name = setting['server']['name']
            version = get_param(event, 'mcversion')
            open_jdk_ver = [ x['open_jdk'] for x in common_settings['versions'] if x['value'] == version ][0]
            capacity = get_param(event, 'capacity')
            instance_type, max_user = [ (x['instance_type'], x['value']) for x in common_settings['capacities'] if str(x['value']) == capacity ][0]
            script_arg = 'admin' if request_as_admin == 'true' else 'user'
            update_plugins = get_param(event, 'update_plugins', 'false')
            with open('res/txt/discord_webhook_user.txt') as f:
                discord_webhook_user = f.read()
            with open('res/txt/discord_webhook_admin.txt') as f:
                discord_webhook_admin = f.read()
            lambda_url = get_lambda_url(event)
            region = setting['aws']['region']
            aws_settings = {
                'region': region,
                'security_group_name': setting['aws']['security_group_name'],
                'key_pair_name': setting['aws']['key_pair_name'],
                'instance_profile_name': setting['aws']['instance_profile_name'],
                'subnet_name': setting['aws']['subnet_name'],
                'instance_type': instance_type,
                'bucket_name': setting['aws']['archive_bucket_name']
            }
            minecraft_settings = {
                'server_name': setting['server']['server_name'],
                'version': version,
                'open_jdk_ver': open_jdk_ver,
                'max_user': max_user,
                'difficulty': get_param(event, 'difficulty', 'easy'),
                'gamemode': get_param(event, 'gamemode', 'survival'),
                'world_size': get_param(event, 'world_size', None),
                'hardcore': get_param(event, 'hardcore', None)
            }
            discord_settings = {
                'webhook_user': discord_webhook_user,
                'webhook_admin': discord_webhook_admin
            }

            validate_massage = validate_minecraft_settings(mode == 'admin', minecraft_settings)
            if validate_massage is not None:
                return {
                    'statusCode': 429,
                    'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                    'body': '{"message":"%s"}' % validate_massage,
                }

            if len([ x for x in instance_describe.describe_action(name, [region])['instances'] if x['State'] != 'terminated' ]) > 0:
                return {
                    'statusCode': 429,
                    'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                    'body': '{"message":"非停止状態のインスタンスが存在しています。"}',
                }

            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_create.create_action(branch_name, minecraft_settings, name, aws_settings, script_arg, update_plugins, discord_settings, lambda_url),
            }
        elif action == "SyncInstanceRuning":
            region = setting['aws']['region']
            instance_id = get_param(event, 'instance_id')
            return {
                'statusCode': 200,
                'headers': { 'Content-Type': 'text/json; charset=UTF-8' },
                'body': instance_create.sync_action(region, instance_id),
            }
        elif action == "ListArchive":
            bucket_name = setting['aws']['archive_bucket_name']
            server_name = setting['server']['server_name']
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
