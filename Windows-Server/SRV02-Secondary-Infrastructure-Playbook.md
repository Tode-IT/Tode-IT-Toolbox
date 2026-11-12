# Windows Server 2022 (`SRV-02`) Secondary Infrastructure Playbook

## 1. High Availability (HA) Architecture Overview
To eliminate `DC-01` as a single point of failure, `SRV-02` serves as a secondary Domain Controller, a DNS replication partner, and a DHCP Failover node. This ensures client PCs (VLAN 20) experience zero network downtime during server maintenance.

| Service | Primary Node (`DC-01`) | Secondary Node (`SRV-02`) | HA Relationship Type |
| :--- | :--- | :--- | :--- |
| **Active Directory** | `192.168.10.10` | `192.168.10.20` | Multi-Master Replication |
| **DNS** | `192.168.10.10` | `192.168.10.20` | AD-Integrated Zone Sync |
| **DHCP (VLAN 20)** | Active | Active | Load Balance (50% / 50%) |

---

## 2. Hyper-V VM Provisioning & Initial Baseline
Before `SRV-02` can be promoted, it must be provisioned on the correct VLAN and point exclusively to `DC-01` for DNS resolution.

1. **Hyper-V VM Settings:**
   * **Generation:** Generation 2 (UEFI, Secure Boot enabled).
   * **Memory / Storage:** 4 GB RAM (Dynamic), 60 GB Virtual Disk.
   * **Network Adapter:** Connected to `External LAN` Virtual Switch -> Check **Enable virtual LAN identification** and set VLAN ID to **`10`**.
2. **Assign Static IP (`ncpa.cpl`):**
   * **IPv4 Address:** `192.168.10.20`
   * **Subnet Mask:** `255.255.255.0`
   * **Default Gateway:** `192.168.10.1` (DrayTek VLAN 10 interface).
   * **Preferred DNS:** `192.168.10.10` (Must point directly to `DC-01`).
   * *Critical Note:* Never set the Alternate DNS to a public resolver (like `8.8.8.8`). Doing so will cause Domain Join failures if the server queries the public internet for the `.local` Active Directory zone.
3. **Rename & Join Domain (`sysdm.cpl`):**
   * Change Computer Name to **`SRV-02`**.
   * Change Member of to **Domain**: `TodTech.local` and supply Domain Admin credentials. Reboot.
4. **Organize Active Directory:**
   * On `DC-01`, open **Active Directory Users and Computers**, right-click `SRV-02` in the default *Computers* container, and move it to the `_TodTech_Corp -> Servers` Organizational Unit.

---

## 3. Active Directory Promotion (Replica Domain Controller)
1. Open **Server Manager** -> **Manage** -> **Add Roles and Features**.
2. Check the **Active Directory Domain Services (AD DS)** role and install.
3. Click the yellow notification flag in Server Manager -> **Promote this server to a domain controller**:
   * Select **Add a domain controller to an existing domain**.
   * Domain: **`TodTech.local`**.
   * *Credential Override:* Click **Change...** and supply `TODTECH\Administrator` credentials (the local `SRV-02\Administrator` account does not have forest rights).
4. On Domain Controller Options, ensure **Domain Name System (DNS) server** and **Global Catalog (GC)** are checked.
5. Set the DSRM password, pass the Prerequisite Check, and click **Install**. (Server reboots automatically).

---

## 4. DHCP Load Balance & Failover Configuration
Instead of manually carving out split IP scopes, modern DHCP utilizes a Load Balance failover relationship to share a single scope seamlessly across two servers.

#### Step 1: Install & Authorize on `SRV-02`
1. Open **Server Manager** -> **Manage** -> **Add Roles and Features**.
2. Install the **DHCP Server** role.
3. Click the yellow notification flag -> **Complete DHCP configuration**.
4. Click **Next**, ensure `TODTECH\Administrator` is selected, and click **Commit** to authorize `SRV-02` in Active Directory.

#### Step 2: Configure Failover from `DC-01`
1. On `DC-01`, open **DHCP Manager**, expand `IPv4`, and right-click **Scope [192.168.20.0] VLAN 20 - Clients**.
2. Select **Configure Failover...**
3. Ensure **Select all** is checked for the `192.168.20.0` scope and click **Next**.
4. **Partner Server:** Type `192.168.10.20` (or `srv-02.todtech.local`) and click **Next**.
5. **Mode:** Select **Load balance** with a **50% / 50%** load distribution percentage.
6. Disable the *State Switchover Interval*, input a secure **Shared Secret**, and click **Finish**.
7. Verify on `SRV-02`: Open DHCP Manager and refresh. The entire VLAN 20 scope, including current address leases, will now be mirrored.

---

## 5. DNS Redundancy & Scope Option Updates
Client PCs must be instructed to use both servers for DNS resolution, otherwise, they will lose domain connectivity if `DC-01` goes offline.

1. **Update Scope Options on Primary (`DC-01`):**
   * Open **DHCP Manager** -> expand the VLAN 20 Scope -> click **Scope Options**.
   * Double-click **006 DNS Servers**.
   * Add `192.168.10.20` (`SRV-02`) beneath `192.168.10.10` (`DC-01`) and click **OK**.
2. **Force Failover Replication:**
   * DHCP failover does not automatically sync post-setup modifications immediately.
   * Right-click **IPv4** (or the scope) -> click **Replicate Failover Scopes** -> click **OK**.
3. **Verify Configuration on Clients (`FIN-PC01` / `SALES-PC01`):**
   * Run `ipconfig /renew` to pull the updated DHCP lease.
   * Run `ipconfig /all` and verify the *DNS Servers* property now lists both `192.168.10.10` and `192.168.10.20`.
