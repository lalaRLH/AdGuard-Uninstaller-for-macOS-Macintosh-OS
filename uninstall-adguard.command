#!/usr/bin/env bash

# ==========================================================
# AdGuard for macOS - Cold & Blunt Uninstaller
# Now with "save your shit" option
# Targets: 2.18.0.2089-release
# ==========================================================

if [ "$EUID" -ne 0 ]; then
  echo "[-] Run with sudo, genius."
  echo "    sudo bash $0"
  exit 1
fi

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
TTY_DEVICE="/dev/tty"

if [ ! -r "$TTY_DEVICE" ] || [ ! -w "$TTY_DEVICE" ]; then
  echo "[-] Needs an interactive terminal. Don't be weird." >&2
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
# Cold & Blunt Warning (12 seconds)
# ==========================================================

confirm_reboot_warning() {
  local REQUIRED_PHRASE="i have saved my work"
  local CONFIRM

  trap 'abort_before_changes "Cancelled by user." 130' INT TERM

  printf '\033[2J\033[H\033[?25l' > "$TTY_DEVICE"

  tty_line "${RED}${BOLD}ADGUARD UNINSTALLER - COLD MODE${NC}"
  tty_line ""
  tty_line "This deletes AdGuard then force-reboots your Mac."
  tty_line "Save your shit or lose it. Not my problem."
  tty_line "Skill issue if you cry about it later."
  tty_line ""
  tty_line "${YELLOW}You have 12 seconds after typing the phrase.${NC}"
  tty_line ""
  tty_line "Type exactly: ${GREEN}${BOLD}${REQUIRED_PHRASE}${NC}"
  tty_line ""

  tty_write "> "
  IFS= read -r CONFIRM < "$TTY_DEVICE"

  if [ "$CONFIRM" != "$REQUIRED_PHRASE" ]; then
    abort_before_changes "Wrong phrase, dumbass." 0
  fi

  tty_line ""
  tty_line "${GREEN}Good. Timer starting.${NC}"
  sleep 0.8

  for s in 12 11 10 9 8 7 6 5 4 3 2 1; do
    tty_write "\r${YELLOW}Rebooting in ${s} seconds...${NC}  "
    sleep 1
  done

  tty_line "\n\n${RED}Too late now.${NC}"
  sleep 0.6
  trap - INT TERM
}

confirm_reboot_warning

# ==========================================================
# Backup Option (new)
# ==========================================================

BACKUP_DIR=""
tty_line ""
tty_write "${YELLOW}Backup your custom rules, filters & settings before I nuke them? (y/N): ${NC}"
read -r BACKUP_CHOICE < "$TTY_DEVICE"

if [[ "$BACKUP_CHOICE" =~ ^[Yy]$ ]]; then
    BACKUP_DIR="$TARGET_HOME/Desktop/AdGuard_Backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo "[+] Backing up your precious data..."
    cp -a "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" "$BACKUP_DIR/" 2>/dev/null || true
    cp -a "$TARGET_HOME/Library/Application Support/AdGuard" "$BACKUP_DIR/" 2>/dev/null || true
    cp -a "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" "$BACKUP_DIR/" 2>/dev/null || true
    
    cat > "$BACKUP_DIR/RESTORE_INSTRUCTIONS.txt" << 'EOF'
=== AdGuard Backup - Restore Instructions ===

1. Install fresh AdGuard from the official website.
2. Completely quit AdGuard (including from menu bar).
3. Copy these folders from this backup:

   • com.adguard.mac.adguard  →  ~/Library/Application Support/
   • AdGuard                  →  ~/Library/Application Support/
   • TC3Q7MAJXF.com.adguard.mac → ~/Library/Group Containers/

4. Launch AdGuard. Your rules, filters, exceptions and license should be back.

Pro tip: If it doesn't pick them up, replace the folders while AdGuard is closed.
EOF

    tty_line "${GREEN}Backup saved to:${NC} $BACKUP_DIR"
    tty_line "Check RESTORE_INSTRUCTIONS.txt inside it."
else
    tty_line "${YELLOW}No backup. Hope you exported your rules, champ.${NC}"
fi

# ==========================================================
# Actual Uninstall
# ==========================================================

echo "[+] Killing AdGuard processes..."
pkill -9 -f "AdGuard" 2>/dev/null
pkill -9 "AdGuard Login Helper" 2>/dev/null
pkill -9 "AdGuard Assistant" 2>/dev/null

echo "[+] Unloading daemons..."
launchctl unload /Library/LaunchDaemons/com.adguard.mac.adguard.*.plist 2>/dev/null

echo "[+] Deleting files..."
rm -rf "/Applications/AdGuard.app" 2>/dev/null
rm -rf "/Library/Application Support/AdGuard Software" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Caches/com.adguard.mac.adguard" 2>/dev/null
rm -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null

echo "[+] Cleaning certificates..."
security delete-certificate -c "AdGuard Personal CA" /Library/Keychains/System.keychain 2>/dev/null
security delete-certificate -c "AdGuard Personal CA" "$TARGET_HOME/Library/Keychains/login.keychain-db" 2>/dev/null

echo "[+] Restarting prefs daemon..."
killall -u "$TARGET_USER" cfprefsd 2>/dev/null

echo ""
echo "${GREEN}AdGuard has been removed.${NC}"
if [ -n "$BACKUP_DIR" ]; then
    echo "${GREEN}Your data is on the Desktop.${NC}"
fi
echo "${YELLOW}Rebooting now like we warned you.${NC}"
echo ""

sync
shutdown -r now "AdGuard successfully yeeted."
