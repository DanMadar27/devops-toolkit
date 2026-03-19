# Ansible

Ansible is an automation language that can describe any IT environment, whether homelab or large scale infrastructure (such as many EC2 instances).

---

## Inventory — `.ini` format

```ini
# inventory.ini

# A standalone host
mail.example.com

# A group called [webservers]
[webservers]
web1.example.com
web2.example.com ansible_user=ubuntu

# A group called [databases]
[databases]
db1.example.com ansible_port=2222

# Variables for a whole group
[webservers:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa

# A group of groups
[production:children]
webservers
databases
```

### Key host variables

| Variable | What it does |
|---|---|
| `ansible_host` | IP or hostname to connect to |
| `ansible_user` | SSH username |
| `ansible_port` | SSH port (default 22) |
| `ansible_ssh_private_key_file` | Path to `.pem` key |
| `ansible_become` | Enable sudo (`true`/`false`) |
| `ansible_python_interpreter` | Python path on remote host |

### Inventory in YAML (alternative)

```yaml
# inventory.yml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
          ansible_user: ubuntu
        web2.example.com:
    databases:
      hosts:
        db1.example.com:
          ansible_port: 2222
```

---

## Playbook syntax — fully annotated

```yaml
---                          # Every YAML file starts with ---
# This is a play
- name: Configure web servers   # Human-readable name (shows in output)
  hosts: webservers              # Target: an inventory group or "all"
  become: true                   # Run tasks as sudo/root
  vars:                          # Variables scoped to this play
    app_port: 8080
    app_user: www-data

  tasks:                         # Ordered list of tasks

    - name: Install Nginx        # Task name (shown in run output)
      apt:                       # Module name
        name: nginx              # Module parameter
        state: present           # present = install, absent = remove
        update_cache: yes

    - name: Create config file
      template:                  # Jinja2 template module
        src: nginx.conf.j2       # Local template file
        dest: /etc/nginx/nginx.conf
        owner: root
        mode: '0644'
      notify: Restart Nginx      # Trigger a handler when this changes

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: true            # Start on boot

    - name: Create app user
      user:
        name: "{{ app_user }}"   # Variable interpolation with {{ }}
        shell: /bin/bash
        state: present

  handlers:                      # Run only when notified, and only once
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

---

## Variables

```yaml
# In a playbook
vars:
  app_version: "1.4.2"

# From an external file
vars_files:
  - vars/production.yml

# Passed at runtime
# ansible-playbook playbook.yml -e "app_version=2.0"
```

---

## Conditionals — `when`

```yaml
- name: Install on Debian only
  apt:
    name: curl
    state: present
  when: ansible_os_family == "Debian"

- name: Install on RedHat only
  yum:
    name: curl
    state: present
  when: ansible_os_family == "RedHat"
```

---

## Loops

```yaml
- name: Install multiple packages
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - git
    - curl
    - python3
```

---

## Register — capture task output

```yaml
- name: Check if file exists
  stat:
    path: /etc/myapp/config.yml
  register: config_file

- name: Show result
  debug:
    msg: "Config exists: {{ config_file.stat.exists }}"
```

---

## Ansible Vault — encrypt secrets

```bash
# Encrypt a whole file
ansible-vault encrypt vars/secrets.yml

# Encrypt a single value (paste into your vars)
ansible-vault encrypt_string 'mysecretpassword' --name db_password

# Run a playbook that uses vault
ansible-playbook playbook.yml --ask-vault-pass
```

---

## Roles — directory structure

```
my_project/
├── inventory.ini
├── playbook.yml
└── roles/
    └── nginx/
        ├── tasks/
        │   └── main.yml      ← task list goes here
        ├── handlers/
        │   └── main.yml      ← handlers go here
        ├── templates/
        │   └── nginx.conf.j2 ← Jinja2 templates
        ├── files/
        │   └── index.html    ← static files to copy
        ├── vars/
        │   └── main.yml      ← role variables
        └── defaults/
            └── main.yml      ← low-priority default vars
```

### Using roles in a playbook

```yaml
- name: Setup web servers
  hosts: webservers
  roles:
    - nginx
    - nodejs
    - myapp
```

---

## CLI

```bash
# Test connectivity first
ansible -i inventory.ini webservers -m ping

# Run the playbook
ansible-playbook -i inventory.ini playbook.yml

# Dry run (no changes applied)
ansible-playbook -i inventory.ini playbook.yml --check

# Run with sudo password
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
# Run with extra variable
ansible-playbook -i inventory.ini playbook.yml -e "app_version=2.0"

# Run with vault password prompt
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass

# Run only tasks with a specific tag
ansible-playbook -i inventory.ini playbook.yml --tags "nginx"

# Run ad-hoc command on all hosts
ansible -i inventory.ini all -m shell -a "uptime"

# Gather facts from a host
ansible -i inventory.ini webservers -m setup

# Install a role from Ansible Galaxy
ansible-galaxy install geerlingguy.nginx

# Init a new role scaffold
ansible-galaxy init myrole

# Use dynamic AWS inventory
ansible-playbook -i inventory.aws_ec2.yml playbook.yml
```