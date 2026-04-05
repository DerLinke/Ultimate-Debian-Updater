# 🚀 Ultimate Debian Updater v2.7.0

Ein intelligentes All-in-one Update-Skript für Debian-basierte Systeme (Debian, Mint, Ubuntu), das alle gängigen Paketmanager und Gaming-Tools in einem einzigen Befehl vereint.

## ✨ Features (v2.7.0)

- **System-Updates**: APT, Flatpak (System & User), Snap, deb-get, NPM, Pipx.
- **Gamer-Mode (Intelligent)**: 
    - Automatische Diagnose (32-Bit Libs, GPU-Treiber).
    - Dynamische GameMode-Konfiguration (`performance` vs `powersave`).
    - GE-Proton Update-Check via ProtonUp.
    - MangoHud, GOverlay, vkBasalt & Protontricks System-Check & Bereinigung.
- **Standard-Modus**: Über `DEFAULT_MODE` im Skript-Kopf konfigurierbar (`full`, `system`, `game`).
- **Hygiene**: Bereinigt Logs, verwaiste Pakete und Caches.

## 🛠 Voraussetzungen

Das Skript prüft beim Start auf folgende Tools und bietet deren Installation an:
- **System**: `curl`, `lspci`, `lsb_release`, `sudo`.
- **Gaming**: `pipx`, `glxinfo`, `vulkaninfo`.

## 🚀 Nutzung

```bash
update          # Nutzt den konfigurierten DEFAULT_MODE (Standard: full)
update --system # Nur System-Updates (APT, Flatpak, etc.)
update --game   # Nur Gaming-Tools (Proton, MangoHud, etc.)
update --full   # System- und Gaming-Updates kombiniert
```

## ⚙️ Konfiguration

Du kannst das Skript am Anfang der Datei anpassen:
- `DEFAULT_MODE`: Legt fest, was passiert, wenn du nur `update` ohne Parameter tippst.
- `CLEANUP_LOG_DAYS`: Zeitraum für die Journalctl-Reinigung (Standard: 3d).

---
*Created with ❤️ by DerLinke*
