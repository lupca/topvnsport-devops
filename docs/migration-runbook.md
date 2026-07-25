# Migration Runbook: IaC Foundation (Phase 1)

Step-by-step instructions for bringing the existing TopVNSport production
infrastructure (EC2, RDS, VPC/Security Groups) under Terraform management,
creating the new S3 assets bucket, and cutting over the apps from
self-hosted Postgres/MinIO containers to RDS/S3.

Related: [[docs/prod-infrastructure.md]] for current resource identifiers,
[[docs/infrastructure-diagram.html]] for the current vs. target architecture.

> This repo (`topvnsport-devops`) only covers the Terraform/IaC side
> (Phases 1-4 below). App-level changes (Phase 5) require separate tasks in
> `topvnsport-pmi`, `topvnsport-oms`, `topvnsport-wms`, and `identity` — see
> "Dependencies on Other Projects" at the end of this document.

## Prerequisites

- Terraform >= 1.0, AWS CLI v2, configured with credentials that have
  access to account `402631154151` (`us-east-1`).
- IAM permissions to create S3 buckets, DynamoDB tables, and to read/import
  EC2, VPC, and RDS resources.
- `psql` and `mc` (MinIO Client) installed on the machine used for data
  migration (Phase 5), or run from the EC2 instance itself.

## Phase 1: Terraform State Backend

Run once, before any `terraform init` against `environments/prod`.

```bash
aws s3api create-bucket \
  --bucket topvnsport-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket topvnsport-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket topvnsport-terraform-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket topvnsport-terraform-state \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

`environments/prod/backend.tf` is already configured to point at this
bucket/table. Do not run `terraform init` in `environments/prod` until both
resources above exist.

## Phase 2: Discover Existing Resources

These values populate `environments/prod/terraform.tfvars` (copy from
`terraform.tfvars.example`; it is gitignored, never commit real values).

```bash
# VPC
aws ec2 describe-vpcs --region us-east-1 --output table
# -> record vpc_cidr

# Subnets (used by the EC2 instance and intended for RDS)
aws ec2 describe-subnets --region us-east-1 --output table
# -> record public_subnet_cidrs and availability_zones, same order

# EC2 instance details
aws ec2 describe-instances --instance-ids i-0ede7353edeef0c63 \
  --query 'Reservations[*].Instances[*].{AMI:ImageId,Type:InstanceType,Key:KeyName,Subnet:SubnetId,VPC:VpcId,SGs:SecurityGroups}' \
  --output table
# -> record ec2_ami_id, ec2_key_name

# RDS Aurora cluster details
aws rds describe-db-clusters --db-cluster-identifier database-topvnsport \
  --region us-east-1 \
  --query 'DBClusters[0].{Engine:Engine,Version:EngineVersion,Subnets:DBSubnetGroup,SGs:VpcSecurityGroups}'
# -> record rds_engine_version

# RDS master password: retrieve from wherever it was originally stored
# (password manager / Secrets Manager). Never put it in terraform.tfvars —
# export it instead:
export TF_VAR_rds_master_password="<the current master password>"
```

Fill in `environments/prod/terraform.tfvars` with the discovered VPC/subnet/
AMI/engine values. Leave `rds_master_password` out of the file and rely on
the `TF_VAR_rds_master_password` environment variable.

## Phase 3: Import Existing Infrastructure

```bash
cd environments/prod
terraform init
terraform validate

# VPC
terraform import module.vpc.aws_vpc.main <vpc-id>
terraform import module.vpc.aws_internet_gateway.main <igw-id>
terraform import 'module.vpc.aws_subnet.public[0]' <subnet-id-1>
terraform import 'module.vpc.aws_subnet.public[1]' <subnet-id-2>
terraform import module.vpc.aws_route_table.public <route-table-id>
terraform import 'module.vpc.aws_route_table_association.public[0]' <subnet-id-1>/<route-table-id>
terraform import 'module.vpc.aws_route_table_association.public[1]' <subnet-id-2>/<route-table-id>

# EC2
terraform import module.ec2.aws_security_group.app <sg-id>
terraform import module.ec2.aws_instance.topvnsport i-0ede7353edeef0c63

