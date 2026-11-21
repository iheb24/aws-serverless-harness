mock_provider "aws" {}

variables {
  name          = "orders-api"
  invoke_arn    = "arn:aws:lambda:eu-west-3:123456789012:function:orders-api"
  function_name = "orders-api"
}

run "defaults_create_open_http_api_with_logs" {
  command = plan

  assert {
    condition     = aws_apigatewayv2_api.this.protocol_type == "HTTP"
    error_message = "the edge is an HTTP API (v2)"
  }

  assert {
    condition     = aws_apigatewayv2_route.catch_all.authorization_type == "NONE"
    error_message = "auth defaults to none"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.access) == 1
    error_message = "access logging is on by default"
  }

  assert {
    condition     = length(aws_apigatewayv2_authorizer.jwt) == 0
    error_message = "no authorizer without jwt mode"
  }
}

run "jwt_mode_creates_authorizer" {
  command = plan

  variables {
    auth_mode    = "jwt"
    jwt_issuer   = "https://auth.example.com/"
    jwt_audience = ["orders"]
  }

  assert {
    condition     = length(aws_apigatewayv2_authorizer.jwt) == 1
    error_message = "jwt mode creates the authorizer"
  }

  assert {
    condition     = aws_apigatewayv2_route.catch_all.authorization_type == "JWT"
    error_message = "the catch-all route requires JWT"
  }
}

run "jwt_without_issuer_is_rejected" {
  command = plan

  variables {
    auth_mode = "jwt"
  }

  expect_failures = [
    var.auth_mode,
  ]
}
