#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.2.1
# ------------------------------------------------------------------------------
# Ein all-in-one Update-Skript für Debian-basierte Systeme.
# Unterstützt: APT, Flatpak, Snap, NPM, Desktop-Spices (Cinnamon/XFCE/GNOME).
#
# GitHub: https://github.com/DerLinke
# Copyright (c) 2026 DerLinke
# ==============================================================================

# --- KONFIGURATION ---
STEAM_GE_PATH="$HOME/.local/share/Steam/compatibilitytools.d/"
TITLE="Ultimate Debian Updater"

# --- INITIALISIERUNG ---
UPDATED=(); FAILED=(); SKIPPED=()
export PATH="$HOME/.local/bin:$PATH"

check_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- FARBEN & STILE (mit tput für maximale Kompatibilität) ---
if check_cmd tput && [ -t 1 ]; then
    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
        BOLD=$(tput bold)
        NC=$(tput sgr0)
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        PURPLE=$(tput setaf 5)
        CYAN=$(tput setaf 6)
    fi
fi

# Fallback falls tput nicht geht
: "${BOLD:=}"; : "${NC:=}"; : "${RED:=}"; : "${GREEN:=}"; : "${YELLOW:=}"; : "${BLUE:=}"; : "${PURPLE:=}"; : "${CYAN:=}"

# --- HEADER ---
clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}          🚀 Ultimate Debian Updater v2.2 🚀          ${NC}"
echo -e "${YELLOW}           Created by DerLinke (GitHub)           ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo ""

# --- DEPENDENCY CHECK ---
MISSING_DEPS=()
check_cmd whiptail || MISSING_DEPS+=("whiptail")
check_cmd notify-send || MISSING_DEPS+=("libnotify-bin")
check_cmd fwupdmgr || MISSING_DEPS+=("fwupd")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "\n${BOLD}${YELLOW}🔍 PRÜFUNG DER ABHÄNGIGKEITEN${NC}"
    echo -e "${YELLOW}Es fehlen Pakete für das optimale Erlebnis: ${MISSING_DEPS[*]}${NC}"
    echo -n "Sollen diese jetzt installiert werden? (j/n): "
    read -r install_choice
    if [[ "$install_choice" =~ ^([jJ][aA]|[jJ])$ ]]; then
        sudo apt update && sudo apt install -y "${MISSING_DEPS[@]}"
    fi
fi

# Prüfen ob whiptail jetzt vorhanden ist
if check_cmd whiptail; then USE_GUI=true; else USE_GUI=false; fi

# --- DESKTOP ERKENNUNG ---
CURRENT_DE=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')

# --- ROOT-RECHTE ---
if [ "$USE_GUI" = true ]; then
    whiptail --title "$TITLE" --msgbox "Das Skript benötigt Root-Rechte für die Updates. Bitte gib dein Passwort im Terminal ein." 10 60
fi

echo -e "\n${BOLD}${YELLOW}🔐 AUTHENTIFIZIERUNG${NC}"
if ! sudo -v; then
    echo -e "${RED}Fehler: Root-Rechte erforderlich. Beende...${NC}"
    exit 1
fi

# Sudo-Session im Hintergrund aktiv halten
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---

# 1. Firmware (fwupdmgr)
if check_cmd fwupdmgr; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [FIRMWARE]${NC} ${CYAN}Suche nach Hardware-Updates...${NC}"
    sudo fwupdmgr refresh >/dev/null 2>&1
    if sudo fwupdmgr get-updates; then
        echo -e "${GREEN}✓ Firmware-Check abgeschlossen.${NC}"
    fi
fi

# 2. Extrepo
if check_cmd extrepo; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [EXTREPO]${NC} ${CYAN}Aktualisiere Drittanbieter-Quellen...${NC}"
    if sudo extrepo update; then UPDATED+=("Extrepo"); else FAILED+=("Extrepo"); fi
fi

