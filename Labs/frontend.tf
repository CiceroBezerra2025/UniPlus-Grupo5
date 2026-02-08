# 1. Configuração do Origin Access Control (OAC) - Recomendado pela AWS
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "oac-uniplus-portals"
  description                       = "OAC para os buckets S3 dos portais"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. Definição dos Portais (Lista para evitar repetição de código)
locals {
  portals = {
    "aluno"      = "uniplus-portal-aluno-spa"
    "professor"  = "uniplus-portal-professor"
    "matricula"  = "uniplus-sistema-matricula"
  }
}

# 3. Criação dos Buckets S3 para cada portal
resource "aws_s3_bucket" "portal_buckets" {
  for_each = local.portals
  bucket   = each.value
  force_destroy = true
}

# Configuração de Site Estático para os Buckets
resource "aws_s3_bucket_website_configuration" "web_config" {
  for_each = aws_s3_bucket.portal_buckets
  bucket   = each.value.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" } # Importante para SPAs (React/Vue)
}

# 4. Distribuições CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  for_each = local.portals

  enabled             = true
  web_acl_id = aws_wafv2_web_acl.main.arn
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.portal_buckets[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3-${each.value}"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${each.value}"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Integração com WAF (Opcional - Requer ID do WAF WebACL)
  # web_acl_id = aws_wafv2_web_acl.main.arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "Prod"
    Portal      = each.key
  }
}

# 5. Políticas de Bucket (Permite que apenas o CloudFront leia os arquivos)
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  for_each = local.portals
  bucket   = aws_s3_bucket.portal_buckets[each.key].id
  policy   = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portal_buckets[each.key].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution[each.key].arn
          }
        }
      }
    ]
  })
}