# `aws-serverless-harness` — Quickstart & IDE MCP Setup Guide

**`aws-serverless-harness`** is a deterministic AWS serverless & container repository composer (Python 3.13 + Terraform 1.15 + GitHub Actions). It exposes a standalone native binary (`harness`) that works both as a **CLI** and as a **Model Context Protocol (MCP) server** (`harness mcp`) for AI IDEs (**Google Antigravity**, **Claude Code / Desktop**, **Cursor**, **Windsurf**).

Instead of letting an AI agent invent raw Terraform or IAM policies from scratch, your IDE calls `harness` to materialize certified Terraform modules, scaffold typed Python packages, and run a **26-tool, 5-gate verification ladder** inside an isolated Git worktree before merging a single file into your branch.

---

## 1. System Requirements

The `harness` binary is self-contained (no Python setup or `pip install` needed to run the binary itself). Because it composes and validates real AWS Python + Terraform repositories on your machine, install the following tools on your `PATH`:

### Required (Core Composition & Python/Unit Gates)
- **`git`** (`>= 2.38`) — Used for gitflow initialization and transactional Git worktree sandboxes.
- **`uv`** (`>= 0.5`) — Manages the generated repository's Python 3.13 virtual environment (`ruff`, `mypy`, `pytest`).
- **`terraform`** (`>= 1.10`) — Validates and formats generated infrastructure modules.
- **An LLM API Key** (or local Ollama) — One of:
  - Google AI Studio (`GEMINI_API_KEY` — **Recommended**: `gemini:gemini-3-flash-preview`, ~$0.01 per stack)
  - OpenAI (`OPENAI_API_KEY`)
  - Moonshot / Kimi (`KIMI_API_KEY`)
  - OpenRouter (`OPENROUTER_API_KEY`) or DeepSeek (`DEEPSEEK_API_KEY`)
  - Local Ollama (`ollama:<model>`, no API key required)

### Recommended (Static Security & Local AWS Emulation Gates)
*(Note: If any of the optional static tools below are not installed, `harness verify` automatically marks that tool as `SKIPPED` rather than failing.)*
- **`ls-lint`**, **`tflint`**, **`trivy`**, **`gitleaks`**, **`hadolint`** — Static structure, HCL, security, secret, and Dockerfile linters.
- **`podman`** (or **`docker`**) — Runs the local `floci` (`:4566`) AWS emulator for live `terraform apply`, ECR container builds, and integration tests without an AWS account.

#### One-Line Prerequisite Install (macOS Homebrew)
```bash
brew install git uv terraform tflint trivy gitleaks hadolint ls-lint podman
```

---

## 2. Download & Install the Binary

