# step_functions_workflow

Logical capability: one Step Functions state machine with its execution
role, CloudWatch execution logs, and least-privilege Lambda invoke
permissions derived from `task_lambda_arns`.

## Intent & Non-Goals

**Intent.** Orchestrate multi-step backend work (Lambda tasks, waits,
retries, callbacks) with a hardened default: typed workflow switch,
structured execution logging, X-Ray flag, JSON-validated definition.

**Non-goals.** The module never guesses ASL content — the definition comes
from the stack's work order (or a `custom_*.tf` adjacent file).
EventBridge-triggered starts and `.waitForTaskToken` callback targets are
wired in the root `main.tf` per stack.

## Architecture

```mermaid
flowchart LR
    EV[Event source] --> SFN[State machine<br/>STANDARD or EXPRESS]
    SFN --> L1[Lambda task A]
    SFN --> L2[Lambda task B]
    SFN --> LOG[CloudWatch execution logs]
```

## Inputs & Outputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.invoke_lambdas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_sfn_state_machine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_asl_definition"></a> [asl\_definition](#input\_asl\_definition) | Amazon States Language definition; reference task ARNs via task\_lambda\_arns. | `string` | n/a | yes |
| <a name="input_enable_xray"></a> [enable\_xray](#input\_enable\_xray) | Enable X-Ray tracing on executions. | `bool` | `false` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Execution log level: OFF, ERROR, or ALL. | `string` | `"ERROR"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch retention for execution logs. | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | State machine name; prefixes its role and log group. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags merged onto every taggable resource. | `map(string)` | `{}` | no |
| <a name="input_task_lambda_arns"></a> [task\_lambda\_arns](#input\_task\_lambda\_arns) | Map of logical task label to Lambda ARN; grants states InvokeFunction on each. | `map(string)` | `{}` | no |
| <a name="input_workflow_type"></a> [workflow\_type](#input\_workflow\_type) | STANDARD for durable long-running flows; EXPRESS for high-rate short ones. | `string` | `"STANDARD"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | Execution role ARN for extra task permissions outside this module. |
| <a name="output_state_machine_arn"></a> [state\_machine\_arn](#output\_state\_machine\_arn) | State machine ARN. |
| <a name="output_state_machine_name"></a> [state\_machine\_name](#output\_state\_machine\_name) | State machine name. |
<!-- END_TF_DOCS -->

## Known Caveats & Next Steps

- floci emulates the control plane (`ValidateStateMachineDefinition`,
  `StartExecution`); real task execution is covered by unit tests.
- `logging_configuration` requires the role's log policy to exist first
  (handled via depends_on).
