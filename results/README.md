# Evidence bundle: Floci vs AWS Emulator campaign

Every number in the v0.3.0 release notes and in the accompanying article
traces back to the files in this directory. Nothing here is harness source
code: this is measured evidence (reports, receipts, fixtures) plus one
materialized repository you can re-verify yourself with the published
binary.

## Layout

| Path | What it is |
| --- | --- |
| `reports/` | The two rendered campaign reports. **Start here.** `floci-vs-aws-emulator-campaign.md` is the first campaign (2 repetitions per backend), `floci-vs-aws-emulator-r2-certification.md` is the certification campaign (5 paired repetitions per backend). |
| `campaigns/run-1/`, `campaigns/run-2/` | Raw per-stack evidence: `generation.json` (provenance, token usage), `status.json`, `verify-repN.json` (per-repetition gate results), and `validation-runs/` (the versioned receipts written during the runs). |
| `campaign.yaml` | The campaign matrix: the 11 stacks, their modules, their fixture definitions, the model used for generation. |
| `fixtures/` | The frozen, reviewed agent-generated stacks (HCL + backend package + tests + the verbatim `state.yaml` stack record) used as deterministic replay inputs. |
| `repro/arch-serverless-sqs/` | One complete materialized campaign repository (SQS → Lambda → DynamoDB), including its `.harness/state.yaml` and the receipts its runs produced. Use this for the one-command reproduction below. |
| `capabilities/` | A captured `harness capabilities` output for the repro repository: the execution-free coverage report that classifies each required AWS operation against the pinned official fidelity evidence (the source of the "170 covered-passing operations" figure across the 8 catalog modules). |

## How to read a receipt

Receipts live under `campaigns/<run>/<stack>/validation-runs/<run-id>/receipt.json`
and follow gate report schema v2:

- `backend` / `backend_version` — `aws-emulator 1.0.492` or `floci 2.5.0` in
  this campaign; coverage evidence is pinned to the official AWS Emulator
  `v1.0.471` fidelity release.
- `status` — `passed` / `failed` for the whole run.
- `coverage` — required AWS operations classified as `covered_passing`,
  `covered_failing`, `uncovered`, `unsupported`. Uncovered and unsupported
  never count as passing.
- `timing_ms` — per-tool and total wall time (the source of the speed
  figures).
- `cleanup` — teardown result; cleanup failures are first-class failures.
- `failures` — each with a `failure_class`; only `APPLICATION_FAILURE`
  reaches the repair agent.

The interesting cells: `arch-negative-ssm` (floci passed an invalid SSM
parameter name 5/5 — the false green; the emulator rejected it 5/5 with the
same `ValidationException` real AWS produces), `arch-ecs` / `arch-batch`
(floci failed on its own registry path; the emulator passed), and
`arch-firehose` (both backends fail on the documented S3 Control host-prefix
boundary).

## Reproduce

1. **Coverage report, no emulator needed** (seconds):

   ```bash
   harness capabilities results/repro/arch-serverless-sqs
   ```

   Compare with `capabilities/capabilities.txt` (same content, modulo the
   repository path).

2. **Full validation** (needs the AWS Emulator: native on Linux, container
   via podman/docker on macOS — see `docs/aws-emulator-from-scratch.md`):

   ```bash
   harness verify results/repro/arch-serverless-sqs
   ```

   A fresh receipt appears under
   `results/repro/arch-serverless-sqs/.harness/validation-runs/` and can be
   diffed against the committed ones.

3. **Replay a fixture cell**: run `harness init` to scaffold a fresh
   repository, copy the chosen `fixtures/<id>/repo/` overlay into it, append
   the fixture's `stack` record to `.harness/state.yaml`, then
   `harness verify`.

## Trust notes

- Local paths inside receipts were replaced with placeholders
  (`<harness-repo>`, `~`); nothing else was modified after capture.
- Emulator credentials visible anywhere in this bundle are per-run keys that
  stopped existing when their run stopped.
- Validation is control-plane verification plus owned workflow assertions.
  Documented boundaries (S3 Control tagging, ECR push, Lambda/Batch/ECS
  execution semantics, no IAM security evaluation) are listed in the reports
  and in each module's known gaps. Stacks touching those boundaries certify
  on real AWS.
