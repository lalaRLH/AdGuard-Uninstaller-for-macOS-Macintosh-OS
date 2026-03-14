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
