# 🚀 Ultimate Debian Updater v2.8.0

Ein intelligentes All-in-one Update-Skript für Debian-basierte Systeme (Debian, Mint, Ubuntu), das alle gängigen Paketmanager und Gaming-Tools in einem einzigen Befehl vereint.

## ✨ Features (v2.8.0)

- **Parameter-Steuerung**: `--full`, `--system`, `--game` für gezielte Updates.
- **Desktop-Optimierung**: Spezifische Unterstützung für Cinnamon, GNOME, XFCE, KDE (pkcon), Mate und SteamOS (Gamescope).
- **Gamer-Mode (Intelligent)**: 
    - Automatische Diagnose (32-Bit Libs, GPU-Treiber).
    - GE-Proton Update-Check via ProtonUp.
    - MangoHud (Source-Check), GOverlay, vkBasalt & Protontricks Support.
- **Hardware-Check**: Erkennt NVIDIA (inkl. Treiberversion), AMD (Mesa) und Intel.
- **Auto-Installation**: Erkennt fehlende Tools und bietet die Installation (APT/Pipx) direkt an.

## 📊 Kompatibilitätsmatrix
Das Skript wurde auf folgenden Konfigurationen erfolgreich getestet:

| Distro | Desktop | 32bit | 64bit | arm | AMD | Nvidia |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Debian 12** | Cinnamon | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Debian 12** | GNOME | ❔ | ❔ | ❔ | ❔ | ❔ |
| **Debian 12** | XFCE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Debian 12** | KDE | ❔ | ❔ | ❔ | ❔ | ❔ |
| **Debian 13 (Trixie)** | Cinnamon | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13 (Trixie)** | GNOME | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13 (Trixie)** | XFCE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13 (Trixie)** | KDE | ❔ | ❔ | ❔ | ❔ | ❔ |
| **Ubuntu 24.04** | Cinnamon | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | GNOME | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | XFCE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | KDE | ❔ | ❔ | ❔ | ❔ | ❔ |
| **Ubuntu 25.04** | Cinnamon | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | GNOME | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | XFCE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | KDE | ❔ | ❔ | ❔ | ❔ | ❔ |
| **PopOS 24** | GNOME | ❔ | ❔ | ❔ | ❔ | ❔ |
| **Linux Mint** | Mate | ❔ | ❔ | ❔ | ❔ | ❔ |
| **LMDE 7** | Cinnamon | ❔ | ✅ | ❔ | ✅ | ❔ |
| **SteamOS** | Gamescope | ❔ | ✅ | ❔ | ✅ | ❌ |

**Legende:** ✅ erfolgreich getestet | ❔ ungetestet | ❌ fehlerhaft/nicht unterstützt

## 📦 Voraussetzungen (Dependencies)
Das Skript prüft beim Start automatisch auf fehlende Pakete. Manuelle Installation:
```bash
sudo apt update && sudo apt install -y ncurses-bin whiptail libnotify-bin fwupd pciutils curl lsb-release mesa-utils vulkan-tools pipx
```

## 🚀 Nutzung

```bash
update          # Vollständiger Run (System + Gaming)
update --system # Nur System-Updates (APT, Flatpak, etc.)
update --game   # Nur Gaming-Tools (Proton, MangoHud, etc.)
update --help   # Zeigt alle Parameter an
```

---
*Created with ❤️ by DerLinke*
