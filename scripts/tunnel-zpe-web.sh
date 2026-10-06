#!/usr/bin/env bash
# ==============================================================================
# Helper Script: Establish SSH Tunnel to ZPE Nodegrid Web UI
# ==============================================================================
set -euo pipefail

PROXMOX_HOST="${PROXMOX_HOST:-100.118.216.78}"
PROXMOX_USER="${PROXMOX_USER:-root}"
ZPE_IP="${ZPE_IP:-192.168.0.17}"
LOCAL_PORT="${LOCAL_PORT:-8443}"

echo "================================================================"
echo " Establishing SSH Tunnel to ZPE Systems Nodegrid Web UI"
echo " Target:     https://${ZPE_IP}:443"
echo " Relay Host: ${PROXMOX_USER}@${PROXMOX_HOST}"
echo " Local Port: https://localhost:${LOCAL_PORT}"
echo "================================================================"
echo ""
echo "Once connected, open your browser to: https://localhost:${LOCAL_PORT}"
echo "Press Ctrl+C to stop the tunnel."
echo ""

exec ssh -N -L "${LOCAL_PORT}:${ZPE_IP}:443" "${PROXMOX_USER}@${PROXMOX_HOST}"
