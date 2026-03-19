# Ansible Basic Demo

## Getting Started

Test connectivity:

```bash
ansible -i inventory.ini webservers -m ping
```

Run the playbook:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

Clean resources:

```bash
ansible-playbook -i inventory.ini cleanup.yml --ask-become-pass
```