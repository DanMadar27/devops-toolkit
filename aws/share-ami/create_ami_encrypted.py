#!/usr/bin/env python3
"""
create_ami_encrypted.py

Creates an AMI from a running/stopped EC2 instance with encrypted EBS volumes
using a newly created customer-managed KMS key. This allows the AMI (and its
snapshots) to be shared with other AWS accounts by granting KMS key access.

Usage:
    python create_ami_encrypted.py -i <instance-id> [OPTIONS]

Prerequisites:
    pip install boto3
    AWS credentials configured via env vars, ~/.aws/credentials, or IAM role.

Required IAM permissions:
    ec2:CreateImage, ec2:CreateTags, ec2:DescribeImages, ec2:DescribeInstances,
    ec2:ModifyImageAttribute, ec2:ModifySnapshotAttribute,
    kms:CreateAlias, kms:CreateKey, kms:DeleteAlias, kms:DescribeKey,
    kms:ListAliases, kms:PutKeyPolicy, kms:ScheduleKeyDeletion, kms:TagResource,
    sts:GetCallerIdentity
"""

from __future__ import annotations

import argparse
import atexit
import json
import re
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

import boto3
from botocore.exceptions import BotoCoreError, ClientError


# ── Colour output (auto-disabled when not a TTY) ──────────────────────────────

_USE_COLOUR = sys.stdout.isatty()


def _c(code: str, text: str) -> str:
    return f"\033[{code}m{text}\033[0m" if _USE_COLOUR else text


def log(msg: str) -> None:
    print(_c("34", "[INFO] ") + msg)


def success(msg: str) -> None:
    print(_c("32", "[OK]   ") + msg)


def warn(msg: str) -> None:
    print(_c("33", "[WARN] ") + msg)


def error(msg: str) -> None:
    print(_c("31", "[ERROR]") + " " + msg, file=sys.stderr)


def die(msg: str) -> None:
    error(msg)
    sys.exit(1)


# ── Result container ──────────────────────────────────────────────────────────

@dataclass
class RunResult:
    kms_key_id: str = ""
    kms_key_arn: str = ""
    kms_alias: str = ""
    ami_id: str = ""
    ami_name: str = ""
    region: str = ""
    source_instance: str = ""
    shared_with: str = ""


# ── Cleanup state (for atexit handler) ───────────────────────────────────────

@dataclass
class _CleanupState:
    kms_key_id: str = ""
    region: str = ""
    success: bool = False


_cleanup_state = _CleanupState()


def _cleanup_handler() -> None:
    """Scheduled via atexit. Deletes orphaned KMS key if script failed mid-run."""
    if _cleanup_state.success or not _cleanup_state.kms_key_id:
        return

    warn(f"Script failed after creating KMS key {_cleanup_state.kms_key_id}.")
    warn("Scheduling key deletion in 7 days (minimum) to avoid orphaned costs.")
    try:
        kms = boto3.client("kms", region_name=_cleanup_state.region or None)
        kms.schedule_key_deletion(
            KeyId=_cleanup_state.kms_key_id,
            PendingWindowInDays=7,
        )
        warn(f"KMS key scheduled for deletion: {_cleanup_state.kms_key_id}")
    except Exception as exc:  # noqa: BLE001
        warn(
            f"Could not schedule deletion — delete manually:\n"
            f"  aws kms schedule-key-deletion --key-id {_cleanup_state.kms_key_id}\n"
            f"  ({exc})"
        )


atexit.register(_cleanup_handler)


# ── Input validation helpers ──────────────────────────────────────────────────

_INSTANCE_ID_RE = re.compile(r"^i-[0-9a-f]{8,17}$")
_ACCOUNT_ID_RE  = re.compile(r"^\d{12}$")
_SAFE_AMI_CHARS = re.compile(r"[^a-zA-Z0-9 ()./\\\-_#]")
_SAFE_ALIAS_CHARS = re.compile(r"[^a-zA-Z0-9/_\-]")


def sanitise_ami_name(raw: str) -> str:
    cleaned = _SAFE_AMI_CHARS.sub("", raw)[:128]
    if cleaned != raw:
        warn(f"AMI name was sanitised to: '{cleaned}'")
    return cleaned


def sanitise_kms_alias(raw: str) -> str:
    if not raw.startswith("alias/"):
        raw = f"alias/{raw}"
    if raw.startswith("alias/aws/"):
        die("KMS alias cannot start with 'alias/aws/' (reserved for AWS-managed keys).")
    # Keep only valid characters after 'alias/'
    prefix, rest = "alias/", raw[len("alias/"):]
    return prefix + _SAFE_ALIAS_CHARS.sub("", rest)


