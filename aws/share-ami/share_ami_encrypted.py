#!/usr/bin/env python3
"""
Creates a CMK, encrypts an AMI with it, copies it (re-encrypting under the CMK),
and shares both the AMI and KMS key with a target AWS account.

Usage:
    python share_ami_encrypted.py \
        --instance-id i-0abc123def456789 \
        --target-account-id 123456789012 \
        --region us-east-1 \
        [--kms-alias alias/ami-sharing-key] \
        [--ami-name my-encrypted-ami]
"""

import argparse
import json
import sys
import time

import boto3
from botocore.exceptions import ClientError


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-i", "--instance-id", required=True, help="Source EC2 instance ID")
    parser.add_argument("-a", "--target-account-id", required=True, help="AWS account ID to share the AMI with")
    parser.add_argument("-r", "--region", required=True, help="AWS region (e.g. us-east-1)")
    parser.add_argument("-t", "--kms-alias", default="alias/ami-sharing-key", help="KMS key alias (default: alias/ami-sharing-key)")
    parser.add_argument("-n", "--ami-name", default="", help="AMI name (default: encrypted-ami-<instance-id>-<timestamp>)")
    return parser.parse_args()


# ---------------------------------------------------------------------------
# Step 1 — Create CMK
# ---------------------------------------------------------------------------

def create_cmk(kms: "boto3.client", alias: str, source_account_id: str) -> dict:
    """Create a CMK with a key policy that allows EC2/EBS to use it."""
    key_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowRootFullAccess",
                "Effect": "Allow",
                "Principal": {"AWS": f"arn:aws:iam::{source_account_id}:root"},
                "Action": "kms:*",
                "Resource": "*",
            },
        ],
    }

    print(f"[1/6] Creating CMK with alias '{alias}' ...")
    try:
        key = kms.create_key(
            Description="CMK for encrypted AMI sharing",
            KeyUsage="ENCRYPT_DECRYPT",
            Policy=json.dumps(key_policy),
            Tags=[{"TagKey": "Purpose", "TagValue": "ami-sharing"}],
        )["KeyMetadata"]
    except ClientError as exc:
        sys.exit(f"Failed to create CMK: {exc}")

    key_id = key["KeyId"]
    key_arn = key["Arn"]

    try:
        kms.create_alias(AliasName=alias, TargetKeyId=key_id)
        print(f"    Key ID : {key_id}")
        print(f"    Key ARN: {key_arn}")
        print(f"    Alias  : {alias}")
    except ClientError as exc:
        # Alias may already exist — not fatal, but surface the warning.
        print(f"    Warning: could not create alias ({exc})")

    return {"key_id": key_id, "key_arn": key_arn}


# ---------------------------------------------------------------------------
# Step 2 — Grant target account KMS permissions
# ---------------------------------------------------------------------------

def grant_target_account_kms_access(kms: "boto3.client", key_id: str, source_account_id: str, target_account_id: str) -> None:
    print(f"[2/6] Granting account {target_account_id} KMS access ...")

    current_policy = json.loads(kms.get_key_policy(KeyId=key_id, PolicyName="default")["Policy"])

    target_principal = f"arn:aws:iam::{target_account_id}:root"
    target_statement = {
        "Sid": "AllowTargetAccountAMIUsage",
        "Effect": "Allow",
        "Principal": {"AWS": target_principal},
        "Action": [
            "kms:DescribeKey",
            "kms:ReEncrypt*",
            "kms:CreateGrant",
            "kms:Decrypt",
        ],
        "Resource": "*",
    }

    # Avoid duplicating the statement on re-runs.
    existing_sids = {s.get("Sid") for s in current_policy.get("Statement", [])}
    if target_statement["Sid"] not in existing_sids:
        current_policy["Statement"].append(target_statement)

    try:
        kms.put_key_policy(KeyId=key_id, PolicyName="default", Policy=json.dumps(current_policy))
        print(f"    Permissions granted to {target_account_id}")
    except ClientError as exc:
        sys.exit(f"Failed to update KMS key policy: {exc}")


# ---------------------------------------------------------------------------
# Step 3 — Create AMI from instance
# ---------------------------------------------------------------------------

def create_ami(ec2: "boto3.client", instance_id: str, ami_name: str) -> str:
    print(f"[3/6] Creating AMI from instance {instance_id} ...")

    try:
        response = ec2.create_image(
            InstanceId=instance_id,
            Name=ami_name,
            Description=f"Encrypted AMI from {instance_id}",
            NoReboot=False,
        )
    except ClientError as exc:
        sys.exit(f"Failed to create AMI: {exc}")

    ami_id = response["ImageId"]
    print(f"    AMI ID: {ami_id} — waiting for 'available' state ...")
    _wait_for_ami(ec2, ami_id)
    print(f"    AMI {ami_id} is available")
    return ami_id


# ---------------------------------------------------------------------------
# Step 4 — Copy AMI with re-encryption under the CMK
# ---------------------------------------------------------------------------

