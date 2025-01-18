# What is this

AWSで廉価にMinecraftのサーバーを運用するためのプログラム群です。

事前にAWS側で最低限の設定(VPC,IAM Role,デプロイ先lambda等)とリポジトリの設定(secrets,リポジトリ変数等)を行います。
その後GitHub Actionsからlambdaへプログラムをデプロイしておきます。

Minecraftサーバーを作成する際は、まずlambdaにブラウザからアクセスします。
Webページとして管理コンソールが開かれ、そのページからMinecraftサーバー用インスタンスが作成できます。
作成されたインスタンス上には、Minecraftサーバーと、インスタンスやMinecraftサーバーの状態を確認可能な簡素なWebサーバーが起動します。
インスタンスが作成されていると、管理コンソールページからサーバー状態確認ページへ自動で遷移します。

サーバー状態確認ページにはMinecraftサーバーへのアクセス情報も表示されます。
Java版であれば「マルチプレイ > ダイレクト接続」からアドレスを指定して接続します。

Minecraftサーバーにログインしているプレイヤーが不在の状態が一定時間続くと、必要に応じてワールドデータをS3にアーカイブするとともに、インスタンスを自動で終了します。
アーカイブされたワールドデータは次回インスタンス作成時に取得されます。


# How to use

1. ブラウザから lambda の関数URLにアクセスする
2. パラメータを適当に選択し「起動する」ボタンを押す
3. インスタンスが起動するのを待つ (期待値は60～90秒程度)
4. インスタンスが起動するとサーバー状態確認ページへ自動で遷移する
5. Minecraftサーバーの初期化が完了するのを待つ (期待値は150～300秒程度)
6. 表示される「接続先情報」を設定してMinecraftサーバーへ接続する
7. 遊ぶ

サーバーにログインしているプレイヤーが不在の状態が一定時間続くと、
必要に応じてワールドデータをアーカイブしてからインスタンスが自動で終了するため、
遊び終わった後の対応は不要です。


# How to setup

## 事前の設定 (AWS)

### VPC

必要ならVPCを作成しておく。
デフォルトのVPCを利用する形でも問題ない。

作成されるインスタンスのためのサブネットを作成する。
以降の設定と同一リージョンであれば、どのVPCに作成しても問題ない。
名前は適当に命名する。
複数のサブネットを作成して良いが、同じ名前を付ける必要がある。

※インスタンスを作成する際は、利用するインスタンスタイプが利用可能なAZに存在する、指定された名前を持つサブネットの内最初に見つかったものを利用する。

### Security Group

SecurityGroupを作成する。
名前は適当に命名する。

インバウンドルール
|IP バージョン|タイプ|プロトコル|ポート範囲|ソース|説明|
|---|---|---|---|---|---|
|IPv4|SSH|TCP|22|0.0.0.0/0|SSH接続用|
|IPv4|カスタム TCP|TCP|18080|0.0.0.0/0|サーバー状態確認ページ用|
|IPv4|カスタム TCP|TCP|18081|0.0.0.0/0|サーバー状態問い合わせ用|
|IPv4|カスタム TCP|TCP|19132|0.0.0.0/0|Minecraftサーバー統合版用|
|IPv4|カスタム UDP|UDP|19132|0.0.0.0/0|Minecraftサーバー統合版用|
|IPv4|カスタム TCP|TCP|26291|0.0.0.0/0|MinecraftサーバーJava版用|

アウトバウンドルール
|IP バージョン|タイプ|プロトコル|ポート範囲|ソース|説明|
|---|---|---|---|---|---|
|IPv4|すべてのトラフィック|すべて|すべて|0.0.0.0/0||

### Key Pair

Key Pairを作成する。
名前は適当に命名する。
作成したインスタンスへSSHログインするためにはこのKey Pairを利用する必要がある。

### ID Provider

* プロバイダのタイプ: OpenID Connect
* プロバイダの URL: https://token.actions.githubusercontent.com
* 対象者: sts.amazonaws.com

上記設定でID Providerを作成する。

### IAM ポリシー

#### lambda にデプロイするポリシー

名前は適当に命名する。
対象とするlambdaを制限したい場合はResourceの内容を適当に書き換える。
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:UpdateFunctionCode"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:*"
            ]
        }
    ]
}
```

#### lambda のポリシー

名前は適当に命名する。
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DescribeVpcs",
                "ec2:CreateTags",
                "ec2:RunInstances",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:GetInstanceProfile"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
```

#### インスタンスのポリシー