Download the standalone binary for your OS/architecture from [GitHub Releases](https://github.com/iheb24/aws-serverless-harness/releases/latest) and place it on your `PATH`:

### macOS (Apple Silicon — `arm64`)
```bash
mkdir -p ~/.local/bin
curl -fsSL https://github.com/iheb24/aws-serverless-harness/releases/latest/download/harness-darwin-arm64 \
  -o ~/.local/bin/harness
chmod +x ~/.local/bin/harness

# Remove macOS Gatekeeper quarantine attribute (if downloaded via browser/curl)
xattr -d com.apple.quarantine ~/.local/bin/harness 2>/dev/null || true

# Verify installation
~/.local/bin/harness version
```

### Linux (`x86_64`)
```bash
mkdir -p ~/.local/bin
curl -fsSL https://github.com/iheb24/aws-serverless-harness/releases/latest/download/harness-linux-x86_64 \
  -o ~/.local/bin/harness
chmod +x ~/.local/bin/harness
~/.local/bin/harness version
```

---

## 3. Connect the MCP Server to Your IDE

Add the following JSON block to your IDE's MCP configuration file and replace `YOUR_GEMINI_API_KEY` with your own key (and `/Users/YOUR_USERNAME` with your home folder path):

| IDE | MCP Config File Path |
| :--- | :--- |
| **Google Antigravity** | `~/.gemini/config/mcp_config.json` |
| **Cursor** | `~/.cursor/mcp.json` (or `.cursor/mcp.json` in workspace) |
| **Claude Code (CLI)** | `~/.claude.json` (or `.mcp.json` in workspace) |
| **Claude Desktop (macOS)** | `~/Library/Application Support/Claude/claude_desktop_config.json` |

### `mcp_config.json`
```json
{
  "mcpServers": {
    "aws-serverless-harness": {
      "command": "/Users/YOUR_USERNAME/.local/bin/harness",
      "args": ["mcp"],
      "env": {
        "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY",
        "HARNESS_DEFAULT_MODEL": "gemini:gemini-3-flash-preview"
      }
    }
  }
}
```

> **Using Another Provider or Multi-Key Fallback?**
> You can swap `GEMINI_API_KEY` for `OPENAI_API_KEY`, `KIMI_API_KEY`, `OPENROUTER_API_KEY`, or `DEEPSEEK_API_KEY`, and set `HARNESS_DEFAULT_MODEL` to `<provider>:<model>` (e.g., `openai:gpt-4.1`, `kimi:k3`, or `ollama:qwen3.8:27b`).

After saving the file, **refresh or restart your IDE's MCP panel**. You will see **`aws-serverless-harness`** online with **8 tools**:
- `harness_init`
- `harness_stack_list`
- `harness_stack_add`
- `harness_stack_edit`
- `harness_stack_remove`
- `harness_verify`
- `harness_docs_sync`
- `harness_upgrade`

---

## 4. Tutorial: Build & Evolve an AWS Serverless Platform from Your IDE Chat

Once the MCP server is connected, open your IDE chat and run the following workflows using natural language.

### Step 1: Initialize a New Golden Repository (Zero Tokens, ~5 Seconds)
**Prompt in IDE Chat:**
> *"Use `harness_init` to create a new AWS serverless repository at `/tmp/orders-platform` named `orders-platform` in region `eu-west-3`."*

**What happens:**
- Renders 213 baseline files: gitflow branches (`main` + `develop`), 8 certified Terraform modules (`infra/modules/`), `.pre-commit-config.yaml`, GitHub Actions CI, and `.harness/state.yaml`.

---

### Step 2: Add Your First Stack (With or Without an Architecture Diagram)
**Prompt in IDE Chat:**
> *"Use `harness_stack_add` on `/tmp/orders-platform` with the prompt: 'HTTP API Gateway fronting a FastAPI Python 3.13 Lambda (order_api) with POST /orders and GET /orders/{id} routes persisted in a DynamoDB table'. Optionally attach `/path/to/diagram.jpg`."*

**What happens inside the harness:**
1. **Scoping Agent** converts your prompt (and optional `.png`/`.jpg`/`.pdf` diagram) into a typed `WorkOrder`.
2. **Parallel Code Generation** writes `infra/stack_order_management.tf` and `backend/order_api/` inside an isolated Git worktree.
3. **5-Gate Acceptance Ladder** runs `ls-lint`, `ruff`, `mypy --strict`, `terraform validate`, `tflint`, `trivy`, `gitleaks`, `pytest` (`moto` unit tests), and `terraform apply` against local `floci` (`:4566`) + live integration tests.
4. **Transactional Merge**: Merges into `develop`, updates `README.md` tables, and records exact token telemetry in `.harness/state.yaml`.

---

### Step 3: Add a Second Coexisting Stack (e.g. Nightly AWS Batch Container Job)
**Prompt in IDE Chat:**
> *"Use `harness_stack_add` on `/tmp/orders-platform` with the prompt: 'Nightly AWS Batch job archiving processed orders from DynamoDB to S3 with a container image'."*

**What happens:**
- Creates a dedicated `infra/stack_order_archival.tf` and a multi-stage `uv` `backend/order_archiver/Dockerfile` (non-root UID `10001`), builds and smoke-tests the container image via Podman, and coexists cleanly alongside your existing FastAPI stack without touching its files.

---

### Step 4: Day-2 Evolution, Verification & Upgrades
- **Update an existing stack**:
  > *"Use `harness_stack_edit` on `/tmp/orders-platform` for stack `order-management` with prompt: 'Publish newly created orders to an SNS topic'."*
- **Run static or full verification (0 tokens)**:
  > *"Use `harness_verify` on `/tmp/orders-platform` with gates `["structure", "python", "unit"]`."*
- **Decommission or purge a stack**:
  > *"Use `harness_stack_remove` on `/tmp/orders-platform` for stack `order-archival` with `purge: true`."*

---

## 5. Troubleshooting

- **IDE MCP Client Timeout (`timed out after 3m0s`)**:
  - Some IDE MCP clients enforce a 180-second RPC timeout. On a cold run (when `uv` downloads wheels, `terraform` initializes providers, or `podman` pulls `floci`), `harness_stack_add` may take ~3.5–4.5 minutes.
  - **Do not kill the process**: the `harness mcp` worker finishes the gate ladder in the background and merges automatically. Simply ask the IDE to call `harness_stack_list` a minute later to see the merged stack and its token telemetry in `.harness/state.yaml`!
- **Inspecting Failed Runs**:
  - If a stack cannot pass the gates after 3 repair attempts, your Git branch is left **100% untouched**, and the diagnostic patch + JSON gate failure report are saved in `<repo>/.harness/failed-runs/<run-id>.patch` and `<run-id>-report.json`.
