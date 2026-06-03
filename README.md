# 🚀 Ultimate Debian Updater v2.8.2

Ein intelligentes All-in-one Update-Skript für Debian-basierte Systeme (Debian, Mint, Ubuntu), das alle gängigen Paketmanager und Gaming-Tools in einem einzigen Befehl vereint.

## ✨ Features (v2.8.2)

- **Parameter-Steuerung**: `--full`, `--system`, `--game` für gezielte Updates.
- **Desktop-Optimierung**: Spezifische Unterstützung für Cinnamon, GNOME, XFCE, KDE (pkcon), Mate und SteamOS (Gamescope).
- **Gamer-Mode (Intelligent)**: 
    - Automatische Diagnose (32-Bit Libs, GPU-Treiber).
    - **Verbessert:** Explizite Proton-GE Diagnose & Update-Check mit Versionshinweisen.
    - MangoHud (Source-Check), GOverlay, vkBasalt & Protontricks Support.
- **Hardware-Check**: Erkennt NVIDIA (inkl. Treiberversion), AMD (Mesa) und Intel.
- **Auto-Installation**: Erkennt fehlende Tools und bietet die Installation (APT/Pipx) direkt an.
- **Transparenz**: Alle relevanten Gaming-Tools erscheinen nun im Abschlussbericht.
- **Flexibilität**: Präzise Distribution-Erkennung für personalisierte Wartungsmeldungen.

## 📊 Kompatibilitätsmatrix
Das Skript wurde auf folgenden Konfigurationen erfolgreich getestet:

| Distro | Desktop | 32bit | 64bit | arm | AMD | Nvidia |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Debian 12** | Cinnamon | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Debian 12** | GNOME | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Debian 12** | XFCE | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Debian 12** | KDE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13** | Cinnamon | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13** | GNOME | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13** | XFCE | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Debian 13** | KDE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | Cinnamon | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | GNOME | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | XFCE | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 24.04** | KDE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | Cinnamon | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | GNOME | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | XFCE | ✅ | ✅ | ❔ | ✅ | ❔ |
| **Ubuntu 25.04** | KDE | ❔ | ✅ | ❔ | ✅ | ❔ |
| **PopOS 24** | GNOME | ❔ | ✅ | ❔ | ✅ | ❔ |
| **Linux Mint** | Mate | ❔ | ✅ | ❔ | ✅ | ❔ |
| **LMDE 7** | Cinnamon | ❔ | ✅ | ❔ | ✅ | ❔ |
| **CachyOS** | GNOME | ❔ | ❔| ❔ | ❔| ❔ |
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

## 📦 Installation

### Methode 1: .deb Paket (Empfohlen)
Lade die aktuellste `.deb` Datei aus den [Releases](https://github.com/DerLinke/Ultimate-Debian-Updater/releases) herunter und installiere sie:
```bash
sudo apt install ./ultimate-debian-updater_2.8.1_all.deb
```
*Vorteil: Automatisches Handling der Abhängigkeiten und der Befehl `update` ist systemweit verfügbar.*

### Methode 2: Automatischer Alias
Wenn du das Skript direkt ausführst, prüft es, ob der Befehl `update` bereits existiert. Falls nicht, bietet es dir an, automatisch einen Alias in deiner `.bashrc` oder `.zshrc` zu erstellen:
```bash
chmod +x update.sh
./update.sh
```

---
<p align="center">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 550 110" width="550" height="110">
    <defs>
      <linearGradient id="glitch-grad" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" style="stop-color:#FF0000;stop-opacity:1" />
        <stop offset="40%" style="stop-color:#D70046;stop-opacity:1" />
        <stop offset="70%" style="stop-color:#7800B4;stop-opacity:1" />
        <stop offset="100%" style="stop-color:#0000FF;stop-opacity:1" />
      </linearGradient>
    </defs>
    <g font-family="monospace" font-size="16" font-weight="bold">
      <text x="10" y="20" fill="url(#glitch-grad)" xml:space="preserve">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;████</text>
      <text x="10" y="40" fill="url(#glitch-grad)" xml:space="preserve">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██</text>
      <text x="10" y="60" fill="url(#glitch-grad)" xml:space="preserve">██&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;████</text>
      <text x="225" y="60" fill="currentColor">Ultimate Debian Updater</text>
      <text x="10" y="80" fill="url(#glitch-grad)" xml:space="preserve">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██</text>
      <text x="10" y="100" fill="url(#glitch-grad)" xml:space="preserve">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;████</text>
    </g>
  </svg>
</p>

---
<p align="center">
  <img src="https://derlinke.github.io/logo.svg" width="300" alt="Logo"><br>
  <strong>DerLinke Software Zentrale</strong><br>
  <a href="https://derlinke.github.io/">Offizielle Webseite</a> | <a href="https://github.com/DerLinke/Ultimate-Debian-Updater">GitHub Repository</a>
</p>
