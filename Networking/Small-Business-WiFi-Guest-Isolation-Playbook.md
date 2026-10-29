# Small Business Wi-Fi & Guest Isolation Playbook

## 1. Deployment Architecture Overview

Small business customers require wireless networks that are reliable, low-maintenance, and strictly separate public/visitor devices from internal business systems (servers, reception PCs, printers, and card terminals). 

Select the deployment model based on the customer's existing router hardware and compliance requirements:

| Scenario | Customer Profile | Router Hardware | Isolation Method | Controller Required 24/7? |
| :--- | :--- | :--- | :--- | :--- |
| **Scenario 1: Flat Network** | Small retail, cafe, barber, micro-office (1–5 PCs) | Standard ISP Router (No VLAN support) | Layer 2 AP Client Device Isolation | **No** |
| **Scenario 2: Segmented VLANs** | Medical/dental clinic, law firm, growing office (5+ PCs) | Business Router (DrayTek, pfSense, UniFi Gateway) | Layer 3 VLAN Tagging + Layer 2 AP Isolation | **No** |
| **Scenario 3: Captive Portal** | Hospitality, coffee shop, branded guest lounges | Business Router + Dedicated Controller Host | VLAN + Hotspot Landing Page | **Yes (Mandatory)** |

---

## 2. Scenario 1: Basic ISP Router (No VLAN Support)
Use this model when the customer only has a standard ISP router (e.g., BT, Virgin, Sky, Vodafone) that only supports a single flat subnet (e.g., `192.168.1.0/24`) and cannot create VLAN tags.

### How It Works
Both the **Staff Wi-Fi** and **Guest Wi-Fi** pull IP addresses from the ISP router's default subnet, but the UniFi Access Point enforces **Client Device Isolation** at the wireless layer so guests cannot communicate with other wireless devices.

### Configuration Steps (UniFi Controller)
1. Navigate to **Settings > WiFi > Create New**.
2. Configure the Guest SSID:
   * **Name:** `<BusinessName>-Guest`
   * **Password:** Set a simple WPA2 password.
   * **Network:** `Native Network` (Default untagged network).
   * **Application:** `Standard` *(Ensures Wi-Fi works 24/7 even if the UniFi Controller software is closed)*.
