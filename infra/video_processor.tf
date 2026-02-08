resource "aws_s3_bucket" "video_in"  { bucket = "uniplus-video-input-g5" }
resource "aws_s3_bucket" "video_out" { bucket = "uniplus-video-output-g5" }

resource "aws_lambda_function" "processor" {
  function_name = "uniplus-video-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda_function.zip" # Requer arquivo zip local
}

resource "aws_lambda_permission" "s3_trigger" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.video_in.arn
}

resource "aws_s3_bucket_notification" "notify" {
  bucket = aws_s3_bucket.video_in.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}