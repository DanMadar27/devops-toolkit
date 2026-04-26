# EC2 Configuration with Docker compose

This setup include Ansible playbook that installs docker compose with a git repository.

## Prerequisites

- Git Access Token

## Getting Started

1. Ensure your SSH key has correct permissions: `chmod 400 /path/to/your-key.pem`
2. Configure `inventory.ini` with public IP of EC2
3. Copy `vars.example.yml` to `vars.yml` and make proper changes.
4. Run the playbook:

    ```bash
    ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
    ```