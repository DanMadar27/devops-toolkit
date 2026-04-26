# Share AMI (Encrypted)

Create an encrypted AMI from an EC2 instance using a customer-managed KMS key (CMK), then optionally share it with another AWS account.

Because the snapshots are encrypted with a CMK you control, sharing is safe: you grant the target account just enough KMS permissions to use (or re-encrypt) the snapshot — and you can revoke access at any time by deleting the key.

---

## Files

| File | Purpose |
|---|---|
| `create_ami_encrypted.py` | Creates the KMS key, AMI, and shares both with a target account |
| `prepare_instance.sh` | Runs **on the instance** to scrub secrets before snapshotting |

---

## Prerequisites

```bash
pip install boto3
```

AWS credentials configured via environment variables, `~/.aws/credentials`, or an IAM role.

### Required IAM permissions

```
ec2:CreateImage, ec2:CreateTags, ec2:DescribeImages, ec2:DescribeInstances,
ec2:ModifyImageAttribute, ec2:ModifySnapshotAttribute,
kms:CreateAlias, kms:CreateKey, kms:DeleteAlias, kms:DescribeKey,
kms:ListAliases, kms:PutKeyPolicy, kms:ScheduleKeyDeletion, kms:TagResource,
sts:GetCallerIdentity
```

---

## Recommended workflow

> **Before you start:** Rather than modifying a live instance, launch a fresh instance from your existing AMI (or a base AMI), configure it exactly as intended, then follow the steps below. This keeps your original instance untouched and avoids any risk of data loss if something goes wrong during preparation.

### Step 1 — Prepare the instance (run on the instance)

Before snapshotting, scrub secrets and identity-specific data from the instance so they don't end up baked into the AMI.

```bash
# Copy the script to the instance, then:
sudo bash prepare_instance.sh

# Preview changes without applying them:
sudo bash prepare_instance.sh --dry-run
```

What the script removes:

| Category | Paths |
|---|---|
| SSH authorized keys | `/root/.ssh/authorized_keys`, `/home/*/.ssh/authorized_keys` |
| SSH host keys | `/etc/ssh/ssh_host_*` (regenerated on first boot) |
| Shell history | `~/.bash_history`, `~/.zsh_history` for root and all users |
| AWS credentials | `/root/.aws/credentials`, `/home/*/.aws/credentials` |
| `.env` files | `.env`, `.env.local`, `.env.production` under common app directories |
| Cloud-init state | `cloud-init clean --logs` |
| Temp / package caches | `/tmp`, `/var/tmp`, `apt`/`yum`/`dnf` caches |

> **Do not reboot the instance after running the script.** A reboot regenerates SSH host keys before the snapshot is taken, which is fine — but it also re-runs cloud-init, which may restore some state. Stop the instance instead (see below).

After the script completes, exit the SSH session.

### Step 2 — Stop the instance (recommended)

A stopped instance produces a fully consistent snapshot. A running instance works but may have in-flight I/O.

```bash
aws ec2 stop-instances --instance-ids i-0abc123def456789
aws ec2 wait instance-stopped --instance-ids i-0abc123def456789
```

### Step 3 — Create the encrypted AMI

```bash
python create_ami_encrypted.py -i <instance-id>
```

Share with another account at the same time:

```bash
python create_ami_encrypted.py \
  -i i-0abc123def456789 \
  -a 123456789012 \
  -r us-east-1
```

---

## Usage reference

```
python create_ami_encrypted.py -i <instance-id> [OPTIONS]

Required:
  -i, --instance-id       Source EC2 instance ID

Optional:
  -n, --ami-name          AMI name (default: encrypted-ami-<id>-<timestamp>)
  -r, --region            AWS region (default: from env / AWS config)
  -a, --share-account-id  Target AWS account ID to share AMI + KMS key with
  -t, --kms-key-alias     KMS alias (default: alias/ami-share-<instance-id>)
  -d, --description       AMI description
  -w, --wait-timeout      Max seconds to wait for AMI (default: 3600)
```

---

## What the Python script does

1. Validates credentials and resolves the current account/region via STS.
2. Checks the instance state — warns if running (no-reboot snapshot).
3. Creates a CMK with a key policy that allows EC2/EBS to use it for encryption.
4. If `--share-account-id` is given, extends the key policy to grant the target account the minimum permissions needed to re-encrypt or launch from the snapshot.
5. Creates the AMI with all EBS volumes forced to encrypted using the CMK.
6. Waits for the AMI to reach `available` state.
7. Shares the AMI and its underlying snapshots with the target account.
8. Writes results to `ami_creation_results_<timestamp>.env` for scripting.

If the script fails after creating the KMS key, an `atexit` handler schedules the orphaned key for deletion (7-day pending window) to avoid unnecessary costs.

---

## Outputs

Results are written to `ami_creation_results_<timestamp>.env`:

```bash
KMS_KEY_ID=...
KMS_KEY_ARN=...
KMS_ALIAS=...
AMI_ID=...
AMI_NAME=...
REGION=...
SOURCE_INSTANCE=...
SHARED_WITH=...    # only present when --share-account-id was used
```

Source it in shell scripts: `source ami_creation_results_<timestamp>.env`

---

## Next steps for the target account

Copying the AMI is always recommended. When copying, the target account **must specify their own KMS key** (`--kms-key-id`). This re-encrypts the snapshots under a key they own and control — after the copy completes they have zero dependency on the source account's KMS key, and the source account can delete the CMK at any time without affecting them.

### Same-region copy

Use this when the target account operates in the same region as the source (e.g. both in `eu-central-1`).

```bash
aws ec2 copy-image \
  --source-region eu-central-1 \
  --region eu-central-1 \
  --source-image-id <ami-id> \
  --name "copied-<ami-name>" \
  --encrypted \
  --kms-key-id <target-account-kms-key-arn>   # key in eu-central-1
```

### Cross-region copy

Use this when the target account wants the AMI in a different region (e.g. source is `eu-central-1`, target wants `us-east-1`).

**Important:** KMS keys are regional. The CMK created by `create_ami_encrypted.py` only exists in the source region and cannot encrypt volumes in another region. The target account must supply their own KMS key in the destination region.

```bash
aws ec2 copy-image \
  --source-region eu-central-1 \              # where the shared AMI lives
  --region us-east-1 \                        # where the target account wants it
  --source-image-id <ami-id> \
  --name "copied-<ami-name>" \
  --encrypted \
  --kms-key-id <target-account-kms-key-arn>   # key in us-east-1 (target region)
```

After the copy completes, the target account's AMI in `us-east-1` is encrypted with their own key and is fully independent of the source account.

### Launch directly (without copying)

The target account can launch instances from the shared AMI without copying, but:
- They need ongoing access to the source account's KMS key.
- They can only launch in the source region (`eu-central-1`) — cross-region launch is not possible without copying first.
- Deleting the source CMK revokes their access to the snapshots.

---

## Security notes

- The CMK is created with a key policy that grants only the minimum permissions required. The target account cannot administer the key.
- SSH host keys are removed by `prepare_instance.sh` and will be freshly generated when the AMI is launched in the target account — preventing host-spoofing.
- Revoking cross-account access is as simple as removing the target account from the KMS key policy (or deleting the key).
