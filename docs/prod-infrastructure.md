# TopVNSport Production Infrastructure

## AWS Account
| Key | Value |
|:----|:------|
| Account ID | `402631154151` |
| Region | `us-east-1` |

## EC2 Instance (Current)
| Key | Value |
|:----|:------|
| Instance ID | `i-0ede7353edeef0c63` |
| Instance Type | `t3.medium` |
| Public IP | `52.203.250.214` |
| SSH User | `lupca` |
| SSH Key | `~/.ssh/id_rsa` |
| Name Tag | `topvnsport` |

## RDS Aurora PostgreSQL (Created, not connected yet)
| Key | Value |
|:----|:------|
| Cluster Endpoint | `database-topvnsport.cluster-copm008y8icu.us-east-1.rds.amazonaws.com` |
| Port | `5432` |
| Database | `postgres` |
| Username | `postgres` |
| Auth | IAM Database Authentication |

### RDS Connection Example
```bash
export RDSHOST="database-topvnsport.cluster-copm008y8icu.us-east-1.rds.amazonaws.com"
psql "host=$RDSHOST port=5432 dbname=postgres user=postgres sslmode=require password=$(aws rds generate-db-auth-token --hostname $RDSHOST --port 5432 --username postgres --region us-east-1)"
```

## S3 (To be created)
| Key | Value |
|:----|:------|
| Bucket Name | `topvnsport-assets` (proposed) |
| Region | `us-east-1` |
| Purpose | Replace MinIO for file storage |

## GitHub Secrets (To configure for CI/CD)
```
AWS_ACCESS_KEY_ID=<from IAM user>
AWS_SECRET_ACCESS_KEY=<from IAM user>
AWS_REGION=us-east-1

# EC2 SSH
EC2_HOST=52.203.250.214
EC2_USER=lupca
EC2_SSH_KEY=<private key content>

# RDS
RDS_HOST=database-topvnsport.cluster-copm008y8icu.us-east-1.rds.amazonaws.com
RDS_PORT=5432
RDS_USER=postgres
RDS_PASSWORD=<generate secure password or use IAM auth>

# S3
S3_BUCKET=topvnsport-assets
S3_REGION=us-east-1
```

## Current Services on EC2
| Service | API Port | DB Port (container) | Notes |
|:--------|:---------|:--------------------|:------|
| Gateway (Nginx) | 80 | - | Reverse proxy |
| Identity (SSO) | 18110 | 15436 | Needs migrate to RDS |
| PMI | 18100 | 15433 | Needs migrate to RDS |
| OMS | 18101 | 15434 | Needs migrate to RDS |
| WMS | 18102 | 15435 | Needs migrate to RDS |
| Web | 3000 | - | Next.js storefront |
| MinIO | 19005 | - | → Replace with S3 |

## Migration Plan Summary
1. IaC: Import existing EC2 + RDS into Terraform
2. Create S3 bucket via Terraform
3. Update app configs to use RDS + S3
4. Migrate data: PostgreSQL containers → RDS
5. Migrate files: MinIO → S3
6. Update CI/CD with new env vars