def copy_ami(ec2: "boto3.client", source_ami_id: str, ami_name: str, region: str, key_arn: str) -> str:
    copied_name = f"copy-{ami_name}"
    print(f"[4/6] Copying AMI {source_ami_id} with CMK re-encryption ...")

    try:
        response = ec2.copy_image(
            SourceImageId=source_ami_id,
            SourceRegion=region,
            Name=copied_name,
            Description=f"Re-encrypted copy of {source_ami_id}",
            Encrypted=True,
            KmsKeyId=key_arn,
        )
    except ClientError as exc:
        sys.exit(f"Failed to copy AMI: {exc}")

    copied_ami_id = response["ImageId"]
    print(f"    Copied AMI ID: {copied_ami_id} — waiting for 'available' state ...")
    _wait_for_ami(ec2, copied_ami_id)
    print(f"    Copied AMI {copied_ami_id} is available")
    return copied_ami_id


# ---------------------------------------------------------------------------
# Step 5 — Share the copied AMI with the target account
# ---------------------------------------------------------------------------

def share_ami(ec2: "boto3.client", ami_id: str, target_account_id: str) -> None:
    print(f"[5/6] Sharing AMI {ami_id} with account {target_account_id} ...")

    try:
        ec2.modify_image_attribute(
            ImageId=ami_id,
            Attribute="launchPermission",
            OperationType="add",
            UserIds=[target_account_id],
        )
    except ClientError as exc:
        sys.exit(f"Failed to share AMI: {exc}")

    # Share each underlying snapshot too.
    snapshots = _get_ami_snapshots(ec2, ami_id)
    for snap_id in snapshots:
        try:
            ec2.modify_snapshot_attribute(
                SnapshotId=snap_id,
                Attribute="createVolumePermission",
                OperationType="add",
                UserIds=[target_account_id],
            )
            print(f"    Snapshot {snap_id} shared")
        except ClientError as exc:
            print(f"    Warning: could not share snapshot {snap_id}: {exc}")

    print(f"    AMI {ami_id} shared with {target_account_id}")


# ---------------------------------------------------------------------------
# Step 6 — Print summary
# ---------------------------------------------------------------------------

def print_summary(key_id: str, key_arn: str, alias: str, source_ami_id: str, copied_ami_id: str, target_account_id: str, region: str) -> None:
    print("\n" + "=" * 60)
    print("[6/6] Summary")
    print("=" * 60)
    print(f"  KMS Key ID       : {key_id}")
    print(f"  KMS Key ARN      : {key_arn}")
    print(f"  KMS Alias        : {alias}")
    print(f"  Source AMI ID    : {source_ami_id}")
    print(f"  Copied AMI ID    : {copied_ami_id}")
    print(f"  Region           : {region}")
    print(f"  Shared with      : {target_account_id}")
    print("=" * 60)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _wait_for_ami(ec2: "boto3.client", ami_id: str, poll_interval: int = 30, timeout: int = 3600) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            images = ec2.describe_images(ImageIds=[ami_id])["Images"]
        except ClientError as exc:
            sys.exit(f"Error polling AMI {ami_id}: {exc}")

        if not images:
            sys.exit(f"AMI {ami_id} not found")

        state = images[0]["State"]
        if state == "available":
            return
        if state == "failed":
            sys.exit(f"AMI {ami_id} entered failed state")

        time.sleep(poll_interval)

    sys.exit(f"Timed out waiting for AMI {ami_id} to become available")


def _get_ami_snapshots(ec2: "boto3.client", ami_id: str) -> list[str]:
    try:
        images = ec2.describe_images(ImageIds=[ami_id])["Images"]
    except ClientError as exc:
        print(f"    Warning: could not fetch snapshots for {ami_id}: {exc}")
        return []

    return [
        mapping["Ebs"]["SnapshotId"]
        for mapping in images[0].get("BlockDeviceMappings", [])
        if "Ebs" in mapping and "SnapshotId" in mapping["Ebs"]
    ]


def _get_caller_account(sts: "boto3.client") -> str:
    try:
        return sts.get_caller_identity()["Account"]
    except ClientError as exc:
        sys.exit(f"Could not resolve caller identity: {exc}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()

    ami_name = args.ami_name or f"encrypted-ami-{args.instance_id}-{int(time.time())}"

    session = boto3.Session(region_name=args.region)
    ec2 = session.client("ec2")
    kms = session.client("kms")
    sts = session.client("sts")

    source_account_id = _get_caller_account(sts)
    print(f"Source account : {source_account_id}")
    print(f"Target account : {args.target_account_id}")
    print(f"Region         : {args.region}")
    print(f"Instance       : {args.instance_id}\n")

    key_info = create_cmk(kms, args.kms_alias, source_account_id)
    grant_target_account_kms_access(kms, key_info["key_id"], source_account_id, args.target_account_id)
    source_ami_id = create_ami(ec2, args.instance_id, ami_name)
    copied_ami_id = copy_ami(ec2, source_ami_id, ami_name, args.region, key_info["key_arn"])
    share_ami(ec2, copied_ami_id, args.target_account_id)
    print_summary(
        key_info["key_id"],
        key_info["key_arn"],
        args.kms_alias,
        source_ami_id,
        copied_ami_id,
        args.target_account_id,
        args.region,
    )


if __name__ == "__main__":
    main()
