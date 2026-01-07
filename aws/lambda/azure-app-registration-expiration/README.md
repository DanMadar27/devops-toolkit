# Azure App Registration Expiration Monitor

This Lambda function monitors Azure App Registration secrets for expiration and sends Slack notifications when secrets are about to expire.

## Environment Variables

### Required Environment Variables

- `AZURE_TENANT_ID`: Name of the AWS Secrets Manager secret containing the Azure AD Tenant ID (plaintext, default: `azure-tenant-id`)
- `AZURE_CLIENT_ID`: Name of the AWS Secrets Manager secret containing the Azure App Registration Client ID (plaintext, default: `azure-client-id`)
- `AZURE_CLIENT_SECRET`: Name of the AWS Secrets Manager secret containing the Azure App Registration Client Secret (plaintext, default: `azure-client-secret`)
- `SLACK_WEBHOOK_URL`: Slack webhook URL for notifications

### Optional Environment Variables

- `DAYS_UNTIL_EXPIRY_WARNING`: Number of days before expiration to trigger warning (default: 30)
- `IGNORE_EXPIRED_SECRETS`: Skip warnings for already expired secrets (default: `false`). Useful when expired secrets are not always deleted immediately from Azure, preventing noise in notifications

## Prerequisites

The Lambda function requires:

1. **Azure App Registration Permissions**: 
   - The app must have `Application.Read.All` permission in Microsoft Graph API
   - Admin consent must be granted for this permission

2. **AWS Secrets Manager**:
   - Create three plaintext secrets in AWS Secrets Manager:
     - `azure-tenant-id`: Contains your Azure AD Tenant ID
     - `azure-client-id`: Contains your Azure App Registration Client ID
     - `azure-client-secret`: Contains your Azure App Registration Client Secret
   - Set the secret names as environment variables (or use the defaults above)
   - Ensure the Lambda execution role has `secretsmanager:GetSecretValue` permission for all three secrets

3. **Slack Webhook**:
   - Create an incoming webhook in your Slack workspace
   - Set the webhook URL as the `SLACK_WEBHOOK_URL` environment variable

## Building and Deploying

### Build Docker Image

```bash
docker build -t azure-app-registration-expiration .
```

### Test Locally

```bash
docker run -p 9000:8080 \
  -e AZURE_TENANT_ID="azure-tenant-id" \
  -e AZURE_CLIENT_ID="azure-client-id" \
  -e AZURE_CLIENT_SECRET="azure-client-secret" \
  -e SLACK_WEBHOOK_URL="your-slack-webhook-url" \
  -e DAYS_UNTIL_EXPIRY_WARNING="30" \
  -e IGNORE_EXPIRED_SECRETS="false" \
  -e AWS_ACCESS_KEY_ID="your-aws-access-key" \
  -e AWS_SECRET_ACCESS_KEY="your-aws-secret-key" \
  -e AWS_DEFAULT_REGION="us-east-1" \
  azure-app-registration-expiration
```

**Note**: For local testing, you need to provide AWS credentials so the function can access Secrets Manager.

Test the function:

```bash
curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```

### Deploy to AWS ECR and Lambda

1. **Create ECR Repository**:
```bash
aws ecr create-repository --repository-name azure-app-registration-expiration --region us-east-1
```

2. **Authenticate Docker to ECR**:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com
```

3. **Tag and Push Image**:
4. **Create Lambda Function**:
   - Use the pushed ECR image as the function source
   - Set environment variables in Lambda configuration:
     - `AZURE_TENANT_ID`: Name of the secret containing tenant ID (default: `azure-tenant-id`)
     - `AZURE_CLIENT_ID`: Name of the secret containing client ID (default: `azure-client-id`)
     - `AZURE_CLIENT_SECRET`: Name of the secret containing client secret (default: `azure-client-secret`)
     - `SLACK_WEBHOOK_URL`: Your Slack webhook URL
     - `DAYS_UNTIL_EXPIRY_WARNING`: Optional, defaults to 30
     - `IGNORE_EXPIRED_SECRETS`: Optional, defaults to `false`. Set to `true` to suppress warnings about expired secrets
   - Configure timeout (recommended: 30 seconds)
   - Assign appropriate IAM role with the following permissions:
     - `secretsmanager:GetSecretValue` for all three secrets containing Azure credentials
     - Basic Lambda execution permissions

## Scheduling Automated Checks

Use Amazon EventBridge to schedule regular secret expiration checks.

### Setting Up an EventBridge Rule

1. **Navigate to EventBridge** in AWS Console

2. **Create a Rule**:
   - Enter a name: `azure-secret-expiration-check`
   - Description: "Check Azure app registration secrets daily"

3. **Define Schedule Pattern**:
   - Daily check at 9 AM UTC: `cron(0 9 * * ? *)`
   - Weekly check on Monday at 9 AM UTC: `cron(0 9 ? * MON *)`
### Best Practices

- **Timing**: Schedule checks at regular intervals (daily or weekly)
- **Monitoring**: Set up CloudWatch alarms for Lambda failures
- **Secrets Management**: All Azure credentials (tenant ID, client ID, and client secret) are securely stored in AWS Secrets Manager as plaintext
- **Testing**: Test the function manually before relying on scheduled runs

## Troubleshooting

- **Authentication Errors**: Verify Azure credentials are correct and have proper permissions
- **Slack Notifications Not Sent**: Check `SLACK_WEBHOOK_URL` is valid and webhook is active
- **No Secrets Found**: Ensure the app registration has password credentials configured
