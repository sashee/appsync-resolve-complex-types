provider "aws" {
}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_iam_role" "appsync" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/${random_id.id.hex}-lambda.zip"
  source {
    content  = file("index.mjs")
    filename = "index.mjs"
  }
}

resource "aws_lambda_function" "function" {
  function_name = "function-${random_id.id.hex}"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs16.x"
  role    = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_exec_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}

data "aws_iam_policy_document" "appsync" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [
			aws_lambda_function.function.arn,
    ]
  }
}

resource "aws_iam_role_policy" "appsync" {
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync.json
}

resource "aws_appsync_graphql_api" "appsync" {
  name                = "appsync_test"
  schema              = file("schema.graphql")
  authentication_type = "AWS_IAM"
}

resource "aws_appsync_datasource" "lambda" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "lambda"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AWS_LAMBDA"
	lambda_config {
		function_arn = aws_lambda_function.function.arn
	}
}

# resolvers
resource "aws_appsync_resolver" "Query_allGroups" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "allGroups"
  data_source = aws_appsync_datasource.lambda.name
}

resource "aws_appsync_resolver" "Query_group" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "group"
  data_source = aws_appsync_datasource.lambda.name
}

resource "aws_appsync_resolver" "Query_user" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "user"
  data_source = aws_appsync_datasource.lambda.name
}

