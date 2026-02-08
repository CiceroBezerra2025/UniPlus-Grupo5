locals {
  # Mapeamento de extensões para o navegador entender o que é cada arquivo
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "svg"  = "image/svg+xml"
  }
}

# Upload para o Portal Aluno
resource "aws_s3_object" "arquivos_aluno" {
  for_each = fileset("../app/aluno/", "**/*")

  bucket       = aws_s3_bucket.portal_buckets["aluno"].id
  key          = each.value
  source       = "../app/aluno/${each.value}"
  # Define o tipo do arquivo baseado na extensão, padrão é text/plain
  content_type = lookup(local.mime_types, element(split(".", each.value), length(split(".", each.value)) - 1), "text/plain")
  # Garante que o upload ocorra apenas após o bucket estar pronto
  depends_on   = [aws_s3_bucket.portal_buckets]
}

# Upload para o Portal Professor
resource "aws_s3_object" "arquivos_professor" {
  for_each = fileset("../app/professor/", "**/*")

  bucket       = aws_s3_bucket.portal_buckets["professor"].id
  key          = each.value
  source       = "../app/professor/${each.value}"
  content_type = lookup(local.mime_types, element(split(".", each.value), length(split(".", each.value)) - 1), "text/plain")
  depends_on   = [aws_s3_bucket.portal_buckets]
}

# Upload para o Sistema de Matrícula
resource "aws_s3_object" "arquivos_matricula" {
  for_each = fileset("../app/matricula/", "**/*")

  bucket       = aws_s3_bucket.portal_buckets["matricula"].id
  key          = each.value
  source       = "../app/matricula/${each.value}"
  content_type = lookup(local.mime_types, element(split(".", each.value), length(split(".", each.value)) - 1), "text/plain")
  depends_on   = [aws_s3_bucket.portal_buckets]
}