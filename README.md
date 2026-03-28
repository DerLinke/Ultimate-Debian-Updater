# 🚀 Ultimate Debian Updater (v2.4)

Ein umfassendes All-in-one Update-Skript für Debian-basierte Linux-Systeme.

## ✨ Features (v2.4)

- **Auto-Update**: Das Skript prüft beim Start automatisch auf neue Versionen auf GitHub und kann sich auf Wunsch selbst aktualisieren.
- **Smart Hardware Diagnosis**: Erkennt NVIDIA/AMD GPUs und gibt Tipps zur optimalen Treiber-Konfiguration.
- **Backports-Check**: Prüft, ob Debian Backports aktiviert sind.
- **APT System Update**: Volles Upgrade (`full-upgrade`) inklusive Reinigung.
- **Firmware (fwupd)**: Integrierter Hardware- und BIOS-Check.
- **Flatpak & Snap**: Hält alle Container-Apps und Snaps aktuell.
- **Desktop-Support**: Optimierte Pflege für Cinnamon, GNOME und XFCE.
- **Gaming (GE-Proton)**: Automatisiertes Update für Steam Compatibility Tools.
- **System-Hygiene**: Bereinigt Journal-Logs und Thumbnail-Caches.

## 📦 Voraussetzungen (Dependencies)
Das Skript installiert fehlende Abhängigkeiten automatisch. Manuelle Installation:
```bash
sudo apt update && sudo apt install -y ncurses-bin whiptail libnotify-bin fwupd pciutils curl
```

## 🛠 Installation
```bash
git clone https://github.com/DerLinke/Ultimate-Debian-Updater.git
cd Ultimate-Debian-Updater
chmod +x update.sh
./update.sh
```

## 📄 Lizenz
MIT License - Copyright (c) 2026 DerLinke
