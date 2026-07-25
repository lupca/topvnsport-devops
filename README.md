# TopVNSport Infrastructure as Code

Terraform IaC cho hạ tầng TopVNSport trên AWS.

## Quick Start

```bash
# 1. Clone repo
git clone git@github.com:lupca/topvnsport-devops.git
cd topvnsport-devops

# 2. Cấu hình AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"

# 3. Deploy
cd environments/prod
terraform init
terraform plan
terraform apply
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
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars    # Biến prod (gitignored)
│   │   └── backend.tf          # State backend
│   ├── staging/
│   └── dev/
│
├── docs/
│   └── prod-infrastructure.md  # Chi tiết hạ tầng prod
│
└── .github/workflows/
    └── terraform.yml           # CI/CD
```

## Environments

| Environment | Region | State | Mục đích |
|-------------|--------|-------|----------|
| prod | us-east-1 | S3 remote | Production |
| staging | us-east-1 | S3 remote | Testing |
| dev | us-east-1 | Local | Development |

---

## Tạo môi trường mới

### Bước 1: Copy template

```bash
cp -r environments/prod environments/dev
```

### Bước 2: Sửa backend.tf

```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "topvnsport-terraform-state"
    key            = "dev/terraform.tfstate"  # ← Đổi path
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Bước 3: Sửa terraform.tfvars

```hcl
# environments/dev/terraform.tfvars

environment = "dev"

# === TẠO MỚI (để rỗng) ===
ec2_subnet_id             = ""
ec2_existing_sg_id        = ""
rds_existing_subnet_group = ""
rds_existing_sg_id        = ""

# === Cấu hình nhỏ hơn ===
ec2_instance_type = "t3.micro"
rds_min_capacity  = 0.5
rds_max_capacity  = 2

# === Tên riêng ===
s3_bucket_name = "topvnsport-assets-dev"
```

### Bước 4: Deploy

```bash
cd environments/dev
terraform init
terraform plan    # Xem trước
terraform apply   # Tạo hạ tầng
```

---

## Dùng có sẵn vs Tạo mới

Modules hỗ trợ cả 2 chế độ:

| Biến | Rỗng `""` | Có giá trị |
|------|-----------|------------|
| `ec2_existing_sg_id` | Tạo SG mới | Dùng SG có sẵn |
| `rds_existing_subnet_group` | Tạo Subnet Group mới | Dùng có sẵn |
| `rds_existing_sg_id` | Tạo SG mới | Dùng có sẵn |
| `ec2_subnet_id` | Dùng VPC module | Dùng subnet có sẵn |

**Ví dụ Prod (dùng có sẵn):**
```hcl
ec2_existing_sg_id = "sg-0051b179f57a7ad15"
```

**Ví dụ Dev (tạo mới):**
```hcl
ec2_existing_sg_id = ""
```

---

## CI/CD

### Trigger thủ công (GitHub Actions)

1. Vào **Actions** tab
2. Chọn **Terraform CI/CD**
3. Click **Run workflow**
4. Chọn:
   - `environment`: dev / staging / prod
   - `action`: plan / apply

### Tự động

| Event | Hành động |
|-------|-----------|
| PR | `terraform plan` cho tất cả env |
| Push main | `terraform apply` cho staging |

### Secrets cần thiết

Trong GitHub repo → Settings → Secrets:

| Secret | Mô tả |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `PROD_RDS_MASTER_PASSWORD` | RDS password |

### Variables cần thiết

Trong GitHub repo → Settings → Variables:

| Variable | Ví dụ |
|----------|-------|
| `PROD_VPC_CIDR` | `172.31.0.0/16` |
| `PROD_PUBLIC_SUBNET_CIDRS` | `["172.31.0.0/20","172.31.80.0/20"]` |
| `PROD_EC2_AMI_ID` | `ami-06067086cf86c58e6` |
| `PROD_EC2_EXISTING_SG_ID` | `sg-0051b179f57a7ad15` |
| `PROD_RDS_EXISTING_SG_ID` | `sg-05043d7ea0114b259` |
| `PROD_S3_BUCKET_NAME` | `topvnsport-assets` |

### Setup GitHub Secrets & Variables (CLI)

```bash
cd topvnsport-devops

