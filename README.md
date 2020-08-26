# jawsug-saitama-20200820
## はじめに
このリポジトリでは、[「JAWS-UG さいたま支部 第13回勉強会 〜サイタマ ユウチュウ部 オンライン勉強β Vol.1〜」](https://jawsug-saitama.doorkeeper.jp/events/105857 "JAWS-UG さいたま支部 第13回勉強会 〜サイタマ ユウチュウ部 オンライン勉強β Vol.1〜")
で発表した「Fargateでサクっとバッチ処理実行してみる」の資料と実際に使用したソースコードを公開しています。

### 発表動画
Youtubeに動画を公開していますので、宜しければ合わせてご覧ください。
https://youtu.be/yLABC5KnD2E

## 今回実現したいこと
1. Githubにpushする
1. Codebuildで実行したい処理を含むDockerイメージを作成する
1. 定期的にFargateコンテナを起動する

## 手順
### 下準備
1. Githubにリポジトリを作成しておく(このリポジトリをフォークしてもOK)

### 必要な関連リソースを作成する
1. Fargateクラスタを作成する
1. ECRリポジトリを作成する
1. アウトバンド通信のみを許可したセキュリティグループを作成する
1. Fargate用のCloudWatch Logsのロググループを作成する(マネジメントコンソールは省略可)
1. IAMロールを作成する
   1. Fargateタスク用(マネジメントコンソールは自動作成可)
      ```AmazonECSTaskExecutionRolePolicy(AWS Managed Policy)
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "ecr:GetAuthorizationToken",
                      "ecr:BatchCheckLayerAvailability",
                      "ecr:GetDownloadUrlForLayer",
                      "ecr:BatchGetImage",
                      "logs:CreateLogStream",
                      "logs:PutLogEvents"
                  ],
                  "Resource": "*"
              }
          ]
      }
      ```
   1. CloudWatch Events用(マネジメントコンソールは自動作成可)<br>
      ※PassRoleのResourceがアスタリスクなので注意
      ```AmazonEC2ContainerServiceEventsRole(AWS Managed Policy)
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "ecs:RunTask"
                  ],
                  "Resource": [
                      "*"
                  ]
              },
              {
                  "Effect": "Allow",
                  "Action": "iam:PassRole",
                  "Resource": [
                      "*"
                  ],
                  "Condition": {
                      "StringLike": {
                          "iam:PassedToService": "ecs-tasks.amazonaws.com"
                      }
                  }
              }
          ]
      }
      ```
   1. Codebuild用(マネジメントコンソールから作ったあとインラインポリシーで下記を追加)<br>
      ※必要に応じてCloudWatch LogsやS3の権限も追加する
      ```CodeBuildBasePolicy
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Action": [
                      "ecr:BatchCheckLayerAvailability",
                      "ecr:CompleteLayerUpload",
                      "ecr:GetAuthorizationToken",
                      "ecr:InitiateLayerUpload",
                      "ecr:PutImage",
                      "ecr:UploadLayerPart"
                  ],
                  "Resource": "*",
                  "Effect": "Allow"
              }
          ]
      }
      ```

### Codebuildでビルドプロジェクトを作成する
#### 主な設定値
下記に指定がないパラメータはデフォルト値でOK

|||
|---|---|
|プロジェクト名|build-hello-saitama|
|説明|Fargateで実行するdockerイメージを生成し、ECRに登録します。|
|ソースプロバイダ|GitHub|
|リポジトリ|GitHubアカウントのリポジトリ(今回はOAuthで接続)|
|GitHubリポジトリ|https://github.com/<リポジトリ名>/jawsug-saitama-20200820.git|
|環境イメージ|マネージド型イメージ|
|サービスロール|新しいサービスロール|
|オペレーティングシステム|Amazon Linux2|
|ランタイム|Standard|
|イメージ|最新のイメージを選択|
|イメージのバージョン|常に最新|
|環境タイプ|Linux|
|特権付与|【重要】チェックを入れる|
|ロール名|codebuild-build-service-role|
|タイムアウト|10分|
|VPC|指定しない|
|セキュリティグループ|前手順で作成したセキュリティグループ|
|環境変数|AWS_DEFAULT_REGION: ap-northeast-1|
| |AWS_ACCOUNT_ID: <AWSアカウントID>|
| |IMAGE_REPO_NAME: hello-saitama|
| |IMAGE_TAG: latest|
|ビルド仕様|buildspecファイルを使用する|
|ログ|CloudWatch Logsにチェックを入れる(値は空で良い)|

### Codebuild用ロールのポリシーを修正する
1. 「必要な関連リソースを作成する」の通りCodebuild用ロールのポリシーを上書きする

### Codebuildでビルドジョブを実行する
1. Githubにソースコードをpushすると、buildspec.ymlで指定した処理が実行される(手動実行も可)
#### 関連ファイル
- buildspec.yml Codebuildで実行するビルド処理を記述したファイル
- Dockerfile Dockerイメージ作成時に行う処理を記述したファイル
- hello_saitama.sh 定期実行するシェルスクリプト

### Fargateの定期実行スケジュールを登録する
1. Fargateのタスク定義を作成する(task-definition.json参照)
1. 試しにタスクを手動実行してみる
1. Fargate(CloudWatch Events)のタスク実行スケジュールを登録する
#### 関連ファイル
- task-definition.json Fargateタスクの構成を記述したファイル

## 改善したいポイント
- AWSリソースをコード化すれば管理しやすくできる
- ビルド処理はMakefile化しておくとローカルやCircleCIなどで実行しやすくできる
- Fargate用のタスク定義をCodebuildで書き換えれば複数環境で利用しやすくできる
- CloudWatch Eventsの実行スケジュールをCodebuildで書き換えれば管理しやすくできる

## 参考リンク
https://docs.aws.amazon.com/ja_jp/codebuild/latest/userguide/sample-docker.html
https://docs.aws.amazon.com/ja_jp/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-syntax
https://dev.classmethod.jp/articles/codebuild-supports-accessing-build-environments-with-aws-session-manager/
