# EC2 Configuration with Docker compose

This setup include Ansible playbook that installs docker compose with a git repository.

## Prerequisites

- Git Access Token

## Getting Started

1. Configure `inventory.ini` with public IP of EC2
2. Copy `vars.example.yml` to `vars.yml` and make proper changes.
3. Run the playbook:

    ```bash
    ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
    ```