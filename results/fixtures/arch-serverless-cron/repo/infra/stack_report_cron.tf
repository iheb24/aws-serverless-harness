module "heartbeat_store" {
  source = "./modules/stateful_storage"

  name            = "report-cron"
  enable_dynamodb = true

  tags = local.common_tags
}

module "report_executor" {
  source = "./modules/serverless_compute"

  name             = "report-cron-executor"
  filename         = "${path.module}/../dist/report_cron.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/report_cron.zip")
  handler          = "report_cron.entrypoint.handler"
  runtime          = "python3.13"

  triggers = {
    schedule = {
      expression = "rate(1 hour)"
    }
  }

  environment_variables = {
    TABLE_NAME = module.heartbeat_store.table_name
  }

  policy_statements = [
    {
      actions   = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:GetItem"]
      resources = [module.heartbeat_store.table_arn]
    }
  ]

  tags = local.common_tags
}