# 3. APT
if check_cmd apt; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [APT SYSTEM]${NC} ${CYAN}Vollständiges System-Update...${NC}"
    sudo apt update
    if sudo apt full-upgrade -y; then
        echo -e "\n${BOLD}${GREEN}🧹 [APT CLEANUP]${NC} ${CYAN}Räume alte Pakete auf...${NC}"
        sudo apt autoremove -y && sudo apt autoclean
        UPDATED+=("APT (System)"); 
    else 
        FAILED+=("APT (System)"); 
    fi
fi

# 4. Flatpak
if check_cmd flatpak; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [FLATPAK]${NC} ${CYAN}Suche nach App-Updates...${NC}"
    if sudo flatpak update -y; then 
        sudo flatpak uninstall --unused -y
        UPDATED+=("Flatpak"); 
    else 
        FAILED+=("Flatpak"); 
    fi
fi

# 5. Snap
if check_cmd snap; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [SNAP]${NC} ${CYAN}Aktualisiere Snaps...${NC}"
    if sudo snap refresh; then UPDATED+=("Snap"); else FAILED+=("Snap"); fi
fi

# 6. Desktop-Spezifisches
case "$CURRENT_DE" in
    *cinnamon*)
        if check_cmd cinnamon-spice-updater; then
            echo -e "\n\n${BOLD}${PURPLE}📂 [CINNAMON]${NC} ${CYAN}Aktualisiere Applets & Extensions...${NC}"
            if cinnamon-spice-updater --update-all; then UPDATED+=("Cinnamon Spices"); fi
        fi
        ;;
    *xfce*)
        echo -e "\n\n${BOLD}${PURPLE}📂 [XFCE]${NC} ${CYAN}Optimiere Umgebung...${NC}"
        ;;
esac

# 7. Gaming (GE-Proton)
if check_cmd protonup; then
    if [ -d "$STEAM_GE_PATH" ]; then
        echo -e "\n\n${BOLD}${PURPLE}📂 [GAMING]${NC} ${CYAN}Suche nach GE-Proton Updates...${NC}"
        if protonup -d "$STEAM_GE_PATH"; then UPDATED+=("GE-Proton (Steam)"); fi
    fi
fi

# 8. System-Hygiene (Das Wohl der Allgemeinheit)
echo -e "\n\n${BOLD}${PURPLE}🧹 [REINIGUNG]${NC} ${CYAN}Räume System-Logs und Cache auf...${NC}"
sudo journalctl --vacuum-time=3d >/dev/null 2>&1
rm -rf ~/.cache/thumbnails/*
echo -e "${GREEN}✓ Reinigung abgeschlossen.${NC}"

# --- ZUSAMMENFASSUNG ---
if [ "$USE_GUI" = true ]; then
    SUMMARY="Erfolgreich aktualisiert:\n"
    for item in "${UPDATED[@]}"; do SUMMARY="$SUMMARY ✅ $item\n"; done
    if [ ${#FAILED[@]} -gt 0 ]; then
        SUMMARY="$SUMMARY\nFehler bei:\n"
        for item in "${FAILED[@]}"; do SUMMARY="$SUMMARY ❌ $item\n"; done
    fi
    whiptail --title "Zusammenfassung" --msgbox "$SUMMARY" 15 60
else
    echo -e "\n\n${BOLD}${GREEN}🏁 FERTIG!${NC}"
    for item in "${UPDATED[@]}"; do echo -e "  ✅ $item"; done
fi

# Desktop Benachrichtigung
if check_cmd notify-send; then
    notify-send "Update Abgeschlossen" "Dein System ist nun auf dem neuesten Stand." -i system-software-update
fi

# --- ABSCHLUSS-AKTION (Modernes TUI Menü) ---
if [ "$USE_GUI" = true ]; then
    CHOICE=$(whiptail --title "Update Beendet" --menu "Was möchtest du tun?" 15 60 4 \
    "1" "System neu starten (Reboot)" \
    "2" "System ausschalten (Shutdown)" \
    "3" "Skript beenden (Exit)" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) sudo reboot ;;
        2) sudo poweroff ;;
        3) exit 0 ;;
    esac
else
    echo -e "\n"
    read -p "Neustart erforderlich? (j/n): " r
    [[ "$r" == "j" ]] && sudo reboot
fi
