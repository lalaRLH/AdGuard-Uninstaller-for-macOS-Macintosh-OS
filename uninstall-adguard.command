#!/usr/bin/env bash

# ==========================================================
# AdGuard for macOS - Advanced Uninstaller Script
# Targets release: 2.18.0.2089-release
# Use with caution. Execute with elevated permissions.
# ==========================================================

# Check if running with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: Please run this script with sudo."
  echo "    Usage: sudo bash uninstaller.sh"
  exit 1
fi

# ==========================================================
# WARNING
# ==========================================================

echo ""
echo "  This script will reboot your Mac. No warning. No countdown."
echo "  It just does it."
echo ""
echo "  Save your files. Close your stuff. Then press RETURN."
echo ""
read -r -p "  → Press RETURN if you understand: "

echo ""
echo "  Type YES to confirm you saved everything."
echo "  If you lose your work, that's on you."
echo "  This script told you. Twice."
echo ""
read -r -p "  → Type YES: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo ""
  echo "  Go save your files."
  echo ""
  exit 0
fi

echo ""
# ==========================================================

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

# --- Kill Running Processes ---
echo "[+] Terminating all active AdGuard processes..."
pkill -9 -f "AdGuard" 2>/dev/null
pkill -9 "AdGuard" 2>/dev/null
pkill -9 "AdGuard Login Helper" 2>/dev/null
pkill -9 "AdGuard Assistant" 2>/dev/null
pkill -9 "com.adguard.mac.adguard.adguard-pac.daemon" 2>/dev/null
pkill -9 "com.adguard.mac.adguard.adguard-tun-helper.daemon" 2>/dev/null

# --- Unload LaunchDaemons ---
echo "[+] Unloading launchd automation entries..."
[ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" 2>/dev/null
[ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" 2>/dev/null

# --- Remove App Bundle ---
echo "[+] Erasing AdGuard App bundle..."
rm -rf "/Applications/AdGuard.app" 2>/dev/null

# --- Remove Application Support files ---
echo "[+] Clearing config registries..."
rm -rf "/Library/Application Support/AdGuard Software" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
find "$TARGET_HOME/Library/Application Support" -name "com.adguard.browser_extension_host.nm.json" -delete 2>/dev/null
find "$TARGET_HOME/Library/Application Support" -name "com.adguard.*" -delete 2>/dev/null

# --- Clear logs and caches ---
echo "[+] Emptying log repositories and storage items..."
rm -rf "/Library/Logs/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Caches/com.adguard.mac.adguard" 2>/dev/null
rm -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null
rm -f "$TARGET_HOME/Library/Cookies/com.adguard.mac.adguard.binarycookies" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Saved Application State/com.adguard.mac.adguard.savedState" 2>/dev/null

# --- Remove Root CA certificates ---
echo "[+] Purging security certificate profiles from Keychain..."
security delete-certificate -c "AdGuard Personal CA" /Library/Keychains/System.keychain 2>/dev/null
security delete-certificate -c "AdGuard Personal CA" "$TARGET_HOME/Library/Keychains/login.keychain-db" 2>/dev/null

# --- Flush cached memory defaults ---
echo "[+] Restarting cfprefsd process..."
killall -u "$TARGET_USER" cfprefsd 2>/dev/null

# --- Reboot Machine ---
echo "[+] Uninstallation clean! Restarting OS..."
sync
shutdown -r now "AdGuard uninstalled successfully."
