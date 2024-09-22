# Lambda

## Environment Variables

Use these:

- DB_NAME
- DB_USER
- DB_PASSWORD
- DB_HOST
- DB_PORT
- OUTPUT_DIR
- S3_BUCKET_NAME
- AWS_REGION
- S3_BUCKET_PATH

## Test

Test using:

```bash
curl "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{}'
```

Or with payload:

```bash
curl "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'
```
