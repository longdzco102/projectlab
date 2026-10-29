# Xianxia Chat - AWS Infrastructure (Terraform)

Hạ tầng AWS cho ứng dụng chat, tổ chức theo module và tách biệt từng môi trường.

```
                    Internet
                        │
                 ┌──────▼──────┐
                 │     ALB     │  public subnets (2 AZ)
                 └──────┬──────┘
                        │ :3000 (SG → SG)
          ┌─────────────▼─────────────┐
          │  ASG - EC2 (private)      │  private subnets (2 AZ)
          │  SSM agent, no SSH key    │
          └─────────────┬─────────────┘
                        │ :5432 (SG → SG)
                 ┌──────▼──────┐
                 │ RDS Postgres│  private subnets, Multi-AZ (prod)
                 └─────────────┘
```

## Cấu trúc

```
iac/
├── environments/
│   └── dev/                  # root module, chỉ gọi module + truyền biến
│       ├── backend.tf        # partial backend, config qua -backend-config
│       ├── backend.hcl.example
│       ├── versions.tf
│       ├── provider.tf       # AWS provider + default_tags
│       ├── variables.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
└── modules/
    ├── networking/           # VPC, subnets, IGW, NAT, route tables, flow logs
    ├── security-groups/      # ALB/app/DB SG (tránh cycle ALB ↔ EC2)
    ├── alb/                  # ALB, target group, listeners, Route53 alias
    ├── compute/              # IAM (SSM), launch template, ASG
    └── database/             # subnet group, parameter group, RDS, monitoring role
```

Quy ước:

- Root **không** khai báo resource, chỉ gọi module.
- Mỗi module sở hữu resource của mình và chỉ nhận đầu vào qua `variables`, trả ra `outputs`.
- Mọi tên resource đều có dạng `<project>-<environment>-...` nên nhiều môi trường
  dùng chung một account vẫn không đụng nhau.
- Tag `Project / Environment / ManagedBy` được gắn tự động qua `default_tags`.

## Yêu cầu

- Terraform >= 1.6
- AWS CLI v2 (đã cấu hình credentials)
- Quyền tạo: VPC, EC2/ASG, ALB, RDS, IAM role, Secrets Manager, CloudWatch Logs

## 1. Bootstrap state backend (làm một lần)

```bash
aws s3api create-bucket \
  --bucket xianxia-chat-terraform-state \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

aws s3api put-bucket-versioning \
  --bucket xianxia-chat-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket xianxia-chat-terraform-state \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket xianxia-chat-terraform-state \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws dynamodb create-table \
  --table-name xianxia-chat-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

Terraform >= 1.10 có thể bỏ DynamoDB và dùng `use_lockfile = true` trong `backend.hcl`.

## 2. Triển khai

```bash
cd iac/environments/dev

cp backend.hcl.example backend.hcl   # sửa bucket/table
cp terraform.tfvars.example terraform.tfvars

terraform init -backend-config=backend.hcl
terraform fmt -recursive ../..
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Xem kết quả:

```bash
terraform output
```

> **Lưu ý trước khi apply:** ASG dùng health check của ALB. Nếu `user_data` chưa
> cài ứng dụng (mặc định là rỗng), instance sẽ không trả 200 cho `health_check_path`
> và bị ASG thay liên tục. Hãy truyền `user_data` cài app, hoặc trỏ
> `health_check_path` vào endpoint có sẵn trên AMI.

## 3. Truy cập instance (không cần SSH)

Instance nằm trong private subnet và dùng **SSM Session Manager**:

```bash
aws ssm start-session --target <instance-id>
# hoặc dùng output:
$(terraform output -raw ssm_session_command)
```

Mở SSH qua SSM (nếu thực sự cần):

```bash
aws ssm start-session --target <instance-id> \
  --document-name AWS-StartSSHSession --parameters portNumber=22
```

Nếu muốn mở SSH trực tiếp, đặt `allowed_ssh_cidr` và `key_pair_name`.

## 4. Lấy mật khẩu database

Mật khẩu **không** nằm trong tfvars hay state. RDS tự sinh và lưu ở Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id "$(terraform output -raw db_master_user_secret_arn)" \
  --query SecretString --output text
