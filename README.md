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
Das Skript prüft beim Start automatisch auf fehlende Pakete. Zur manuellen Vorab-Installation:
```bash
sudo apt update && sudo apt install -y ncurses-bin whiptail libnotify-bin fwupd pciutils curl lsb-release mesa-utils vulkan-tools
```

## ⚙️ Konfiguration (Customization)
Das Skript bietet verschiedene Einstellungen im `# --- KONFIGURATION ---` Block. Diese können entweder direkt im Skript oder als Umgebungsvariable (z.B. in der `~/.bashrc`) gesetzt werden:

| Variable | Standardwert | Beschreibung |
| :--- | :--- | :--- |
| `STEAM_GE_PATH` | `~/.local/share/Steam/...` | Pfad für GE-Proton Installationen. |
| `TITLE` | `Ultimate Debian Updater` | Anzeigename im Skript-Header. |
| `CLEANUP_LOG_DAYS`| `3d` | Zeitraum für die Journalctl-Bereinigung. |
| `ENABLE_ALIAS_CHECK`| `true` | Schaltet den interaktiven Alias-Check beim Start an/aus. |
| `DEBGET_TOKEN` | `(leer)` | GitHub PAT für deb-get (verhindert Rate-Limits). |

Beispiel für dauerhafte Konfiguration in der `~/.bashrc`:
```bash
export CLEANUP_LOG_DAYS="7d"
export DEBGET_TOKEN="dein_geheimer_token"
```

## 🛠 Installation & Schnellstart
Du kannst das Skript direkt klonen oder als Einzeiler ausführen:
```bash
git clone https://github.com/DerLinke/Ultimate-Debian-Updater.git
cd Ultimate-Debian-Updater
chmod +x update.sh
./update.sh
```

Alternativ als Alias in die `~/.bashrc` eintragen:
```bash
alias update='~/Projekte/Ultimate-Debian-Updater/update.sh'
```

## 📄 Lizenz
MIT License - Copyright (c) 2026 DerLinke
