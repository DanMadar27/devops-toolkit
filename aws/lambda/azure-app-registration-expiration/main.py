import os
import json
import boto3
import requests
from azure.identity import ClientSecretCredential # type: ignore
from datetime import datetime, timezone

DAYS_UNTIL_EXPIRY_WARNING = int(os.environ.get('DAYS_UNTIL_EXPIRY_WARNING', '30'))
IGNORE_EXPIRED_SECRETS = os.environ.get('IGNORE_EXPIRED_SECRETS', 'false').lower() == 'true'

def normalize_iso_datetime(iso_string):
    """
    Normalize ISO datetime string from Microsoft Graph API.
    Handles variable fractional seconds precision (e.g., .24 vs .240000).
    """
    normalized = iso_string.replace('Z', '+00:00')
    
    if '.' in normalized and '+' in normalized:
        parts = normalized.split('.')
        fractional_and_tz = parts[1].split('+')
        fractional = fractional_and_tz[0].ljust(6, '0')[:6]
        normalized = f"{parts[0]}.{fractional}+{fractional_and_tz[1]}"
    
    return normalized

def send_slack_notification(message):
    """Send notification to Slack webhook"""
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    if not webhook_url:
        print("Warning: SLACK_WEBHOOK_URL not set, skipping Slack notification")
        return
    
    payload = {'text': message}
    try:
        response = requests.post(webhook_url, json=payload)
        response.raise_for_status()
        print("Slack notification sent successfully")
    except Exception as e:
        print(f"Failed to send Slack notification: {e}")

def get_secret(secret_name):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager')
    
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        return get_secret_value_response['SecretString']
    except Exception as e:
        print(f"Error retrieving secret {secret_name}: {e}")
        raise

def lambda_handler(event, context):
    # Azure App Credentials from AWS Secrets Manager (plaintext secrets)
    tenant_id_secret_name = os.environ.get('AZURE_TENANT_ID', 'azure-tenant-id')
    client_id_secret_name = os.environ.get('AZURE_CLIENT_ID', 'azure-client-id')
    client_secret_secret_name = os.environ.get('AZURE_CLIENT_SECRET', 'azure-client-secret')
    
    tenant_id = get_secret(tenant_id_secret_name)
    client_id = get_secret(client_id_secret_name)
    client_secret = get_secret(client_secret_secret_name)

    # 1. Get Access Token for MS Graph
    # Note: Use the app's own client_id and secret here
    cred = ClientSecretCredential(tenant_id, client_id, client_secret)
    token = cred.get_token("https://graph.microsoft.com/.default").token

    # 2. Query MS Graph for THIS specific app's details
    # We use the app's ID to fetch only its own passwordCredentials
    url = f"https://graph.microsoft.com/v1.0/applications(appId='{client_id}')"
    headers = {'Authorization': f'Bearer {token}'}
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    app_data = response.json()

    # 3. Check for the secret that matches your current one or check all
    secrets = app_data.get('passwordCredentials', [])
    current_time = datetime.now(timezone.utc)
    
    for secret in secrets:
        expiry_str = secret.get('endDateTime')
        expiry_date = datetime.fromisoformat(normalize_iso_datetime(expiry_str))
        days_until_expiry = (expiry_date - current_time).days
        
        print(f"Secret Hint: {secret.get('hint')} expires on {expiry_str}")
        print(f"Days until expiry: {days_until_expiry}")
        
        # Skip already expired secrets if IGNORE_EXPIRED_SECRETS is enabled
        if IGNORE_EXPIRED_SECRETS and days_until_expiry < 0:
            print(f"Skipping expired secret (hint: {secret.get('hint')})")
            continue
        
        # 4. Logic: Send Slack notification if expiration is close
        if days_until_expiry < DAYS_UNTIL_EXPIRY_WARNING:
            warning_message = f"⚠️ WARNING: Azure secret '{secret.get('displayName', 'N/A')}' (hint: {secret.get('hint')}) expires in {days_until_expiry} days! Expiry date: {expiry_str}"
            print(warning_message)
            send_slack_notification(warning_message)