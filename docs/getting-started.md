# Getting Started

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- GitHub CLI (`gh`) installed
- Quyền access vào AWS account và GitHub repo

## Quick Start

### 1. Clone repo

```bash
git clone git@github.com:lupca/topvnsport-devops.git
cd topvnsport-devops
```

### 2. Cấu hình AWS credentials

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

Hoặc dùng AWS CLI:
```bash
aws configure
```

### 3. Deploy môi trường

```bash
cd environments/prod
terraform init
terraform plan    # Xem trước thay đổi
terraform apply   # Apply thay đổi
```

## Cấu trúc thư mục

```
topvnsport-devops/
├── modules/                    # Modules dùng chung
│   ├── ec2/                    # EC2 instance
│   ├── rds/                    # Aurora PostgreSQL Serverless v2
│   ├── s3/                     # S3 bucket
│   └── vpc/                    # VPC, subnets, routing
│
├── environments/               # Config từng môi trường
│   ├── prod/
│   │   ├── main.tf             # Gọi modules
│   │   ├── variables.tf        # Định nghĩa biến
│   │   ├── terraform.tfvars    # Giá trị biến (gitignored)
│   │   └── backend.tf          # State backend config
│   ├── staging/
│   └── dev/
│
├── docs/                       # Documentation
│
└── .github/workflows/
    └── terraform.yml           # CI/CD
```

## Environments

| Environment | Region | Mục đích |
|-------------|--------|----------|
| prod | us-east-1 | Production - dùng resources có sẵn |
| staging | us-east-1 | Testing trước prod |
| dev | us-east-1 | Development - tạo mới tất cả |

## Tiếp theo

- [Tạo môi trường mới](./create-new-environment.md)
- [Setup CI/CD](./cicd-setup.md)
- [Xử lý sự cố](./troubleshooting.md)
