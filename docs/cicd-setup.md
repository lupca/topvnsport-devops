# CI/CD Setup

Hướng dẫn setup GitHub Actions để tự động deploy Terraform.

## Cách hoạt động

| Event | Hành động |
|-------|-----------|
| Pull Request | Chạy `terraform plan` cho tất cả env |
| Push to main | Chạy `terraform apply` cho staging |
| Manual trigger | Chọn env + action (plan/apply) |

## Setup GitHub Secrets

Secrets là thông tin nhạy cảm (credentials, passwords):

```bash
cd topvnsport-devops

# AWS credentials
gh secret set AWS_ACCESS_KEY_ID
# (nhập key khi được hỏi, Enter để confirm)

gh secret set AWS_SECRET_ACCESS_KEY
# (nhập secret khi được hỏi)

# RDS password
gh secret set PROD_RDS_MASTER_PASSWORD
# (nhập password khi được hỏi)
```

Hoặc set trực tiếp (không khuyến khích vì lưu trong shell history):
```bash
gh secret set AWS_ACCESS_KEY_ID --body "AKIAXXXXXXXX"
```

## Setup GitHub Variables

Variables là thông tin không nhạy cảm:

```bash
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
```

## Kiểm tra

```bash
# List secrets (chỉ thấy tên, không thấy giá trị)
gh secret list

# List variables (thấy cả giá trị)
gh variable list
```

---

## Trigger workflow thủ công

### Qua GitHub UI

1. Vào repo → **Actions** tab
2. Chọn workflow **Terraform CI/CD**
3. Click **Run workflow**
4. Chọn:
   - `environment`: dev / staging / prod
   - `action`: plan / apply
5. Click **Run workflow**

### Qua CLI

```bash
# Plan
gh workflow run terraform.yml -f environment=prod -f action=plan

# Apply
gh workflow run terraform.yml -f environment=prod -f action=apply

# Xem kết quả
gh run list --workflow=terraform.yml
gh run view <run-id> --log
```

---

## Thêm environment mới vào CI/CD

### 1. Thêm secrets/variables cho env mới

```bash
# Ví dụ: staging
gh secret set STAGING_RDS_MASTER_PASSWORD

gh variable set STAGING_VPC_CIDR --body "10.1.0.0/16"
gh variable set STAGING_EC2_EXISTING_SG_ID --body ""  # Rỗng = tạo mới
gh variable set STAGING_RDS_EXISTING_SG_ID --body ""
# ... các biến khác
```

### 2. Sửa workflow để đọc biến theo env

```yaml
# .github/workflows/terraform.yml
env:
  # Dùng biến động theo environment
  TF_VAR_vpc_cidr: ${{ vars[format('{0}_VPC_CIDR', inputs.environment)] }}
```

---

## Thêm approval cho Production

### 1. Tạo Environment trong GitHub

1. Vào repo → **Settings** → **Environments**
2. Click **New environment**
3. Tên: `prod`
4. Thêm **Protection rules**:
   - ✅ Required reviewers → chọn người approve
   - ✅ Wait timer (optional) → 5 minutes

### 2. Workflow tự động dừng chờ approval

Khi chạy với `environment: prod`, workflow sẽ pause và chờ approval trước khi apply.

---

## Debug CI/CD

### Xem logs

```bash
# List các run gần đây
gh run list --workflow=terraform.yml

# Xem log chi tiết
gh run view <run-id> --log

# Xem log của 1 job cụ thể
gh run view <run-id> --log --job=<job-id>
```

### State lock bị stuck

Nếu workflow fail và để lại state lock:

```bash
cd environments/prod
terraform force-unlock -force <lock-id>
```

Lấy `lock-id` từ error message trong workflow log.
