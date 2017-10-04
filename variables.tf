variable "max_retries" {
  default     = "100"
  description = "Max retries for AWS requests."
}

variable "aws_region" {
  default     = "us-west-2"
  description = "AWS region to deploy the lambda function to."
}

variable "lamba_schedue" {
  default     = "60 minutes"
  description = "Schedule interval for the lambda function."
}

variable "lambda_source_dir" {
  default     = "../lambda"
  description = "Lambda source files"
}

variable "lambda_prepared_source_dir" {
  default     = "../lambda"
  description = "Working directory to build the lambda source files"
}

variable "lambda_archive_path" {
  default     = "../dist/aws_maintenance_lambda.zip"
  description = "Path to the final lambda zip artifact"
}

variable "config_json" {
  default     = "../lambda/config.json"
  description = "Path to the configuration file used by the lambda"
}

variable "force_lambda_update" {
  default     = ""
  description = "Variable to trigger forced update of lambda source"
}
