# Tạo môi trường mới

Hướng dẫn tạo môi trường mới (dev, staging, hoặc bất kỳ env nào).

## Bước 1: Copy template

```bash
cp -r environments/prod environments/dev
```

## Bước 2: Sửa backend.tf

Mỗi environment cần state file riêng:

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

## Bước 3: Sửa terraform.tfvars

```hcl
# environments/dev/terraform.tfvars

environment = "dev"
region      = "us-east-1"

# === VPC ===
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]

# === EC2 - TẠO MỚI ===
ec2_ami_id            = "ami-0c7217cdde317cfec"  # Amazon Linux 2023
ec2_instance_type     = "t3.micro"               # Nhỏ hơn prod
ec2_key_name          = "dev-key"
ec2_subnet_id         = ""                       # Rỗng = dùng VPC module
ec2_existing_sg_id    = ""                       # Rỗng = tạo SG mới

# === RDS - TẠO MỚI ===
rds_engine_version        = "15.4"
rds_min_capacity          = 0.5
rds_max_capacity          = 2                    # Nhỏ hơn prod
rds_existing_subnet_group = ""                   # Rỗng = tạo mới
rds_existing_sg_id        = ""                   # Rỗng = tạo mới

# === S3 ===
s3_bucket_name = "topvnsport-assets-dev"         # Tên riêng
```

## Bước 4: Deploy

```bash
cd environments/dev
terraform init
terraform plan    # Xem trước
terraform apply   # Tạo hạ tầng
```

---

## Dùng có sẵn vs Tạo mới

Modules hỗ trợ cả 2 chế độ qua biến `existing_*`:

| Biến | Rỗng `""` | Có giá trị |
|------|-----------|------------|
| `ec2_subnet_id` | Dùng subnet từ VPC module | Dùng subnet có sẵn |
| `ec2_existing_sg_id` | Tạo Security Group mới | Dùng SG có sẵn |
| `rds_existing_subnet_group` | Tạo DB Subnet Group mới | Dùng có sẵn |
| `rds_existing_sg_id` | Tạo Security Group mới | Dùng SG có sẵn |

### Ví dụ: Prod (dùng resources có sẵn)

```hcl
ec2_existing_sg_id        = "sg-0051b179f57a7ad15"
rds_existing_subnet_group = "topvnsport-db-subnet"
rds_existing_sg_id        = "sg-05043d7ea0114b259"
```

### Ví dụ: Dev (tạo mới tất cả)

```hcl
ec2_existing_sg_id        = ""
rds_existing_subnet_group = ""
rds_existing_sg_id        = ""
```

---

## Deploy lên AWS account khác

Nếu muốn deploy lên AWS account khác:

### 1. Tạo S3 bucket cho state

```bash
# Trong AWS account mới
aws s3api create-bucket \
  --bucket mycompany-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket mycompany-terraform-state \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Sửa backend.tf

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"  # Bucket mới
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 3. Cấu hình AWS credentials mới

```bash
export AWS_ACCESS_KEY_ID="new-account-key"
export AWS_SECRET_ACCESS_KEY="new-account-secret"
```

### 4. Deploy

```bash
terraform init
terraform apply
```

---

## Deploy lên region khác

1. Sửa `region` trong backend.tf và terraform.tfvars
2. **Quan trọng:** Đổi `ec2_ami_id` - AMI khác nhau theo region

```bash
# Tìm AMI Amazon Linux 2023 cho region mới
aws ec2 describe-images \
  --region ap-southeast-1 \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId'
```
