"""Create the terraform state bucket inside the local AWS emulator.

Reads ``infra/envs/dev.tfbackend`` for bucket and region, then creates the
bucket at ``AWS_ENDPOINT_URL`` so terraform can initialize the real S3
backend against the local endpoint. Runs in CI before ``terraform init``
and inside the harness's integration gate (AWS Emulator).

Credentials resolve through boto3's default chain when the environment
publishes identity files (``AWS_SHARED_CREDENTIALS_FILE``/``AWS_PROFILE``,
used by AWS Emulator's per-run credentials); otherwise the static ``test``
credentials used for local development are used.
"""

import os
import re
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import ClientError

ROOT = Path(__file__).resolve().parents[1]


def _credentials() -> dict[str, str]:
    """Explicit test credentials, unless the environment provides identity."""
    if os.environ.get("AWS_SHARED_CREDENTIALS_FILE") or os.environ.get("AWS_PROFILE"):
        return {}
    return {
        "aws_access_key_id": os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        "aws_secret_access_key": os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    }


def main() -> None:
    """Create the state bucket from the dev.tfbackend configuration."""
    text = (ROOT / "infra" / "envs" / "dev.tfbackend").read_text(encoding="utf-8")
    bucket_match = re.search(r'bucket\s*=\s*"([^"]+)"', text)
    if bucket_match is None:
        raise ValueError("no bucket configured in infra/envs/dev.tfbackend")
    bucket = bucket_match.group(1)
    region_match = re.search(r'region\s*=\s*"([^"]+)"', text)
    region = region_match.group(1) if region_match else "us-east-1"
    client = boto3.client(
        "s3",
        endpoint_url=os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566"),
        region_name=region,
        **_credentials(),
    )
    try:
        if region == "us-east-1":
            client.create_bucket(Bucket=bucket)
        else:
            location: Any = {"LocationConstraint": region}
            client.create_bucket(Bucket=bucket, CreateBucketConfiguration=location)
        print(f"state bucket ready: {bucket}")
    except ClientError as exc:
        code = exc.response["Error"]["Code"]
        if code in {"BucketAlreadyOwnedByYou", "BucketAlreadyExists"}:
            print(f"state bucket exists: {bucket}")
        else:
            raise


if __name__ == "__main__":
    main()
