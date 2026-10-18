# Windows Server 2022 (`DC-01`) Core Infrastructure Playbook

## 1. Network Architecture & IPAM Overview
This lab uses 802.1Q VLAN segmentation across a DrayTek Vigor 2865 router, UniFi switches/APs, and Hyper-V.

| VLAN ID | Network Name | Subnet | Default Gateway | DHCP Handled By (Hybrid) | DNS Server | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **VLAN 1** | Default (LAN 1) | `192.168.1.0/24` | `192.168.1.1` | DrayTek Router | DrayTek | Switches, APs, Hyper-V Host |
| **VLAN 10** | Servers (LAN 2) | `192.168.10.0/24` | `192.168.10.1` | `DC-01` (Local) | `192.168.10.10` | Domain Controller (`DC-01`) |
| **VLAN 20** | Clients (LAN 3) | `192.168.20.0/24` | `192.168.20.1` | `DC-01` (via Relay) | `192.168.10.10` | Corporate PCs (`IT-PC`) & Corp Wi-Fi |
| **VLAN 30** | Guest Wi-Fi (LAN 4) | `192.168.30.0/24` | `192.168.30.1` | DrayTek Router | DrayTek | Isolated Guest Wi-Fi |

---

## 2. Hyper-V VM Provisioning & Initial Baseline
Before installing Active Directory, the server must have a static IP, a proper hostname, and the right VLAN tag.

1. **Hyper-V VM Settings:**
   * **Generation:** Generation 2 (UEFI, Secure Boot enabled).
   * **Memory / Storage:** 4 GB RAM, 60 GB Virtual Disk.
   * **Network Adapter:** Connected to `External LAN` Virtual Switch -> Check **Enable virtual LAN identification** and set VLAN ID to **`10`**.
2. **Assign Static IP (`ncpa.cpl`):**
   * **IPv4 Address:** `192.168.10.10`
   * **Subnet Mask:** `255.255.255.0`
   * **Default Gateway:** `192.168.10.1` (DrayTek VLAN 10 interface)
   * **Preferred DNS:** `127.0.0.1` (Points to itself once DNS role is installed)
3. **Rename Server (`sysdm.cpl`):**
   * Change Computer Name to **`DC-01`** and reboot.

---

## 3. Installing Server Roles (AD DS, DNS, DHCP, GPO)
1. Open **Server Manager** -> **Manage** -> **Add Roles and Features**.
2. Select **Role-based or feature-based installation** on `DC-01`.
3. Check the following **Server Roles** (click *Add Features* when prompted):
   * **Active Directory Domain Services (AD DS)** (Automatically includes **Group Policy Management / GPO** tools).
   * **DNS Server**
   * **DHCP Server**
4. Complete the installation wizard, then click the yellow notification flag in Server Manager -> **Promote this server to a domain controller**:
   * Select **Add a new forest** -> Root domain name: **`TodTech.local`**.
   * Set the DSRM password and complete the promotion (server will reboot automatically).

---

## 4. DHCP Architecture & Implementation Guide (3 Options)
DHCP automatically hands out IP addresses, Default Gateways, and DNS Server IPs to devices. In a multi-VLAN network, there are three ways to design and implement DHCP.

---

### Option A: Router-Only DHCP (All DHCP on DrayTek)
* **How it works:** The DrayTek router hands out IP addresses for every VLAN (1, 10, 20, 30).
* **Pros:** Simple setup; works even if `DC-01` is powered off.
* **Cons:** Non-Windows devices won't automatically register their hostnames in Windows DNS.
* **How to Implement:**
  1. **On Windows Server (`DC-01`):** Do not install or authorize the DHCP Server role.
  2. **On DrayTek Router (`LAN >> General Setup`):**
     * Open **Details Page** for **LAN 2 (VLAN 10)** and **LAN 3 (VLAN 20)**.
     * Under *DHCP Server Configuration*, select **Enable Server**.
     * Set **Start IP Address** to `.50` (`192.168.10.50` / `192.168.20.50`) so it does not conflict with static server IPs like `.10`.
     * Under *DNS Server IP Address*, set **Primary IP Address** to **`192.168.10.10`** (`DC-01`). Leave Secondary DNS blank so domain computers only ask `DC-01` for DNS.

---

### Option B: Windows Server-Only DHCP (All DHCP on `DC-01`)
* **How it works:** `DC-01` manages scopes for every single VLAN (1, 10, 20, 30).
* **Pros:** Single pane of glass for all IP leases on the network.
* **Cons:** Security risk (Guest Wi-Fi traffic must reach the Domain Controller via Inter-LAN routing) and if `DC-01` is powered off, the entire network loses DHCP.
* **How to Implement:**
  1. **On DrayTek Router (`LAN >> General Setup`):**
     * **LAN 2 (VLAN 10):** Set *DHCP Server Configuration* to **Disable** (since `DC-01` sits inside VLAN 10).
     * **LAN 1, LAN 3 (VLAN 20), and LAN 4 (VLAN 30):** Set *DHCP Server Configuration* to **Enable Relay Agent** and set **1st DHCP Server IP Address** to **`192.168.10.10`**.
     * Enable **Inter-LAN Routing** between LAN 2 and all other LANs so DHCP Relay traffic can reach `DC-01`.
  2. **On Windows Server (`DC-01`):**
     * Open **DHCP**, right-click `dc-01.todtech.local` -> **Authorize**.
     * Create 4 separate IPv4 Scopes (`192.168.1.0`, `192.168.10.0`, `192.168.20.0`, `192.168.30.0`), each configured with its matching VLAN Default Gateway (`003 Router`).

