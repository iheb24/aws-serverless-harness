mock_provider "aws" {}

variables {
  name = "order-pipeline"
  asl_definition = jsonencode({
    StartAt = "Pass"
    States = {
      Pass = {
        Type = "Pass"
        End  = true
      }
    }
  })
}

run "defaults_are_standard_with_error_logs" {
  command = plan

  assert {
    condition     = aws_sfn_state_machine.this.type == "STANDARD"
    error_message = "workflow type defaults to STANDARD"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 1
    error_message = "execution logs default to ERROR level"
  }

  assert {
    condition     = length(aws_iam_role_policy.invoke_lambdas) == 0
    error_message = "no invoke policy without task arns"
  }
}

run "task_arns_create_scoped_invoke_policy" {
  command = plan

  variables {
    task_lambda_arns = {
      validate = "arn:aws:lambda:eu-west-3:123456789012:function:order-validate"
    }
  }

  assert {
    condition     = length(aws_iam_role_policy.invoke_lambdas) == 1
    error_message = "task arns create the invoke policy"
  }
}

run "invalid_definition_is_rejected" {
  command = plan

  variables {
    asl_definition = "not json"
  }

  expect_failures = [
    var.asl_definition,
  ]
}
