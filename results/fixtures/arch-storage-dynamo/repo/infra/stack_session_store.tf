module "session_store" {
  source = "./modules/stateful_storage"

  name             = "session-store"
  enable_dynamodb  = true
  enable_s3_bucket = false

  ssm_parameters = {
    "/session-store/config" = {
      value       = "placeholder"
      description = "Session store configuration parameter"
    }
  }

  tags = local.common_tags
}
