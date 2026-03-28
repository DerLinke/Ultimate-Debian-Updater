# 🚀 Ultimate Debian Updater (v2.3)

Ein umfassendes All-in-one Update-Skript für Debian-basierte Linux-Systeme.

## ✨ Features (v2.3)

- **Smart Hardware Diagnosis**: Erkennt NVIDIA/AMD GPUs und gibt Tipps zur optimalen Treiber-Konfiguration.
- **Backports-Check**: Prüft, ob Debian Backports aktiviert sind (wichtig für aktuelle Grafik-Firmware).
- **APT System Update**: Volles Upgrade (`full-upgrade`) inklusive automatischer Reinigung (`autoremove`, `autoclean`).
- **Firmware (fwupd)**: Integrierter Hardware- und BIOS-Check für moderne Systeme.
- **Flatpak & Snap**: Hält alle installierten Container-Apps und Snaps aktuell.
- **Desktop-Support**: 
  - **Cinnamon**: Aktualisiert Applets, Desklets und Extensions via Spice-Updater.
  - **GNOME & XFCE**: Visuelle Bestätigung und Pflege der Systemkomponenten.
- **Gaming (GE-Proton)**: Automatisiertes Update für Steam Compatibility Tools via `protonup`.
- **System-Hygiene**: Bereinigt alte Journal-Logs (älter als 3 Tage) und Thumbnail-Caches zur Speicherplatz-Optimierung.

## 🖥 Moderne TUI
Grafische Menüs via `whiptail` und eine farbenfrohe Terminal-Ausgabe mit modernen Icons für eine klare Struktur.

## 📦 Voraussetzungen (Dependencies)
Das Skript prüft beim Start automatisch auf fehlende Pakete. Für eine manuelle Vorinstallation (Debian/Ubuntu):
```bash
sudo apt update && sudo apt install -y ncurses-bin whiptail libnotify-bin fwupd pciutils curl
```

## 🛠 Installation
1. Klonen Sie das Repository:
   ```bash
   git clone https://github.com/DerLinke/Ultimate-Debian-Updater.git
   cd Ultimate-Debian-Updater
   ```
2. Machen Sie das Skript ausführbar:
   ```bash
   chmod +x update.sh
   ```
3. Starten Sie das Skript:
   ```bash
   ./update.sh
   ```

## 📄 Lizenz
Dieses Projekt steht unter der MIT-Lizenz - Copyright (c) 2026 DerLinke
