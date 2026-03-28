#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater
# ------------------------------------------------------------------------------
# Ein all-in-one Update-Skript für Debian-basierte Systeme.
# Unterstützt: APT, Extrepo, deb-get, Flatpak, Snap, NPM, Cinnamon Spices, GE-Proton.
#
# GitHub: https://github.com/DerLinke
# Copyright (c) 2026 DerLinke
# ==============================================================================

# --- KONFIGURATION ---
ENABLE_REBOOT_PROMPT=true
STEAM_GE_PATH="$HOME/.local/share/Steam/compatibilitytools.d/"

# --- FARBEN ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- INITIALISIERUNG ---
UPDATED=(); FAILED=(); SKIPPED=()
export PATH="$HOME/.local/bin:$PATH"

check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# --- HEADER ---
clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${CYAN}          🚀 Ultimate Debian Updater 🚀          ${NC}"
echo -e "${YELLOW}           Created by DerLinke (GitHub)           ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo ""

# --- ROOT-RECHTE ---
echo -e "${YELLOW}Bitte gib dein Passwort für das Update ein:${NC}"
if ! sudo -v; then
    echo -e "${RED}Fehler: Root-Rechte erforderlich. Beende...${NC}"
    exit 1
fi

# Sudo-Session im Hintergrund aktiv halten
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---

# 1. Extrepo
if check_cmd extrepo; then
    echo -e "${PURPLE}[Extrepo] Aktualisiere Quellen...${NC}"
    if sudo extrepo update; then UPDATED+=("Extrepo"); else FAILED+=("Extrepo"); fi
fi

# 2. APT
if check_cmd apt; then
    echo -e "${PURPLE}[APT] System-Update wird ausgeführt...${NC}"
    sudo apt update
    if sudo apt full-upgrade -y; then
        echo -e "${GREEN}[APT] Räume alte Pakete auf...${NC}"
        sudo apt autoremove -y && sudo apt autoclean
        UPDATED+=("APT (System)"); 
    else 
        FAILED+=("APT (System)"); 
    fi
fi

# 3. deb-get / get-deb
if check_cmd deb-get; then
    echo -e "${PURPLE}[deb-get] Aktualisiere Drittanbieter-Apps...${NC}"
    if sudo deb-get update && sudo deb-get upgrade -y; then UPDATED+=("deb-get"); else FAILED+=("deb-get"); fi
elif check_cmd get-deb; then
    echo -e "${PURPLE}[get-deb] Aktualisiere...${NC}"
    if sudo get-deb update; then UPDATED+=("get-deb"); else FAILED+=("get-deb"); fi
fi

# 4. Flatpak
if check_cmd flatpak; then
    echo -e "${PURPLE}[Flatpak] Suche nach App-Updates...${NC}"
    if sudo flatpak update -y; then 
        echo -e "${GREEN}[Flatpak] Entferne ungenutzte Runtimes...${NC}"
        sudo flatpak uninstall --unused -y
        UPDATED+=("Flatpak"); 
    else 
        FAILED+=("Flatpak"); 
    fi
fi

# 5. Snap
if check_cmd snap; then
    echo -e "${PURPLE}[Snap] Aktualisiere Snaps...${NC}"
    if sudo snap refresh; then UPDATED+=("Snap"); else FAILED+=("Snap"); fi
fi

# 6. NPM
if check_cmd npm; then
    echo -e "${PURPLE}[NPM] Aktualisiere globale Pakete...${NC}"
    if sudo npm update -g; then UPDATED+=("NPM"); else FAILED+=("NPM"); fi
fi

# 7. Cinnamon Spices
if check_cmd cinnamon-spice-updater; then
    echo -e "${PURPLE}[Cinnamon] Aktualisiere Applets, Desklets & Extensions...${NC}"
    if cinnamon-spice-updater --update-all; then UPDATED+=("Cinnamon Spices"); else FAILED+=("Cinnamon Spices"); fi
fi

# 8. Gaming (GE-Proton)
if check_cmd protonup; then
    if [ -d "$STEAM_GE_PATH" ]; then
        echo -e "${PURPLE}[Gaming] Suche nach GE-Proton Updates...${NC}"
        if protonup -d "$STEAM_GE_PATH"; then 
            UPDATED+=("GE-Proton (Steam)"); 
        else 
            FAILED+=("GE-Proton (Steam)"); 
        fi
    fi
fi

# --- Zusammenfassung anzeigen ---
echo ""
echo -e "${BLUE}====================================================${NC}"
echo -e "${CYAN}              Zusammenfassung                      ${NC}"
echo -e "${BLUE}====================================================${NC}"

if [ ${#UPDATED[@]} -gt 0 ]; then
    echo -e "${GREEN}Erfolgreich aktualisiert:${NC}"
    for item in "${UPDATED[@]}"; do echo -e "  ✅ $item"; done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "${RED}Fehler aufgetreten bei:${NC}"
    for item in "${FAILED[@]}"; do echo -e "  ❌ $item"; done
fi

echo -e "${BLUE}----------------------------------------------------${NC}"

# --- Konsolen-GUI für Abschlussaktion ---
echo -e "${YELLOW}Was möchtest du als Nächstes tun?${NC}"
echo ""
echo -e "  ${CYAN}[1]${NC} Neustarten (Reboot)"
echo -e "  ${CYAN}[2]${NC} Ausschalten (Shutdown)"
echo -e "  ${CYAN}[3]${NC} Einfach nur Beenden (Exit)"
echo ""
read -p "Auswahl wählen [1-3]: " choice

case $choice in
    1) echo -e "${RED}System wird neu gestartet...${NC}"; sudo reboot ;;
    2) echo -e "${RED}System wird heruntergefahren...${NC}"; sudo poweroff ;;
    3) echo -e "${GREEN}Update-Prozess beendet. Einen schönen Tag noch!${NC}"; exit 0 ;;
    *) echo -e "${YELLOW}Ungültige Eingabe. Beende Skript...${NC}"; exit 0 ;;
esac