---

### Option C: Hybrid DHCP (Implemented in TodTech Production Lab)
* **How it works:** We split DHCP based on security and purpose:
  * **DrayTek** runs DHCP for **VLAN 1 (Mgmt)** and **VLAN 30 (Guest Wi-Fi)** so guests stay isolated from the Domain Controller and the host network stays up if the VM is off.
  * **`DC-01`** runs DHCP for **VLAN 10 (Servers)** and **VLAN 20 (Clients)** so corporate machines automatically register in Active Directory DNS (`TodTech.local`).

#### Step 1: Configure DrayTek Router (`LAN >> General Setup`)
1. **LAN 1 (`192.168.1.1` - Default/Mgmt) & LAN 4 (`192.168.30.1` - Guest VLAN 30):**
   * Keep left-side *Network Configuration* **Enabled**.
   * Keep right-side *DHCP Server Configuration* set to **Enable Server**.
2. **LAN 2 (`192.168.10.1` - Servers VLAN 10):**
   * Keep left-side *Network Configuration* **Enabled** (this is `DC-01`'s Default Gateway).
   * Set right-side *DHCP Server Configuration* to **Disable**. *(Prevents DHCP conflicts since `DC-01` sits directly inside VLAN 10 and answers requests locally).*
3. **LAN 3 (`192.168.20.1` - Clients VLAN 20):**
   * Keep left-side *Network Configuration* **Enabled**.
   * Set right-side *DHCP Server Configuration* to **Enable Relay Agent** -> **1st DHCP Server IP Address:** **`192.168.10.10`**.
   * *Why Relay is needed:* DHCP broadcasts cannot cross VLAN boundaries on their own. The DrayTek listens on VLAN 20 (`192.168.20.1`) and forwards client IP requests over to `DC-01` (`192.168.10.10`).

#### Step 2: Configure DHCP Server & Scopes on `DC-01`
1. Open **Server Manager** -> **Tools** -> **DHCP**.
2. Right-click `dc-01.todtech.local` -> click **Authorize**, then press **F5** (Refresh) until green checkmarks appear next to `IPv4`.
3. Right-click **IPv4** -> **New Scope** to create both corporate buckets:
   * **Scope 1: `VLAN 10 - Servers`**
     * **IP Range:** `192.168.10.50` – `192.168.10.150` | **Mask:** `255.255.255.0` (`/24`)
     * **Option 003 (Router / Default Gateway):** `192.168.10.1`
     * **Option 006 (DNS Servers):** `192.168.10.10`
     * **Option 015 (DNS Domain Name):** `TodTech.local`
   * **Scope 2: `VLAN 20 - Clients`**
     * **IP Range:** `192.168.20.50` – `192.168.20.150` | **Mask:** `255.255.255.0` (`/24`)
     * **Option 003 (Router / Default Gateway):** `192.168.20.1` *(Must match VLAN 20 gateway!)*
     * **Option 006 (DNS Servers):** `192.168.10.10`
     * **Option 015 (DNS Domain Name):** `TodTech.local`

---

## 5. DNS Configuration & Scratch Rebuild Process
Active Directory relies on DNS to locate the Domain Controller.

1. **Configure DNS Forwarders (For Internet Access):**
   * Open **DNS Manager** -> right-click **`DC-01`** -> **Properties** -> **Forwarders** tab -> **Edit**.
   * Add **`1.1.1.1`** and **`8.8.8.8`**. (Allows `DC-01` to resolve external internet websites for clients).
2. **Forward Lookup Zone (`TodTech.local`):**
   * Resolves hostnames to IP addresses.
   * Created under **Forward Lookup Zones** -> **New Zone** -> **Primary Zone (Store in AD)** -> Name: `TodTech.local` -> **Allow only secure dynamic updates**.
3. **Reverse Lookup Zones (`10` & `20`):**
   * Resolves IP addresses back to hostnames (`PTR` records).
   * Created under **Reverse Lookup Zones** -> **New Zone** -> **Primary Zone (Store in AD)** -> **IPv4** -> Network IDs: **`192.168.10`** and **`192.168.20`**.
4. **How to Force AD to Rebuild DNS Records (If Zones Are Recreated):**
   * Restart the **Netlogon** service in `services.msc` (automatically recreates `_msdcs`, `_sites`, `_tcp`, and `_udp` SRV folders).
   * Run `ipconfig /registerdns` in an elevated Command Prompt on `DC-01`.

---

## 6. Client Onboarding (`IT-PC`) & Common Fixes
1. **Hyper-V Tagging:** Set `IT-PC` Network Adapter VLAN ID to **`20`**.
2. **Verify DHCP Lease:**
   ```cmd
   ipconfig /release
   ipconfig /renew
   ipconfig /all
