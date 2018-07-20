provider "aws" {
  region      = "${var.aws_region}"
  max_retries = "${var.max_retries}"
}

terraform {
  required_version = ">= 0.8.0"
}

resource "null_resource" "aws_maintenance_lambda" {
  triggers = {
    package_json        = "${base64sha256(file("${var.lambda_source_dir}/package.json"))}"
    force_lambda_update = "${var.force_lambda_update}"
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/setup.sh ${var.lambda_source_dir} ${var.lambda_prepared_source_dir} ${var.config_json}"
  }
}

data "archive_file" "aws_maintenance_lambda" {
  type        = "zip"
  source_dir  = "${var.lambda_prepared_source_dir}/package"
  output_path = "${var.lambda_archive_path}"

  depends_on = ["null_resource.aws_maintenance_lambda"]
}

resource "aws_iam_role" "aws_maintenance_lambda" {
  name               = "aws_maintenance_lambda_role"
  assume_role_policy = "${file("${path.module}/templates/role.json")}"
}

resource "aws_iam_role_policy" "aws_maintenance_lambda" {
  name   = "aws_maintenance_lambda_role_policy"
  role   = "${aws_iam_role.aws_maintenance_lambda.id}"
  policy = "${file("${path.module}/templates/policy.json")}"
}

resource "aws_lambda_function" "aws_maintenance_lambda" {
  filename         = "${data.archive_file.aws_maintenance_lambda.output_path}"
  source_code_hash = "${data.archive_file.aws_maintenance_lambda.output_base64sha256}"
  function_name    = "aws_maintenance_lambda"
  description      = "Lambda function to send notifications on AWS Maintenance Events"
  role             = "${aws_iam_role.aws_maintenance_lambda.arn}"
  handler          = "aws_maintenance_lambda.handler"
  runtime          = "nodejs4.3"
  timeout          = 10
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "lambda_schedule_aws_maintenance_lambda"
  description         = "Lambda Schedule"
  schedule_expression = "rate(${var.lamba_schedue})"
}

resource "aws_cloudwatch_event_target" "aws_maintenance_lambda_schedule" {
  rule      = "${aws_cloudwatch_event_rule.lambda_schedule.name}"
  target_id = "aws_maintenance_lambda"
  arn       = "${aws_lambda_function.aws_maintenance_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_aws_maintenance_lambda" {
  statement_id  = "allow_cloudwatch_to_call_aws_maintenance_lambda"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.aws_maintenance_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.lambda_schedule.arn}"
}
