"""Build and verify workload container images against the local ECR.

Reads `.harness/state.yaml` for containerized workloads, maps their ECR
repositories from `terraform show`, builds each image, verifies the package
imports cleanly inside the built container, and prints the image digest.

Default mode is verify-only: a valid image build is never hidden behind
registry trust or login behavior. Pass `--push` to additionally log into the
emulator's ECR endpoint and push the images (the harness gate treats push as
best-effort and reports it separately from build verification).

Credentials resolve through boto3's default chain when the environment
publishes identity files (``AWS_SHARED_CREDENTIALS_FILE``/``AWS_PROFILE``,
used by AWS Emulator's per-run credentials); otherwise the static ``test``
credentials used for local development are used.
"""

import base64
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

import boto3
import yaml

ROOT = Path(__file__).resolve().parents[1]


def _run(argv: list[str], **kwargs: Any) -> subprocess.CompletedProcess[str]:
    """Run one command and return the completed process."""
    return subprocess.run(  # noqa: S603
        argv, capture_output=True, text=True, check=False, **kwargs
    )


def _endpoint() -> str:
    """Return the local emulator endpoint URL."""
    return os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")


def _credentials() -> dict[str, str]:
    """Explicit test credentials, unless the environment provides identity."""
    if os.environ.get("AWS_SHARED_CREDENTIALS_FILE") or os.environ.get("AWS_PROFILE"):
        return {}
    return {
        "aws_access_key_id": os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        "aws_secret_access_key": os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    }


def _ecr_urls(env: dict[str, str]) -> dict[str, str]:
    """Map ECR repository names to their URIs from the applied state."""
    show = _run(["terraform", "show", "-json"], cwd=ROOT / "infra", env=env)
    payload = json.loads(show.stdout or "{}")
    repos: dict[str, str] = {}
    modules = payload.get("values", {}).get("root_module", {}).get("child_modules", [])
    for module in modules:
        for resource in module.get("resources", []):
            if resource.get("type") == "aws_ecr_repository":
                values = resource.get("values", {})
                repos[values["name"]] = values["repository_url"]
    return repos


def _tls_flags(runtime: str) -> list[str]:
    """TLS flags for loopback emulator registries on podman.

    HTTPS emulators (AWS Emulator) sign with a per-run self-signed cert that
    has no CA basic constraints, so it can never be a Go trust root (the
    push path is Go code) — certs.d injection cannot work. On loopback the
    trust anchor is the per-run SigV4 credential, not PKI, so podman skips
    verification for loopback registries only; real registries keep PKI.
    """
    if Path(runtime).name != "podman":
        return []
    endpoint = _endpoint()
    registry_host = endpoint.split("://", maxsplit=1)[-1].split(":", maxsplit=1)[0]
    if registry_host in {"127.0.0.1", "localhost", "::1"}:
        return ["--tls-verify=false"]
    return []


def _podman_login(runtime: str, url: str) -> subprocess.CompletedProcess[str]:
    """Attempt to log the container runtime into the emulator's ECR registry."""
    registry = url.split("/", maxsplit=1)[0]
    region = os.environ.get("AWS_DEFAULT_REGION", "eu-west-3")
    ecr = boto3.client(
        "ecr",
        endpoint_url=_endpoint(),
        region_name=region,
        **_credentials(),
    )
    token = ecr.get_authorization_token()["authorizationData"][0]["authorizationToken"]
    password = base64.b64decode(token).decode().split(":", maxsplit=1)[1]
    return _run(
        [
            runtime,
            "login",
            *_tls_flags(runtime),
            registry,
            "--username",
            "AWS",
            "--password-stdin",
        ],
        input=password,
    )


def _image_digest(runtime: str, image: str, env: dict[str, str]) -> str | None:
    """Return the built image's digest, when the runtime reports one."""
    inspect = _run(
        [runtime, "image", "inspect", image],
        cwd=ROOT,
        env=env,
    )
    try:
        payload = json.loads(inspect.stdout or "[]")
    except json.JSONDecodeError:
        return None
    if not payload or not isinstance(payload, list):
        return None
    digest = payload[0].get("Digest")
    return str(digest) if digest else None


def _build_and_verify(
    runtime: str,
    package: str,
    uri: str,
    env: dict[str, str],
    *,
    push: bool,
) -> str | None:
    """Build the workload image, smoke-test it, and push when asked to."""
    image = f"{uri}:latest"
    build = _run(
        [runtime, "build", "-f", f"backend/{package}/Dockerfile", "-t", image, "."],
        cwd=ROOT,
        env=env,
    )
    if build.returncode != 0:
        return f"build: {build.stderr[-300:]}"
    smoke = _run(
        [runtime, "run", "--rm", image, "python", "-c", f"import {package}"],
        cwd=ROOT,
        env=env,
    )
    if smoke.returncode != 0:
        return f"smoke: {smoke.stderr[-300:]}"
    digest = _image_digest(runtime, image, env)
    print(f"verified {image}" + (f" (digest {digest})" if digest else ""))
    if not push:
        return None
    login = _podman_login(runtime, uri)
    if login.returncode != 0:
        return f"ecr login: {login.stderr[-300:]}"
    pushed = _run([runtime, "push", *_tls_flags(runtime), image], env=env)
    if pushed.returncode != 0:
        return f"push: {pushed.stderr[-300:]}"
    return None


def main() -> int:
    """Build, verify, and optionally push every containerized workload image."""
    push = "--push" in sys.argv[1:]
    state = yaml.safe_load(
        (ROOT / ".harness" / "state.yaml").read_text(encoding="utf-8")
    )
    workloads = [
        (w["package_name"], w["image_repo"])
        for stack in state.get("stacks", [])
        for w in stack.get("workloads", [])
        if w.get("containerized") and w.get("image_repo")
    ]
    if not workloads:
        print("no containerized workloads")
        return 0
    env = dict(os.environ)
    repos = _ecr_urls(env)
    runtime = shutil.which("podman") or shutil.which("docker") or "podman"
    rc = 0
    for package, repo_name in workloads:
        uri = repos.get(repo_name)
        if uri is None:
            print(f"FAILED {package}: no ecr repository named {repo_name}")
            rc = 1
            continue
        err = _build_and_verify(runtime, package, uri, env, push=push)
        if err is not None:
            print(f"FAILED {package}: {err}")
            rc = 1
            continue
        print(f"done {uri}:latest" + (" (pushed)" if push else ""))
    return rc


if __name__ == "__main__":
    sys.exit(main())
