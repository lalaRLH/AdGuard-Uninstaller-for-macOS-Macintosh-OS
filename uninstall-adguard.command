#!/usr/bin/env bash

# ==========================================================
# AdGuard for macOS - Advanced Uninstaller Script
# Targets release: 2.18.0.2089-release & macOS Tahoe/Sequoia
# Use with caution. Execute with elevated permissions.
# ==========================================================

# Check if running with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: Please run this script with sudo."
  echo "    Usage: sudo bash uninstaller.sh"
  exit 1
fi

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
TTY_DEVICE="/dev/tty"

if [ ! -r "$TTY_DEVICE" ] || [ ! -w "$TTY_DEVICE" ]; then
  echo "[-] ERROR: This script needs an interactive terminal for confirmations." >&2
  echo "    Run it from Terminal, not from a background job or detached shell." >&2
  exit 1
fi

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

tty_line() {
  printf "%b\n" "$*" > "$TTY_DEVICE"
}

tty_write() {
  printf "%b" "$*" > "$TTY_DEVICE"
}

cleanup_prompt_ui() {
  printf '\033[?25h' > "$TTY_DEVICE" 2>/dev/null || true
}

abort_before_changes() {
  local message="$1"
  local code="${2:-0}"
  cleanup_prompt_ui
  tty_line ""
  tty_line "${YELLOW}${message}${NC}"
  tty_line ""
  tty_line "No changes were made. Go save your files."
  tty_line ""
  exit "$code"
}

prompt_from_tty() {
  local prompt="$1"
  local result_var="$2"

  tty_write "$prompt"
  IFS= read -r "$result_var" < "$TTY_DEVICE"
}

