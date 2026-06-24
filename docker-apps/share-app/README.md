# Share App

This folder contain scripts for sharing the app with on-premises environments.
It works with the `linux-instance-config` folder configuration.

## Pre Requisites:

- Docker compose installed on VM.
- Policies and roles

### Policies & Roles

Prerequisites: IAM role for EC2 and permissions for the deployer that we use his access keys.

Create a policy `SendCommand`:

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
				"arn:aws:ec2:eu-west-1:<account-id>:instance/<instance-id>",
				"arn:aws:ssm:eu-west-1::document/AWS-RunShellScript"
			]
		}
	]
}
```

Create a policy `ReadWriteS3`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPresignedURLGeneration",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "<your-s3-bucket-arn>/*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "<your-s3-bucket-arn>"
        }
    ]
}
```

Give `SendCommand` and `ReadWriteS3` policies to deployer user.
Give `AmazonSSMManagedInstanceCore` and `ReadWriteS3` policies to the role attached to EC2.

## Getting Started

- Connect to EC2 using SSM 

- Run the export script:
```bash
bash ~/infrastructure/share-app/export.sh <version> <s3-bucket> [--presign]
# e.g.
bash ~/infrastructure/share-app/export.sh 1.2.3 my-project-bucket
bash ~/infrastructure/share-app/export.sh 1.2.3 my-project-bucket --presign
```

The script will:
1. Export all Docker images to `project-<version>/project-images.tar.gz`
2. Copy ` (excluding `.env`), replacing `docker-compose.override.yml` with the one from `share-app/`
3. Compress everything into `project-<version>.tar.gz` and upload to S3
4. *(With `--presign`)* Print a presigned URL valid for 7 days