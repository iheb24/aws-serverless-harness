module "orders_queue" {
  source = "./modules/event_choreography"

  name                       = "order-worker-queue"
  visibility_timeout_seconds = 180

  tags = local.common_tags
}

module "orders_table" {
  source = "./modules/stateful_storage"

  name            = "order-worker-store"
  enable_dynamodb = true

  tags = local.common_tags
}

module "orders_worker_lambda" {
  source = "./modules/serverless_compute"

  name             = "order-worker-lambda"
  filename         = "${path.module}/../dist/order_worker.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/order_worker.zip")
  handler          = "order_worker.entrypoint.handler"
  runtime          = "python3.13"

  environment_variables = {
    ORDERS_TABLE_NAME = module.orders_table.table_name
    ORDER_QUEUE_URL   = module.orders_queue.queue_url
  }

  triggers = {
    sqs = {
      queue_arn = module.orders_queue.queue_arn
    }
  }

  policy_statements = [
    {
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:Query"]
      resources = [module.orders_table.table_arn]
    }
  ]

  tags = local.common_tags
}
