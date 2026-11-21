module "order_archive_storage" {
  source = "./modules/stateful_storage"

  name            = "order-archive"
  enable_dynamodb = true
  dynamodb_partition_key = {
    name = "pk"
    type = "S"
  }
  dynamodb_sort_key = {
    name = "sk"
    type = "S"
  }
  enable_s3_bucket = false

  ssm_parameters = {
    "/order-archive/config" = {
      value       = "placeholder"
      description = "Order archive configuration"
    }
  }

  tags = local.common_tags
}
