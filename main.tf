################################
# S3 Bucket                    #
################################

resource "random_string" "suffix" {
  length  = 63 - length(var.identifier) - 1
  special = false
  upper   = false
}

locals {
  bucket_name = "${var.identifier}-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

################################
# Route53                      #
################################

locals {
  sub_strings = split(".", var.domain)
  base_domain = "${local.sub_strings[length(local.sub_strings) - 2]}.${local.sub_strings[length(local.sub_strings) - 1]}"
}

# get public zone for base domain (must be already present in account)
data "aws_route53_zone" "main" {
  count        = length(var.zone_id) < 1 ? 1 : 0
  name         = local.base_domain
  private_zone = false
}

# conditionally set the zone_id to avoid duplication of conditions 
locals {
  zone_id = length(var.zone_id) < 1 ? data.aws_route53_zone.main[0].id : "testzone123"
}

# Cloudfront requires the certificate to be issued in the global region (us-east-1)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"
  provider          = aws.virginia
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
  provider        = aws.virginia
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
  provider                = aws.virginia
}

################################
# CloudFront                   #
################################

resource "aws_cloudfront_origin_access_identity" "main" {}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain]
  price_class         = var.price_class

  origin {
    origin_id   = "${local.bucket_name}-origin"
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.bucket_name}-origin"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = var.min_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.main.arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# point domain to CloudFront DNS name
resource "aws_route53_record" "main" {
  name    = var.domain
  type    = "A"
  zone_id = local.zone_id

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# give CloudFront read access to S3 bucket objects
data "aws_iam_policy_document" "main" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.main.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
}
