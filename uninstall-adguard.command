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

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
TTY_DEVICE="/dev/tty"

if [ ! -r "$TTY_DEVICE" ] || [ ! -w "$TTY_DEVICE" ]; then
  echo "[-] ERROR: This script needs an interactive terminal for the reboot confirmation." >&2
  echo "    Run it from Terminal, not from a background job or detached shell." >&2
  exit 1
fi

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
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
  tty_line "${GREEN}${message}${NC}"
  tty_line ""
  tty_line "No changes were made to your system."
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
  local delay="${2:-0.020}"
  local i

  for ((i = 0; i < ${#text}; i++)); do
    printf "%s" "${text:i:1}" > "$TTY_DEVICE"
    sleep "$delay"
  done
  printf "\n" > "$TTY_DEVICE"
}

show_native_warning() {
  command -v osascript >/dev/null 2>&1 || return 0

  local response
  response=$(osascript 2>/dev/null <<'APPLESCRIPT'
try
  set warningText to "This script will restart your Mac automatically upon completion." & return & return & "There will be no additional prompts or confirmation dialogs." & return & return & "Please ensure all work is saved before proceeding."
  set clickedButton to button returned of (display alert "System Restart Required" message warningText as warning buttons {"Cancel", "I Understand"} default button "I Understand" cancel button "Cancel")
  return clickedButton
on error number -128
  return "CANCELLED"
on error
  return "UNAVAILABLE"
end try
APPLESCRIPT
)

  if [ "$response" = "CANCELLED" ]; then
    abort_before_changes "Operation cancelled. Probably the right call." 0
  fi
}

# ==========================================================
# Pre-execution confirmation
# ==========================================================

confirm_reboot_warning() {
  local REQUIRED_PHRASE="i have saved my work"
  local CONFIRM
  local seconds

  trap 'abort_before_changes "Operation cancelled by user." 130' INT TERM

  printf '\033[2J\033[H\033[?25l' > "$TTY_DEVICE"
  
  tty_line "${YELLOW}${BOLD}"
  cat > "$TTY_DEVICE" <<'BANNER'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                  AdGuard Uninstaller for macOS                   ║
║                                                                  ║
║                  (automatic reboot upon completion)              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
BANNER
  tty_line "${NC}"
  sleep 0.5

  show_native_warning

  tty_line ""
  slow_type_line "Right, so here's how this works." 0.025
  sleep 0.4
  slow_type_line "This script will completely remove AdGuard from your system." 0.022
  sleep 0.5
  slow_type_line "When it finishes, your Mac will restart automatically." 0.022
  sleep 0.8
  tty_line ""
  slow_type_line "Not after asking permission." 0.022
  slow_type_line "Not after a polite countdown." 0.022
  slow_type_line "It just restarts." 0.022
  sleep 1
  tty_line ""
  slow_type_line "${BOLD}Why?${NC} Because system-level component removal requires a clean boot cycle" 0.022
  slow_type_line "to properly release kernel extensions and network filters." 0.022
  slow_type_line "This is standard practice for this type of software." 0.022
  sleep 1
  tty_line ""
  tty_line "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  tty_line ""
  slow_type_line "If you have any unsaved work—documents, code, emails, browser tabs," 0.022
  slow_type_line "half-written thoughts, whatever—this would be an excellent moment" 0.022
  slow_type_line "to address that situation." 0.022
  sleep 1
  tty_line ""
  slow_type_line "${BOLD}Command+S is your friend here.${NC}" 0.030
  slow_type_line "Most people remember to use it. Most." 0.022
  sleep 1.5

  slow_type_line "Do not respond to Mandy, Kevin, Jaden, Angela, Chase or" 0.026
  slow_type_line "whoever's blowing up your DM's . Instead save your unsaved files." 0.036
  slow_type_line "If you still do not save your work. Any data loss is on you." 0.034
  slow_type_line "You are not a victim if you ignore all of these warnings!!! " 0.044
  tty_line "...........................................................lets go"
  sleep 1
  
  tty_line "${CYAN}${BOLD}Mandatory review period:${NC}"
  tty_line ""

  for seconds in 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1; do
    if [ "$seconds" -eq 10 ]; then
      tty_line ""
      tty_line "${DIM}(ten seconds left—still time to Command+Tab over and save things)${NC}"
      tty_line ""
    fi
    
    if [ "$seconds" -eq 5 ]; then
      tty_line ""
      tty_line "${YELLOW}(final moments to reconsider your save-file situation)${NC}"
      tty_line ""
    fi
    
    local dots=""
    case $((seconds % 3)) in
      0) dots="..." ;;
      1) dots=".  " ;;
      2) dots=".. " ;;
    esac
    
    tty_write "\r  ${CYAN}${seconds}s${NC} remaining ${dots} "
    sleep 1
  done
  
  tty_line ""
  tty_line ""
  sleep 0.4
  
  cleanup_prompt_ui
  
  tty_line "${BOLD}Alright.${NC}"
  tty_line ""
  slow_type_line "For confirmation purposes, please type the following phrase exactly:" 0.022
  tty_line ""
  tty_line "  ${GREEN}${BOLD}${REQUIRED_PHRASE}${NC}"
  tty_line ""
  tty_line "${DIM}(copy-paste works fine if typing isn't your thing)${NC}"
  tty_line ""

  if ! prompt_from_tty "> " CONFIRM; then
    abort_before_changes "Unable to read terminal input." 1
  fi

  tty_line ""

  if [ "$CONFIRM" != "$REQUIRED_PHRASE" ]; then
    tty_line "${YELLOW}That doesn't match, unfortunately.${NC}"
    tty_line ""
    tty_line "  Expected: ${GREEN}${REQUIRED_PHRASE}${NC}"
    tty_line "  Received: ${RED}${CONFIRM}${NC}"
    tty_line ""
    tty_line "${DIM}(precision matters for confirmation prompts)${NC}"
    sleep 2
    abort_before_changes "Confirmation phrase mismatch. Operation cancelled." 0
  fi

  tty_line "${GREEN}Confirmed.${NC}"
  tty_line ""
  sleep 0.4
  tty_line "Proceeding with removal."
  tty_line "${YELLOW}Your Mac will restart when this completes.${NC}"
  tty_line ""
  tty_line "${DIM}(Ctrl+C still works right now if you suddenly remembered something unsaved)${NC}"
  sleep 2
  tty_line ""

  trap - INT TERM
}

