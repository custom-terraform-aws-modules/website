output "id" {
  description = "ID of the S3 bucket."
  value       = try(aws_s3_bucket.main.id, null)
}
