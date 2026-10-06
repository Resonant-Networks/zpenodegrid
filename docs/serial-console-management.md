# ZPE Nodegrid — Serial Console Management Guide

## 1. Overview

The ZPE Nodegrid appliance provides centralized, secure serial console access to managed infrastructure. In this environment, Nodegrid provides out-of-band console access to the Dell PowerEdge R520 server (`rm1dev`).

---

## 2. Connecting to Managed Server Consoles

Once logged into the Nodegrid command shell (`admin@nodegrid:`), you can connect to target serial ports using the `console` or `connect` utility.

### 2.1 Connecting to Dell PowerEdge R520

The Dell R520 physical console is wired to port `com2`:

```bash
[admin@nodegrid ~]$ console com2
```

Upon connection, press `<Enter>` to wake the terminal and display the login prompt or kernel console output.

---

## 3. Serial Escape Sequences & Shortcuts

When inside an active serial console session, standard keystrokes are forwarded directly to the attached machine. Use Nodegrid escape characters to control the session:

| Action | Keystroke Sequence | Description |
|---|---|---|
| **Exit Console** | `<Enter>` then `~.` | Terminate serial connection and return to Nodegrid shell |
| **Send Break** | `<Enter>` then `~#` or `~B` | Send hardware RS-232 BREAK signal (e.g. for bootloader/SysRq) |
| **Session Help** | `<Enter>` then `~?` | Display list of supported escape sequences |
| **Force Disconnect** | `<Enter>` then `~k` | Kill existing session on the port |

> [!TIP]
> Always press `<Enter>` before typing `~.` to ensure the escape character is evaluated at the start of a newline.

---

## 4. Serial Port Configuration & Baud Rates

For the Dell PowerEdge R520 Serial Redirection (COM2):

| Parameter | Recommended Value |
|---|---|
| **Baud Rate** | `115200` bps |
| **Data Bits** | `8` |
| **Parity** | `None` |
| **Stop Bits** | `1` |
| **Flow Control** | `None` / `RTS/CTS` |

### 4.1 Checking Port Status via CLI
To check the status and parameters of configured ports:
```bash
show /status/serial_ports
show /settings/devices/com2
```

---

## 5. Multi-User Access & Session Stealing

If another engineer or process is currently connected to `com2`:
- Nodegrid will prompt whether to enter **Read-Only (Snoop)** mode or **Read-Write** mode.
- Administrators can review active sessions:
  ```bash
  show /status/active_sessions
  ```
- To forcefully close an orphaned connection:
  ```bash
  kill session <session_id>
  ```
