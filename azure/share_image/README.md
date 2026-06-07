# Prepare VM (Azure Marketplace)

`prepare_vm.sh` runs **on an Azure Linux VM** to scrub secrets and identity-specific data, then deprovisions the Azure agent — so the VM is ready to capture as an image for the marketplace.

> **Tip:** Run this on a fresh VM created from your image (or a base image) rather than a live one, so your original VM stays untouched.

## Usage

Copy the script to the VM, then run it as the last thing before capturing:

```bash
sudo bash prepare_vm.sh

# Preview changes without applying them:
sudo bash prepare_vm.sh --dry-run

# Keep Microsoft Defender installed (skip mdatp removal):
sudo bash prepare_vm.sh --keep-defender

# Full reset — also delete the admin user and its home directory:
sudo bash prepare_vm.sh --delete-user

# If your admin user is not `azureuser`:
sudo ADMIN_USER=myadmin bash prepare_vm.sh
```

> **Do not log back into the VM after running the script** — logging in recreates host keys, shell history and user state.

## What it does

| Step | Action |
|---|---|
| SSH authorized keys | Truncates `authorized_keys` for the admin user and root |
| Admin password | Deletes and locks the admin password so no password is baked into the image |
| SSH host keys | Removes `/etc/ssh/ssh_host_*` (regenerated on first boot) |
| Shell history | Truncates `.bash_history` / `.zsh_history` for the admin user and root |
| Microsoft Defender | Offboards and uninstalls `mdatp`, removes onboarding config and `client_analyzer` |
| Azure agent | Runs `waagent -deprovision -force` (keeps user home; `--delete-user` switches to `-deprovision+user`) |

> By default it runs `waagent -deprovision` (**not** `+user`), keeping the admin user and its home directory — useful when you leave data/app files under `/home/<admin>`. Pass `--delete-user` to also wipe the user and home.

## Common errors

### A password already exists on the admin account

Marketplace publishing requires the image to ship with no admin password:

```bash
sudo passwd -d azureuser     # delete the password
sudo passwd -l azureuser     # lock the account
sudo grep azureuser /etc/shadow   # verify the hash field shows ! or *
```

### Microsoft Defender (mdatp) onboarding baked into the image

Defender's onboarding identity is per-tenant and must not ship in a shared image. Leftover EICAR test files or the `client_analyzer` directory can also break antivirus.

```bash
# Offboard first
sudo mdatp config real-time-protection --value disabled
sudo /opt/microsoft/mdatp/sbin/wdavdaemon offboard

# Uninstall the package
sudo apt-get purge mdatp -y      # Debian/Ubuntu
sudo yum remove mdatp -y         # RHEL/CentOS

# Remove leftover config / onboarding files
sudo rm -rf /etc/opt/microsoft/mdatp /var/opt/microsoft/mdatp

# Validate (should return 0)
curl -o mdatp_check.sh https://aka.ms/mdatp-check-sh
chmod +x mdatp_check.sh
sudo ./mdatp_check.sh

# If antivirus still misbehaves, remove the client analyzer:
sudo rm -rf /opt/microsoft/mdatp/tools/client_analyzer
```

`prepare_vm.sh` performs all the removal steps above (the `mdatp_check.sh` validation is left manual).
