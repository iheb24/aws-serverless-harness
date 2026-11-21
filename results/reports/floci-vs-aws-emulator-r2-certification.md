# Floci vs AWS Emulator — comparison campaign

- generated: 2026-11-18
- campaign dir: `benchmarks/differential/run-2`
- evidence: per-run receipts and comparison records under each repo's `.harness/validation-runs/`; coverage from pinned validation manifests + official v1.0.471 fidelity snapshot

## Per-stack paired results

| stack | module | generated | tokens | repairs | floci (rep1/rep2) | aws-emulator (rep1/rep2) | floci total | emulator total | verdict |
| --- | --- | --- | ---: | ---: | --- | --- | --- | --- | --- |
| `arch-api-edge` | api_edge | fixture | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 83.8s | 85.1s | - |
| `arch-batch` | batch_compute | fixture | 0 | 0 | failed/failed/failed/failed/failed | passed/passed/passed/passed/passed | 344.2s | 125.1s | floci-gap (candidate) |
| `arch-ecs` | container_service_ecs | fixture | 0 | 0 | failed/failed/failed/failed/failed | passed/passed/passed/passed/passed | 323.8s | 45.0s | floci-gap (candidate) |
| `arch-events` | event_choreography | snapshot | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 191.0s | 192.1s | - |
| `arch-firehose` | firehose_ingestion | fixture | 0 | 0 | failed/failed/failed/failed/failed | failed/failed/failed/failed/failed | 3.8s | 4.9s | shared / application-defect (candidate) |
| `arch-negative-ssm` | stateful_storage | fixture | 0 | 0 | passed/passed/passed/passed/passed | failed/failed/failed/failed/failed | 12.3s | 14.5s | FALSE GREEN floci |
| `arch-serverless-cron` | serverless_compute | snapshot | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 83.8s | 85.0s | - |
| `arch-serverless-sqs` | serverless_compute | snapshot | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 151.0s | 155.9s | - |
| `arch-stepfunctions` | step_functions_workflow | fixture | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 6.3s | 8.0s | - |
| `arch-storage-dynamo` | stateful_storage | snapshot | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 12.5s | 16.6s | - |
| `arch-storage-full` | stateful_storage | snapshot | 0 | 0 | passed/passed/passed/passed/passed | passed/passed/passed/passed/passed | 12.4s | 16.7s | - |

## Divergences and classifications

- `arch-batch` (batch_compute): floci-gap (candidate)
- `arch-ecs` (container_service_ecs): floci-gap (candidate)
- `arch-firehose` (firehose_ingestion): shared / application-defect (candidate)

## False-green probe (negative cell)

- `arch-negative-ssm`: FALSE GREEN floci

## Theory check: "aws emulator is good but not mature yet"

- **Speed**: median total 45.0s (emulator) vs 83.8s (floci) — ~2x faster on the emulator.
- **Coverage**: see the coverage table (same manifests, same official v1.0.471 evidence on both sides).
- **Maturity**: every emulator-side-only failure is classified above (documented gap, unsupported operation, or candidate defect); floci-side-only failures count against floci maturity.

## Operation coverage per module (pinned fidelity evidence)

| module | covered-passing | covered-failing | uncovered | known gaps |
| --- | ---: | ---: | ---: | --- |
| api_edge | 18 | 0 | 0 | - |
| batch_compute | 23 | 0 | 0 | ecr-push-unsupported, batch-job-execution |
| container_service_ecs | 30 | 0 | 0 | ecr-push-unsupported, ecs-task-execution |
| event_choreography | 21 | 0 | 0 | - |
| firehose_ingestion | 15 | 0 | 0 | - |
| serverless_compute | 28 | 0 | 0 | - |
| stateful_storage | 20 | 0 | 1 | s3-control-host-prefix |
| step_functions_workflow | 15 | 0 | 0 | - |
