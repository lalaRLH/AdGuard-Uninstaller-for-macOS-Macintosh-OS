<div align="center">

<img src="banner.svg" alt="AdGuard Uninstaller for macOS" width="100%"/>

<br/>

![macOS](https://img.shields.io/badge/macOS-Monterey%2B-black?style=flat-square&logo=apple&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash-informational?style=flat-square&logo=gnubash&logoColor=white&color=3a3a3c)
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

### Option 1 &nbsp;·&nbsp; One-liner (recommended)

No download. No Gatekeeper warning. Paste into Terminal and go.

```bash
curl -fsSL https://raw.githubusercontent.com/lalaRLH/AdGuard-Uninstaller-for-macOS-Macintosh-OS/main/uninstall-adguard.command | sudo bash
```

<br/>

### Option 2 &nbsp;·&nbsp; Double-click

Download [`uninstall-adguard.command`](./uninstall-adguard.command), then:

```bash
# strip the quarantine flag first
xattr -d com.apple.quarantine ~/Downloads/uninstall-adguard.command

# then just double-click it — macOS will prompt for your password
```

> If macOS still blocks it: right-click → **Open** → **Open**

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
