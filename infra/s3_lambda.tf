# Buckets S3
resource "aws_s3_bucket" "input_s3" { bucket = "uniplus-video-input" }
resource "aws_s3_bucket" "output_s3" { bucket = "uniplus-video-output" }

# Lambda Function para Processamento
resource "aws_lambda_function" "video_processor" {
  filename      = "lambda_function_payload.zip"
  function_name = "VideoProcessor"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output_s3.id
    }
  }
}

# Gatilho do S3 para a Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.input_s3.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.video_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}