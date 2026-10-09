# Implementation Plan: Deploy `pi.dev` Container Harness on ZPE Docker (Configured for OpenRouter)

> **STATUS: HISTORICAL / SUPERSEDED — DECOMMISSIONED ON 2026-10-09**  
> **Note:** This plan was successfully implemented and tested on `RM1-ZPE`. The `pi.dev` container was subsequently decommissioned and replaced by **Hermes Agent** per [plan-decom-pi-dev-and-replace-with-hermes.md](./plan-decom-pi-dev-and-replace-with-hermes.md).

---

## Goal Description (Historical Archive)
Deploy a dedicated Docker container named **`pi.dev`** directly onto the **ZPE Systems Nodegrid appliance** (`RM1-ZPE` at `100.119.254.114` / `192.168.0.17`). The container runs the open-source **Pi Coding Agent** ([`pi.dev`](https://pi.dev) / `@earendil-works/pi-coding-agent`), configured out-of-the-box with **OpenRouter** as the primary AI model provider using your OpenRouter API key.

```mermaid
graph TD
    subgraph Control_Host ["Control Host (rm1dev-control: 100.80.103.95)"]
        Builder["Docker Engine<br/>(Builds pi.dev image)"]
        DeployScript["deploy-pi-to-zpe.sh<br/>(Streams image & injects OpenRouter config)"]
        CLI["Remote CLI Helper<br/>(scripts/zpe-pi.sh)"]
    end

    subgraph ZPE_Appliance ["ZPE Nodegrid Appliance (RM1-ZPE: 100.119.254.114)"]
        ZPEDocker["ZPE Docker Daemon (dockerd 24.0.9-ce)"]
        
        subgraph Container_PIDev ["pi.dev Docker Container (HISTORICAL)"]
            PiRuntime["Node.js 22 LTS + Pi Coding Agent<br/>(@earendil-works/pi-coding-agent)"]
            OpenRouterAuth["OpenRouter Auth & Settings<br/>(OPENROUTER_API_KEY + settings.json)"]
            PiStorage["Persistent /workspace & /home/agent/.pi"]
        end

        SSHD["OpenSSH (agent@100.119.254.114)"]
        Serial["Serial Ports (/dev/ttyS1-8, /dev/ttyUSB2 / COM2)"]
        LocalServices["Local Web & API (localhost:443 / :4880)"]
    end

    subgraph External_Cloud ["Cloud AI Provider"]
        OpenRouterAPI["OpenRouter API<br/>(https://openrouter.ai/api/v1)"]
    end

    Builder -->|"docker save | gzip | ssh docker load"| ZPEDocker
    DeployScript -->|"Sets up env & settings"| OpenRouterAuth
    ZPEDocker -->|"Runs & Manages"| Container_PIDev
    CLI -->|"ssh -t agent@100.119.254.114 docker exec -it pi.dev pi"| PiRuntime
    Container_PIDev -->|"--device /dev/ttyS* / dialout"| Serial
    Container_PIDev -->|"--net=host"| LocalServices
    PiRuntime -->|"Inference Requests"| OpenRouterAPI
```

---

## Decommission Summary

1. Container `pi.dev` stopped and removed on `RM1-ZPE`.
2. Image `pi.dev:latest` purged from `RM1-ZPE` and `rm1dev-control` (reclaiming ~836MB disk space).
3. Legacy launcher links (`/home/agent/bin/pi`, `/home/agent/scripts/zpe-pi.sh`) removed on `RM1-ZPE`.
4. State directory `/home/agent/.pi` backed up to `/home/agent/.pi.bak.*`.
5. Active replacement is **Hermes Agent** (`nousresearch/hermes-agent:latest`), documented in [`docs/hermes-zpe-harness.md`](./hermes-zpe-harness.md).
