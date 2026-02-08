# 1. Definição dos Portais
locals {
  portals = {
    "aluno"     = "uniplus-portal-aluno-spa"
    "professor" = "uniplus-portal-professor"
    "matricula" = "uniplus-sistema-matricula"
  }
}

# 2. Criação dos Buckets S3
resource "aws_s3_bucket" "portal_buckets" {
  for_each = local.portals
  bucket   = each.value
  force_destroy = true
}

# 3. Configuração de Site Estático (O CloudFront usará isso como origem)
resource "aws_s3_bucket_website_configuration" "web_config" {
  for_each = aws_s3_bucket.portal_buckets
  bucket   = each.value.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" }
}

# 4. Desativar bloqueio de acesso público (Necessário para o lab aceitar a política)
resource "aws_s3_bucket_public_access_block" "public_allow" {
  for_each = aws_s3_bucket.portal_buckets
  bucket   = each.value.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 5. Política de Bucket Aberta para Leitura (Padrão para sites estáticos em Labs)
resource "aws_s3_bucket_policy" "allow_public_read" {
  for_each = aws_s3_bucket.portal_buckets
  bucket   = each.value.id
  depends_on = [aws_s3_bucket_public_access_block.public_allow]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portal_buckets[each.key].arn}/*"
      }
    ]
  })
}

# 6. Distribuições CloudFront (Apontando para o Site Estático)
resource "aws_cloudfront_distribution" "s3_distribution" {
  for_each = local.portals

  enabled             = true
  web_acl_id          = aws_wafv2_web_acl.main.arn
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    # Usamos o endpoint de website (HTTP) em vez do domínio regional (S3 API)
    domain_name = aws_s3_bucket_website_configuration.web_config[each.key].website_endpoint
    origin_id   = "S3-${each.value}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}