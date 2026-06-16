# How to Configure AWS SSM Session Manager on Ubuntu EC2

## Prerequisites

- An EC2 instance running Ubuntu
- AWS account access with IAM permissions

---

## Step 1: Create an IAM Role for SSM

1. Go to **IAM → Roles → Create Role**
2. Select **AWS service** → **EC2**
3. Attach the managed policy: `AmazonSSMManagedInstanceCore`
4. Name the role (e.g. `ssminstancerole`) and create it

---

## Step 2: Attach the Role to Your EC2 Instance

1. Go to **EC2 → Instances** and select your instance
2. Click **Actions → Security → Modify IAM Role**
3. Select your role (`ssminstancerole`) and click **Update IAM Role**

---

## Step 3: Install and Start the SSM Agent

On Ubuntu, the SSM agent is typically installed via snap:

```bash
sudo snap install amazon-ssm-agent --classic
```

> If it's already installed, you'll see: `snap "amazon-ssm-agent" is already installed`

Start the agent and enable it on boot:
```bash
sudo snap start amazon-ssm-agent
sudo snap enable amazon-ssm-agent
```

Verify it's running:
```bash
sudo snap services amazon-ssm-agent
```

Expected output:
```
Service                            Startup  Current  Notes
amazon-ssm-agent.amazon-ssm-agent  enabled  active   -
```

> **Note:** On Ubuntu, the SSM agent runs as a snap service — not a systemd service. Using `systemctl` commands will fail. Always use `snap` commands instead.

---

## Step 4: Enable Default Host Management Configuration

This is a required account-level SSM setting. Without it, the agent will fail with:

```
AccessDeniedException: Systems Manager's instance management role is not configured for account
```

To fix it:

1. Go to **AWS Systems Manager → Fleet Manager**
2. Click **Account management** (top right)
3. Click **Configure Default Host Management Configuration**
4. **Enable** it and save

> This creates a service-linked role that allows SSM to manage instances in your account. You do **not** need to register a delegated administrator — that is only for AWS Organizations multi-account setups.

---

## Step 5: Verify Connectivity

From inside the instance, check that the SSM endpoint is reachable:
```bash
curl -I https://ssm.<your-region>.amazonaws.com
```

A `400 Bad Request` response is expected and means connectivity is working fine. The endpoint rejects raw HTTP requests but is reachable.

If the request hangs or times out, your instance likely lacks outbound internet access. You need either:
- A **public IP + Internet Gateway**, or
- Three **VPC Interface Endpoints**:
  - `com.amazonaws.<region>.ssm`
  - `com.amazonaws.<region>.ssmmessages`
  - `com.amazonaws.<region>.ec2messages`

---

## Step 6: Check Agent Logs

If the instance still doesn't appear in Session Manager, inspect the agent logs:
```bash
sudo snap logs amazon-ssm-agent.amazon-ssm-agent
```

### Common log errors and fixes

| Error | Cause | Fix |
|---|---|---|
| `no EC2 instance role found` | IAM role not attached | Re-attach role in EC2 → Actions → Security → Modify IAM Role |
| `AccessDeniedException: instance management role is not configured` | Default Host Management not enabled | See Step 4 |

### Successful log output looks like:
```
INFO EC2RoleProvider Successfully connected with instance profile role credentials
INFO [CredentialRefresher] Credentials ready
INFO [WorkerProvider] Worker ssm-agent-worker started
```

---

## Step 7: Connect via Session Manager

1. Go to **AWS Systems Manager → Session Manager** (make sure you're in the correct region)
2. Click **Start session**
3. Your instance should appear in the list
4. Select it and click **Start session**

> After starting the agent and attaching the role, it can take **2–5 minutes** for the instance to appear in the console.

### Default User

SSM logs you in as `ssm-user`, not `ubuntu`. Your files in `/home/ubuntu/` are still there — just switch user after connecting:

```bash
sudo su - ubuntu
```

### IAM Policy For Additional Users

To give permission to other users in your AWS account they need the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession",
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceProperties",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:TerminateSession",
        "ssm:ResumeSession"
      ],
      "Resource": "arn:aws:ssm:*:*:session/${aws:username}*"
    }
  ]
}
```

### IAM Policy For CI/CD

For deploying versions via sending ssm commands:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SSMSendCommand",
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations",
        "ssm:DescribeInstanceInformation"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2DescribeForSSM",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus"
      ],
      "Resource": "*"
    }
  ]
}
```

Or more tightened:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "SSMGetCommand",
			"Effect": "Allow",
			"Action": [
				"ssm:GetCommandInvocation",
				"ssm:ListCommandInvocations",
				"ssm:DescribeInstanceInformation"
			],
			"Resource": "*"
		},
		{
			"Sid": "EC2DescribeForSSM",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceStatus"
			],
			"Resource": "*"
		},
		{
			"Sid": "SSMSendCommand",
			"Effect": "Allow",
			"Action": [
				"ssm:SendCommand"
			],
			"Resource": [
				"arn:aws:ec2:<region>:<account-id>:instance/<instance-id>",
				"arn:aws:ssm:<region>::document/AWS-RunShellScript"
			]
		}
	]
}
```