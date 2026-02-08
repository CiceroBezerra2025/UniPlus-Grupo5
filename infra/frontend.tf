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
  for_each      = local.portals
  bucket        = each.value
  force_destroy = true
}

# 3. Configuração de Site Estático
resource "aws_s3_bucket_website_configuration" "web_config" {
  for_each = aws_s3_bucket.portal_buckets
  bucket   = each.value.id

  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# 4. Liberar Acesso Público (Necessário para sites em Labs)
resource "aws_s3_bucket_public_access_block" "public_allow" {
  for_each = aws_s3_bucket.portal_buckets
  bucket   = each.value.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 5. Política de Leitura Pública
resource "aws_s3_bucket_policy" "allow_public_read" {
  for_each   = aws_s3_bucket.portal_buckets
  bucket     = each.value.id
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