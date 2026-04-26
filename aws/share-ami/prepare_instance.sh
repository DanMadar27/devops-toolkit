# 1. Remove authorized keys for both root and ubuntu users
sudo truncate -s 0 ~/.ssh/authorized_keys
sudo truncate -s 0 /root/.ssh/authorized_keys

# 2. Remove your shell history (so they can't see your commands)
cat /dev/null > ~/.bash_history && history -c

# 3. Securely remove the SSH host keys (they will be regenerated on next boot)
sudo rm -f /etc/ssh/ssh_host_*

# 4. Clear current session history
echo ""
echo "ACTION REQUIRED - run this in your terminal before disconnecting:"
echo "  cat /dev/null > ~/.bash_history && history -c"