```

Ứng dụng nên đọc secret này bằng IAM role (không hardcode), ví dụ gắn thêm policy
`secretsmanager:GetSecretValue` cho role `${project}-${env}-app-instance`.

## 5. Bật HTTPS + DNS

1. Tạo certificate trong ACM (cùng region với ALB).
2. Trong `terraform.tfvars`:

```hcl
enable_https    = true
certificate_arn = "arn:aws:acm:ap-southeast-1:111122223333:certificate/..."
domain_name     = "chat.example.com"
route53_zone_id = "Z0123456789ABCDEFGHIJ"
```

HTTP sẽ tự redirect 301 sang HTTPS.

## 6. Biến quan trọng

| Biến | Dev | Prod |
|---|---|---|
| `single_nat_gateway` | `true` | `false` (HA, 1 NAT/AZ) |
| `asg_min_size` / `desired` / `max` | `1/1/2` | `2/2/6` |
| `db_instance_class` | `db.t3.micro` | `db.r6g.large` |
| `db_multi_az` | `false` | `true` |
| `db_deletion_protection` | `false` | `true` |
| `db_skip_final_snapshot` | `true` | `false` |
| `db_final_snapshot_identifier` | – | bắt buộc, tên duy nhất |
| `db_performance_insights_enabled` | `false` | `true` |
| `enable_vpc_flow_logs` | `false` | `true` |
| `enable_https` | `false` | `true` |

Ghi chú:

- `db_skip_final_snapshot = false` yêu cầu `db_final_snapshot_identifier` và tên này
  **phải chưa tồn tại**; mỗi lần destroy nên đổi hậu tố (ví dụ `-20261024`).
- `db.t3.micro` không phải lúc nào cũng hỗ trợ Performance Insights → để `false` ở dev.

## 7. Quyết định thiết kế

- **Security group ở module riêng**: ALB cần mở tới SG app, app cần mở tới SG ALB.
  Nếu đặt trong hai module khác nhau sẽ tạo dependency cycle; gom về một module với
  `aws_vpc_security_group_ingress_rule`/`egress_rule` (standalone) giải quyết triệt để.
- **Không dùng EIP cho EC2**: instance nằm sau ALB, không cần IP công khai.
- **Không dùng SSH key mặc định**: SSM + IMDSv2 (`http_tokens = required`) là đường
  quản trị mặc định; `key_pair_name` để `null`.
- **Không để mật khẩu trong state**: `manage_master_user_password = true` sinh secret
  trong Secrets Manager.
- **Egress tối thiểu**: app chỉ mở 443/80 ra internet, DNS tới resolver trong VPC,
  NTP tới Amazon Time Sync, và 5432 tới SG của DB. DB không có egress.
- **AMT/AMI**: dùng `data.aws_ami` (Canonical, Ubuntu 24.04) thay vì hardcode AMI ID,
  tránh lỗi khi đổi region.
- **NAT Gateway**: mặc định 1 NAT cho dev; prod đặt `single_nat_gateway = false` để
  mỗi AZ có NAT riêng (không còn SPOF và tránh phí cross-AZ).

## 8. Chưa bao gồm (khuyến nghị bổ sung)

- VPC endpoints cho SSM/ECR/S3 (bỏ phụ thuộc NAT, giảm chi phí)
- WAF + CloudFront trước ALB
- CloudWatch alarms / dashboard, SNS alert
- AWS Backup cho RDS, cross-region snapshot copy
- CI/CD (GitHub Actions + OIDC role, không dùng access key)
- `environments/prod` và `environments/staging` (copy thư mục `dev`, đổi
  `environment` và file `backend.hcl` – state tách riêng theo `key`)

## 9. Chi phí dev ước tính (ap-southeast-1)

- ALB: ~$18/tháng (chưa tính LCU)
- EC2 t3.small: ~$15/tháng
- NAT Gateway 1 cái: ~$32/tháng + data
- RDS db.t3.micro: ~$15/tháng (single-AZ, 20GB gp3)
- Secrets Manager: ~$0.40/tháng

Tắt hết bằng `terraform destroy` khi không dùng.
