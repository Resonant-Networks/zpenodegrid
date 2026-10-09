# Resonant Networks — ZPE Systems Nodegrid (`zpenodegrid`)

Welcome to the centralized source of truth for **ZPE Systems Nodegrid** Out-of-Band (OOB) Management and Serial Console infrastructure across Resonant Networks.

---

## 📌 Executive Summary

The **ZPE Systems Nodegrid** appliance provides dedicated, hardware-isolated out-of-band management and RS-232 serial console connectivity for bare-metal datacenter infrastructure. In our deployment, Nodegrid directly manages the primary virtualization hypervisor host:

* **Managed Server:** Dell PowerEdge R520 (`rm1dev`)
* **Dell Service Tag:** `J3FSWX1`
* **Appliance Role:** Out-of-Band Serial Console Server & Remote Hardware Recovery Gateway

---

## 🏛️ Deployment & Network Topology

```
Remote Engineer (Tailscale / Internet)
    │
    ▼
Proxmox Hypervisor Host (`rm1dev` — 100.118.216.78 / 192.168.0.101)
    │  Acts as Tailscale Subnet Router (192.168.0.0/24) & SSH Relay Host
    │
    ▼ (Internal L2 Bridge vmbr0 / LAN Switch)
ZPE Systems Nodegrid Appliance (192.168.0.17)
    ├─ Web UI (HTTPS): Port 443 (IP-restricted)
    ├─ SSH Console: Port 22
    └─ Serial Cable (COM2) ───────► Dell PowerEdge R520 (BIOS/Kernel Serial Console)
```

### Quick Technical Reference

| Parameter | Value | Description |
|---|---|---|
| **Appliance Model** | ZPE Systems NodeGrid Series | Linux-based Out-of-Band Operating System |
| **LAN Management IP** | `192.168.0.17` | Bound to management network bridge `vmbr0` |
| **MAC Address** | `be:b3:31:d9:bb:03` | Hardware MAC on `192.168.0.0/24` subnet |
| **Default Gateway** | `192.168.0.1` | Local network router |
| **Default User** | `admin` | Appliance CLI and Web UI administrator |
| **SSL Certificate Subject** | `CN=e41a2c04073d` | Self-signed certificate issued by ZPE Systems |
| **Managed Console Target** | `console com2` | Serial COM2 port on Dell PowerEdge R520 |

---

## 🚀 Quick Access Methods

### 1. Web Management UI (Via SSH Tunnel — Recommended)

The Nodegrid web management portal has IP access control filtering enabled that accepts traffic originating from the Proxmox host (`192.168.0.101`). Use an SSH tunnel to connect from any remote laptop or workstation:

```bash
# Run one-line tunnel command:
ssh -L 8443:192.168.0.17:443 root@100.118.216.78

# Or execute the helper script:
./scripts/tunnel-zpe-web.sh
```

Then open your browser to **[`https://localhost:8443`](https://localhost:8443)** (accept the self-signed certificate warning).

---

### 2. SSH Console Access (Double-Hop / Jump Host)

To connect directly to the Nodegrid command-line interface from remote machines:

```bash
# Using SSH ProxyJump:
ssh -J root@100.118.216.78 admin@192.168.0.17

# Or execute the helper script:
./scripts/connect-zpe-ssh.sh
```

If connecting directly on the office LAN with subnet access:
```bash
ssh admin@192.168.0.17
```

---

## 🖥️ Serial Console Session Management

Once authenticated to the Nodegrid shell:

### Connect to Server Console:
```bash
[admin@nodegrid ~]$ console com2
```
*(Press `<Enter>` to display the login prompt or system console).*

### Essential Escape Sequences:
| Key Sequence | Action |
|---|---|
| `<Enter>` followed by `~.` | **Exit serial console** and return to Nodegrid shell |
| `<Enter>` followed by `~#` | **Send hardware RS-232 BREAK** (for bootloader/SysRq) |
| `<Enter>` followed by `~?` | **Help** — display supported escape keys |
| `<Enter>` followed by `~k` | **Force disconnect** previous active connection |

---

## 📂 Repository Structure

```
zpenodegrid/
├── README.md                            # Central knowledge base & quick reference (this file)
├── .gitignore                           # Exclude secret keys and environment artifacts
│
├── docs/                                # Detailed technical specifications and runbooks
│   ├── architecture-and-topology.md     # Hardware specs, network architecture & IP policy
│   ├── access-mop.md                    # Step-by-step Method of Procedure (MOP)
│   ├── serial-console-management.md     # Serial session controls, baud rates & escape keys
│   ├── troubleshooting-guide.md         # Diagnostic runbook for ACL, ARP, and connectivity
│   └── tailscale-docker-subnet-router.md # Dockerized Tailscale subnet router specification
│
└── scripts/                             # Operational automation scripts
    ├── tunnel-zpe-web.sh                # Automated port-forwarding for Web UI (localhost:8443)
    └── connect-zpe-ssh.sh               # One-click SSH jump connection script
```

---

## 🔒 Security Guidelines

* This repository is maintained as a **public** engineering reference.
* **Never commit plaintext administrative passwords, private SSH keys (`id_rsa`), or sensitive credentials.**
* Production deployments must utilize SSH key authentication and restricted access controls.

---

## 👥 Maintainers & Contributors

* **Resonant Networks Engineering Team**
* **Repository:** [https://github.com/Resonant-Networks/zpenodegrid](https://github.com/Resonant-Networks/zpenodegrid)
