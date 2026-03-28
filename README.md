# 🚀 Ultimate Debian Updater (v2.2)

Ein umfassendes All-in-One Update-Skript für Debian-basierte Linux-Systeme (Debian, Linux Mint, Ubuntu, etc.).

Dieses Skript automatisiert den Update-Prozess für eine Vielzahl von Paketmanagern und Diensten, die oft manuell nacheinander aktualisiert werden müssen.

## ✨ Features (v2.2)

Das Skript erkennt automatisch Ihre Desktop-Umgebung und führt die entsprechenden Updates aus:

- **APT**: Volles System-Upgrade (`full-upgrade`), `autoremove` und `autoclean`.
- **Firmware (fwupd)**: Prüft auf Hardware- und BIOS-Updates.
- **Extrepo**: Aktualisierung der externen Repository-Metadaten.
- **Flatpak**: Aktualisiert alle Apps und entfernt ungenutzte Runtimes.
- **Snap**: Führt `snap refresh` aus.
- **NPM**: Aktualisiert alle global installierten Pakete.
- **Desktop-Support**: 
  - **Cinnamon**: Aktualisiert Applets, Desklets und Extensions.
  - **XFCE**: Optimierte Systempflege.
- **GE-Proton**: Prüft und installiert die neueste Proton-GE Version für Steam (via `protonup`).
- **System-Hygiene**: Automatische Reinigung von System-Logs (Journal) und Cache-Dateien.

## 🖥 Moderne TUI (Terminal User Interface)

- **Grafische Menüs**: Auswahl von Aktionen (Reboot/Shutdown/Exit) via `whiptail`.
- **Farbige Icons**: Klare Strukturierung durch moderne Icons und farbliche Hervorhebung.
- **Dependency-Check**: Automatisierte Prüfung und Installation fehlender Hilfsprogramme beim Start.

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

## 🚀 Nutzung

Starten Sie das Skript einfach im Terminal:
```bash
./update.sh
```

## 👤 Autor

**DerLinke**
- GitHub: [https://github.com/DerLinke](https://github.com/DerLinke)

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz.
