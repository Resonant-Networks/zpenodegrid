# Pi Coding Agent Harness (`pi.dev`) on ZPE Systems Nodegrid

This document specifies the architecture, operation, and maintenance of the **`pi.dev`** Docker container harness running natively inside the **ZPE Systems Nodegrid** appliance (`RM1-ZPE`).

---

## 1. Overview & Architecture

The `pi.dev` container is an autonomous, self-hosted AI agent harness powered by `@earendil-works/pi-coding-agent`. By running directly inside the Nodegrid Docker daemon (`dockerd 24.0.9-ce`) on `RM1-ZPE` (`100.119.254.114`), the agent can operate directly on the appliance with zero network hop latency to:
- RS-232 serial console ports (`/dev/ttyS1` through `/dev/ttyS8`, `/dev/ttyUSB2` / `console com2`).
- Nodegrid local services and APIs (port 443 / 8443 web services, Cockpit port 4880).
- Local persistent workspaces and diagnostic automation scripts.

```
┌──────────────────────────────────────────────────────────────┐
│                    Cloud AI Provider                         │
│             OpenRouter (api.openrouter.ai)                   │
└──────────────────────────────▲───────────────────────────────┘
                               │ HTTPS (Inference API)
┌──────────────────────────────┴──────────────────────────────┐
│          ZPE Systems Nodegrid Appliance (RM1-ZPE)            │
│                  (IP: 100.119.254.114)                       │
│                                                             │
│   Docker Engine (dockerd 24.0.9-ce)                         │
│     └── Container: pi.dev (--net=host, --group-add dialout)  │
│           ├── Node.js 22 LTS Runtime                        │
│           ├── Pi Coding Agent CLI & Tools                   │
│           ├── Workspace: /home/agent/workspace              │
│           ├── State & Config: /home/agent/.pi/agent         │
│           └── Devices: /dev/ttyS1, /dev/ttyS2               │
│                                │ Direct RS-232 Serial       │
│                                ▼                            │
│                 Dell PowerEdge R520 (COM2 Console)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Model Provider Configuration (OpenRouter)

`pi.dev` is configured to use **OpenRouter** as its primary AI provider:
- **Default Provider**: `openrouter`
- **Default Model**: `anthropic/claude-sonnet-latest` (configurable to any model in the OpenRouter catalog)
- **Configuration Path on ZPE**: `/home/agent/.pi/agent/settings.json`
- **Environment Variable**: `OPENROUTER_API_KEY` (injected at container startup)

### Switching Models On-the-Fly
Inside an interactive Pi session:
```bash
/model openrouter/deepseek/deepseek-chat
/model openrouter/openai/gpt-4o-mini
/model openrouter/google/gemini-flash-latest
```

Or from the command line:
```bash
./scripts/zpe-pi.sh --model openrouter/openai/gpt-4o-mini "Check disk usage and report"
```

---

## 3. Operational Quick Reference

### 3.1 Connecting to the Interactive Agent Session
From `rm1dev-control` (or any machine with SSH access to `agent@100.119.254.114`):

```bash
./scripts/zpe-pi.sh
```

### 3.2 Running One-Off Commands / Background Tasks
```bash
# Ask the agent to inspect files in the workspace:
./scripts/zpe-pi.sh -p "List files in /workspace and report status"

# Read serial port activity:
./scripts/zpe-pi.sh -p "Check if /dev/ttyS2 has active carrier signal or output"
```

### 3.3 Container Lifecycle Controls on RM1-ZPE
From an SSH shell on `RM1-ZPE`:

```bash
# Check container status
docker ps --filter name=pi.dev

# View container logs
docker logs -f pi.dev

# Restart container
docker restart pi.dev

# Stop container
docker stop pi.dev
```

---

## 4. Re-deploying and Updating

To update the image or push new changes from the repository:

```bash
./scripts/deploy-pi-to-zpe.sh
```

This builds the latest image on the control host and streams the compressed binary directly to `RM1-ZPE` without requiring network builds or npm compilation on the appliance itself.
