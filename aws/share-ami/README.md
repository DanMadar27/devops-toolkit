# Share AMI (Encrypted)

Create an encrypted AMI from an EC2 instance using a customer-managed KMS key (CMK), then optionally share it with another AWS account.

Because the snapshots are encrypted with a CMK you control, sharing is safe: you grant the target account just enough KMS permissions to use (or re-encrypt) the snapshot — and you can revoke access at any time by deleting the key.

---

## Files

| File | Purpose |
|---|---|
| `share_ami_encrypted.py` | Creates the KMS key, AMI, copies it (re-encrypting under the CMK), and shares both with a target account |
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

### Step 3 — Create and share the encrypted AMI

```bash
python share_ami_encrypted.py \
  -i i-0abc123def456789 \
  -a 123456789012 \
  -r us-east-1 \
  -n my-encrypted-ami \
  -t alias/ami-sharing-key
```

---

## Usage reference

```
python share_ami_encrypted.py -i <instance-id> -a <target-account-id> -r <region> [OPTIONS]

Required:
  -i, --instance-id       Source EC2 instance ID
  -a, --target-account-id Target AWS account ID to share the AMI and KMS key with
  -r, --region            AWS region (e.g. us-east-1)

Optional:
  -n, --ami-name          AMI name (default: encrypted-ami-<id>-<timestamp>)
  -t, --kms-alias         KMS key alias (default: alias/ami-sharing-key)
```

---

## What the Python script does

1. Resolves the caller account ID via STS.
2. Creates a CMK (`alias/ami-sharing-key`) with a key policy that allows EC2/EBS to use it for encryption.
3. Extends the key policy to grant the target account `kms:DescribeKey`, `kms:ReEncrypt*`, `kms:CreateGrant`, and `kms:Decrypt`.
4. Creates an AMI from the source instance and waits for it to reach `available`.
5. Copies the AMI in the same region, re-encrypting all snapshots under the CMK, and waits for `available`.
6. Shares the copied AMI and its underlying snapshots with the target account via `ModifyImageAttribute` / `ModifySnapshotAttribute`.
7. Prints a summary of all relevant IDs.

---

## Why Two Steps? (create-image + copy-image)

`create-image` snapshots the instance volumes as-is. AWS locks each snapshot to whatever KMS key the source volume already uses — typically the default AWS-managed key (`aws/ebs`) — and there is no API parameter to override this during image creation.

`copy-image` is the only AWS API that allows re-encryption: it decrypts each snapshot and re-encrypts it under a key you specify (`--kms-key-id`). This is how you move the snapshots onto a CMK you control, which is required for cross-account sharing (the default AWS-managed key cannot be shared with another account).

**Exception — skip `copy-image` if your volumes already use your CMK.** If the source instance's EBS volumes were created with your CMK, `create-image` produces snapshots already encrypted under it. In that case you can share the original AMI and its snapshots directly and skip the copy step entirely.

---

## Outputs

A summary is printed on completion:

```
KMS Key ID       : ...
KMS Key ARN      : ...
KMS Alias        : alias/ami-sharing-key
Source AMI ID    : ami-... (original, not shared)
Copied AMI ID    : ami-... (re-encrypted copy, shared with target)
Region           : ...
Shared with      : <target-account-id>
```

---

## Next steps for the target account

Copying the AMI into the target account is always recommended. The copy re-encrypts all snapshots under a key the target account owns — after that they have zero dependency on the source account's CMK, and the source account can delete it at any time without affecting them.

### What to share with the target account

The AMI ID alone is not enough. Share all three:

| What | Where to find it |
|---|---|
| AMI ID | printed in the summary at the end of the script |
| Source region | the region you ran the script in |
| Source CMK ARN | printed in the summary (`KMS Key ARN`) |

The target account does not pass the source CMK ARN in the copy command, but they need it to confirm they have the correct KMS permissions before running the copy — and to diagnose any `KMS access denied` errors.

### Same-region copy

Use this when the target account operates in the same region as the source (e.g. both in `eu-central-1`).

```bash
aws ec2 copy-image \
  --source-region eu-central-1 \
  --region eu-central-1 \
  --source-image-id <ami-id> \
  --name "copied-<ami-name>" \
  --encrypted \
  --kms-key-id <target-account-kms-key-arn>   # their own key in eu-central-1
```

### Cross-region copy

Use this when the target account wants the AMI in a different region (e.g. source is `eu-central-1`, target wants `us-east-1`).

**Important:** KMS keys are regional. The source CMK only exists in the source region. The target account must supply their own KMS key in the destination region.

```bash
# --source-region: where the shared AMI lives
# --region:        where the target account wants it
# --kms-key-id:    their own key in the destination region
aws ec2 copy-image \
  --source-region eu-central-1 \
  --region us-east-1 \
  --source-image-id <ami-id> \
  --name "copied-<ami-name>" \
  --encrypted \
  --kms-key-id <target-account-kms-key-arn>
```

After the copy completes, the target account's AMI is encrypted with their own key and is fully independent of the source account.

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
