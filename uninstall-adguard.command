#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

BACKUP_DIR="$TARGET_HOME/AdGuard-backup-2026-05-03_0340"

read -r -p "Backup user files and settings before removal? [Y/n] " choice
case "$choice" in
  [Nn]*) DO_BACKUP=0 ;;
  *)      DO_BACKUP=1 ;;
esac

# Backup mode: the archive is created before removal begins.

if [ "$DO_BACKUP" -eq 1 ]; then
  mkdir -p "$BACKUP_DIR"
  while IFS= read -r item; do
    [ -e "$item" ] || continue
    cp -R "$item" "$BACKUP_DIR/"
  done <<'EOF'
    "$HOME/Library/Application Support/com.adguard.mac.adguard"
    "$HOME/Library/Application Support/AdGuard"
    "$HOME/Library/Preferences/com.adguard.mac.adguard.plist"
    "$HOME/Library/LaunchAgents/com.adguard.mac.adguard.loginhelper.plist"
    "$HOME/Library/LaunchAgents/com.adguard.mac.adguard.mac.update.plist"
    "$HOME/Library/Caches/com.adguard.mac.adguard"
EOF
  tar -czf "$BACKUP_DIR/AdGuard-user-files.tar.gz" -C "$BACKUP_DIR" .
  chown -R "$TARGET_USER" "$BACKUP_DIR"
fi

while IFS= read -r item; do
  rm -rf "$item"
done <<'EOF'
    "/Applications/AdGuard.app"
    "/Library/Application Support/AdGuard Software"
    "$HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac"
    "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist"
    "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist"
EOF
