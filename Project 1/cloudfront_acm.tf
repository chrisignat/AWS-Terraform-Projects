
# ADDITIONAL PROVIDER FOR US-EAST-1 (ACM & CloudFront)

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "myapp.example.com" 
}

# AWS CERTIFICATE MANAGER (ACM)

resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = variable.domain_name
  validation_method = "DNS"

  tags = { Name = "Project-3-CloudFront-Cert" }

  lifecycle { create_before_destroy = true }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cert.arn
}


# AMAZON CLOUDFRONT DISTRIBUTION

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront for Project 3 ALB"
  default_root_object = ""

  origin {
    domain_name = aws_lb.external_alb.dns_name
    origin_id   = "ALB-Origin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-Origin"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Redirect HTTP -> HTTPS
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Name = "Project-3-CloudFront" }
}