# ── Argument parsing ──────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create an encrypted AMI from an EC2 instance using a CMK.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("-i", "--instance-id",    required=True,
                        help="Source EC2 instance ID (required)")
    parser.add_argument("-n", "--ami-name",        default="",
                        help="AMI name (default: encrypted-ami-<id>-<timestamp>)")
    parser.add_argument("-r", "--region",          default="",
                        help="AWS region (default: from env / AWS config)")
    parser.add_argument("-a", "--share-account-id", default="",
                        help="Target AWS account ID to share AMI + KMS key with")
    parser.add_argument("-t", "--kms-key-alias",   default="",
                        help="KMS key alias (default: alias/ami-share-<instance-id>)")
    parser.add_argument("-d", "--description",     default="",
                        help="AMI description")
    parser.add_argument("-w", "--wait-timeout",    type=int, default=3600,
                        help="Max seconds to wait for AMI (default: 3600)")
    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if not _INSTANCE_ID_RE.match(args.instance_id):
        die(f"Invalid instance ID format: '{args.instance_id}'. Expected: i-xxxxxxxxxxxxxxxxx")
    if args.share_account_id and not _ACCOUNT_ID_RE.match(args.share_account_id):
        die(f"Invalid account ID: '{args.share_account_id}'. Must be exactly 12 digits.")
    if args.wait_timeout <= 0:
        die("Wait timeout must be a positive integer (seconds).")


# ── KMS helpers ───────────────────────────────────────────────────────────────

def build_kms_base_policy(account_id: str) -> dict:
    return {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "EnableIAMRootPermissions",
                "Effect": "Allow",
                "Principal": {"AWS": f"arn:aws:iam::{account_id}:root"},
                "Action": "kms:*",
                "Resource": "*",
            },
            {
                "Sid": "AllowEC2EBSEncryption",
                "Effect": "Allow",
                "Principal": {"Service": "ec2.amazonaws.com"},
                "Action": [
                    "kms:GenerateDataKeyWithoutPlaintext",
                    "kms:CreateGrant",
                    "kms:Decrypt",
                    "kms:DescribeKey",
                    "kms:ReEncrypt*",
                ],
                "Resource": "*",
            },
        ],
    }


def build_kms_shared_policy(account_id: str, share_account_id: str) -> dict:
    policy = build_kms_base_policy(account_id)
    policy["Statement"].append({
        "Sid": "AllowTargetAccountEBSGrants",
        "Effect": "Allow",
        "Principal": {"AWS": f"arn:aws:iam::{share_account_id}:root"},
        "Action": [
            "kms:DescribeKey",
            "kms:ReEncryptFrom",
            "kms:ReEncryptTo",
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant",
        ],
        "Resource": "*",
    })
    return policy


def create_kms_key(
    kms: "boto3.client",
    instance_id: str,
    timestamp: str,
    account_id: str,
) -> tuple[str, str]:
    """Creates a CMK. Returns (key_id, key_arn)."""
    policy = build_kms_base_policy(account_id)
    resp = kms.create_key(
        Description=f"AMI sharing key for instance {instance_id} - created {timestamp}",
        KeyUsage="ENCRYPT_DECRYPT",
        Policy=json.dumps(policy),
        Tags=[
            {"TagKey": "Purpose",        "TagValue": "AMISharing"},
            {"TagKey": "SourceInstance", "TagValue": instance_id},
            {"TagKey": "CreatedAt",      "TagValue": timestamp},
        ],
    )
    meta = resp["KeyMetadata"]
    return meta["KeyId"], meta["Arn"]


def ensure_kms_alias(kms: "boto3.client", alias: str, key_id: str) -> None:
    """Creates or reassigns the KMS alias to key_id safely."""
    existing_key = ""
    try:
        aliases = kms.list_aliases(KeyId=key_id)
        # list_aliases filtered by KeyId only shows aliases for that key —
        # but we need to check by alias name globally to detect conflicts.
    except ClientError:
        pass

    # Check alias globally
    paginator = kms.get_paginator("list_aliases")
    for page in paginator.paginate():
        for a in page.get("Aliases", []):
            if a.get("AliasName") == alias:
                existing_key = a.get("TargetKeyId", "")
                break

    if existing_key and existing_key != key_id:
        warn(f"Alias '{alias}' already exists on key {existing_key}.")
        warn(f"Deleting old alias and reassigning to new key {key_id}.")
        kms.delete_alias(AliasName=alias)
        existing_key = ""

    if existing_key != key_id:
        try:
            kms.create_alias(AliasName=alias, TargetKeyId=key_id)
        except ClientError as exc:
            warn(f"Could not create alias '{alias}': {exc}. Continuing without alias.")


