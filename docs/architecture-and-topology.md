# ZPE Systems Nodegrid — Architecture & Topology

## 1. Overview

At Resonant Networks, the **ZPE Systems Nodegrid** appliance serves as the primary **Out-of-Band (OOB) Management** and serial console server for physical server hardware, primarily managing the **Dell PowerEdge R520** host (`rm1dev`).

While Dell servers traditionally utilize Dell iDRAC, out-of-band management and direct console access in this deployment is managed via the **ZPE Systems Nodegrid** appliance connected to the server's serial interface.

---

## 2. Hardware & Device Specifications

| Attribute | Specification | Notes |
|---|---|---|
| **Manufacturer** | ZPE Systems Inc. | NodeGrid Series |
| **Appliance Type** | Serial Console / Out-of-Band Management Appliance | Dedicated Linux OOB OS |
| **Device CN / Serial** | `e41a2c04073d` | Embedded in SSL Certificate |
| **MAC Address** | `be:b3:31:d9:bb:03` | Bound on `vmbr0` (LAN) |
| **Primary IP Address** | `192.168.0.17` | LAN Subnet `192.168.0.0/24` |
| **Subnet Mask** | `255.255.255.0` (`/24`) | |
| **Default Gateway** | `192.168.0.1` | Local Network Router |
| **SSL Certificate Subject** | `C=US, ST=CA, L=Fremont, O=ZPE Systems Inc, OU=NodeGrid, CN=e41a2c04073d` | Self-signed |
| **Managed Host** | Dell PowerEdge R520 (`rm1dev`) | Service Tag: `J3FSWX1` |
| **Console Binding** | Serial Port COM2 (`console com2`) | Direct serial cable |

---

## 3. Network Topology Diagram

```
                 ┌──────────────────────────────────────────────┐
                 │          Network Router / Gateway            │
                 │                192.168.0.1                   │
                 └──────────────────────┬───────────────────────┘
                                        │
           ┌────────────────────────────┼────────────────────────────┐
           │                            │                            │
           ▼                            ▼                            ▼
┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│  ZPE Nodegrid OOB    │    │  Proxmox VE Host     │    │  Client Workstations │
│  192.168.0.17        │    │  `rm1dev`            │    │  192.168.0.15 (Win)  │
│                      │    │  192.168.0.101 (LAN) │    │  192.168.0.9 (Ubuntu)│
│  - Web UI: Port 443  │    │  100.118.216.78 (TS) │    │                      │
│  - SSH: Port 22      │    │                      │    │                      │
└──────────┬───────────┘    └──────────┬───────────┘    └──────────────────────┘
           │                           │
           │ Serial Connection (COM2)  │ (Physical Chassis)
           └───────────────────────────┘
```

---

## 4. Logical Connectivity & Routing

### 4.1 Subnet Routing via Tailscale
The Proxmox VE host (`100.118.216.78`) acts as the Tailscale subnet router advertising `192.168.0.0/24` and `10.90.39.0/24`. Remote engineers connected to Tailscale with `--accept-routes` can route IP packets destined for `192.168.0.17` directly through the Proxmox encrypted tunnel.

### 4.2 IP Access Filtering (Security Policy)
By default, the Nodegrid web management service enforces an access control list (ACL) allowing administrative connections originating from the primary hypervisor management IP (`192.168.0.101`). 

For clients connecting from other IPs (e.g., Windows laptop `192.168.0.15` or remote Tailscale clients), direct HTTPS requests may be blocked or dropped by the appliance firewall. To guarantee web access, an **SSH local port-forwarding tunnel** through Proxmox is used:

```
Remote Client Browser
       │ (https://localhost:8443)
       ▼
Local Port 8443
       │ (Encrypted SSH Tunnel)
       ▼
Proxmox Host (192.168.0.101 / 100.118.216.78)
       │ (Forwarded as source 192.168.0.101)
       ▼
ZPE Nodegrid (192.168.0.17:443)
```
