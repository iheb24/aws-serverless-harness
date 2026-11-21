# stateful_storage

Logical capability: serverless persistence for a stack — a DynamoDB table
with point-in-time recovery, an optionally-provisioned hardened S3 bucket,
and SSM parameter placeholders that workloads resolve at runtime.

## Intent & Non-Goals

**Intent.** Make the secure posture the default: PITR on, encryption at
rest on, public access blocked, versioning on, incomplete multipart uploads
aborted. Key schema stays explicit (`pk`/`sk` overridable).

**Non-goals.** GSIs and autoscaling policies are stack-specific and are
added per work order, not guessed here. SSM parameters are placeholders:
Terraform never stores real secret values; workloads write and read them at
runtime (values are `ignore_changes`d).

## Architecture

```mermaid
flowchart TD
    APP[Workload] -->|GetItem/PutItem| DDB[(DynamoDB table<br/>PITR + encrypted)]
    APP -->|GetObject/PutObject| S3[(S3 bucket<br/>versioned + blocked public)]
    APP -->|GetParameter| SSM[SSM parameters<br/>placeholder values]
    DDB -->|optional| STR[DynamoDB stream]
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
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_parameter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | Deletion protection for the table; enable for staging and prod. | `bool` | `false` | no |
| <a name="input_dynamodb_partition_key"></a> [dynamodb\_partition\_key](#input\_dynamodb\_partition\_key) | Partition key attribute; type is one of S, N, B. | <pre>object({<br/>    name = string<br/>    type = string<br/>  })</pre> | <pre>{<br/>  "name": "pk",<br/>  "type": "S"<br/>}</pre> | no |
| <a name="input_dynamodb_sort_key"></a> [dynamodb\_sort\_key](#input\_dynamodb\_sort\_key) | Sort key attribute; type is one of S, N, B. | <pre>object({<br/>    name = string<br/>    type = string<br/>  })</pre> | <pre>{<br/>  "name": "sk",<br/>  "type": "S"<br/>}</pre> | no |
| <a name="input_enable_dynamodb"></a> [enable\_dynamodb](#input\_enable\_dynamodb) | Provision the DynamoDB table. | `bool` | `true` | no |
| <a name="input_enable_s3_bucket"></a> [enable\_s3\_bucket](#input\_enable\_s3\_bucket) | Provision the hardened S3 bucket. | `bool` | `false` | no |
| <a name="input_enable_streams"></a> [enable\_streams](#input\_enable\_streams) | Enable DynamoDB streams (NEW\_AND\_OLD\_IMAGES) for CDC consumers. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name for the table, bucket, and parameter namespace. | `string` | n/a | yes |
| <a name="input_pitr_enabled"></a> [pitr\_enabled](#input\_pitr\_enabled) | Point-in-time recovery for the table; disabling is a prod blocker. | `bool` | `true` | no |
| <a name="input_s3_force_destroy"></a> [s3\_force\_destroy](#input\_s3\_force\_destroy) | Allow Terraform to delete a non-empty bucket; dev convenience only. | `bool` | `false` | no |
| <a name="input_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#input\_s3\_kms\_key\_arn) | Customer-managed CMK for bucket encryption; AES256 when null. | `string` | `null` | no |
| <a name="input_ssm_parameters"></a> [ssm\_parameters](#input\_ssm\_parameters) | SSM parameters created as placeholders; workloads overwrite values at runtime. | <pre>map(object({<br/>    value       = string<br/>    description = string<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags merged onto every taggable resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | S3 bucket ARN; null when enable\_s3\_bucket is false. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | S3 bucket name; null when enable\_s3\_bucket is false. |
| <a name="output_ssm_parameter_names"></a> [ssm\_parameter\_names](#output\_ssm\_parameter\_names) | Map of requested SSM path to created parameter name. |
| <a name="output_table_arn"></a> [table\_arn](#output\_table\_arn) | DynamoDB table ARN; null when enable\_dynamodb is false. |
| <a name="output_table_name"></a> [table\_name](#output\_table\_name) | DynamoDB table name; null when enable\_dynamodb is false. |
| <a name="output_table_stream_arn"></a> [table\_stream\_arn](#output\_table\_stream\_arn) | DynamoDB stream ARN; null unless streams are enabled. |
<!-- END_TF_DOCS -->

## Known Caveats & Next Steps

- `deletion_protection_enabled` defaults to false for dev ergonomics; turn
  it on for staging and prod tfvars.
- Bucket access logging and cross-region replication are not wired yet; add
  them when a stack handles regulated data.
- GSIs must be declared explicitly per stack; the module rejects implicit
  key guessing on purpose.
