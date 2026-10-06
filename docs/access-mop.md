# Method of Procedure (MOP): Accessing ZPE Systems Nodegrid

| Document Property | Value |
|---|---|
| **Document Version** | 1.0 |
| **System** | ZPE Systems Nodegrid Out-of-Band Console Gateway |
| **Target Appliance** | `192.168.0.17` |
| **Author** | Resonant Networks Engineering |

---

## 1. Overview & Objective

This document defines the standard operating procedures for network and system engineers to securely access the **ZPE Systems Nodegrid** out-of-band management gateway, both locally within the datacenter/lab LAN and remotely via Tailscale.

---

## 2. Access Matrix

| Target Interface | Access Type | Network Path | Command / Endpoint |
|---|---|---|---|
| **Web UI (HTTPS)** | **SSH Tunnel (Recommended)** | Proxmox Relay | `ssh -L 8443:192.168.0.17:443 root@100.118.216.78`<br>Then open `https://localhost:8443` |
| **Web UI (HTTPS)** | Direct LAN | Local L2 | `https://192.168.0.17:443` *(Requires allowed source IP)* |
| **SSH Console** | **SSH Jump (ProxyJump)** | Proxmox Relay | `ssh -J root@100.118.216.78 admin@192.168.0.17` |
| **SSH Console** | Direct LAN | Local L2 | `ssh admin@192.168.0.17` |
| **SSH Console** | Direct Tailscale | Subnet Route | `ssh admin@192.168.0.17` *(Requires `--accept-routes`)* |

---

## 3. Step-by-Step Access Procedures

### 3.1 Procedure 1: Accessing Web UI via SSH Tunnel (Recommended)

Because the Nodegrid appliance may drop HTTPS traffic from un-whitelisted client IP addresses, tunneling via the Proxmox host (`192.168.0.101`) guarantees access:

1. **Open an SSH Tunnel** from your local terminal:
   ```bash
   ssh -L 8443:192.168.0.17:443 root@100.118.216.78
   ```
   *(Or over LAN: `ssh -L 8443:192.168.0.17:443 root@192.168.0.101`)*

2. **Open Your Web Browser**:
   Navigate to:
   ```
   https://localhost:8443
   ```

3. **Bypass Self-Signed Certificate Warning**:
   The appliance uses a self-signed certificate issued to `CN=e41a2c04073d`.
   Click **Advanced** → **Proceed to localhost (unsafe)**.

4. **Log In**:
   Authenticate using standard administrative credentials (`admin`).

---

### 3.2 Procedure 2: SSH Double-Hop (Jump Host) Access

If you are remote and need CLI or serial console access:

```bash
# Using SSH ProxyJump flag (-J)
ssh -J root@100.118.216.78 admin@192.168.0.17
```

Alternatively, log into Proxmox first and initiate the session:
```bash
ssh root@100.118.216.78
# From Proxmox shell:
ssh admin@192.168.0.17
```

---

### 3.3 Procedure 3: Direct Tailscale Subnet Routing

If your Tailscale client has subnet routes enabled:

1. Confirm Tailscale is running with subnet routes accepted:
   * **Linux**: `sudo tailscale up --accept-routes`
   * **macOS**: `sudo tailscale up --accept-routes`
   * **Windows** (PowerShell as Admin): `tailscale up --accept-routes`
2. Test network connectivity:
   ```bash
   ssh admin@192.168.0.17
   ```

---

## 4. SSH Configuration Shortcut (`~/.ssh/config`)

To simplify access, add the following stanza to your local `~/.ssh/config` file:

```sshconfig
Host proxmox-rm1dev
    HostName 100.118.216.78
    User root

Host zpe-nodegrid
    HostName 192.168.0.17
    User admin
    ProxyJump proxmox-rm1dev
    LocalForward 8443 192.168.0.17:443
```

With this configuration:
* To connect via SSH: simply run `ssh zpe-nodegrid`.
* While the SSH session is open, `https://localhost:8443` will be forwarded automatically.
