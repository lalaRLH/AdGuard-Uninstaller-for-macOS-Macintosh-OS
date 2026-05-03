#!/usr/bin/env bash

# ==========================================================
# AdGuard macOS - Combined Advanced Management Utility
# Handles 1. Advanced Removal + User Backup to /Users/Shared/AdGuard_Backup
# Handles 2. Direct Reinstallation + State Restore from Backup
# Built for GitHub direct execution.
# ==========================================================

# Check if running with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: Please run this script with sudo."
  echo "    Usage: sudo bash script.sh"
  exit 1
fi

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
TTY_DEVICE="/dev/tty"

if [ ! -r "$TTY_DEVICE" ] || [ ! -w "$TTY_DEVICE" ]; then
  echo "[-] ERROR: This script needs an interactive terminal." >&2
  exit 1
fi

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

tty_line() {
  printf "%b\n" "$*" > "$TTY_DEVICE"
}

tty_write() {
  printf "%b" "$*" > "$TTY_DEVICE"
}

prompt_from_tty() {
  local prompt="$1"
  local result_var="$2"

  tty_write "$prompt"
  IFS= read -r "$result_var" < "$TTY_DEVICE"
}

# --- REMOVAL LOGIC ---
perform_removal() {
  local REQUIRED_PHRASE="YES"
  local CONFIRM
  
  tty_line "${RED}${BOLD}"
  cat > "$TTY_DEVICE" <<'BANNER'
######################################################################
#                         UNINSTALL MODE                             #
######################################################################
BANNER
  tty_line "${NC}"

  tty_line "${YELLOW}This will completely remove AdGuard and back up configurations to /Users/Shared/AdGuard_Backup.\n${NC}"
  prompt_from_tty "Proceed with uninstallation? Type '${REQUIRED_PHRASE}' to confirm: " CONFIRM

  if [ "$CONFIRM" != "${REQUIRED_PHRASE}" ]; then
    tty_line "${YELLOW}Action cancelled.${NC}"
    return
  fi

  # Terminate processes
  echo "[+] Terminating all active AdGuard processes..."
  pkill -9 -f "AdGuard" 2>/dev/null
  pkill -9 "AdGuard" 2>/dev/null
  pkill -9 "AdGuard Login Helper" 2>/dev/null
  pkill -9 "com.adguard.mac.adguard.adguard-pac.daemon" 2>/dev/null
  sleep 1

  # Create state backup to disk
  tty_line "[+] Backing up config files to ${BOLD}/Users/Shared/AdGuard_Backup${NC} ..."
  mkdir -p "/Users/Shared/AdGuard_Backup"

  [ -d "/Library/Application Support/AdGuard Software" ] && cp -R "/Library/Application Support/AdGuard Software" "/Users/Shared/AdGuard_Backup/Application Support_System" 2>/dev/null
  [ -d "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" ] && cp -R "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" "/Users/Shared/AdGuard_Backup/Application Support_User" 2>/dev/null
  [ -d "$TARGET_HOME/Library/Application Support/AdGuard" ] && cp -R "$TARGET_HOME/Library/Application Support/AdGuard" "/Users/Shared/AdGuard_Backup/Application Support_User_Legacy" 2>/dev/null
  [ -d "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" ] && cp -R "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" "/Users/Shared/AdGuard_Backup/Group Containers" 2>/dev/null
  [ -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" ] && cp "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" "/Users/Shared/AdGuard_Backup/" 2>/dev/null

  # Restore write ownership back to user
  chown -R "$TARGET_USER" "/Users/Shared/AdGuard_Backup" 2>/dev/null
  tty_line "  ${GREEN}✔ Config successfully backed up.${NC}"

  # Remove System/Network Extensions
  
  echo "[+] Scanning for AdGuard system extensions..."
  ADGUARD_EXTS=$(systemextensionsctl list 2>/dev/null | grep -i "AdGuard" || true)

  if [ -n "$ADGUARD_EXTS" ]; then
    tty_line "${BOLD}${RED}⚠️ ATTENTION:${NC} Touch ID / GUI password may prompt to remove extensions."
    for BUNDLE_ID in \
      com.adguard.mac.adguard.network-extension \
      com.adguard.mac.adguard.adguard-tun-helper; do
      if systemextensionsctl list 2>/dev/null | grep -q "$BUNDLE_ID"; then
        systemextensionsctl uninstall TC3Q7MAJXF "$BUNDLE_ID"
      fi
    done
    sleep 1
  fi
  

  # Remove launch configurations
  
  echo "[+] Unloading user-level LaunchAgents & system-level LaunchDaemons..."
  sudo -u "$TARGET_USER" launchctl unload "$TARGET_HOME/Library/LaunchAgents/com.adguard.mac.adguard.loginhelper.plist" 2>/dev/null
  sudo -u "$TARGET_USER" launchctl unload "$TARGET_HOME/Library/LaunchAgents/com.adguard.mac.adguard.update.plist" 2>/dev/null
  [ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" 2>/dev/null
  

  # Remove App Bundle & purge source directories
  echo "[+] Erasing AdGuard App bundle..."
  rm -rf "/Applications/AdGuard.app" 2>/dev/null

  echo "[+] Purging application support and preferences..."
  rm -rf "/Library/Application Support/AdGuard Software" 2>/dev/null
  rm -rf "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
  rm -rf "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
  rm -rf "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
  find "$TARGET_HOME/Library/Application Support" -name "com.adguard.*" -delete 2>/dev/null

  # Clear logs and caches
  rm -rf "/Library/Logs/com.adguard.mac.adguard" 2>/dev/null
  rm -rf "$TARGET_HOME/Library/Caches/com.adguard.mac.adguard" 2>/dev/null
  rm -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null
  rm -f "$TARGET_HOME/Library/Cookies/com.adguard.mac.adguard.binarycookies" 2>/dev/null
  rm -rf "$TARGET_HOME/Library/Saved Application State/com.adguard.mac.adguard.savedState" 2>/dev/null

  
  echo "[+] Purging AdGuard root security certificates..."
  security delete-certificate -c "AdGuard Personal CA" /Library/Keychains/System.keychain 2>/dev/null
  security delete-certificate -c "AdGuard Personal CA" "$TARGET_HOME/Library/Keychains/login.keychain-db" 2>/dev/null
  

  echo "[+] Restarting cfprefsd process to flush cached preferences..."
  killall -u "$TARGET_USER" cfprefsd 2>/dev/null

  
  echo "[+] Flushing system DNS cache..."
  dscacheutil -flushcache
  killall -HUP mDNSResponder
  

  # Final cleanup systemextensionsctl gc
  systemextensionsctl gc 2>/dev/null || true

  tty_line ""
  tty_line "${GREEN}${BOLD}[✔] COMPLETE REMOVAL SUCCESSFUL!${NC}"
  reboot
}

# --- REINSTALL LOGIC ---
perform_reinstall() {
  local DMG_URL="https://github.com/AdguardTeam/AdguardForMac/releases/download/v2.18.0/AdGuard-2.18.0.2089-release.dmg"
  local DMG_PATH="/tmp/AdGuard-Release.dmg"

  tty_line "${GREEN}${BOLD}"
  cat > "$TTY_DEVICE" <<'BANNER'
######################################################################
#                         REINSTALL MODE                             #
######################################################################
BANNER
  tty_line "${NC}"

  tty_line "[+] Downloading AdGuard from official GitHub releases..."
  curl -L -o "$DMG_PATH" "$DMG_URL"

  if [ $? -ne 0 ]; then
    tty_line "${RED}[-] ERROR: Download failed from the release link.${NC}"
    return
  fi

  tty_line "[+] Mounting downloaded package image..."
  # Disconnect previous if there's any
  hdiutil detach "/Volumes/AdGuard" 2>/dev/null || true
  hdiutil detach "/Volumes/AdGuard Installer" 2>/dev/null || true
  
  # Attach directly
  local MOUNT_OUTPUT=$(hdiutil attach -nobrowse -noautoopen "$DMG_PATH" 2>/dev/null)
  local MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep -o "/Volumes/.*" | head -n 1)

  if [ -z "$MOUNT_DIR" ]; then
    MOUNT_DIR=$(df | grep "/Volumes/" | grep -i "adguard" | awk -F'  +' '{print $NF}' | head -n 1)
  fi

  if [ -z "$MOUNT_DIR" ]; then
    if [ -d "/Volumes/AdGuard" ]; then
      MOUNT_DIR="/Volumes/AdGuard"
    elif [ -d "/Volumes/AdGuard Installer" ]; then
      MOUNT_DIR="/Volumes/AdGuard Installer"
    else
      MOUNT_DIR=$(df | grep "/Volumes/" | tail -n 1 | awk -F'  +' '{print $NF}')
    fi
  fi

  if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
    tty_line "${RED}[-] ERROR: Could not resolve the mounted volume path.${NC}"
    rm -f "$DMG_PATH"
    return
  fi

  tty_line "[+] Volume discovered at: ${MOUNT_DIR}"

  # Discover all available .app or .pkg packages inside the volume
  local APP_PATH=$(find "$MOUNT_DIR" -maxdepth 2 -name "*.app" | head -n 1)
  local PKG_PATH=$(find "$MOUNT_DIR" -maxdepth 2 -name "*.pkg" | head -n 1)

  if [ -n "$PKG_PATH" ]; then
    tty_line "[+] Running direct silent installation using installer utility..."
    installer -pkg "$PKG_PATH" -target /
  elif [ -n "$APP_PATH" ]; then
    local APP_NAME=$(basename "$APP_PATH")
    tty_line "[+] ${APP_NAME} found inside the volume."

    # Since it's a full installer DMG, run 'open' directly as root to execute it.
    tty_line "[+] Launching installation from mounted DMG..."
    open -W "$APP_PATH"
  else
    tty_line "${RED}[-] ERROR: No executable binaries found inside mounted DMG.${NC}"
  fi

  tty_line "[+] Detaching mounted DMG image..."
  hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
  rm -f "$DMG_PATH"

  # Restore backup if available
  if [ -d "/Users/Shared/AdGuard_Backup" ]; then
    tty_line "[+] Restoring backed up files from /Users/Shared/AdGuard_Backup..."

    [ -d "/Users/Shared/AdGuard_Backup/Application Support_System" ] && cp -R "/Users/Shared/AdGuard_Backup/Application Support_System" "/Library/Application Support/AdGuard Software" 2>/dev/null
    [ -d "/Users/Shared/AdGuard_Backup/Application Support_User" ] && cp -R "/Users/Shared/AdGuard_Backup/Application Support_User" "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
    [ -d "/Users/Shared/AdGuard_Backup/Application Support_User_Legacy" ] && cp -R "/Users/Shared/AdGuard_Backup/Application Support_User_Legacy" "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
    [ -d "/Users/Shared/AdGuard_Backup/Group Containers" ] && cp -R "/Users/Shared/AdGuard_Backup/Group Containers" "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
    [ -f "/Users/Shared/AdGuard_Backup/com.adguard.mac.adguard.plist" ] && cp "/Users/Shared/AdGuard_Backup/com.adguard.mac.adguard.plist" "$TARGET_HOME/Library/Preferences/" 2>/dev/null

    # Enforce read/write accessibility corrections
    chown -R "$TARGET_USER" "/Library/Application Support/AdGuard Software" 2>/dev/null
    chown -R "$TARGET_USER" "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
    chown -R "$TARGET_USER" "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
    chown -R "$TARGET_USER" "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
    [ -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" ] && chown "$TARGET_USER" "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null

    tty_line "  ${GREEN}✔ Config state successfully restored.${NC}"
  else
    tty_line "${YELLOW}[!] No backup directory found at /Users/Shared/AdGuard_Backup. Standard fresh configuration remains.${NC}"
  fi

  # Clear cached preferences
  killall -u "$TARGET_USER" cfprefsd 2>/dev/null

  tty_line ""
  tty_line "${GREEN}${BOLD}[✔] COMPLETE REINSTALLATION SUCCESSFUL!${NC}"
}

# --- MENU ROUTER ---
clear
tty_line "${BOLD}Choose your script task for AdGuard on this Mac:${NC}"
tty_line "  1) Advanced Uninstallation (Backup state to /Users/Shared/AdGuard_Backup)"
tty_line "  2) Full Reinstall & Restore (Pulls DMG from releases + restores state)"
tty_line "  3) Sequential Cycle (Run uninstallation then immediate fresh reinstallation)"
tty_line "  4) Exit without making changes"
tty_line ""

while true; do
  prompt_from_tty "Enter choice [1, 2, 3, or 4]: " OPT_CHOICE
  case "$OPT_CHOICE" in
    1)
      perform_removal
      break
      ;;
    2)
      perform_reinstall
      break
      ;;
    3)
      perform_removal
      perform_reinstall
      break
      ;;
    4)
      tty_line "${YELLOW}Closing without adjustments. Bye!${NC}"
      exit 0
      ;;
    *)
      tty_line "${RED}Invalid option. Enter 1, 2, 3, or 4.${NC}"
      ;;
  esac
done
