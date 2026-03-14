<br/>

![macOS](https://img.shields.io/badge/macOS-Monterey%2B-black?style=flat-square&logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square&color=30d158)
![Version](https://img.shields.io/badge/Tested-v2.14%20·%20v2.17%20·%20v2.18-blue?style=flat-square&color=0a84ff)
![Support](https://img.shields.io/badge/Support-None-critical?style=flat-square&color=ff453a)

<br/>

**A personal script for fully removing AdGuard from macOS.**  
Shared publicly in case it saves someone else the time. Nothing more.

</div>

---

## Disclaimer

> This script is provided **"as is"** without warranty of any kind. The author accepts no responsibility for data loss, system damage or any other consequence arising from its use. It runs with administrator privileges and removes files permanently. **Review it before running it. Use entirely at your own risk.**

---

## Usage

<br/>

### Within macOS terminal &nbsp;·&nbsp; One-liner (recommended)

No download. No Gatekeeper warning. Paste into Terminal and go.

```bash
curl -fsSL https://raw.githubusercontent.com/lalaRLH/AdGuard-Uninstaller-for-macOS-Macintosh-OS/main/uninstall-adguard.command | sudo bash
```

<br/>

<div align="center">

<img src="banner.svg" alt="AdGuard Uninstaller for macOS" width="100%"/>

<br/>

![Shell](https://img.shields.io/badge/Shell-Bash-informational?style=flat-square&logo=gnubash&logoColor=white&color=3a3a3c)

<br/>

---

## The Script

<details>
<summary>View <code>uninstall-adguard.command</code></summary>

<br/>

```bash
#!/bin/bash
# uninstall-adguard.command
# double-click to run — will ask for your password via gui prompt

if [ "$EUID" -ne 0 ]; then
    osascript -e "do shell script \"bash '$0'\" with administrator privileges"
    exit
fi

REAL_USER="${SUDO_USER:-$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && !/loginwindow/ { print $3 }' | head -1)}"

osascript -e 'display notification "Starting AdGuard removal..." with title "AdGuard Uninstaller"'

pkill -x "Adguard" 2>/dev/null || true
pkill -x "adguard-nm" 2>/dev/null || true
sleep 1

for plist in \
    "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist" \
    "/Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist" \
    "/Library/LaunchDaemons/com.adguard.mac.adguard.helper.plist"; do
    if [ -f "$plist" ]; then
        launchctl bootout "system/$(basename $plist .plist)" 2>/dev/null || launchctl unload "$plist" 2>/dev/null || true
    fi
done

for ext in "com.adguard.mac.adguard.network-extension" "com.adguard.mac.adguard.tunnel"; do
    systemextensionsctl list 2>/dev/null | grep -q "$ext" && \
        systemextensionsctl uninstall TC3Q7MAJXF "$ext" 2>/dev/null || true
    pluginkit -e ignore -i "$ext" 2>/dev/null || true
done

rm -rf /Applications/Adguard.app
rm -rf /Applications/AdGuard.app

rm -f /Library/LaunchDaemons/com.adguard.mac.adguard.adguard-pac.daemon.plist
rm -f /Library/LaunchDaemons/com.adguard.mac.adguard.adguard-tun-helper.daemon.plist
rm -f /Library/LaunchDaemons/com.adguard.mac.adguard.helper.plist

rm -rf "/Library/Application Support/AdGuard Software/com.adguard.mac.adguard"
rmdir "/Library/Application Support/AdGuard Software" 2>/dev/null || true
rm -rf "/Library/Application Support/com.adguard.mac.adguard"
rm -rf "/Library/Application Support/com.adguard.mac"
rm -rf "/Library/Logs/com.adguard.mac.adguard"

for home in $(find /Users -maxdepth 1 -mindepth 1 -type d ! -name Shared); do
    rm -rf "$home/Library/Group Containers/TC3Q7MAJXF.com.adguard.mac"
    rm -f  "$home/Library/Preferences/com.adguard.mac.adguard.plist"
    rm -f  "$home/Library/Preferences/com.adguard.Adguard.plist"
    rm -f  "$home/Library/Preferences/TC3Q7MAJXF.com.adguard.mac.plist"
    rm -rf "$home/Library/Application Support/com.adguard.mac.adguard"
    rm -rf "$home/Library/Caches/com.adguard.mac.adguard"
    rm -rf "$home/Library/Caches/TC3Q7MAJXF.com.adguard.mac"
    rm -rf "$home/Library/Saved Application State/com.adguard.mac.adguard.savedState"

    for nm_dir in \
        "$home/Library/Application Support/Google/Chrome/NativeMessagingHosts" \
        "$home/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts" \
        "$home/Library/Application Support/Microsoft Edge/NativeMessagingHosts" \
        "$home/Library/Application Support/Chromium/NativeMessagingHosts"; do
        rm -f "$nm_dir/com.adguard.browser_extension_host.nm.json" 2>/dev/null || true
    done

    for profile in $(find "$home/Library/Application Support/Firefox/Profiles" -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
        rm -f "$profile/native-messaging-hosts/com.adguard.browser_extension_host.nm.json"
    done
done

pkgutil --pkgs 2>/dev/null | grep -i adguard | while read receipt; do
    pkgutil --forget "$receipt" 2>/dev/null || true
done

pkill -u "$REAL_USER" -x cfprefsd 2>/dev/null || true

osascript -e 'display alert "AdGuard removed" message "All done. You can delete this file now."'
```

</details>

<br/>

---

## What gets removed

| Location | Contents |
|---|---|
| `/Applications/Adguard.app` | Main application |
| `/Library/LaunchDaemons/com.adguard.*` | PAC daemon · TUN helper · helper |
| `TC3Q7MAJXF.com.adguard.mac` | System/network extension |
| `~/Library/Group Containers/TC3Q7MAJXF.*` | All user data and settings |
| `~/Library/Preferences/com.adguard.*` | Preferences (all user accounts) |
| `~/Library/Caches/com.adguard.*` | Caches |
| `~/Library/Saved Application State/com.adguard.*` | Saved state |
| `/Library/Application Support/AdGuard Software/` | System-level app support |
| `/Library/Logs/com.adguard.*` | Logs |
| Browser `NativeMessagingHosts/` | Chrome · Brave · Edge · Firefox · Chromium |
| `pkgutil` receipts | `com.adguard.*` |

<br/>

---

## SIP

No SIP changes required. The network extension is removed via `systemextensionsctl` using AdGuard's team ID (`TC3Q7MAJXF`). If it reports `waiting for user` after the script completes, a reboot will finish the job.

---

## Notes

- Tested on **macOS Monterey 12** and later
- Covers AdGuard for Mac **v2.14.2**, **v2.17.0**, **v2.18.0**
- Runs against every local user account on the machine, not just the current one
- If something fails mid-run (usually AdGuard still running in the background), reboot and run again

---

<div align="center">

<sub>Personal hobby script · No support · No warranty · Not affiliated with AdGuard</sub>

</div>
