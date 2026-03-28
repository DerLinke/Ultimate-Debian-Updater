# 🚀 Ultimate Debian Updater

Ein umfassendes All-in-One Update-Skript für Debian-basierte Linux-Systeme (Debian, Linux Mint, Ubuntu, etc.).

Dieses Skript automatisiert den Update-Prozess für eine Vielzahl von Paketmanagern und Diensten, die oft manuell nacheinander aktualisiert werden müssen.

## ✨ Features

Das Skript prüft automatisch, welche der folgenden Dienste installiert sind, und führt die entsprechenden Updates aus:

- **APT**: Volles System-Upgrade (`full-upgrade`), `autoremove` und `autoclean`.
- **Extrepo**: Aktualisierung der externen Repository-Metadaten.
- **deb-get / get-deb**: Updates für Drittanbieter-Anwendungen.
- **Flatpak**: Aktualisiert alle Apps und entfernt ungenutzte Runtimes.
- **Snap**: Führt `snap refresh` aus.
- **NPM**: Aktualisiert alle global installierten Pakete.
- **Cinnamon Spices**: Aktualisiert Applets, Desklets und Extensions (für Cinnamon Desktop).
- **GE-Proton**: Prüft und installiert die neueste Proton-GE Version für Steam (via `protonup`).

## 🛠 Installation

1. Klonen Sie das Repository oder laden Sie die `update.sh` herunter:
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

Am Ende des Prozesses erhalten Sie eine übersichtliche Zusammenfassung und können wählen, ob das System neu gestartet oder heruntergefahren werden soll.

## ⚙️ Konfiguration

Im oberen Bereich der `update.sh` können Sie Pfade anpassen, falls diese von den Standardwerten abweichen (z. B. der Pfad zu Ihren Steam Compatibility Tools).

## 👤 Autor

**DerLinke**
- GitHub: [https://github.com/DerLinke](https://github.com/DerLinke)

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz.
