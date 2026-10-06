#!/usr/bin/env bash
# ==============================================================================
# Helper Script: Connect to ZPE Nodegrid SSH Console via ProxyJump
# ==============================================================================
set -euo pipefail

PROXMOX_HOST="${PROXMOX_HOST:-100.118.216.78}"
PROXMOX_USER="${PROXMOX_USER:-root}"
ZPE_IP="${ZPE_IP:-192.168.0.17}"
ZPE_USER="${ZPE_USER:-admin}"

echo "Connecting to ZPE Nodegrid (${ZPE_USER}@${ZPE_IP}) via ${PROXMOX_USER}@${PROXMOX_HOST}..."
exec ssh -J "${PROXMOX_USER}@${PROXMOX_HOST}" "${ZPE_USER}@${ZPE_IP}"
