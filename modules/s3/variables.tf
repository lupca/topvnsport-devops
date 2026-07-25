variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "allowed_origins" {
  description = "Origins allowed to access the bucket via CORS"
  type        = list(string)
  default     = ["https://topvnsport.com", "https://*.topvnsport.com"]
}

variable "tags" {
  description = "Common tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
