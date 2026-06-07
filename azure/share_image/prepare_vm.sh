#!/usr/bin/env bash
#
# prepare_vm.sh — scrub an Azure Linux VM before capturing it as a
# managed image / shared image gallery version for the marketplace.
#
# Run this ON THE VM, as the last thing you do before deallocating and
# generalizing it. After it finishes, DO NOT log back in (logging in
# recreates host keys, history and user state). Deallocate and generalize
# the VM from the Azure CLI / portal instead.
#
# Usage:
#   sudo bash prepare_vm.sh                 # scrub + deprovision (keeps user home)
#   sudo bash prepare_vm.sh --dry-run       # print actions without running them
#   sudo bash prepare_vm.sh --keep-defender # skip Microsoft Defender removal
#   sudo bash prepare_vm.sh --delete-user   # also delete the admin user + home dir
#
# By default we run `waagent -deprovision` (NOT +user), which keeps the admin
# user account and its home directory — useful when you intentionally leave
# data/app files under /home/<admin>. Pass --delete-user for a full reset.
#
set -euo pipefail

ADMIN_USER="${ADMIN_USER:-azureuser}"
DRY_RUN=false
REMOVE_DEFENDER=true
DELETE_USER=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=true ;;
    --keep-defender)  REMOVE_DEFENDER=false ;;
    --delete-user)    DELETE_USER=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]] && ! $DRY_RUN; then
  echo "This script must be run as root (use sudo)." >&2
  exit 1
fi

# run CMD... — execute, or just print when --dry-run is set.
run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    echo "  + $*"
    "$@"
  fi
}

echo "==> Preparing Azure VM for image capture (admin user: ${ADMIN_USER})"
$DRY_RUN && echo "    DRY RUN — no changes will be made"

# 1. Remove SSH authorized keys for the admin user and root.
echo "[1/6] Removing SSH authorized keys"
for home in "/home/${ADMIN_USER}" /root; do
  keys="${home}/.ssh/authorized_keys"
  [[ -f "$keys" ]] && run truncate -s 0 "$keys"
done

# 2. Clear and lock the admin password so the captured image has no
#    pre-existing password (a leftover password blocks marketplace
#    publishing / cloud-init reprovisioning).
echo "[2/6] Clearing and locking the ${ADMIN_USER} password"
if id "$ADMIN_USER" &>/dev/null; then
  run passwd -d "$ADMIN_USER"   # delete the password
  run passwd -l "$ADMIN_USER"   # lock the account
  $DRY_RUN || grep "$ADMIN_USER" /etc/shadow || true  # expect ! or * in the hash field
fi

# 3. Remove SSH host keys (regenerated on first boot of each new VM,
#    preventing host-key reuse across customer deployments).
echo "[3/6] Removing SSH host keys"
run bash -c 'rm -f /etc/ssh/ssh_host_*'

# 4. Clear shell history for root and the admin user.
echo "[4/6] Clearing shell history"
for home in "/home/${ADMIN_USER}" /root; do
  for hist in "${home}/.bash_history" "${home}/.zsh_history"; do
    [[ -f "$hist" ]] && run truncate -s 0 "$hist"
  done
done

# 5. Offboard and remove Microsoft Defender for Endpoint (mdatp), if present.
#    A baked-in onboarding identity is per-tenant and must not ship in the
#    image; leftover EICAR test files / client_analyzer can also break AV.
if $REMOVE_DEFENDER; then
  echo "[5/6] Removing Microsoft Defender for Endpoint (mdatp)"
  if command -v mdatp &>/dev/null || [[ -d /opt/microsoft/mdatp ]]; then
    run bash -c 'mdatp config real-time-protection --value disabled || true'
    [[ -x /opt/microsoft/mdatp/sbin/wdavdaemon ]] && \
      run /opt/microsoft/mdatp/sbin/wdavdaemon offboard || true

    if command -v apt-get &>/dev/null; then
      run apt-get purge mdatp -y
    elif command -v yum &>/dev/null; then
      run yum remove mdatp -y
    fi

    run bash -c 'rm -rf /etc/opt/microsoft/mdatp'
    run bash -c 'rm -rf /var/opt/microsoft/mdatp'
    run bash -c 'rm -rf /opt/microsoft/mdatp/tools/client_analyzer'
  else
    echo "  (mdatp not installed — skipping)"
  fi
else
  echo "[5/6] Skipping Microsoft Defender removal (--keep-defender)"
fi

# 6. Deprovision the Azure agent. This is the Azure-specific generalize step:
#    it clears cached DHCP/hostname state, nameserver config and waagent state
#    so a fresh identity is created on first boot.
#    Default keeps the admin user + home dir (-deprovision). --delete-user
#    switches to -deprovision+user, which also deletes the user and its home.
if $DELETE_USER; then
  deprovision_arg="-deprovision+user"
  echo "[6/6] Deprovisioning the Azure Linux agent (waagent, deleting ${ADMIN_USER} + home)"
else
  deprovision_arg="-deprovision"
  echo "[6/6] Deprovisioning the Azure Linux agent (waagent, keeping ${ADMIN_USER} home)"
fi
if command -v waagent &>/dev/null; then
  run waagent "$deprovision_arg" -force
else
  echo "  WARNING: waagent not found — install walinuxagent or run" >&2
  echo "           'sudo waagent ${deprovision_arg} -force' manually." >&2
fi

echo
echo "==> Done."
echo "    DO NOT log back into this VM."
echo "    Next: from your workstation, deallocate and generalize it:"
echo "      az vm deallocate -g <rg> -n <vm>"
echo "      az vm generalize -g <rg> -n <vm>"
