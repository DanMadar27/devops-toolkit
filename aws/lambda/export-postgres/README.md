# Export PostgreSQL Lambda

This lambda function export PostgreSQL DB into S3 bucket.

## Environment Variables

This lambda function uses AWS Secrets Manager to securely store and retrieve database credentials. You need to set the following environment variables:

### Required Environment Variables

- `DATABASE_SECRET_ID`: AWS Secrets Manager secret ID containing database credentials
- `S3_BUCKET_NAME`: The S3 bucket name where the database backup will be stored

### Optional Environment Variables

- `OUTPUT_DIR`: Local directory for temporary file storage (default: './output')
  - **Important for Lambda:** Set this to `/tmp/output` as Lambda only allows writing to the `/tmp` directory
- `AWS_REGION`: AWS region for the S3 bucket (default: 'eu-central-1')
- `S3_BUCKET_PATH`: Path within the S3 bucket (default: 'database/backup/')

### AWS Secrets Manager Configuration

The secret in AWS Secrets Manager should contain the following keys:

- `DB_NAME`: PostgreSQL database name
- `DB_USER`: PostgreSQL username
- `DB_PASSWORD`: PostgreSQL password
- `DB_HOST`: PostgreSQL host address
- `DB_PORT`: PostgreSQL port
- `DB_SSLMODE`: PostgreSQL SSL mode (default: 'require')

## Prerequisites

The Lambda function requires specific IAM permissions:

1. **Secrets Manager Permissions**: 
   - `secretsmanager:GetSecretValue` for the specific secret containing database credentials

2. **S3 Permissions**:
   - `s3:PutObject` permission for the target S3 bucket where backups will be stored

Ensure your Lambda execution role has these permissions properly configured before deployment.

## Test

Test using:

```bash
curl "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{}'
```

Or with payload:

```bash
curl "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'
```

## Scheduling Automated Backups

You can use Amazon EventBridge (formerly CloudWatch Events) to schedule regular database backups by triggering this Lambda function on a periodic basis.

### Setting Up an EventBridge Rule

1. **Navigate to EventBridge**: Open the AWS Management Console and go to the EventBridge service.

2. **Create a Rule**:
   - Choose "Create rule"
   - Enter a name and description for your rule

3. **Define Schedule Pattern**:
   - Select "Schedule" as the Rule type
   - Choose a fixed rate (e.g., 1 day for daily backups, 7 days for weekly backups)
   - Or use a cron expression for more specific scheduling:
     - Daily backup at 2 AM UTC: `cron(0 2 * * ? *)`
     - Weekly backup on Sunday at 3 AM UTC: `cron(0 3 ? * SUN *)`

4. **Select Target**:
   - Choose "Lambda function" as the target
   - Select your export-postgres Lambda function
   - Optionally configure input payload if needed

5. **Create the Rule**: Review your settings and create the rule

### Best Practices for Scheduled Backups

- **Timing**: Schedule backups during off-peak hours to minimize impact on database performance
- **Retention Policy**: Consider implementing a retention policy for your backups in S3 using lifecycle rules
- **Monitoring**: Set up CloudWatch alarms to notify you of any failures in the backup process
- **Testing**: Regularly test the restoration process from your backups to ensure they are valid

With this configuration, your PostgreSQL database will be automatically backed up to S3 according to your defined schedule without manual intervention.
