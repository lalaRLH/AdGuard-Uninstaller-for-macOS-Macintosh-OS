#!/usr/bin/env bash

# ==========================================================
# ADGUARD ADVANCED UNINSTALLER
# Optional backup of user data. Automatic reboot.
# Targets: 2.18.0.2089-release
# ==========================================================

if [ "$EUID" -ne 0 ]; then
  echo "[-] This script must be run with sudo."
  echo "    sudo bash $0"
  exit 1
fi

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
TTY_DEVICE="/dev/tty"

if [ ! -r "$TTY_DEVICE" ] || [ ! -w "$TTY_DEVICE" ]; then
  echo "[-] This script requires an interactive terminal." >&2
  exit 1
fi

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
NC=$'\033[0m'

tty_line() { printf "%b\n" "$*" > "$TTY_DEVICE"; }
tty_write() { printf "%b" "$*" > "$TTY_DEVICE"; }
cleanup_prompt_ui() { printf '\033[?25h' > "$TTY_DEVICE" 2>/dev/null || true; }

abort_before_changes() {
  cleanup_prompt_ui
  tty_line ""
  tty_line "${GREEN}${1}${NC}"
  tty_line ""
  tty_line "No changes were made."
  exit "${2:-0}"
}

# ==========================================================
# Confirmation + Backup + Countdown
# ==========================================================

confirm_reboot_warning() {
  local REQUIRED_PHRASE="i have saved my work"
  local CONFIRM

  trap 'abort_before_changes "Cancelled by user." 130' INT TERM

  printf '\033[2J\033[H\033[?25l' > "$TTY_DEVICE"

  tty_line "${RED}${BOLD}ADGUARD ADVANCED UNINSTALLER${NC}"
  tty_line ""
  tty_line "This will remove AdGuard and restart your Mac automatically."
  tty_line "Save all work now. Restart cannot be stopped after confirmation."
  tty_line ""
  tty_line "Type exactly: ${GREEN}${BOLD}${REQUIRED_PHRASE}${NC}"
  tty_line ""

  tty_write "> "
  IFS= read -r CONFIRM < "$TTY_DEVICE"

  if [ "$CONFIRM" != "$REQUIRED_PHRASE" ]; then
    abort_before_changes "Confirmation phrase did not match." 0
  fi

  trap - INT TERM
}

confirm_reboot_warning

# ==========================================================
# Backup Option (now before countdown)
# ==========================================================

BACKUP_DIR=""
tty_line ""
tty_write "${YELLOW}Backup custom rules, filters and settings first? (y/N): ${NC}"
read -r BACKUP_CHOICE < "$TTY_DEVICE"

if [[ "$BACKUP_CHOICE" =~ ^[Yy]$ ]]; then
    BACKUP_DIR="$TARGET_HOME/Desktop/AdGuard_Backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo "[+] Creating backup..."
    cp -a "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" "$BACKUP_DIR/" 2>/dev/null || true
    cp -a "$TARGET_HOME/Library/Application Support/AdGuard" "$BACKUP_DIR/" 2>/dev/null || true
    cp -a "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" "$BACKUP_DIR/" 2>/dev/null || true
    
    cat > "$BACKUP_DIR/RESTORE_INSTRUCTIONS.txt" << 'EOF'
AdGuard Backup - Restore Instructions

1. Install a fresh copy of AdGuard.
2. Quit AdGuard completely.
3. Copy these folders from the backup:

   • com.adguard.mac.adguard  →  ~/Library/Application Support/
   • AdGuard                  →  ~/Library/Application Support/
   • TC3Q7MAJXF.com.adguard.mac → ~/Library/Group Containers/

4. Start AdGuard. Your rules and settings should return.

Replace the folders while AdGuard is fully closed for best results.
EOF

    tty_line "${GREEN}Backup saved to:${NC} $BACKUP_DIR"
    tty_line "See RESTORE_INSTRUCTIONS.txt inside."
else
    tty_line "${YELLOW}No backup created.${NC}"
fi

# ==========================================================
# Final Warning + Countdown
# ==========================================================

tty_line ""
tty_line "${RED}${BOLD}Last chance.${NC}"
tty_line "The next step will uninstall AdGuard and reboot immediately."
tty_line "Press Ctrl+C now if you want to stop."
tty_line ""
sleep 1.5

trap 'abort_before_changes "Cancelled by user." 130' INT TERM

tty_line "${YELLOW}Starting 12-second countdown.${NC}"
sleep 0.8

for s in 12 11 10 9 8 7 6 5 4 3 2 1; do
    tty_write "\r${YELLOW}Restarting in ${s} seconds...${NC}   "
    sleep 1
done

tty_line "\n\n${RED}Restart initiated.${NC}"
sleep 0.6
trap - INT TERM

# ==========================================================
# Uninstall
# ==========================================================

echo "[+] Stopping AdGuard processes..."
pkill -9 -f "AdGuard" 2>/dev/null
pkill -9 "AdGuard Login Helper" 2>/dev/null
pkill -9 "AdGuard Assistant" 2>/dev/null

echo "[+] Unloading launch agents..."
launchctl unload /Library/LaunchDaemons/com.adguard.mac.adguard.*.plist 2>/dev/null

echo "[+] Removing files..."
rm -rf "/Applications/AdGuard.app" 2>/dev/null
rm -rf "/Library/Application Support/AdGuard Software" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Caches/com.adguard.mac.adguard" 2>/dev/null
rm -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null

echo "[+] Removing certificates..."
security delete-certificate -c "AdGuard Personal CA" /Library/Keychains/System.keychain 2>/dev/null
security delete-certificate -c "AdGuard Personal CA" "$TARGET_HOME/Library/Keychains/login.keychain-db" 2>/dev/null

echo "[+] Restarting preferences daemon..."
killall -u "$TARGET_USER" cfprefsd 2>/dev/null

echo ""
echo "${GREEN}AdGuard removal complete.${NC}"
if [ -n "$BACKUP_DIR" ]; then
    echo "${GREEN}Backup saved to Desktop.${NC}"
fi
echo "${YELLOW}System restart starting now.${NC}"
echo ""

sync
shutdown -r now "AdGuard removed. Restarting."
