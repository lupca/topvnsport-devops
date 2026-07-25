# Xử lý sự cố

## State lock bị stuck

### Triệu chứng

```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc-123-xyz
  Path:      topvnsport-terraform-state/prod/terraform.tfstate
  Operation: OperationTypePlan
  Who:       runner@xxx
```

### Nguyên nhân

- Workflow trước bị cancel/timeout nhưng chưa release lock
- Đang có process khác chạy terraform

### Fix

```bash
cd environments/prod
terraform force-unlock -force abc-123-xyz
```

Thay `abc-123-xyz` bằng Lock ID từ error message.

---

## Terraform muốn destroy/replace resources

### Triệu chứng

```
Plan: 5 to add, 3 to change, 2 to destroy
```

Hoặc:
```
# module.ec2.aws_instance.topvnsport must be replaced
```

### Nguyên nhân

- Config trong `.tf` files không khớp với AWS thực tế
- Thường do: subnet_id, ami_id, security_group khác

### Fix

**Option 1:** Cập nhật tfvars để match AWS

```bash
# Lấy thông tin thực từ AWS
aws ec2 describe-instances --instance-ids i-xxx --query 'Reservations[0].Instances[0].{SubnetId:SubnetId,AMI:ImageId}'

# Cập nhật terraform.tfvars với giá trị đúng
```

**Option 2:** Ignore changes trong lifecycle

```hcl
# modules/ec2/main.tf
resource "aws_instance" "topvnsport" {
  # ...
  lifecycle {
    ignore_changes = [ami, subnet_id]
  }
}
```

**Option 3:** Xóa resource khỏi state (không quản lý bằng Terraform nữa)

```bash
terraform state rm module.ec2.aws_instance.topvnsport
```

---

## Thiếu biến khi chạy CI/CD

### Triệu chứng

Workflow stuck hoặc fail với:
```
var.s3_bucket_name
  S3 bucket name

  Enter a value:
```

### Fix

Thêm biến vào GitHub Variables:

```bash
gh variable set PROD_S3_BUCKET_NAME --body "topvnsport-assets"
```

Và cập nhật workflow để đọc biến đó:

```yaml
# .github/workflows/terraform.yml
env:
  TF_VAR_s3_bucket_name: ${{ vars.PROD_S3_BUCKET_NAME }}
```

---

## AWS credentials không hợp lệ

### Triệu chứng

```
Error: error configuring Terraform AWS Provider: error validating provider credentials
```

### Fix

```bash
# Kiểm tra credentials
aws sts get-caller-identity

# Nếu fail, set lại
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Hoặc update GitHub Secrets
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
```

---

## S3 bucket đã tồn tại

### Triệu chứng

```
Error: creating Amazon S3 Bucket: BucketAlreadyExists
```

### Fix

S3 bucket name phải globally unique. Đổi tên:

```hcl
# terraform.tfvars
s3_bucket_name = "topvnsport-assets-dev-12345"
```

Hoặc import bucket có sẵn:

```bash
terraform import module.s3.aws_s3_bucket.assets topvnsport-assets
```

---

## RDS cluster không thể modify

### Triệu chứng

```
Error: error modifying RDS Cluster: InvalidParameterCombination
```

### Nguyên nhân

Một số thay đổi RDS yêu cầu downtime hoặc không thể thực hiện trực tiếp.

### Fix

**Option 1:** Apply với `apply_immediately = true`

```hcl
resource "aws_rds_cluster" "main" {
  # ...
  apply_immediately = true
}
```

**Option 2:** Tạo cluster mới, migrate data

1. Tạo snapshot: `aws rds create-db-cluster-snapshot`
2. Đổi tên cluster cũ trong tfvars
3. `terraform apply` để tạo cluster mới
4. Restore data từ snapshot
5. Xóa cluster cũ

---

## Network timeout khi init

### Triệu chứng

```
Error: Failed to install provider
dial tcp: i/o timeout
```

### Fix

Retry, thường do mạng tạm thời:

```bash
terraform init -upgrade
```

Hoặc dùng mirror:

```bash
# ~/.terraformrc
provider_installation {
  network_mirror {
    url = "https://registry.terraform.io/"
  }
}
```

---

## Các lệnh debug hữu ích

```bash
# Xem state hiện tại
terraform state list
terraform state show module.ec2.aws_instance.topvnsport

# Refresh state từ AWS (không thay đổi gì)
terraform refresh

# Validate config
terraform validate

# Format code
terraform fmt -recursive

# Xem plan chi tiết
terraform plan -out=plan.tfplan
terraform show plan.tfplan

# Import resource có sẵn
terraform import module.ec2.aws_instance.topvnsport i-0ede7353edeef0c63
```