3. Scroll down to **Advanced (Manual)**:
   * **Security Protocol:** `WPA2` *(Maximum compatibility with older visitor phones)*.
   * **PMF (Protected Management Frames):** `Disabled`.
   * **Client Device Isolation:** **Checked** *(Blocks wireless client-to-client traffic)*.
   * **Multicast and Broadcast Blocker:** **Unchecked** *(Critical: Leaving this checked without manually adding the third-party ISP router's MAC address to the allowlist will block DHCP broadcasts and cause devices to fail with a `169.254.x.x` APIPA address)*.

> **Security Note for Flat Networks:** In `Standard` mode on a single flat network, `Client Device Isolation` blocks wireless-to-wireless traffic. If wired office PCs or printers are plugged into a UniFi Switch on the same flat subnet, enable **Port Isolation** on the switch port connected to the Access Point (or use Hotspot mode with the Landing Page disabled) to prevent guests from reaching wired IP addresses.

---

## 3. Scenario 2: Business Router with VLAN Segmentation (Recommended Best Practice)
Use this model for medical/dental clinics, offices handling sensitive data, or environments with a Windows Server (`DC-01`). It provides dual-layer security by placing guests on a completely separate IP subnet.

### Step 1: Configure the Business Router (e.g., DrayTek Vigor)
1. **Create the Guest VLAN Interface (`LAN >> General Setup`):**
   * Enable **LAN 4 (Guest VLAN 30)** with IP `192.168.30.1` (`/24`).
   * **DHCP Server:** `Enable Server` (Range: `192.168.30.10` – `192.168.30.200`).
   * **Lease Time:** Set to `7200` seconds (2 hours) or `3600` seconds (1 hour) so transient visitors do not exhaust the IP pool.
   * **DNS Server IP Address:** Explicitly set Primary to `1.1.1.1` and Secondary to `8.8.8.8`. *(Never leave Guest DNS blank, or the router may pass through unreachable internal/upstream DNS servers, causing "No Internet" errors on client devices)*.
2. **Tag the Uplink Port (`LAN >> VLAN`):**
   * Assign **VID `30`** to **LAN 4** on the trunk port connected to the switch.
3. **Disable Inter-LAN Routing (`LAN >> General Setup`):**
   * Uncheck all Inter-LAN routing boxes between **LAN 4 (VLAN 30)** and corporate subnets (**LAN 1, LAN 2, LAN 3**).

### Step 2: Configure UniFi Network & Switch Port Profile
1. **Create the VLAN in UniFi (`Settings > Networks`):**
   * Create a new network named `Wi-Fi` (or `Guest`) with **Router: Third-Party Gateway** and **VLAN ID: `30`**.
2. **Verify the Access Point Switch Port (`Ports > AP Port`):**
   * **Native VLAN / Network:** Set to `Default (1)` (or Management VLAN) so the Access Point hardware receives a management IP.
   * **Tagged VLAN Management:** Select `Allow All` (or `Custom` and include both Corporate `Clients (20)` and Guest `Wi-Fi (30)`).
   * *Note:* Any SSID set to `Native Network` will drop users onto the switch port's Native VLAN. Any SSID mapped to a specific VLAN network will tag traffic across the trunk.

### Step 3: Configure the Guest Wi-Fi SSID (`Settings > WiFi`)
1. Select the Guest Wi-Fi SSID:
   * **Network:** Select **`Wi-Fi (30)`** *(Do not leave on `Native Network`, or clients will receive corporate IP addresses)*.
   * **Application:** `Standard`
   * **Security Protocol:** `WPA2` (with password) or `Open` (for passwordless guest access).
   * **Client Device Isolation:** **Checked** *(Stops Guest A from seeing Guest B inside VLAN 30)*.
   * **Multicast and Broadcast Blocker:** **Unchecked** *(Unless the DrayTek LAN 4 MAC address is added to the Device Allowlist)*.

---

## 4. Scenario 3: Hotspot / Captive Portal (Splash Page Considerations)
Some hospitality clients request a branded terms-of-service splash page (`Application: Hotspot > Captive Portal`). Before deploying a Captive Portal, review the operational trade-offs with the client:

* **Controller Must Run 24/7:** The captive portal login page is hosted directly by the UniFi Network Controller. If the controller is installed on a desktop PC that goes to sleep or is powered off, the Access Point will quarantine new guests in a pre-authorization state and block all internet access. Only deploy Captive Portals if the client has a dedicated 24/7 controller (e.g., UniFi CloudKey, UniFi OS Server, or Cloud Hosting).
* **Cross-VLAN Firewall Rules Required:** If the UniFi Controller resides on `192.168.1.x` (VLAN 1) and guests reside on `192.168.30.x` (VLAN 30), the router and host firewall **must** allow traffic from VLAN 30 to the Controller IP on TCP ports **`8880`** (HTTP portal redirect) and **`8843`** (HTTPS portal redirect), or the splash page will fail to load.

---

## 5. Quick Troubleshooting Reference

| Symptom | Root Cause | Resolution |
| :--- | :--- | :--- |
| **Connected to Wi-Fi, "No Internet" message** | Router Guest DHCP has blank DNS fields, passing an unreachable internal DNS IP. | Manually enter `1.1.1.1` and `8.8.8.8` under the router's Guest LAN DNS settings. |
| **Device gets `169.254.x.x` (APIPA) IP address** | `Multicast and Broadcast Blocker` is checked on a non-UniFi router without the router's MAC in the allowlist. | Uncheck `Multicast and Broadcast Blocker` in the Wi-Fi settings, or add the router's MAC address to the allowlist. |
| **Guest Wi-Fi assigns Corporate IP (`192.168.20.x`)** | Wi-Fi SSID `Network` is set to `Native Network` instead of the Guest VLAN. | Change the Wi-Fi `Network` dropdown from `Native Network` to `Wi-Fi (30)`. |
| **Captive Portal hangs or blocks internet** | UniFi Controller PC is offline, or Windows Firewall is blocking ports `8880`/`8843`. | Switch Wi-Fi Application from `Hotspot` to `Standard` for 24/7 controller-free operation. |
