# Windows Server 2022 (`PKI-01`) Internal PKI & AD CS Playbook

## 1. PKI Architecture & Infrastructure Overview

This playbook documents the deployment of an internal Enterprise Root Certificate Authority (`PKI-01`) for the `TodTech.local` domain. It enables automatic workstation certificate enrollment, encrypted LDAPS (Port 636) on Domain Controllers, and trusted internal HTTPS certificates for web portals.

| Server / Component | Role / Value | Purpose |
| :--- | :--- | :--- |
| **Server Hostname** | `PKI-01.TodTech.local` | Dedicated Enterprise Root CA (Domain-joined Member Server) |
| **CA Common Name** | `TodTech-PKI-01-CA` | Root Certificate Authority name trusted by all domain clients |
| **Cryptography / Validity** | `RSA 4096-bit` / `SHA256` / `10 Years` | Strong cryptographic baseline (Valid until `24/11/2036`) |
| **Storage Location** | External Drive `D:` | Dedicated lab VM storage |
| **Domain Controller** | `DC-01.TodTech.local` (`192.168.10.10`) | Automatic LDAPS (Port 636) & GPO distribution |
| **Web Server** | `SRV-02.TodTech.local` | Internal IIS HTTPS web portal (`https://srv-02.todtech.local`) |

---

## 2. Enterprise Root CA Deployment (`PKI-01`)

1. **Server Baseline:**
   * Provision Windows Server 2022 VM (`PKI-01`), assign a static IP on VLAN 10, and join it to `TodTech.local`.
2. **Install AD CS Role:**
   * Open **Server Manager** -> **Add Roles and Features** -> select **Active Directory Certificate Services (AD CS)** -> **Certification Authority**.
3. **Configure Enterprise Root CA:**
   * Run the post-deployment **AD CS Configuration** wizard:
     * **Setup Type:** `Enterprise CA` *(integrates with Active Directory so domain PCs automatically trust the Root CA)*.
     * **CA Type:** `Root CA`.
     * **Private Key:** Create a new private key (`RSA#Microsoft Software Key Storage Provider`, **4096-bit**, **SHA256**).
     * **CA Name:** `TodTech-PKI-01-CA`.
     * **Validity Period:** `10 Years`.
4. **Verify Automatic Domain Trust:**
   * On any domain-joined client (`SALES-PC01` / `FIN-PC01`), open `certlm.msc` -> **Trusted Root Certification Authorities** -> **Certificates**.
   * Confirm **`TodTech-PKI-01-CA`** appears automatically.

---

## 3. Workstation Auto-Enrollment Template & GPO

### Create & Publish the Custom Template (on `PKI-01`)
*Best Practice: Never edit default Microsoft templates directly—always duplicate them.*

1. Open **Certification Authority** (`certsrv.msc`), right-click **Certificate Templates** -> **Manage** (`certtmpl.msc`).
2. Right-click **Workstation Authentication** -> **Duplicate Template**.
3. Configure the template properties:
   * **General:** Display Name = `TodTech-Workstation-AutoEnroll`, Validity = `1 year`, Renewal period = `6 weeks`.
   * **Security:** Select **`Domain Computers`** and grant **Read**, **Enroll**, and **Autoenroll**.
4. Close `certtmpl.msc`. In `certsrv.msc`, right-click **Certificate Templates** -> **New** -> **Certificate Template to Issue** -> select **`TodTech-Workstation-AutoEnroll`**.

### Enable Auto-Enrollment via GPO (on `DC-01`)
*Note: The GPO acts as the master switch—it does not link specific templates. Clients check Active Directory for any published template where their group has `Autoenroll` granted.*

1. Open **Group Policy Management** (`gpmc.msc`) and create a new GPO named **`SEC-PKI-AutoEnrollment`** linked to the domain (or Workstation OUs).
2. Navigate to:
   `Computer Configuration > Policies > Windows Settings > Security Settings > Public Key Policies > Certificate Services Client - Auto-Enrollment`
3. Set **Configuration Model** to **Enabled** and check both boxes:
   * **Renew expired certificates, update pending certificates, and remove revoked certificates**
   * **Update certificates that use certificate templates**
4. **Verification (on `SALES-PC01`):**
   * Run `gpupdate /force` and `certutil -pulse`.
   * Open `certlm.msc` -> **Personal** -> **Certificates** and confirm a certificate issued using **`TodTech-Workstation-AutoEnroll`** is present.

---

## 4. Verify Encrypted LDAPS (Port 636) on `DC-01`

Once `PKI-01` is configured as an Enterprise Root CA, Domain Controllers automatically enroll for `Kerberos Authentication` / `Domain Controller Authentication` certificates and unlock **LDAPS (Port 636)**.

