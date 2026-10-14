# UniFi Controller & Networking Playbook

### 1. Site & Device Management
By default, the self-hosted UniFi controller operates as a single site. To manage multiple isolated environments (or clients), you must explicitly enable multi-site support.

* **Enable Multi-Site:** Go to Settings > System > Advanced, check Multi-Site Management, and apply.
* **Create a New Site:** Click the current site name in the top-left corner of the dashboard and select Add New Site. This creates a blank configuration template.
* **Move a Device Between Sites:**
  1. Click the device in the Devices tab to open the right-hand panel.
  2. Go to Settings (the gear icon in the panel).
  3. Scroll down to Manage and select Move to another site.
  4. Choose the destination site. The device will reboot, provision with the new site's rules, and disconnect from the current site.

---

### 2. Device Adoption Strategies
UniFi devices must establish an inform connection to the controller to receive configurations and state updates.

* **Layer 2 (Local / Flat Subnet):**
  * Automatic broadcast discovery when hardware resides on the same management subnet as the controller.
  * Displays directly in the UniFi UI as *Ready to Adopt*.

* **Layer 3 (Remote / Multi-VLAN / Branch Deployment via PuTTY):**
  * Required when adopting hardware across subnets, through routers, or at customer branch sites.
  1. Identify the DHCP address assigned to the unadopted UniFi device.
  2. Open **PuTTY**, connect via SSH (Port 22), and log in with default credentials (`ubnt` / `ubnt`).
  3. Execute the inform command:
     * *Local Lab / Same Site:*
       `set-inform http://<Local-Controller-IP>:8080/inform`
     * *Enterprise / Remote Branch (via Public FQDN & Firewall NAT):*
       `set-inform http://unifi-01.desktopservice.eu:8080/inform`
  4. Return to the UniFi web interface and click **Adopt**.
  5. **Engineer Best Practice:** Re-run the exact same `set-inform` command in PuTTY a second time immediately after clicking adopt. This prevents the device from reverting to factory state before receiving its permanent controller config.

---

### 3. Network & VLAN Architecture (Layer 2 Switching Mode)
When routing and DHCP are handled by an upstream core gateway (e.g., DrayTek Vigor, pfSense, FortiGate), UniFi operates strictly as a Layer 2 management fabric.

* **Network Scope:**
  * UniFi must NOT host DHCP servers or attempt Layer 3 routing for these networks to avoid IP pool conflicts.
  * Each VLAN created on the core gateway must be mirrored inside the controller as an identical tag.

* **VLAN Creation Steps:**
  1. Navigate to **Settings > Networks > New Virtual Network**.
  2. Set **Router** to **Third-Party Gateway** (or check *VLAN Only* depending on UI version).
  3. Set **Name** and assign the matching **VLAN ID**:
     * `Servers` — VLAN 10 (Untagged/Tagged infrastructure services)
     * `Clients` — VLAN 20 (End-user devices & standard workstations)
     * `Wifi / Voice` — VLAN 30 (VoIP infrastructure & wireless SSIDs)

---

### 4. Layer 3 Routing & DHCP (Core Router / DrayTek)
When using UniFi strictly for Layer 2 switching, the upstream router is entirely responsible for DHCP, IP gateways, and inter-network communication.
* **Step 1: Define VLANs and Trunk Port (LAN > VLAN)**
  1. Check the box to Enable the VLAN configuration.
  2. Assign VLAN IDs to specific LAN profiles (e.g., VID 10 to LAN2, VID 20 to LAN3, VID 30 to LAN4).
  3. Check the box for the physical port connecting to the UniFi switch (e.g., P1) across all active VLANs. This configures the physical port as an 802.1Q trunk.

* **Step 2: Assign IP Subnets (LAN > General Setup)**
  1. Open the **Details Page** for each LAN profile (LAN2, LAN3, LAN4).
  2. Enable the interface and set the Gateway IP Address. 
  3. *Best Practice:* Match the third octet to the VLAN ID (e.g., IP `192.168.10.1` for VLAN 10).

* **Step 3: Configure DHCP Servers**
  1. In the same Details Page, select **Enable Server**.
  2. **Critical:** Ensure the *Start IP Address* and *Gateway IP Address* in the DHCP Server Configuration box strictly match your new custom subnet (e.g., `192.168.10.10` and `192.168.10.1`). Do not leave the auto-filled defaults.

* **Step 4: Enable Inter-LAN Routing**
  1. DrayTek isolates LAN interfaces by default. 
  2. Scroll to the bottom of the **General Setup** page to the **Inter-LAN Routing** matrix.
  3. Check the intersection boxes to allow routing between networks (e.g., allowing LAN3 Clients to reach LAN2 Servers).

* **Trunk Port Configuration:**
  * The physical router port connecting to the UniFi switch must be configured to pass all required VLAN tags (802.1Q).
* **Subnets & DHCP:**
  * Each VLAN requires a dedicated interface on the router (e.g., LAN2, LAN3).
  * Best Practice: Match the third octet of the IP scheme to the VLAN ID (e.g., `192.168.20.x` for VLAN 20).
  * Verify the DHCP Gateway IP matches the router's interface IP for that specific subnet.
* **Inter-LAN Routing:**
  * Routers (like DrayTek) often isolate LAN interfaces by default. 
  * To allow Client endpoints to reach Server infrastructure (like a Domain Controller), explicitly enable Inter-LAN routing in the router's general setup matrix.

---

### 5. Switch Port Configuration (Access vs. Trunk Ports)
Understanding how to configure physical switch ports based on the connected device.

* **Access Ports (Single Device / Single Network)**
  * **Use Case:** A standard end-device like a laptop, PC, or standard IP phone. 
  * **Configuration:** Set the *Primary Network* in UniFi to the specific VLAN (e.g., VLAN 20 for Clients).
  * **How it works:** The switch tags the traffic invisibly. The connected device does not know VLANs exist.
* **Trunk Ports (Multiple Networks on One Cable)**
  * **Use Case:** A smart device hosting multiple networks simultaneously, such as a Hyper-V Server, a Wi-Fi Access Point broadcasting multiple SSIDs, or an uplink to another switch.
  * **Configuration:** Set the *Primary Network* to **Default** (Native) and ensure *Traffic Restriction* is unchecked to allow all tagged VLANs to pass through.
  * **How it works:** The management IP uses the untagged Default network, while the other networks pass through with their tags intact so the smart device (like the Hyper-V virtual switch or Access Point) can sort them out and route them accordingly.
