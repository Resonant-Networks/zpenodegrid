# ZPE Nodegrid — Troubleshooting & Diagnostics Runbook

## 1. Quick Diagnostic Checklist

| Check | Command / Verification | Expected Result |
|---|---|---|
| **L2 Link / ARP** | `ssh root@192.168.0.101 "ip neigh grep 192.168.0.17"` | `192.168.0.17 lladdr be:b3:31:d9:bb:03 REACHABLE` |
| **Ping from Hypervisor** | `ssh root@192.168.0.101 "ping -c 2 192.168.0.17"` | `0% packet loss` |
| **HTTPS Port Check** | `ssh root@192.168.0.101 "nc -zv 192.168.0.17 443"` | `Connection to 192.168.0.17 443 port [tcp/https] succeeded!` |
| **SSH Port Check** | `ssh root@192.168.0.101 "nc -zv 192.168.0.17 22"` | `Connection to 192.168.0.17 22 port [tcp/ssh] succeeded!` |

---

## 2. Common Symptoms & Remediation

### 2.1 Symptom: Web UI Fails to Load from Workstation (Timeout / Blank)

* **Behavior**: Navigating to `https://192.168.0.17` from your laptop hangs or times out, but SSH to Proxmox works fine.
* **Root Cause**: The Nodegrid appliance has **IP Access Control** enabled, filtering out web requests that do not originate from authorized management IPs (such as the Proxmox host `192.168.0.101`).
* **Solution**: Establish an encrypted SSH tunnel via Proxmox:
  ```bash
  ssh -L 8443:192.168.0.17:443 root@100.118.216.78
  ```
  Then access `https://localhost:8443` in your browser. All requests are presented to Nodegrid as coming from `192.168.0.101`.

---

### 2.2 Symptom: "Destination Host Unreachable" or STALE ARP

* **Behavior**: Pinging `192.168.0.17` returns `Destination Host Unreachable`, and `ip neigh` reports `STALE` or `FAILED`.
* **Root Cause**: 
  1. The Nodegrid hardware appliance is powered off or rebooting.
  2. Ethernet cable disconnected from the management network switch or `vmbr0` bridge.
  3. DHCP lease changed or expired (if static IP is not set on device).
* **Remediation**:
  1. Verify physical power LED on the ZPE hardware unit.
  2. Verify Ethernet link lights on the primary management NIC (labeled `ETH0` or `MGMT`).
  3. Force ARP refresh from Proxmox:
     ```bash
     arping -I vmbr0 -c 3 192.168.0.17
     ```

---

### 2.3 Symptom: Browser Certificate Security Alert

* **Behavior**: Browser shows `NET::ERR_CERT_AUTHORITY_INVALID` or `Your connection is not private`.
* **Root Cause**: The Nodegrid appliance utilizes an internal self-signed X.509 certificate:
  * **CN**: `e41a2c04073d`
  * **Organization**: `ZPE Systems Inc`
  * **Organizational Unit**: `NodeGrid`
* **Remediation**:
  * For temporary access: Click **Advanced** → **Proceed to localhost (unsafe)**.
  * For permanent browser trust: Export the appliance certificate and install it in your operating system's Trusted Root Certification Authorities store.

---

### 2.4 Symptom: Cannot Access via Remote Tailscale

* **Behavior**: Tailscale is connected, but pinging `192.168.0.17` fails.
* **Troubleshooting Steps**:
  1. Check if subnet routes are accepted on client:
     ```bash
     tailscale status
     ```
  2. Verify routes on Proxmox:
     ```bash
     ssh root@100.118.216.78 "tailscale status --json | grep PrimaryRoutes"
     ```
  3. Fallback method: Use SSH ProxyJump (which operates entirely at layer 7 through SSH):
     ```bash
     ssh -J root@100.118.216.78 admin@192.168.0.17
     ```