1. **Verify Certificate on `DC-01`:**
   * Open `certlm.msc` -> **Personal** -> **Certificates** and confirm a certificate is issued to `DC-01.TodTech.local` by `TodTech-PKI-01-CA`.
2. **Test Port 636 Connectivity (PowerShell as Admin):**
   ```powershell
   Test-NetConnection -ComputerName DC-01.TodTech.local -Port 636
   ```
   * Expected output: `TcpTestSucceeded : True`.
3. **Verify SSL Handshake via `ldp.exe`:**
   * Run `ldp.exe` -> **Connection** -> **Connect...**
   * **Server:** `DC-01.TodTech.local` | **Port:** `636` | Check **SSL**.
   * Expected output: `Host supports SSL, SSL cipher strength = 256 bits` and `Established connection to DC-01.TodTech.local.`

---

## 5. Internal HTTPS Web Server Certificate (`SRV-02`)

### Create & Publish the Web Server Template (on `PKI-01`)
1. Open `certtmpl.msc`, right-click **Web Server** -> **Duplicate Template**.
2. Configure the template properties:
   * **General:** Display Name = `TodTech-WebServer`.
   * **Subject Name:** Confirm **Supply in the request** is selected.
   * **Security:** Grant **Read** and **Enroll** to **`Domain Controllers`** (since `SRV-02` is a DC) or the target server's computer account. *(Do not enable Autoenroll.)*
3. Publish **`TodTech-WebServer`** under **Certificate Templates** in `certsrv.msc`.

### Install IIS & Request SAN Certificate (on `SRV-02`)
1. Install IIS via PowerShell (Admin):
   ```powershell
   Install-WindowsFeature -Name Web-Server -IncludeManagementTools
   ```
2. Open `certlm.msc` -> right-click **Personal** -> **All Tasks** -> **Request New Certificate...**.
3. Check **`TodTech-WebServer`** and click **More information is required to enroll for this certificate**.
4. On the **Subject** tab *(SAN is mandatory for modern browsers)*:
   * **Subject name (Common name):** `srv-02.todtech.local` -> **Add**.
   * **Alternative name (DNS):** `srv-02.todtech.local` -> **Add**.
5. Click **OK** -> **Enroll** -> **Finish**.

### Bind Certificate in IIS & Verify Padlock
1. Open **IIS Manager** (`inetmgr`) on `SRV-02` -> **Sites** -> **Default Web Site** -> **Bindings...** -> **Add...**.
2. Set **Type:** `https`, **Port:** `443`, **SSL certificate:** `srv-02.todtech.local`.
3. **Verification (on `FIN-PC01` / `SALES-PC01`):**
   * Browse to `https://srv-02.todtech.local` in Microsoft Edge.
   * Confirm a clean padlock with zero warnings, issued to `srv-02.todtech.local` by `TodTech-PKI-01-CA`.

---

## 6. 3rd-Line Troubleshooting & Command Reference

### Common Lab & Production Fixes

| Issue / Error | Root Cause | Resolution |
| :--- | :--- | :--- |
| **`TodTech-WebServer` not visible in enrollment wizard on `SRV-02`** | `SRV-02` is a Domain Controller, so it belongs to `Domain Controllers`, not `Domain Computers`. | Add **`Domain Controllers`** (or `SRV-02$`) with **Read** and **Enroll** on the template's Security tab in `certtmpl.msc`. |
| **`0x80092013 CRYPT_E_REVOCATION_OFFLINE`** | `PKI-01` cannot verify a fresh Certificate Revocation List (CRL) before signing a new cert. | Run `certutil -crl`, restart `certsvc` on `PKI-01`, and run `certutil -urlcache crl delete` on the requesting server. |
| **Browser shows "Not Secure" after binding HTTPS cert** | Missing **Subject Alternative Name (SAN)** DNS entry in the certificate request. | Re-enroll the certificate ensuring the FQDN (`srv-02.todtech.local`) is added under **Alternative name -> DNS**. |

### Essential PKI Commands
```cmd
:: Ping and verify connectivity to the Enterprise CA
certutil -config "PKI-01.TodTech.local\TodTech-PKI-01-CA" -ping

:: Force immediate certificate auto-enrollment check on a workstation/server
certutil -pulse

:: Republish the Certificate Revocation List (run on PKI-01)
certutil -crl

:: Restart Active Directory Certificate Services (run on PKI-01)
net stop certsvc && net start certsvc

:: Clear cached CRL lookups on a client or server
certutil -urlcache crl delete

:: Force AD replication across all Domain Controllers
repadmin /syncall /AdeP

:: Verify Computer GPO application and secure channel health
gpresult /r /scope computer
nltest /sc_verify:TodTech.local
```