# ── EC2 helpers ───────────────────────────────────────────────────────────────

def get_instance_state(ec2: "boto3.client", instance_id: str) -> str:
    try:
        resp = ec2.describe_instances(InstanceIds=[instance_id])
    except ClientError as exc:
        die(f"Instance {instance_id} not found or not accessible: {exc}")

    reservations = resp.get("Reservations", [])
    if not reservations or not reservations[0].get("Instances"):
        die(f"Instance {instance_id} not found.")
    return reservations[0]["Instances"][0]["State"]["Name"]


def get_ebs_block_devices(ec2: "boto3.client", instance_id: str) -> list[dict]:
    """Returns EBS-only block device mappings (excludes instance-store)."""
    resp = ec2.describe_instances(InstanceIds=[instance_id])
    bdms = resp["Reservations"][0]["Instances"][0].get("BlockDeviceMappings", [])
    return [bdm for bdm in bdms if "Ebs" in bdm]


def build_encrypted_bdm(devices: list[dict], kms_key_arn: str) -> list[dict]:
    """Builds block device mappings with encryption forced and KMS key set."""
    result = []
    for bdm in devices:
        ebs = bdm["Ebs"]
        result.append({
            "DeviceName": bdm["DeviceName"],
            "Ebs": {
                "Encrypted": True,
                "KmsKeyId": kms_key_arn,
                "VolumeSize": ebs.get("VolumeSize", 0),
                "DeleteOnTermination": ebs.get("DeleteOnTermination", True),
            },
        })
    return result


def wait_for_ami(
    ec2: "boto3.client",
    ami_id: str,
    timeout_secs: int,
    poll_interval: int = 30,
) -> bool:
    """Polls until AMI is available or timeout. Returns True on success."""
    elapsed = 0
    while elapsed < timeout_secs:
        resp = ec2.describe_images(ImageIds=[ami_id])
        images = resp.get("Images", [])
        if not images:
            warn(f"AMI {ami_id} not yet visible, retrying...")
            time.sleep(poll_interval)
            elapsed += poll_interval
            continue

        state = images[0]["State"]

        if state == "available":
            return True

        if state == "failed":
            reason = images[0].get("StateReason", {}).get("Message", "unknown reason")
            die(f"AMI creation failed: {reason}")

        print(
            f"\r\033[34m[INFO]\033[0m  State: {state:<12}  Elapsed: {elapsed}s / {timeout_secs}s",
            end="",
            flush=True,
        )
        time.sleep(poll_interval)
        elapsed += poll_interval

    print()
    return False


def share_ami_with_account(
    ec2: "boto3.client", ami_id: str, account_id: str
) -> None:
    ec2.modify_image_attribute(
        ImageId=ami_id,
        LaunchPermission={"Add": [{"UserId": account_id}]},
    )


def share_snapshots_with_account(
    ec2: "boto3.client", ami_id: str, account_id: str
) -> None:
    resp = ec2.describe_images(ImageIds=[ami_id])
    for bdm in resp["Images"][0].get("BlockDeviceMappings", []):
        snap_id = bdm.get("Ebs", {}).get("SnapshotId")
        if not snap_id:
            continue
        try:
            ec2.modify_snapshot_attribute(
                SnapshotId=snap_id,
                Attribute="createVolumePermission",
                OperationType="add",
                UserIds=[account_id],
            )
            success(f"Snapshot shared: {snap_id}")
        except ClientError as exc:
            warn(f"Could not share snapshot {snap_id}: {exc}")


# ── Results output ────────────────────────────────────────────────────────────

def write_results_file(result: RunResult, timestamp: str) -> Path:
    path = Path(f"ami_creation_results_{timestamp}.env")
    lines = [
        f"KMS_KEY_ID={result.kms_key_id}",
        f"KMS_KEY_ARN={result.kms_key_arn}",
        f"KMS_ALIAS={result.kms_alias}",
        f"AMI_ID={result.ami_id}",
        f"AMI_NAME={result.ami_name}",
        f"REGION={result.region}",
        f"SOURCE_INSTANCE={result.source_instance}",
    ]
    if result.shared_with:
        lines.append(f"SHARED_WITH={result.shared_with}")
    path.write_text("\n".join(lines) + "\n")
    return path


