# Package the handler. boto3 is in the Lambda runtime, so it isn't zipped.
data "archive_file" "counter" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/lambda"
  output_path = "${path.module}/counter.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "counter" {
  name               = "${var.project}-counter-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "counter" {
  name              = "/aws/lambda/${var.project}-counter"
  retention_in_days = 14
}

# Least privilege: write its own logs, update the one counter item. Nothing else.
data "aws_iam_policy_document" "counter" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.counter.arn}:*"]
  }

  statement {
    sid       = "CounterUpdate"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.visits.arn]
  }
}

resource "aws_iam_role_policy" "counter" {
  name   = "${var.project}-counter-policy"
  role   = aws_iam_role.counter.id
  policy = data.aws_iam_policy_document.counter.json
}

resource "aws_lambda_function" "counter" {
  function_name    = "${var.project}-counter"
  role             = aws_iam_role.counter.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.counter.output_path
  source_code_hash = data.archive_file.counter.output_base64sha256
  timeout          = 5
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.visits.name
      ALLOWED_ORIGIN = local.site_origin
    }
  }

  depends_on = [aws_cloudwatch_log_group.counter]
}