confirm_reboot_warning
# ==========================================================

# --- Kill Running Processes ---
echo "[+] Terminating AdGuard processes..."
pkill -9 -f "AdGuard" 2>/dev/null
pkill -9 "AdGuard" 2>/dev/null
pkill -9 "AdGuard Login Helper" 2>/dev/null
pkill -9 "AdGuard Assistant" 2>/dev/null
pkill -9 "com.adguard.mac.adguard.adguard-pac.daemon" 2>/dev/null
pkill -9 "com.adguard.mac.adguard.adguard-tun-helper.daemon" 2>/dev/null

# --- Unload LaunchDaemons ---
echo "[+] Unloading launch daemons..."
[ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" 2>/dev/null
[ -f "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" ] && launchctl unload "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" 2>/dev/null

# --- Remove App Bundle ---
echo "[+] Removing application bundle..."
rm -rf "/Applications/AdGuard.app" 2>/dev/null

# --- Remove Application Support files ---
echo "[+] Clearing application data..."
rm -rf "/Library/Application Support/AdGuard Software" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Application Support/AdGuard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac" 2>/dev/null
find "$TARGET_HOME/Library/Application Support" -name "com.adguard.browser_extension_host.nm.json" -delete 2>/dev/null
find "$TARGET_HOME/Library/Application Support" -name "com.adguard.*" -delete 2>/dev/null

# --- Clear logs and caches ---
echo "[+] Removing logs and caches..."
rm -rf "/Library/Logs/com.adguard.mac.adguard" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Caches/com.adguard.mac.adguard" 2>/dev/null
rm -f "$TARGET_HOME/Library/Preferences/com.adguard.mac.adguard.plist" 2>/dev/null
rm -f "$TARGET_HOME/Library/Cookies/com.adguard.mac.adguard.binarycookies" 2>/dev/null
rm -rf "$TARGET_HOME/Library/Saved Application State/com.adguard.mac.adguard.savedState" 2>/dev/null

# --- Remove Root CA certificates ---
echo "[+] Removing certificates from keychain..."
security delete-certificate -c "AdGuard Personal CA" /Library/Keychains/System.keychain 2>/dev/null
security delete-certificate -c "AdGuard Personal CA" "$TARGET_HOME/Library/Keychains/login.keychain-db" 2>/dev/null

# --- Flush cached memory defaults ---
echo "[+] Restarting preferences daemon..."
killall -u "$TARGET_USER" cfprefsd 2>/dev/null

# --- Reboot Machine ---
echo ""
echo "${GREEN}Removal complete.${NC}"
echo ""
echo "${YELLOW}Initiating system restart as previously indicated.${NC}"
echo ""
echo "${DIM}(hopefully you saved everything important)${NC}"
echo ""
sleep 2

sync
shutdown -r now "AdGuard uninstalled. System restart in progress."