# === SECRETS (sensitive) ===
gh secret set AWS_ACCESS_KEY_ID
# (nhập key khi được hỏi)

gh secret set AWS_SECRET_ACCESS_KEY
# (nhập secret khi được hỏi)

gh secret set PROD_RDS_MASTER_PASSWORD
# (nhập password khi được hỏi)

# === VARIABLES (non-sensitive) ===

# VPC
gh variable set PROD_VPC_CIDR --body "172.31.0.0/16"
gh variable set PROD_PUBLIC_SUBNET_CIDRS --body '["172.31.0.0/20","172.31.80.0/20","172.31.32.0/20"]'
gh variable set PROD_AVAILABILITY_ZONES --body '["us-east-1a","us-east-1b","us-east-1d"]'

# EC2
gh variable set PROD_EC2_AMI_ID --body "ami-06067086cf86c58e6"
gh variable set PROD_EC2_KEY_NAME --body "local"
gh variable set PROD_EC2_SUBNET_ID --body "subnet-02d90789c6c5af683"
gh variable set PROD_EC2_EXISTING_SG_ID --body "sg-0051b179f57a7ad15"

# RDS
gh variable set PROD_RDS_ENGINE_VERSION --body "17.4"
gh variable set PROD_RDS_EXISTING_SUBNET_GROUP --body "topvnsport-db-subnet"
gh variable set PROD_RDS_EXISTING_SG_ID --body "sg-05043d7ea0114b259"

# S3
gh variable set PROD_S3_BUCKET_NAME --body "topvnsport-assets"

# Kiểm tra
gh variable list
gh secret list
```

### Setup cho môi trường mới (ví dụ: staging)

```bash
# Đổi prefix PROD_ thành STAGING_
gh variable set STAGING_VPC_CIDR --body "10.1.0.0/16"
gh variable set STAGING_EC2_EXISTING_SG_ID --body ""  # Rỗng = tạo mới
gh variable set STAGING_RDS_EXISTING_SG_ID --body ""  # Rỗng = tạo mới
# ... tương tự cho các biến khác

# Thêm secret riêng
gh secret set STAGING_RDS_MASTER_PASSWORD
```

Sau đó cập nhật `.github/workflows/terraform.yml` để đọc biến theo environment.

---

## Các lệnh thường dùng

```bash
# Xem trước thay đổi
terraform plan

# Apply thay đổi
terraform apply

# Xem resources đang quản lý
terraform state list

# Xem chi tiết 1 resource
terraform state show module.ec2.aws_instance.topvnsport

# Unlock state bị stuck
terraform force-unlock -force <lock-id>

# Destroy (CẨN THẬN!)
terraform destroy
```

---

## Xử lý sự cố

### State lock bị stuck

```
Error: Error acquiring the state lock
Lock Info:
  ID: abc-123-xyz
```

**Fix:**
```bash
terraform force-unlock -force abc-123-xyz
```

### Muốn thay đổi region

1. Sửa `backend.tf` → region mới
2. Sửa `terraform.tfvars` → region mới
3. Sửa `ec2_ami_id` → AMI của region mới (AMI khác nhau theo region)
4. `terraform init -migrate-state`

### Import resource có sẵn

```bash
# EC2
terraform import module.ec2.aws_instance.topvnsport i-0ede7353edeef0c63

# RDS Cluster
terraform import module.rds.aws_rds_cluster.main topvnsport-db

# RDS Instance
terraform import module.rds.aws_rds_cluster_instance.main topvnsport-db-instance-1
```

---

## Production Infrastructure

| Resource | ID/Name | Endpoint |
|----------|---------|----------|
| EC2 | `i-0ede7353edeef0c63` | `52.203.250.214` |
| RDS | `topvnsport-db` | `topvnsport-db.cluster-xxx.us-east-1.rds.amazonaws.com` |
| S3 | `topvnsport-assets` | `s3://topvnsport-assets` |

Chi tiết: [docs/prod-infrastructure.md](docs/prod-infrastructure.md)

---

## Liên hệ

- **Slack:** #devops
- **Email:** devops@topvnsport.com