def print_summary(result: RunResult, results_file: Path) -> None:
    bold  = "\033[1m"  if _USE_COLOUR else ""
    green = "\033[32m" if _USE_COLOUR else ""
    yellow = "\033[33m" if _USE_COLOUR else ""
    reset = "\033[0m"  if _USE_COLOUR else ""

    print()
    print(f"{bold}{'═' * 42}{reset}")
    print(f"{bold}  ✅  Done!{reset}")
    print(f"{bold}{'═' * 42}{reset}")
    print()
    print(f"  {bold}KMS_KEY_ID{reset}   = {green}{result.kms_key_id}{reset}")
    print(f"  {bold}KMS_KEY_ARN{reset}  = {green}{result.kms_key_arn}{reset}")
    print(f"  {bold}KMS_ALIAS{reset}    = {green}{result.kms_alias}{reset}")
    print(f"  {bold}AMI_ID{reset}       = {green}{result.ami_id}{reset}")
    print(f"  {bold}AMI_NAME{reset}     = {green}{result.ami_name}{reset}")
    print(f"  {bold}REGION{reset}       = {green}{result.region}{reset}")
    if result.shared_with:
        print(f"  {bold}SHARED_WITH{reset}  = {green}{result.shared_with}{reset}")
    print()
    print(f"  Results saved to: {bold}{results_file}{reset}")
    print(f"  Source with:      {bold}source {results_file}{reset}")
    print()

    if result.shared_with:
        print(f"{yellow}Next steps for the target account ({result.shared_with}):{reset}")
        print("  1. Copy the AMI (recommended — removes dependency on your KMS key):")
        print(f"     aws ec2 copy-image \\")
        print(f"       --region {result.region} \\")
        print(f"       --source-region {result.region} \\")
        print(f"       --source-image-id {result.ami_id} \\")
        print(f"       --name 'copied-{result.ami_name}' \\")
        print(f"       --encrypted")
        print()
        print("  2. Or launch directly (requires ongoing access to your KMS key).")
        print()
        print(f"{yellow}Note:{reset} Deleting KMS key {result.kms_key_id} revokes the target")
        print("  account's access to the encrypted snapshots. Option 1 avoids this.")


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    args = parse_args()
    validate_args(args)

    timestamp = datetime.now(tz=timezone.utc).strftime("%Y%m%d%H%M%S")

    print()
    print(_c("1", "=== AMI Encrypted Creation Script ==="))
    print()

    # ── Build boto3 session ───────────────────────────────────────────────────
    session_kwargs = {}
    if args.region:
        session_kwargs["region_name"] = args.region

    try:
        session = boto3.Session(**session_kwargs)
    except (BotoCoreError, Exception) as exc:
        die(f"Failed to create AWS session: {exc}")

    # ── Verify credentials + resolve account/region ───────────────────────────
    log("Verifying AWS credentials...")
    try:
        sts = session.client("sts")
        identity = sts.get_caller_identity()
    except (ClientError, BotoCoreError) as exc:
        die(f"AWS credentials not configured or invalid: {exc}")

    current_account = identity["Account"]
    current_arn     = identity["Arn"]
    log(f"Authenticated: {current_arn} (account: {current_account})")

    # Resolve final region — boto3 may have pulled it from env/config
    region = session.region_name or args.region
    if not region:
        die("No AWS region set. Use -r/--region or set AWS_DEFAULT_REGION.")
    log(f"Region: {region}")

    # ── Fill defaults ─────────────────────────────────────────────────────────
    raw_ami_name = args.ami_name or f"encrypted-ami-{args.instance_id}-{timestamp}"
    ami_name     = sanitise_ami_name(raw_ami_name)

    raw_alias  = args.kms_key_alias or f"alias/ami-share-{args.instance_id}"
    kms_alias  = sanitise_kms_alias(raw_alias)

    description = args.description or (
        f"Encrypted AMI created from {args.instance_id} on {timestamp}"
    )

    if args.share_account_id and args.share_account_id == current_account:
        warn("Share account is the same as the current account — sharing with self.")

    # ── Create boto3 clients ──────────────────────────────────────────────────
    ec2 = session.client("ec2", region_name=region)
    kms = session.client("kms", region_name=region)

    # Register cleanup now that we have a client
    _cleanup_state.region = region

    # ── Validate instance ─────────────────────────────────────────────────────
    log(f"Looking up instance {args.instance_id}...")
    instance_state = get_instance_state(ec2, args.instance_id)
    log(f"Instance state: {instance_state}")

    match instance_state:
        case "terminated" | "shutting-down":
            die(f"Instance is {instance_state}. Cannot create AMI from it.")
        case "running":
            warn("Instance is running. AMI will be created with no-reboot.")
            warn("For filesystem consistency, consider stopping the instance first.")
        case "stopped":
            log("Instance is stopped — snapshot will be fully consistent.")
        case _:
            warn(f"Unexpected instance state '{instance_state}'. Proceeding anyway.")

    # ── Gather EBS block devices ──────────────────────────────────────────────
    log("Gathering EBS block device mappings...")
    ebs_devices = get_ebs_block_devices(ec2, args.instance_id)
    if not ebs_devices:
        die(f"No EBS volumes found on instance {args.instance_id}.")
    device_names = [d["DeviceName"] for d in ebs_devices]
    log(f"Found {len(ebs_devices)} EBS volume(s): {', '.join(device_names)}")

    # ── Create KMS key ────────────────────────────────────────────────────────
    print()
    log("Creating customer-managed KMS key...")
    try:
        kms_key_id, kms_key_arn = create_kms_key(
            kms, args.instance_id, timestamp, current_account
        )
    except ClientError as exc:
        die(f"Failed to create KMS key: {exc}")

    # Arm the cleanup trap now that a key exists
    _cleanup_state.kms_key_id = kms_key_id
    success(f"KMS key created: {kms_key_id}")
    log(f"KMS ARN: {kms_key_arn}")

    # ── Create alias ──────────────────────────────────────────────────────────
    log(f"Creating KMS alias: {kms_alias}...")
    ensure_kms_alias(kms, kms_alias, kms_key_id)
    success(f"KMS alias set: {kms_alias}")

    # ── Update KMS policy for cross-account sharing (if requested) ────────────
    if args.share_account_id:
        log(f"Granting KMS key access to account: {args.share_account_id}...")
        try:
            policy = build_kms_shared_policy(current_account, args.share_account_id)
            kms.put_key_policy(
                KeyId=kms_key_id,
                PolicyName="default",
                Policy=json.dumps(policy),
            )
            success(f"KMS key policy updated to allow account: {args.share_account_id}")
        except ClientError as exc:
            die(f"Failed to update KMS key policy: {exc}")

    # ── Create AMI ────────────────────────────────────────────────────────────
    print()
    log(f"Creating AMI from instance {args.instance_id}...")
    log(f"AMI name: {ami_name}")

    bdm = build_encrypted_bdm(ebs_devices, kms_key_arn)

    try:
        resp = ec2.create_image(
            InstanceId=args.instance_id,
            Name=ami_name,
            Description=description,
            NoReboot=True,
            BlockDeviceMappings=bdm,
        )
    except ClientError as exc:
        die(f"Failed to create AMI: {exc}")

    ami_id = resp["ImageId"]

    # Tag AMI for traceability
    try:
        ec2.create_tags(
            Resources=[ami_id],
            Tags=[
                {"Key": "SourceInstance", "Value": args.instance_id},
                {"Key": "KmsKeyId",       "Value": kms_key_id},
                {"Key": "CreatedAt",      "Value": timestamp},
            ],
        )
    except ClientError as exc:
        warn(f"Could not tag AMI (non-fatal): {exc}")

    success(f"AMI creation initiated: {ami_id}")

    # ── Wait for AMI ──────────────────────────────────────────────────────────
    print()
    log(f"Waiting for AMI {ami_id} to become available (this can take 5–20 minutes)...")
    log(f"Timeout: {args.wait_timeout}s. Press Ctrl+C to abort — the AMI will keep building.")

    available = wait_for_ami(ec2, ami_id, args.wait_timeout)
    print()

    if not available:
        warn(f"Timed out after {args.wait_timeout}s. AMI {ami_id} is still building.")
        warn(f"Monitor: aws ec2 describe-images --image-ids {ami_id} --query 'Images[0].State'")
    else:
        success("AMI is available!")

    # ── Share AMI + snapshots ─────────────────────────────────────────────────
    if args.share_account_id:
        log(f"Sharing AMI {ami_id} with account {args.share_account_id}...")
        try:
            share_ami_with_account(ec2, ami_id, args.share_account_id)
            success(f"AMI shared with account: {args.share_account_id}")
        except ClientError as exc:
            die(f"Failed to share AMI: {exc}")

        log("Sharing underlying EBS snapshots...")
        share_snapshots_with_account(ec2, ami_id, args.share_account_id)

    # ── Write results and print summary ───────────────────────────────────────
    result = RunResult(
        kms_key_id=kms_key_id,
        kms_key_arn=kms_key_arn,
        kms_alias=kms_alias,
        ami_id=ami_id,
        ami_name=ami_name,
        region=region,
        source_instance=args.instance_id,
        shared_with=args.share_account_id,
    )
    results_file = write_results_file(result, timestamp)

    # Disarm cleanup trap before printing summary
    _cleanup_state.success = True

    print_summary(result, results_file)


if __name__ == "__main__":
    main()
