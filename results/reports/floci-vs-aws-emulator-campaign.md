# Floci vs AWS Emulator — comparison campaign

- generated: 2026-11-18
- campaign dir: `benchmarks/differential/run-1`
- evidence: per-run receipts and comparison records under each repo's `.harness/validation-runs/`; coverage from pinned validation manifests + official v1.0.471 fidelity snapshot

## Per-stack paired results

| stack | module | generated | tokens | repairs | floci (rep1/rep2) | aws-emulator (rep1/rep2) | floci total | emulator total | verdict |
| --- | --- | --- | ---: | ---: | --- | --- | --- | --- | --- |
| `arch-api-edge` | api_edge | fixture | 0 | 0 | passed/passed | passed/passed | 118.9s | 84.8s | - |
| `arch-batch` | batch_compute | fixture | 0 | 0 | failed/failed | error/passed | 344.0s | 118.1s | shared / application-defect (candidate) |
| `arch-ecs` | container_service_ecs | fixture | 0 | 0 | failed/failed | passed/passed | 326.1s | 39.0s | floci-gap (candidate) |
| `arch-events` | event_choreography | agent | 15072 | 1 | passed/passed | passed/passed | 243.9s | 191.8s | - |
| `arch-firehose` | firehose_ingestion | fixture | 0 | 0 | failed/failed | failed/failed | 49.1s | 4.6s | shared / application-defect (candidate) |
| `arch-negative-ssm` | stateful_storage | fixture | 0 | 0 | passed/passed | failed/failed | 73.5s | 14.2s | FALSE GREEN floci |
| `arch-serverless-cron` | serverless_compute | agent | 27086 | 2 | passed/passed | passed/passed | 83.8s | 84.8s | - |
| `arch-serverless-sqs` | serverless_compute | agent | 28441 | 1 | passed/passed | passed/passed | 151.4s | 155.7s | - |
| `arch-stepfunctions` | step_functions_workflow | fixture | 0 | 0 | passed/passed | passed/passed | 57.4s | 7.7s | - |
| `arch-storage-dynamo` | stateful_storage | agent | 13476 | 1 | passed/passed | passed/passed | 65.8s | 16.5s | - |
| `arch-storage-full` | stateful_storage | agent | 15726 | 3 | passed/passed | passed/passed | 66.1s | 16.5s | - |

## Divergences and classifications

- `arch-batch` (batch_compute): shared / application-defect (candidate)
- `arch-ecs` (container_service_ecs): floci-gap (candidate)
- `arch-firehose` (firehose_ingestion): shared / application-defect (candidate)

## False-green probe (negative cell)

- `arch-negative-ssm`: FALSE GREEN floci

## Theory check: "aws emulator is good but not mature yet"

- **Speed**: median total 39.0s (emulator) vs 83.6s (floci) — ~2x faster on the emulator.
- **Coverage**: see the coverage table (same manifests, same official v1.0.471 evidence on both sides).
- **Maturity**: every emulator-side-only failure is classified above (documented gap, unsupported operation, or candidate defect); floci-side-only failures count against floci maturity.

## Operation coverage per module (pinned fidelity evidence)

| module | covered-passing | covered-failing | uncovered | known gaps |
| --- | ---: | ---: | ---: | --- |
| api_edge | 18 | 0 | 0 | - |
| batch_compute | 23 | 0 | 0 | batch-job-execution |
| container_service_ecs | 30 | 0 | 0 | ecs-task-execution |
| event_choreography | 21 | 0 | 0 | - |
| firehose_ingestion | 15 | 0 | 0 | - |
| serverless_compute | 28 | 0 | 0 | - |
| stateful_storage | 20 | 0 | 1 | s3-control-host-prefix |
| step_functions_workflow | 15 | 0 | 0 | - |
