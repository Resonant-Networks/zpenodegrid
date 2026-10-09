# Tailscale Docker Subnet Router for ZPE Nodegrid

This document provides the standard procedure and Docker deployment specification for running **Tailscale in Docker** as a dedicated subnet router for the **ZPE Systems Nodegrid** appliance and the local management LAN.

---

## 1. Overview & Architecture

When bare-metal host Tailscale installation is not desirable or when deploying via containerized gateway infrastructure, Tailscale can be deployed inside a Docker container.

```
Remote Engineers (Tailscale Client with --accept-routes)
                 │
                 ▼
        Tailscale Encrypted Mesh
                 │
                 ▼
   Docker Host (IP Forwarding Enabled)
     └── Container: tailscale-node (--net=host, Subnet Router)
                 │
                 ▼ (LAN Bridge / L2 Network)
   ZPE Systems Nodegrid Appliance (192.168.0.17:22, :443)
```

---

## 2. Prerequisites

### 2.1 Enable Host IP Forwarding (Linux Host)
For the Tailscale container to route packets between the Tailnet and the physical/virtual network interfaces, IPv4 packet forwarding must be enabled on the Docker host:

```bash
# Enable dynamically
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Persist across reboots
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### 2.2 TUN Device Availability
Ensure `/dev/net/tun` exists on the host:
```bash
ls -l /dev/net/tun
# If missing:
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 600 /dev/net/tun
```

---

## 3. Docker Deployment Specification

### 3.1 Docker CLI Command

```bash
docker run -d \
  --name tailscale-node \
  --hostname West-ZPE \
  --restart unless-stopped \
  --net=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device=/dev/net/tun:/dev/net/tun \
  -e TS_STATE_DIR=/var/lib/tailscale \
  -e TS_USERSPACE=false \
  -e TS_EXTRA_ARGS="--advertise-routes=192.168.0.0/24" \
  -v tailscale-state:/var/lib/tailscale \
  tailscale/tailscale:latest
```

> **Targeted Routing Alternative**: If you wish to advertise *only* the ZPE appliance rather than the entire `/24` subnet, change:
> `-e TS_EXTRA_ARGS="--advertise-routes=192.168.0.17/32"`

---

### 3.2 Parameter Reference

| Parameter | Purpose | Rationale |
|---|---|---|
| `--name tailscale-node` | Container identification | Predictable name for operational management and log streaming. |
| `--hostname West-ZPE` | Tailnet device hostname | Identifies the node inside the Tailscale Admin Console and MagicDNS. |
| `--restart unless-stopped` | Auto-restart policy | Ensures the subnet router restarts on host reboot or Docker daemon restart. |
| `--net=host` | Host network namespace | **Critical**: Grants direct access to host network interfaces and physical routing table. |
| `--cap-add=NET_ADMIN` | Linux capability | Allows configuring network interfaces, IP routes, and iptables inside the container. |
| `--cap-add=NET_RAW` | Linux capability | Permits raw socket operations and ICMP packet crafting. |
| `--device=/dev/net/tun` | Virtual tunnel character device | Allows kernel-level WireGuard tunneling interface creation. |
| `-e TS_STATE_DIR=...` | Internal state directory | Directs state and node keys to `/var/lib/tailscale`. |
| `-e TS_USERSPACE=false` | Kernel networking mode | Utilizes high-performance Linux kernel WireGuard/TUN rather than userspace networking. |
| `-e TS_EXTRA_ARGS=...` | Tailscale startup flags | Passes `--advertise-routes=192.168.0.0/24` directly to `tailscale up`. |
| `-v tailscale-state:...` | Persistent Docker volume | Preserves Tailscale identity, authentication tokens, and node keys across recreations. |

---

### 3.3 Equivalent Docker Compose (`docker-compose.yml`)

For infrastructure-as-code deployments:

```yaml
version: "3.8"

services:
  tailscale-node:
    image: tailscale/tailscale:latest
    container_name: tailscale-node
    hostname: West-ZPE
    network_mode: host
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
      - TS_EXTRA_ARGS=--advertise-routes=192.168.0.0/24
      # Optional: Provide auth key to automatically authenticate on first boot:
      # - TS_AUTHKEY=tskey-auth-kXXXXX-XXXXXXXXXXXXXXXXXXXXX
    volumes:
      - tailscale-state:/var/lib/tailscale

volumes:
  tailscale-state:
    name: tailscale-state
```

---

## 4. Post-Deployment & Operational Workflow

### Step 1: Authenticate the Container to Tailnet
If `TS_AUTHKEY` was not supplied during container startup:

1. Fetch the authentication URL from container logs:
   ```bash
   docker logs tailscale-node
   ```
2. Open the printed URL (e.g., `https://login.tailscale.com/a/...`) in your browser and authorize the node with your Tailnet account.

Alternatively, initiate interactive authentication:
```bash
docker exec -it tailscale-node tailscale up --advertise-routes=192.168.0.0/24
```

---

### Step 2: Approve Advertised Subnet Route (Admin Console)
Tailscale does not route subnet traffic until explicitly approved by an administrator:

1. Navigate to the **[Tailscale Admin Console → Machines](https://login.tailscale.com/admin/machines)**.
2. Locate the node named **`West-ZPE`**.
3. Click the three dots `...` → **Edit route settings...**.
4. Check the box for **`192.168.0.0/24`** (or `192.168.0.17/32`) and click **Save**.

---

### Step 3: Verify Remote Client Access
From any remote machine connected to the same Tailnet:

1. Ensure the client accepts advertised routes:
   * **Linux / macOS**:
     ```bash
     sudo tailscale up --accept-routes
     ```
   * **Windows** (PowerShell Administrator):
     ```powershell
     tailscale up --accept-routes
     ```
2. Verify ICMP ping to the ZPE Nodegrid:
   ```bash
   ping 192.168.0.17
   ```
3. Test SSH access to ZPE Nodegrid:
   ```bash
   ssh admin@192.168.0.17
   ```

---

## 5. Maintenance & Troubleshooting

### Inspect Container Tailscale Status
```bash
docker exec -it tailscale-node tailscale status
```

### Inspect Subnet Routes Exported by Container
```bash
docker exec -it tailscale-node tailscale status --json | grep -A 5 "AdvertisedRoutes"
```

### Restart Container
```bash
docker restart tailscale-node
```

### Tear Down & Reset
```bash
docker stop tailscale-node
docker rm tailscale-node

# To completely wipe node identity:
docker volume rm tailscale-state
```
