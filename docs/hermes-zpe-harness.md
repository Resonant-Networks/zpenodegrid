# Hermes Agent Harness on ZPE Systems Nodegrid

This document provides the operational specification for running **Hermes Agent** ([`nousresearch/hermes-agent`](https://hub.docker.com/r/nousresearch/hermes-agent)) inside the Docker engine of the **ZPE Systems Nodegrid** appliance (`RM1-ZPE`).

---

## 1. Overview & Architecture

**Hermes Agent** is an autonomous AI assistant with native tool-calling capabilities (Bash, file read/write/edit, Git, memory, skills, serial ports, and web search). Running natively inside `dockerd` on `RM1-ZPE` (`100.119.254.114`), Hermes has local hardware-level access to:

* **Hardware RS-232 Serial Consoles**: `/dev/ttyS1` through `/dev/ttyS8`, `/dev/ttyUSB2` (e.g. `console com2` on Dell PowerEdge R520).
* **Nodegrid Web & APIs**: Localhost HTTP/HTTPS (ports 443 / 8443) and Cockpit (port 4880).
* **Persistent Workspace**: `/home/agent/workspace` mounted to `/workspace`.
* **State & Memory Database**: `/home/agent/.hermes` mounted to `/opt/data`.

```
┌──────────────────────────────────────────────────────────────┐
│                    Cloud AI Provider                         │
│             OpenRouter (https://openrouter.ai)               │
└──────────────────────────────▲───────────────────────────────┘
                               │ HTTPS API
┌──────────────────────────────┴──────────────────────────────┐
│          ZPE Systems Nodegrid Appliance (RM1-ZPE)            │
│                  (IP: 100.119.254.114)                       │
│                                                             │
│   Docker Engine (dockerd 24.0.9-ce)                         │
│     └── Container: hermes (--net=host, --group-add dialout)  │
│           ├── Python 3.11 / OpenAI SDK Runtime              │
│           ├── Hermes Agent CLI & Toolsets                   │
│           ├── State & Memory: /home/agent/.hermes           │
│           ├── Workspace: /home/agent/workspace              │
│           └── Devices: /dev/ttyS1, /dev/ttyS2               │
│                                │ Direct RS-232 Serial       │
│                                ▼                            │
│                 Dell PowerEdge R520 (COM2 Console)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Configuration & Model Selection (OpenRouter)

Hermes is configured out-of-the-box with **OpenRouter**:
* **Config File on ZPE**: `/home/agent/.hermes/config.yaml`
* **Environment Credentials**: `/home/agent/.hermes/.env` (`OPENROUTER_API_KEY`)
* **Default Model**: `anthropic/claude-sonnet-latest`

### Switching Models in Hermes
Inside an interactive session:
```bash
/model openrouter/deepseek/deepseek-chat
/model openrouter/openai/gpt-4o-mini
/model openrouter/google/gemini-flash-latest
```

Or from the command line:
```bash
hermes -m openrouter/deepseek/deepseek-chat
```

---

## 3. Operational Quick Reference

### 3.1 From Remote Control Host (`rm1dev-control`)
```bash
# Start interactive Hermes chat session
./scripts/zpe-hermes.sh

# Run one-off instruction / non-interactive task
ssh agent@100.119.254.114 'docker exec -w /workspace hermes hermes -z "Check serial port /dev/ttyS2"'
```

### 3.2 From Direct Shell on `RM1-ZPE` (`agent@RM1-ZPE`)
A launcher is installed at `/home/agent/bin/hermes`:
```bash
# Launch interactive chat
hermes

# Run a one-off prompt
hermes -z "Inspect network interfaces and report"
```

### 3.3 Container Lifecycle Controls on RM1-ZPE
```bash
# Check container status
docker ps --filter name=hermes

# View logs
docker logs -f hermes

# Restart container
docker restart hermes
```

---

## 4. Re-deploying and Updating
To re-deploy or update configuration:
```bash
./scripts/deploy-hermes-to-zpe.sh
```
