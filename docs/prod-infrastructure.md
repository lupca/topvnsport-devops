# TopVNSport Production Infrastructure

## AWS Account
| Key | Value |
|:----|:------|
| Account ID | `402631154151` |
| Region | `us-east-1` |

## EC2 Instance
| Key | Value |
|:----|:------|
| Instance ID | `i-0ede7353edeef0c63` |
| Instance Type | `t3.medium` |
| Public IP | `52.203.250.214` |
| SSH User | `lupca` |
| SSH Key | `~/.ssh/id_rsa` |
| Name Tag | `topvnsport` |

## RDS Aurora PostgreSQL — CONNECTED (2026-07-25)
| Key | Value |
|:----|:------|
| Cluster Identifier | `topvnsport-db` |
| Cluster Endpoint | `topvnsport-db.cluster-copm008y8icu.us-east-1.rds.amazonaws.com` |
| Port | `5432` |
| Databases | `pmi`, `oms`, `wms`, `identity` |
| Username | `postgres` |
| Auth | **Password auth** (no IAM) |
| Engine | Aurora PostgreSQL 17.4 Serverless v2 |
| Status | **Data migrated, verified** |

> **Old cluster** `database-topvnsport` (with IAM auth) is deprecated — delete after confirming apps work with new cluster.

### Databases Migrated
| Database | Records | Migrated |
|:---------|:--------|:---------|
| pmi | 65 products | ✅ 2026-07-25 |
| oms | 3 orders | ✅ 2026-07-25 |
| wms | inventory | ✅ 2026-07-25 |
| identity | users | ✅ 2026-07-25 |

### RDS Connection Example
```bash
export RDSHOST="topvnsport-db.cluster-copm008y8icu.us-east-1.rds.amazonaws.com"
export PGPASSWORD="<from GitHub Secrets or .env>"
psql "host=$RDSHOST port=5432 dbname=oms user=postgres sslmode=require"
```

## S3 — CREATED + DATA MIGRATED (2026-07-25)
| Key | Value |
|:----|:------|
| Bucket Name | `topvnsport-assets` |
| Region | `us-east-1` |
| Purpose | Replace MinIO for file storage |
| Objects | 3898 files |
| Size | 433 MiB |
| Status | **Data migrated from MinIO** |

### S3 Structure
```
s3://topvnsport-assets/
└── pim-media/          # Product images (3898 files, migrated from MinIO)
```

## GitHub Secrets (Required for CI/CD)
```
AWS_ACCESS_KEY_ID=<from IAM user>
AWS_SECRET_ACCESS_KEY=<from IAM user>
AWS_REGION=us-east-1

# EC2 SSH
EC2_HOST=52.203.250.214
EC2_USER=lupca
DEPLOY_SSH_KEY=<private key content>

# RDS (use IAM auth, no static password)
RDS_HOST=database-topvnsport.cluster-copm008y8icu.us-east-1.rds.amazonaws.com
RDS_PORT=5432
RDS_USER=postgres

# S3
S3_BUCKET=topvnsport-assets
S3_REGION=us-east-1
```

## Current Services on EC2
| Service | API Port | DB | Storage | Notes |
|:--------|:---------|:---|:--------|:------|
| Gateway (Nginx) | 80 | - | - | Reverse proxy |
| Identity (SSO) | 18110 | **RDS** | - | ✅ Migrated |
| PMI | 18100 | **RDS** | **S3** | ✅ Migrated |
| OMS | 18101 | **RDS** | - | ✅ Migrated |
| WMS | 18102 | **RDS** | - | ✅ Migrated |
| Web | 3000 | - | - | Next.js storefront |
| MinIO | 19005 | - | - | **DEPRECATED** → S3 |

## Migration Status
| Phase | Status | Date |
|:------|:-------|:-----|
| RDS databases created | ✅ Done | 2026-07-25 |
| PostgreSQL data migrated | ✅ Done | 2026-07-25 |
| S3 bucket created | ✅ Done | 2026-07-25 |
| MinIO data migrated | ✅ Done | 2026-07-25 |
| Apps redeployed with RDS config | ⏳ Pending | - |
| Image URLs updated in DB | ⏳ Pending | - |
| Terraform import existing resources | ⏳ Pending | - |

## Pending Actions
1. **Redeploy apps** with RDS/S3 config on EC2
2. **Update image URLs** in `product_media.image_url` from MinIO to S3
3. **Terraform import** EC2, VPC, RDS into state
4. **Stop MinIO** container after cutover verified

See [[docs/migration-runbook.md]] for step-by-step execution instructions.
