# 🛡️ Asus ACPI Master: Low-Level Hardware & Thermal Overrides

**Asus Power Master (v2.6 Stable)** is a modular, system-level automation tool designed for power users and system administrators. Bypassing heavy graphical interfaces, it utilizes the **Linux Kernel Sysfs interfaces** and Systemd services to bring hardware-level power, thermal, and profile management directly to your Kali or Debian Linux environment. Optimized specifically for **Asus Vivobook Pro 14X** and similar architectures.

---

## 🚀 Key Features

* **🔋 Battery Health Guard:** Implements hardware-level charge thresholds (e.g., stopping at 80%) to extend lithium battery longevity.
* **🚀 Performance & Thermal Control:** Dynamic on-the-fly toggling of Intel Turbo Boost and Fan profiles (Balanced, Overboost, Silent).
* **🧠 Smart Watchdog (Monitor):** A background sentinel that instantly detects AC/Battery power state transitions and automatically deploys user-defined profiles.
* **📊 Live Telemetry:** Deep visual metrics dashboard displaying real-time power consumption (Watts), CPU temperature, and active hardware states.
* **💾 Hybrid Profile Management:** Tailored, persistent behavioral profiles for both AC and Battery modes (`--set-ac` & `--set-bat`) running with zero conflicts.

---

## 📂 System Architecture (Local Environment)

The service maintains a clean, centralized directory structure for rapid execution, modularity, and security:

```text
/usr/local/
├── bin/
│   └── asus-pwr                  # Main executable CLI wrapper
├── share/asus-pwr/lib/           # Modular Engine Libraries
│   ├── battery.sh                # Charge limit thresholds
│   ├── dashboard.sh              # Terminal telemetry UI
│   ├── extra.sh                  # Initialization & utility paths
│   ├── performance.sh            # Turbo Boost & Fan governors
│   └── persistence.sh            # State preservation layer
/etc/
├── asus-power.conf               # Secure, whitelisted variable storage
/etc/systemd/system/
├── asus-pwr.service              # Core Watchdog monitoring daemon
└── asus-pwr-persistence.service  # Boot-time configuration loader
```

---

## 🛠️ Deployment Guide

### 📋 Prerequisites
Before you begin, ensure you have the following in your local environment:
* **Linux Kernel** (with standard ACPI and Asus WMI support)
* **Root Privileges** (Superuser permissions via `sudo`)
* **Systemd** framework
* **Git** & **Bash** command-line environment

### 1. Installation
Clone the repository and deploy the system modules using the official installation script:
```bash
git clone https://github.com/zuhtuEren/asus-power-master.git
cd asus-power-master
sudo bash install.sh
```

### 2. Basic CLI Operations
Directly control your hardware via simple switches:

| Command        | Parameter | Description                                            |
| :------------: | :-------: | :----------------------------------------------------: |
| `-s, --status` | None      | Displays the live system telemetry dashboard.          |
| `-b, --battery`| `[60-100]`| Sets the battery charge limit. Append `-p` to save.    |
| `-t, --turbo`  | `[on,off]`| Toggles Intel CPU Turbo Boost. Append `-p` to save.    |
| `-f, --fan`    | `[0-2]`   | Fan Mode: `0` (Balanced), `1` (Overboost), `2` (Silent)|
| `-k, --keyboard`| `[0-3]`  | Sets keyboard backlight brightness level.              |
| `--monitor`    | `[-k val]`| Starts the background smart watchdog daemon.           |

### 3. Advanced Profile Customization (Hybrid Logic)
Design custom automation rules that the Watchdog engine will seamlessly apply when power states change.
* **Set AC (Plugged-in) Profile:** Fans remain balanced, Turbo enabled, and backlight level 2.
  ```bash
  sudo asus-pwr --set-ac -f 0 -t on -k 2
  ```
* **Set Battery Profile:** Fans go silent, Turbo disabled, and backlight off to conserve energy.
  ```bash
  sudo asus-pwr --set-bat -f 2 -t off -k 0
  ```

### 4. Uninstallation (Complete Cleanup)
Safely purge all services, scripts, and configurations from the OS:
```bash
sudo bash uninstall.sh
```

---

## ⚙️ Automation & The Watchdog Engine

Asus Power Master is configured for **Zero-Touch Maintenance**. The following operations are automatically handled by the `asus-pwr.service`:

### Power Sentinel Monitoring
Runs continuously in the background, checking the system `/sys/class/power_supply` status every 2 seconds. Automatically loads the `/etc/asus-power.conf` user profiles based on AC connection status.
```bash
# Handled via Systemd
systemctl status asus-pwr.service
```

### Boot State Persistence
Ensures last-saved parameters and critical configurations (like battery health limits) are re-applied immediately during system startup via the underlying persistence daemon.

---

## 🛡️ Hardware Control Overview

| Layer            | Implementation             | Benefit                                             |
| :--------------: | :------------------------: | :-------------------------------------------------: |
| **Battery Life** | Sysfs Threshold Logic      | Prevents micro-cycles; extends battery by years.    |
| **Thermal**      | WMI Throttle Policy        | Maintains cool temps via Overboost or Silent modes. |
| **Processor**    | Intel P-State Control      | Eliminates unnecessary clock spikes on battery.     |
| **Security**     | Strict Config Whitelisting | Prevents shell code injection via settings file.    |
| **UI/UX**        | Terminal Telemetry         | Low overhead system tracking without heavy GUI apps.|

---

## 🔗 Powered By (Tech Stack & Interfaces)

Asus Power Master interacts closely with the raw Linux kernel infrastructure. For specialized kernel features, refer to:

| Interface        | Role            | Documentation                               |
| :-------------: | :-------------: | :-----------------------------------------: |
| **ACPI / WMI**  | Asus WMI Driver | [kernel.org hwmon](https://www.kernel.org/) |
| **Intel P-State**| CPU Frequency  | [kernel.org intel_pstate](https://www.kernel.org/doc/Documentation/cpu-freq/intel-pstate.txt) |
| **Systemd**     | Service Engine  | [systemd.io](https://systemd.io/)           |
| **Bash**        | Scripting Logic | [gnu.org/software/bash](https://www.gnu.org/software/bash/) |

---

## ⚠️ Disclaimer
This project alters hardware and thermal management routines via Kernel-level parameters. It is developed for educational and experimental use. The author is not responsible for any direct or indirect hardware damage or system instability. Always ensure compatibility with your specific Asus model.

---

## ⚖️ License
Distributed under the MIT License. See `LICENSE` for more information.
