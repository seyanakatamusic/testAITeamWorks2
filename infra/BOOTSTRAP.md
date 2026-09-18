# 初回ブートストラップ手順

Terraformのリモートステート（S3 + DynamoDB）とEKSクラスタ自体はTerraformで管理するが、
「ステートを保存する場所」は卵が先か鶏が先か問題があるため、以下は**手動で一度だけ**作成する。
このリポジトリのTerraformコードには含めていない（含めると、ステートバケット自体が
ステートで管理される循環が生じるため）。

AWS認証情報が未設定の場合は、まず運用者が `aws sso login --profile <プロファイル名>` を
実行してから進める。

## 1. リモートステート用S3バケット + DynamoDBロックテーブルの作成

環境（develop/production）ごとに1つずつ作成する。バケット名はグローバルに一意である必要が
あるため、末尾にアカウントID等を付与する。

```sh
docker run --rm -v "$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE \
  amazon/aws-cli:2.17.62 s3api create-bucket \
  --bucket attendance-saas-tfstate-develop-<ACCOUNT_ID> \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

docker run --rm -v "$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE \
  amazon/aws-cli:2.17.62 s3api put-bucket-versioning \
  --bucket attendance-saas-tfstate-develop-<ACCOUNT_ID> \
  --versioning-configuration Status=Enabled

docker run --rm -v "$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE \
  amazon/aws-cli:2.17.62 s3api put-bucket-encryption \
  --bucket attendance-saas-tfstate-develop-<ACCOUNT_ID> \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

docker run --rm -v "$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE \
  amazon/aws-cli:2.17.62 dynamodb create-table \
  --table-name attendance-saas-tfstate-lock-develop \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-1
```

production環境も同様にバケット名・テーブル名を`-production-`に変えて実行する。

## 2. ローカルからのbackend初期化

```sh
cp infra/environments/develop/backend.hcl.example infra/environments/develop/backend.hcl
# backend.hcl の bucket 名を手順1で作成した実際のバケット名に置き換える

cp infra/environments/develop/terraform.tfvars.example infra/environments/develop/terraform.tfvars
# terraform.tfvars の tf_state_bucket / tf_lock_table を実際の値に置き換える

docker run --rm -v "$PWD/infra/environments/develop:/workspace" -w /workspace \
  -v "$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE \
  hashicorp/terraform:1.9 init -backend-config=backend.hcl

docker run --rm -v "$PWD/infra/environments/develop:/workspace" -w /workspace \
  -v "$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE \
  hashicorp/terraform:1.9 plan
```

`terraform apply`は、Team Leadが`plan`の差分（特に`destroy`が無いこと）をレビューした後に
実行する。**現時点（本Issue対応時点）ではこのマシンにAWS認証情報が一切設定されていないため、
apply/plan（バックエンド有効時）は未実行。**

## 3. GitHub Actions側の設定（初回のみ・手動）

`terraform apply`でOIDCプロバイダとデプロイロールが作成された後、そのロールARNを
GitHub ActionsのRepository Variablesに登録する（Secretsではない。値は機密ではない）。

| Variable名 | 値 |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | `terraform output -raw github_deploy_role_arn`の値 |
| `AWS_REGION` | `ap-northeast-1` |
| `TF_STATE_BUCKET` | 手順1で作成したS3バケット名 |
| `TF_LOCK_TABLE` | 手順1で作成したDynamoDBテーブル名 |

アクセスキー・シークレットキーはGitHub Secretsに一切登録しない。

## 4. アプリケーションSecretの投入（DB接続情報等）

RDSのマスターパスワードはTerraform（`manage_master_user_password = true`）によって
AWS Secrets Managerへ自動生成・保管される（値はどこにも平文で出力されない）。
`infra/k8s/develop/backend-deployment.yaml`が参照する Kubernetes Secret
`backend-db-credentials`は、このSecrets Managerの値をSync元として運用者が投入する
（例: External Secrets Operatorの導入、またはワンタイムで
`kubectl create secret generic backend-db-credentials --from-literal=...`を
Secrets Managerから取得した値で実行）。このリポジトリのコード・CIには
一切値を書き込まない。
