# Azure App Registration Expiration Monitor

This Lambda function monitors Azure App Registration secrets for expiration and sends Slack notifications when secrets are about to expire.

## Environment Variables

### Required Environment Variables

- `AZURE_TENANT_ID`: Azure AD Tenant ID
- `AZURE_CLIENT_ID`: Azure App Registration Client ID
- `AZURE_CLIENT_SECRET`: Azure App Registration Client Secret
- `SLACK_WEBHOOK_URL`: Slack webhook URL for notifications

### Optional Environment Variables

- `DAYS_UNTIL_EXPIRY_WARNING`: Number of days before expiration to trigger warning (default: 30)

## Prerequisites

The Lambda function requires:

1. **Azure App Registration Permissions**: 
   - The app must have `Application.Read.All` permission in Microsoft Graph API
   - Admin consent must be granted for this permission

2. **Slack Webhook**:
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
  -e AZURE_TENANT_ID="your-tenant-id" \
  -e AZURE_CLIENT_ID="your-client-id" \
  -e AZURE_CLIENT_SECRET="your-client-secret" \
  -e SLACK_WEBHOOK_URL="your-slack-webhook-url" \
  -e DAYS_UNTIL_EXPIRY_WARNING="30" \
  azure-app-registration-expiration
```

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
```bash
docker tag azure-app-registration-expiration:latest <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/azure-app-registration-expiration:latest
docker push <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/azure-app-registration-expiration:latest
```

4. **Create Lambda Function**:
   - Use the pushed ECR image as the function source
   - Set environment variables in Lambda configuration
   - Configure timeout (recommended: 30 seconds)
   - Assign appropriate IAM role

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

4. **Select Target**:
   - Choose "Lambda function"
   - Select your `azure-app-registration-expiration` function

5. **Create the Rule**

### Best Practices

- **Timing**: Schedule checks at regular intervals (daily or weekly)
- **Monitoring**: Set up CloudWatch alarms for Lambda failures
- **Secrets Management**: Consider using AWS Secrets Manager to store Azure credentials
- **Testing**: Test the function manually before relying on scheduled runs

## Troubleshooting

- **Authentication Errors**: Verify Azure credentials are correct and have proper permissions
- **Slack Notifications Not Sent**: Check `SLACK_WEBHOOK_URL` is valid and webhook is active
- **No Secrets Found**: Ensure the app registration has password credentials configured