slow_type_line() {
  local text="$1"
  local delay="${2:-0.015}"
  local i

  for ((i = 0; i < ${#text}; i++)); do
    printf "%s" "${text:i:1}" > "$TTY_DEVICE"
    sleep "$delay"
  done
  printf "\n" > "$TTY_DEVICE"
}

show_native_warning() {
  local response

  command -v osascript >/dev/null 2>&1 || return 0

  response=$(osascript 2>/dev/null <<'APPLESCRIPT'
try
  set warningText to "This script removes AdGuard-related files and then reboots this Mac immediately when cleanup finishes." & return & return & "Save open documents and close anything important before continuing. There is no final confirmation at shutdown time."
  set clickedButton to button returned of (display alert "AdGuard uninstaller will reboot this Mac" message warningText as critical buttons {"Cancel", "I understand"} default button "I understand" cancel button "Cancel")
  return clickedButton
on error number -128
  return "CANCELLED"
on error
  return "UNAVAILABLE"
end try
APPLESCRIPT
)

  if [ "$response" = "CANCELLED" ]; then
    abort_before_changes "Cancelled from the macOS warning." 0
  fi
}

# ==========================================================
# WARNING & SAFETY COMPLIANCE
# ==========================================================

confirm_reboot_warning() {
  local REQUIRED_PHRASE="I SAVED MY FILES AND ACCEPT THE REBOOT"
  local CONFIRM
  local seconds

  trap 'abort_before_changes "Interrupted before removal." 130' INT TERM

  printf '\033[2J\033[H\033[?25l' > "$TTY_DEVICE"
  tty_line "${RED}${BOLD}"
  cat > "$TTY_DEVICE" <<'BANNER'
######################################################################
#                                                                    #
#                      STOP. SAVE YOUR FILES.                        #
#                                                                    #
#        THIS SCRIPT WILL REBOOT THIS MAC WHEN IT FINISHES.          #
#                                                                    #
######################################################################
BANNER
  tty_line "${NC}"

  slow_type_line "This script is about to remove AdGuard for macOS completely."
  slow_type_line "At the end, macOS reboots immediately. No bonus question. No dramatic second chance."
  slow_type_line "Unsaved work is not coming along for the ride."
  slow_type_line "If anything has a tiny unsaved dot, go deal with it now."
  tty_line ""
  tty_line "${BOLD}Target user:${NC} $TARGET_USER ($TARGET_HOME)"
  tty_line "${BOLD}Reboot behavior:${NC} shutdown -r now, after cleanup completes"
  tty_line ""

  show_native_warning

  tty_line "${YELLOW}${BOLD}Mandatory reading pause.${NC}"
  tty_line "${DIM}This is the speed bump. It is here because reboots and unsaved work are a tragic little sitcom.${NC}"
  tty_line ""

  for seconds in 5 4 3 2 1; do
    tty_write "\r  Confirmation unlocks in ${BOLD}${seconds}${NC} seconds. Read the warning, not your phone. "
    sleep 1
  done
  tty_line ""
  tty_line ""

  cleanup_prompt_ui
  tty_line "${RED}${BOLD}FINAL CONFIRMATION${NC}"
  tty_line "Type this exact sentence to continue:"
  tty_line ""
  tty_line "  ${BOLD}${REQUIRED_PHRASE}${NC}"
  tty_line ""

  if ! prompt_from_tty "  > " CONFIRM; then
    abort_before_changes "Could not read confirmation from the terminal." 1
  fi

  if [ "$CONFIRM" != "$REQUIRED_PHRASE" ]; then
    abort_before_changes "Confirmation did not match exactly." 0
  fi

  tty_line ""
  tty_line "${GREEN}${BOLD}Confirmed.${NC} Starting removal. The reboot happens at the end."
  tty_line ""
  sleep 1

  trap - INT TERM
}

confirm_reboot_warning

# ==========================================================
# REMOVAL PHASE
# ==========================================================

echo "[+] Terminating all active AdGuard processes..."
# Kill and wait for processes
pkill -9 -f "AdGuard" 2>/dev/null
pkill -9 "AdGuard" 2>/dev/null
pkill -9 "AdGuard Login Helper" 2>/dev/null
pkill -9 "AdGuard Assistant" 2>/dev/null
pkill -9 "com.adguard.mac.adguard.adguard-pac.daemon" 2>/dev/null
pkill -9 "com.adguard.mac.adguard.adguard-tun-helper.daemon" 2>/dev/null
sleep 1

# --- Remove System / Network Extensions ---
echo "[+] Scanning for AdGuard system extensions..."
ADGUARD_EXTS=$(systemextensionsctl list 2>/dev/null | grep -i "adguard" || true)

if [ -n "$ADGUARD_EXTS" ]; then
  tty_line ""
  tty_line "${YELLOW}${BOLD}AdGuard network/system extension detected:${NC}"
  printf "%s\n" "$ADGUARD_EXTS" > "$TTY_DEVICE"
  tty_line ""
  tty_line "${BOLD}${RED}⚠️ ATTENTION - TAHOE/SEQUOIA TOUCH ID VALIDATION:${NC}"
  tty_line "macOS WILL prompt for your admin password or Touch ID fingerprint to authorise"
  tty_line "the uninstallation of each extension. You MUST approve these GUI prompts"
  tty_line "when they appear. The script will wait until macOS completes the process."
  tty_line ""

  prompt_from_tty "  Remove these extensions now? [y/N] > " EXT_CONFIRM

  if [[ "$EXT_CONFIRM" =~ ^[Yy]$ ]]; then
    for BUNDLE_ID in \
      com.adguard.mac.adguard.network-extension \
      com.adguard.mac.adguard.adguard-tun-helper \
      com.adguard.mac.adguard.adguard-pac; do
      if systemextensionsctl list 2>/dev/null | grep -q "$BUNDLE_ID"; then
        tty_line "  Removing $BUNDLE_ID ..."
        # CRITICAL: Do NOT redirect stderr to /dev/null so user can see errors,
        # but let it run natively. macOS pops up a GUI prompt.
        systemextensionsctl uninstall TC3Q7MAJXF "$BUNDLE_ID" 
        
        if [ $? -eq 0 ]; then
          tty_line "  ${GREEN}✔ Successfully uninstalled $BUNDLE_ID${NC}"
        else
          tty_line "  ${YELLOW}⚠ Could not remove $BUNDLE_ID immediately.${NC}"
          tty_line "    (It will be marked for removal on reboot, or SIP must be disabled if it is completely stuck.)"
        fi
      fi
    done
    sleep 2
  else
    tty_line "${YELLOW}Skipped extension removal.${NC}"
  fi
else
  echo "[+] No AdGuard system extensions found."
fi

# --- Unload LaunchAgents (User-level automations) ---
echo "[+] Unloading user-level LaunchAgents..."
# LaunchAgents run as the user. We must run launchctl as the target user.
sudo -u "$TARGET_USER" launchctl unload "$TARGET_HOME/Library/LaunchAgents/com.adguard.mac.adguard.loginhelper.plist" 2>/dev/null
sudo -u "$TARGET_USER" launchctl unload "$TARGET_HOME/Library/LaunchAgents/com.adguard.mac.adguard.mac.update.plist" 2>/dev/null

# --- Unload LaunchDaemons (System-level automations) ---
echo "[+] Unloading system-level LaunchDaemons..."
[ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" 2>/dev/null
[ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" 2>/dev/null

# --- Remove App Bundle ---
echo "[+] Erasing AdGuard App bundle..."
rm -rf "/Applications/AdGuard.app" 2>/dev/null

# --- Remove Application Support files ---
echo "[+] Clearing config registries and application support files..."
rm -rf "/Library/Application Support/AdGuard Software" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
find "$TARGET_HOME/Library/Application Support" -name "com.adguard.browser_extension_host.nm.json" -delete 2>/dev/null
find "$TARGET_HOME/Library/Application Support" -name "com.adguard.*" -delete 2>/dev/null

# --- Clear logs and caches ---
echo "[+] Emptying log repositories, cookies, and cache items..."
rm -rf "/Library/Logs/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Caches/com.adguard.mac.adguard" 2>/dev/null
rm -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null
rm -f "$TARGET_HOME/Library/Cookies/com.adguard.mac.adguard.binarycookies" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Saved Application State/com.adguard.mac.adguard.savedState" 2>/dev/null

# Remove LaunchAgents & LaunchDaemons files
rm -f "$TARGET_HOME/Library/LaunchAgents/com.adguard.mac.adguard.loginhelper.plist" 2>/dev/null
rm -f "$TARGET_HOME/Library/LaunchAgents/com.adguard.mac.adguard.mac.update.plist" 2>/dev/null
rm -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" 2>/dev/null
rm -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" 2>/dev/null

# --- NUCLEAR MODE: Extra Cache and Settings Cleanup ---
echo "[+] NUCLEAR MODE: Purging additional sandboxed containers and webkits..."
rm -rf "$TARGET_HOME/Library/Containers/com.adguard.mac.adguard.network-extension" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Containers/com.adguard.mac.adguard.adguard-pac" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Containers/com.adguard.mac.adguard.adguard-tun-helper" 2>/dev/null
rm -rf "$TARGET_HOME/Library/WebKit/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/HTTPStorages/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/HTTPStorages/com.adguard.mac.adguard.binarycookies" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Logs/AdGuard" 2>/dev/null
# Clean Safari/App Store extension residual files if any
rm -rf "$TARGET_HOME/Library/Containers/com.adguard.mac.adguard" 2>/dev/null

# --- Remove Root CA certificates ---
echo "[+] Purging AdGuard security certificate profiles from Keychain..."
security delete-certificate -c "AdGuard Personal CA" /Library/Keychains/System.keychain 2>/dev/null
security delete-certificate -c "AdGuard Personal CA" "$TARGET_HOME/Library/Keychains/login.keychain-db" 2>/dev/null

# --- Flush cached memory defaults ---
echo "[+] Restarting cfprefsd process to flush cached preferences..."
killall -u "$TARGET_USER" cfprefsd 2>/dev/null

# --- Flush DNS Cache ---
echo "[+] Flushing system DNS cache..."
dscacheutil -flushcache
killall -HUP mDNSResponder

# --- Garbage Collect System Extensions ---
echo "[+] Garbage collecting orphaned network extensions..."
systemextensionsctl gc 2>/dev/null || true

# --- Reboot Machine ---
tty_line ""
tty_line "${GREEN}${BOLD}[✔] UNINSTALLATION COMPLETE AND CLEAN!${NC}"
tty_line "${YELLOW}Syncing disks and restarting macOS Tahoe... Bye!${NC}"
tty_line ""
sleep 2
sync
shutdown -r now "AdGuard uninstalled successfully."
