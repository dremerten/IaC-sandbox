resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.this.id
  key    = var.object_key
  source = var.object_source
  etag   = filemd5(var.object_source)
}