名前は適当に命名する。
対象とするS3を制限したい場合はResourceの内容を適当に書き換える。
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:Put*",
                "s3:List*",
                "s3:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
```

### IAM Role

#### lambda にデプロイするRole

「信頼されたエンティティタイプ: ウェブアイデンティティ」でRoleを作成する。

* アイデンティティプロバイダー: token.actions.githubusercontent.com
* Audience: sts.amazonaws.com
* GitHub 組織: Organization名
* 許可ポリシー: [lambda にデプロイするポリシー](#lambda-にデプロイするポリシー) で作成したポリシー
* ロール名: (適当に命名する)

一度Roleを作成したのち、作成したRoleの「信頼関係」から信頼ポリシーを以下のように変更する。
`<account id>`、 `<organization name>`、 `<repository name>` の3つの値は適切なものに変更する必要がある。
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<account id>:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:<organization name>/<repository name>:*"
                }
            }
        }
    ]
}
```

#### lambda のRole

「信頼されたエンティティタイプ: AWS のサービス」でRoleを作成する。

* サービスまたはユースケース: lambda
* ユースケース: lambda
* 許可ポリシー: [lambda のポリシー](#lambda-のポリシー) で作成したポリシー
* ロール名: (適当に命名する)

#### インスタンスのRole

「信頼されたエンティティタイプ: AWS のサービス」でRoleを作成する。

* サービスまたはユースケース: ec2
* ユースケース: ec2
* 許可ポリシー: [インスタンスのポリシー](#インスタンスのポリシー) で作成したポリシー
* ロール名: (適当に命名する)

### lambda

デプロイ先となるlambdaを事前に作成しておく。

ランタイムはPython(2025/01/05現在 Python3.13がデフォルト)を選択する。
アーキテクチャは x86_64 で動作実績がある。arm64でもおそらく問題ない。

実行ロールは「既存のロールを使用する」から [lambda のRole](#lambda-のrole) で作成したRoleを選択する。

その他の構成から「関数 URL を有効化」を選択し、認証タイプをNONEにする。
※本来は何らかの認証をかけたりするべきであるが、今は対応していない。

### S3

アーカイブを保存するバケットを作成する。
名前は適当に命名する。

新規にサーバーを作成する場合、事前に `server_name` でフォルダを作成しておく必要があるかもしれない。※要確認

## 事前の設定 (Optional: Discord)

### Webhook

サーバーの起動、停止等のアクションが発生するごとにDiscordへ通知を送ることができる。

Discordのチャンネル設定から「連携サービス > ウェブフック」を開き、ウェブフックを作成する。
発行されるウェブフックURLは [事前の設定 (GitHub) - secrets](#secrets) で利用する。

## 事前の設定 (GitHub)

### secrets

`AWS_ROLE_ARN` の名前で [lambda のRole](#lambda-のrole) で作成したRoleのarnを保存する。

[事前の設定 (Optional: Discord) - Webhook](#webhook) でウェブフックを作成した場合は、ウェブフックURLを適当な名前で保存する。

### リポジトリ変数

[template/server_settings.json.template](https://github.com/Hiro-Onozawa/minecraft-server-manager/blob/master/template/server_settings.json.template) の内容を適当に編集し、 `SERVER_SETTINGS_JSON` の名前でリポジトリ変数へ保存する。

以下の項目は事前の設定に基づいた値を設定する。

* `servers.*.aws.region` : [事前の設定 (AWS)](#事前の設定-aws) を実施したリージョン名
* `servers.*.aws.archive_bucket_name` : [事前の設定 (AWS) - S3](#s3) で作成したアーカイブを保存するバケット名
* `servers.*.aws.security_group_name` : [事前の設定 (AWS) - Security Group](#security-group) で作成したSecurityGroupの名前
* `servers.*.aws.key_pair_name` : [事前の設定 (AWS) - Key Pair](#key-pair) で作成したKey Pairの名
* `servers.*.aws.instance_profile_name` : [事前の設定 (AWS) - IAM Role - インスタンスのRole](#インスタンスのrole) で作成したロール名
* `servers.*.aws.subnet_name` : [事前の設定 (AWS) - VPC](#vpc) で作成したサブネット名

### Lambdaへのデプロイ

[リポジトリ変数](#リポジトリ変数) で設定したJSONのうち、デプロイしたいサーバーの `servers.prop_name` の値を確認する。
[デプロイワークフロー](https://github.com/Hiro-Onozawa/minecraft-server-manager/actions/workflows/deploy.yml) を、デプロイ対象のブランチを選択し、Prop Nameに `servers.prop_name` の値を入力して、実行する。
