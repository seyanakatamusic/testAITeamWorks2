# インフラ構成（Terraform + EKS）

Issue #9「インフラ基盤構築(EKS+Terraform)」に対応する構成。VPC/EKS/RDSをTerraformで
再現可能に構築し、`develop`ブランチへのマージでGitHub Actionsが自動デプロイする。

## ディレクトリ構成

```
infra/
├── modules/
│   ├── network/  # VPC・サブネット・NAT Gateway（terraform-aws-modules/vpc を利用）
│   ├── eks/      # EKSクラスタ・マネージドノードグループ（terraform-aws-modules/eks を利用）
│   ├── rds/      # Postgres RDS（マスターパスワードはSecrets Managerへ自動保管）
│   └── oidc/     # GitHub Actions OIDC IDプロバイダ + デプロイ用IAMロール
├── environments/
│   ├── develop/      # develop環境のルートモジュール（上記4モジュールを結線）
│   └── production/   # production環境のルートモジュール（同構成、サイズ違い）
├── k8s/develop/  # develop namespaceへのkubectl/kustomizeマニフェスト
└── BOOTSTRAP.md  # リモートステートバケット等、初回のみ手動で行う手順
```

develop環境はコスト最適化を優先し、NAT Gateway 1つに集約、EKSノード`t3.medium`×1〜2、
RDS `db.t4g.micro`・Single-AZとしている。production環境はAZごとにNAT Gatewayを分散し、
RDSをMulti-AZ・削除保護有効にしている。

## 自動デプロイの流れ（`develop`ブランチ）

1. `develop`ブランチへのpushで`.github/workflows/deploy-develop.yml`が起動する。
2. GitHub ActionsがOIDCフェデレーション（`aws-actions/configure-aws-credentials`の
   `role-to-assume`）でAWSの一時クレデンシャルを取得する。長期アクセスキーはGitHub側に
   一切保存しない。
3. `infra/environments/develop`で`terraform init` → `terraform apply`を実行し、
   VPC/EKS/RDS/OIDCロールをapplyする。
4. `aws eks update-kubeconfig`でkubeconfigを取得し、`kubectl apply -k infra/k8s/develop`で
   `develop` namespaceへbackend/frontendのDeployment/Serviceを適用する。

CI側で必要なGitHub Actions **Variables**（Secretsではない）:

| Variable名 | 内容 |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | OIDCでAssumeするデプロイ用IAMロールARN |
| `AWS_REGION` | 例: `ap-northeast-1` |
| `TF_STATE_BUCKET` | リモートステート用S3バケット名 |
| `TF_LOCK_TABLE` | Terraformロック用DynamoDBテーブル名 |

これらはIAM ARNやリージョン名など機密性のない値のため、Secretsではなく`vars`コンテキストの
Repository Variablesとして設定する。アクセスキー・シークレットキーは本ワークフローでは
一切使用しない。

## 資格情報の扱い

- ローカル実行時は`AWS_PROFILE`環境変数（事前に`aws configure sso`済みのプロファイル）のみを
  参照する。長期アクセスキーはローカルにもコードにも置かない。
- RDSのマスターパスワードはTerraformの`manage_master_user_password = true`により
  AWS Secrets Managerへ自動生成・保管される。Terraformコード・stateに平文パスワードは
  一切含まれない。
- GitHub ActionsはOIDCフェデレーションのみを使う。GitHub Secretsへのアクセスキー登録は
  行っていない。

## 現在のステータス（重要）

**このIssue対応時点では、作業マシンにAWS認証情報が一切設定されていないため、
`terraform apply`は実行していない（`terraform fmt` / `terraform validate`まで実施済み）。**
以下がAWS認証情報提供後にTeam Lead/運用者が行う残作業:

1. `infra/BOOTSTRAP.md`の手順1〜2に従い、リモートステート用S3バケット・DynamoDBロック
   テーブルを手動作成し、ローカルから`terraform plan`を実行して意図しない`destroy`が
   無いことを確認する。
2. 問題なければ`terraform apply`を実行し、VPC/EKS/RDS/OIDCロールを実際に構築する。
3. `terraform output -raw github_deploy_role_arn`等の値をGitHub Actions Variablesへ登録する
   （`infra/BOOTSTRAP.md`手順3）。
4. `infra/BOOTSTRAP.md`手順4に従い、RDSのSecrets Manager値からKubernetes Secret
   `backend-db-credentials`を投入する。
5. backend/frontendのコンテナイメージをビルド・ECR等へpushするステップは、本Issueの
   スコープ外（アプリ側CI/CDの担当）。`.github/workflows/deploy-develop.yml`は
   `infra/k8s/develop/*-deployment.yaml`のイメージタグが既にpush済みであることを前提に
   `kubectl apply -k`のみを行う。イメージビルド・pushが別ワークフローで用意され次第、
   このワークフローの前段（あるいは別ジョブ）として組み込む想定。

以上が揃うまで、CI/CDパイプラインは「backend/frontendのDockerイメージが既に存在する」
という前提のもと動作する構成であり、エンドツーエンドでの成功実行はまだ確認できていない。