# RDS
terraform import module.rds.aws_db_subnet_group.main <db-subnet-group-name>
terraform import module.rds.aws_security_group.rds <rds-sg-id>
terraform import module.rds.aws_rds_cluster.main database-topvnsport
terraform import module.rds.aws_rds_cluster_instance.main <cluster-instance-id>
```

Import order matters: parent resources (VPC, subnets, security groups)
before the resources that reference them (instances, clusters).

After each import, run `terraform plan` and resolve any attribute
mismatches by adjusting `terraform.tfvars` or the module code — do not let
`terraform apply` silently modify a resource that was only meant to be
imported.

## Phase 4: Validate and Create the S3 Bucket

```bash
terraform plan
# Expected: only the S3 module resources should show as "to be created" —
# everything else should show "No changes."
```

If imported resources show unexpected diffs, stop and reconcile the module
config with reality before applying. Once the plan only shows the new S3
resources:

```bash
terraform apply
aws s3 ls s3://topvnsport-assets
terraform state list
```

`terraform state list` should now show the VPC, EC2, RDS, and S3 resources.
This satisfies the AC for this task; the remaining phases below cover the
broader migration (tracked as separate tasks in the app repos) for context.

## CI Configuration

For the PR `terraform plan` workflow (`.github/workflows/terraform.yml`) to
plan `environments/prod` successfully, configure these in the repo's
GitHub Actions secrets/variables (same values as Phase 2 discovery):

- Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
  `PROD_RDS_MASTER_PASSWORD`
- Variables: `PROD_VPC_CIDR`, `PROD_PUBLIC_SUBNET_CIDRS` (e.g.
  `["10.0.1.0/24","10.0.2.0/24"]`), `PROD_AVAILABILITY_ZONES` (e.g.
  `["us-east-1a","us-east-1b"]`), `PROD_EC2_AMI_ID`, `PROD_EC2_KEY_NAME`,
  `PROD_RDS_ENGINE_VERSION`

The plan step uses `continue-on-error: true` so a PR is never blocked by
missing credentials, but the plan output won't be meaningful until these
are set.

## Phase 5: App Cutover (tracked in other repos)

Not part of this repo's deliverables — see "Dependencies on Other
Projects" below. Summarized here for sequencing context:

1. Create `pmi`, `oms`, `wms`, `identity` databases on the Aurora cluster.
2. Update each service's `DATABASE_URL` to point at
   `module.rds.cluster_endpoint` (RDS module output).
3. Replace PMI's MinIO client with a `boto3` S3 client using
   `module.s3.bucket_id`.
4. Add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`,
   `RDS_*`, `S3_BUCKET` as GitHub Secrets and wire them into
   `docker-compose.prod.yml` / `deploy_prod.sh`.

## Phase 6: Data Migration

Run during a scheduled maintenance window.

```bash
# On EC2 - dump from containers
docker exec pmi-db pg_dump -U postgres pmi > pmi_backup.sql
docker exec oms-db pg_dump -U postgres oms > oms_backup.sql
docker exec wms-db pg_dump -U postgres wms > wms_backup.sql
docker exec identity-db pg_dump -U postgres identity > identity_backup.sql

# Restore to RDS
export RDSHOST="database-topvnsport.cluster-copm008y8icu.us-east-1.rds.amazonaws.com"
export PGPASSWORD="<rds_password>"
psql -h "$RDSHOST" -U postgres -d pmi < pmi_backup.sql
psql -h "$RDSHOST" -U postgres -d oms < oms_backup.sql
psql -h "$RDSHOST" -U postgres -d wms < wms_backup.sql
psql -h "$RDSHOST" -U postgres -d identity < identity_backup.sql

# Verify row counts match source vs. destination before proceeding.

# Files: MinIO -> S3
mc alias set myminio http://localhost:19005 <minio_access_key> <minio_secret_key>
mc alias set s3 https://s3.amazonaws.com <aws_access_key> <aws_secret_key>
mc mirror myminio/pmi-assets s3/topvnsport-assets/pmi/
```

## Phase 7: Cutover

1. Put apps in maintenance mode.
2. Final data sync (repeat the `pg_dump`/restore and `mc mirror` steps to
   catch anything written since Phase 6).
3. Stop old `db` and `minio` containers.
4. Redeploy apps with the updated env vars (RDS/S3).
5. Validate:
   ```bash
   curl https://pmi.topvnsport.com/api/health
   curl https://oms.topvnsport.com/api/health
   curl https://wms.topvnsport.com/api/health
   ```
   Also manually test file upload/download and a few DB-backed reads/writes
   per service.
6. Remove maintenance mode.

## Rollback Plan

If cutover fails:

1. Put apps back in maintenance mode.
2. `git checkout` the previous `docker-compose.prod.yml` (with `db` and
   `minio` services restored).
3. Restart the `db` and `minio` containers and redeploy apps against them.
4. Restore from the latest container backups taken before Phase 6 if the
   containers' data has since diverged.

Terraform-managed resources (VPC/EC2/RDS/S3) are additive imports and the
new S3 bucket — rolling back the app cutover does not require touching
Terraform state.

## Risk Mitigation

| Risk | Mitigation |
|:-----|:-----------|
| Data loss during migration | Full backup before starting, verify row counts before cutover |
| Connection issues to RDS | Test connectivity from EC2 before cutover |
| S3 permission issues | Test upload/download with the app's IAM credentials before cutover |
| Downtime | Schedule cutover during low-traffic hours, keep the rollback plan ready |
| Import drift | Run `terraform plan` after every import; do not `apply` until it is clean |

## Dependencies on Other Projects

After this task completes, create follow-up tasks in:

| Project | Task |
|:--------|:-----|
| topvnsport-pmi | Update database connection to RDS |
| topvnsport-pmi | Replace MinIO client with S3 (boto3) |
| topvnsport-oms | Update database connection to RDS |
| topvnsport-wms | Update database connection to RDS |
| topvnsport-web | Update env vars if it has direct DB access |
