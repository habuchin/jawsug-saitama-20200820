# jawsug-saitama-20200820
## はじめに
このリポジトリでは、[「JAWS-UG さいたま支部 第13回勉強会 〜サイタマ ユウチュウ部 オンライン勉強β Vol.1〜」](https://jawsug-saitama.doorkeeper.jp/events/105857 "JAWS-UG さいたま支部 第13回勉強会 〜サイタマ ユウチュウ部 オンライン勉強β Vol.1〜")
で発表した「Fargateでサクっとバッチ処理実行してみる」の資料と実際に使用したソースコードを公開しています。

## 今回実現したいこと
1. Githubにpushする
1. Codebuildで実行したい処理を含むdockerイメージを作成する
1. 定期的にFargateコンテナを起動する

## 手順
### 下準備
1. Githubにリポジトリを作成する
1. Fargateクラスタ及びVPCを作成する
1. ECRリポジトリを作成する
1. CloudWatch Logsのロググループを作成する
1. Codebuildで使用するIAMロールを作成する
1. Fargateコンテナで使用するIAMロールを作成する

### dockerイメージを作成する
1. Codebuildで使用するbuildspec.ymlを用意する
1. バッチ実行したい内容をシェルスクリプト用意する
1. Dockerイメージ作成時に利用するDockerfile用意する

## 改善したいポイント
- AWSリソースのコード化
- Fargate用のタスク定義をCodebuildで書き換える
- CloudWatch Eventsの実行スケジュールをCodebuildで書き換える
