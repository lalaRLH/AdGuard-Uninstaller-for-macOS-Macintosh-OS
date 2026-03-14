# AdGuard Uninstaller for macOS / Macintosh OS

A personal script written for my own use. Published here in case it saves someone else the time it took me to put it together. That is the full extent of this repository.

## Disclaimer

**BY DOWNLOADING OR RUNNING THIS SCRIPT YOU AGREE TO THE FOLLOWING:**

This script is provided "as is", without warranty of any kind, express or implied. The author accepts no responsibility or liability for any loss, damage, data loss, system damage or any other consequence — direct or indirect — arising from the use or misuse of this script. This includes but is not limited to damage to hardware, software, files or data.

This script executes with administrator privileges and removes files from your system. You are solely responsible for reviewing what it does before running it and for any outcome that results from running it. The author makes no representation that this script is suitable for any particular purpose, will work on your system, or will produce any specific result.

**Use entirely at your own risk.**

---

## Usage

Download `uninstall-adguard.command` and double-click it. macOS will prompt for your password.

If macOS blocks the file on first run, right-click → Open → Open. Or strip the quarantine flag first:

```bash
xattr -d com.apple.quarantine uninstall-adguard.command
```

To run without downloading at all:

```bash
curl -fsSL https://raw.githubusercontent.com/lalaRLH/AdGuard-Uninstaller-for-macOS-Macintosh-OS/main/uninstall-adguard.command | sudo bash
```

## What it does

Removes AdGuard for Mac completely — the application, LaunchDaemons, network/system extension, all user data, preferences, caches, browser native messaging hosts and package receipts. Tested against v2.14.2, v2.17.0 and v2.18.0 on macOS Monterey and later.

No SIP changes required. If the network extension reports "waiting for user" after running, a reboot will complete its removal.

---

## Support

This repository is not actively maintained and does not provide support of any kind. Issues, pull requests and all other forms of contribution or contact are disabled. If the script doesn't work for you, you are welcome to fork it and adapt it to your needs.
