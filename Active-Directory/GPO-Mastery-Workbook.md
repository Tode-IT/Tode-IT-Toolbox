
# TodTech Enterprise Active Directory & GPO Lab Workbook

A documented Group Policy engineering lab built on **Windows Server 2022** (`DC-01`, `SRV-02`) and **Windows 11** domain-joined workstations (`FIN-PC01`, `SALES-PC01`, `IT-PC`) in Hyper-V.

---

## 1. Lab Architecture & Standards

* **Domain:** `TodTech.local`
* **OU Structure:** `_TodTech_Corp` -> `_TodTech_Admin` (`Admin_Accounts`, `Service_Accounts`), `Groups`, `Servers`, `Users` (`Disabled_Users`, `Finance`, `IT`, `Sales`), `Workstations` (`Finance`, `IT`, `Sales`)
* **Central Store:** `\\TodTech.local\SYSVOL\TodTech.local\Policies\PolicyDefinitions` (configured with Microsoft Edge ADMX/ADML templates)
* **Software Deployment Share:** `\\DC-01\Software$` (hidden SMB share, Read permissions for Authenticated Users)
* **Naming Convention:**
  * `SEC-*` — Security & Firewall baselines
  * `USR-*` — User environment & desktop standardization
  * `APP-*` — Application baselines & MSI deployments

---

## 2. Deployed GPO Inventory

| GPO Name | Scope | Linked OU | Purpose / Key Settings |
| :--- | :--- | :--- | :--- |
| `SEC-15Min-ScreenLock` | Computer / User | `Workstations` | Enforces 15-minute idle screen lock & password prompt |
| `SEC-Block-USB` | Computer | `Finance`, `Sales` *(or `Workstations` w/ Deny)* | Blocks removable USB storage read/write; `IT-PC` exempt via `G_USB_Exempt_PCs` |
| `SEC-Firewall-Standard` | Computer | `Workstations` | Forces Domain, Private, and Public Defender Firewall profiles ON; allows inbound ICMPv4 (Ping) for IT |
| `USR-Block-ControlPanel` | User | `Users` | Prohibits access to Control Panel and PC Settings for standard users |
| `USR-Corp-Wallpaper` | User | `Users` | Enforces corporate desktop wallpaper via UNC path |
| `USR-Desktop-Shortcuts` | User | `Users` | Deploys corporate shortcuts (e.g., TodTech Portal URL) via GPP (`Update`) |
| `DriveMapping_CorpShares` | User | `_TodTech_Corp` | Maps `S:` to `\\DC-01\CorpShares` (`Update`, Reconnect, Run in user's context, Item-Level Targeting) |
| `APP-Edge-Baseline` | Computer | `Workstations` | Configures Edge startup URLs, favorites bar, and managed JSON bookmarks via Central Store ADMX |
| `APP-Deploy-7Zip` | Computer | `Workstations` | Assigned MSI installation via `\\DC-01\Software$` \vert{} \vert{} `APP-Deploy-Chrome` \vert{} Computer \vert{} `Workstations` \vert{} Assigned Enterprise 64-bit MSI installation via `\\DC-01\Software$` |

---

## 3. Enterprise GPO Best Practices

1. **One Purpose / One App per GPO:** Never bundle unrelated settings or multiple applications into one mega-GPO. Separate GPOs simplify targeting, upgrades, and `gpresult` troubleshooting.
2. **Never Edit Default Policies:** Leave `Default Domain Policy` (account/password/Kerberos policies only) and `Default Domain Controllers Policy` untouched for general settings.
3. **Use the Central Store:** Always host `.admx`/`.adml` templates in `SYSVOL\Policies\PolicyDefinitions` so every admin sees identical policy definitions.
4. **Prefer `Update` Over `Replace` in GPP:** Using `Replace` on Drive Maps or Shortcuts tears down and recreates the object on every background refresh, causing disconnects and *"local device name is already in use"* errors.
5. **Enable "Run in Logged-On User's Security Context":** Always check this on the **Common** tab of User Configuration Drive Maps so mappings use the user's token rather than `SYSTEM`.
6. **Use Deny Permissions for Exceptions:** To exempt a PC from a Computer GPO, add the computer account to a security group (e.g., `G_USB_Exempt_PCs`) and grant **Deny: Apply Group Policy** on the **Delegation** tab—keep `Authenticated Users` intact so the computer can still read the GPO.
7. **Use `Block Inheritance` and `Enforced` Sparingly:** Rely on clean OU hierarchy first. Overusing overrides makes policy precedence difficult to audit.
8. **Back Up Before Major Changes:** Always back up GPOs (`C:\GPO_Backups`) before editing or deleting. Remember that **Restoring** a deleted GPO recovers its settings and permissions, **not** its OU links.
9. **Test Against Official Baselines:** Compare custom security GPOs against the [Microsoft Security Compliance Toolkit](https://www.microsoft.com/en-us/download/details.aspx?id=55319) and [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/) in a staging OU before production rollout.

---

## 4. 3rd-Line GPO Troubleshooting Cheat Sheet

### Precedence Order (LSDOU — Last Writer Wins)
`Local` -> `Site` -> `Domain` -> `Parent OU` -> `Child OU`
* Non-conflicting settings **merge**.
* Conflicting settings are overwritten by the **closest (child) OU**—unless a parent GPO is marked **Enforced**.

### Essential Commands

| Task | Command | Notes |
| :--- | :--- | :--- |
| **Force immediate GPO refresh** | `gpupdate /force` | Computer software installs & new computer group memberships require a **reboot** |
| **Quick summary of applied GPOs** | `gpresult /r` | Add `/scope computer` (in Admin CMD) to see Computer GPOs & Denied filters |
| **Generate HTML RSoP report (same user)** | `gpresult /h C:\Users\Public\Report.html /f` | Avoid writing directly to `C:\` root; `/f` overwrites existing files |
| **Generate HTML RSoP report (elevated admin for another user)** | `gpresult /user TODTECH\finance.user /h C:\Users\Public\Report.html /f` | Fixes `INFO: The user does not have RSoP data` when running CMD as a separate Domain Admin |
| **Check logged-in username** | `query user` | Confirms exact session username for `/user` |
| **Clear stale mapped drive** | `net use S: /delete /y` | Run in a **normal (non-Admin)** CMD, then run `gpupdate /force` |
| **Verify SMB share path on server** | `net share CorpShares` | Confirms the underlying local drive/path on `DC-01` |

### Common Lab & Production Gotchas
* **`The device is not ready` on mapped drive:** The underlying disk on the file server is offline or detached (check `diskmgmt.msc`, `diskpart`, or Hyper-V SCSI Controller).
* **Red `X` on `S:` drive after host sleep (Hyper-V):** An **External Virtual Switch** drops when the host NIC sleeps, cutting off VM-to-VM SMB traffic until the host wakes up.
* **Computer Security Filtering didn't take effect:** Computer accounts only refresh their group memberships (Kerberos TGT) upon **reboot**, not `gpupdate`.
