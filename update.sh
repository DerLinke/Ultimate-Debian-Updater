#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.4.3
# ------------------------------------------------------------------------------
# Ein all-in-one Update-Skript für Debian-basierte Systeme.
# Unterstützt: APT, Flatpak, deb-get, Hardware-Check, Self-Update, Forced Colors.
#
# GitHub: https://github.com/DerLinke/Ultimate-Debian-Updater
# Copyright (c) 2026 DerLinke
# ==============================================================================

VERSION="2.4.3"
RAW_URL="https://raw.githubusercontent.com/DerLinke/Ultimate-Debian-Updater/main/update.sh"

# --- KONFIGURATION ---
STEAM_GE_PATH="$HOME/.local/share/Steam/compatibilitytools.d/"
TITLE="Ultimate Debian Updater"

# --- INITIALISIERUNG ---
UPDATED=(); FAILED=(); SKIPPED=()
export PATH="$HOME/.local/bin:$PATH"

check_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- FARBEN & STILE ---
# Wir aktivieren Farben wenn tput >= 8 Farben meldet ODER wenn FORCE_COLOR gesetzt ist
if [[ -n "$FORCE_COLOR" ]] || (check_cmd tput && [ $(tput colors 2>/dev/null || echo 0) -ge 8 ]); then
    BOLD=$(tput bold); NC=$(tput sgr0); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); PURPLE=$(tput setaf 5); CYAN=$(tput setaf 6)
fi
: "${BOLD:=}"; : "${NC:=}"; : "${RED:=}"; : "${GREEN:=}"; : "${YELLOW:=}"; : "${BLUE:=}"; : "${PURPLE:=}"; : "${CYAN:=}"

# --- HEADER ---
clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}          🚀 Ultimate Debian Updater v$VERSION 🚀          ${NC}"
echo -e "${YELLOW}           Created by DerLinke (GitHub)           ${NC}"
echo -e "${BLUE}====================================================${NC}"

# --- SELF-UPDATE CHECK ---
if check_cmd curl; then
    REMOTE_VERSION=$(curl -s --connect-timeout 2 "$RAW_URL" | grep -m1 "^VERSION=" | cut -d'"' -f2)
    if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$VERSION" ]; then
        echo -e "\n${BOLD}${YELLOW}✨ EINE NEUE VERSION IST VERFÜGBAR ($REMOTE_VERSION)!${NC}"
        echo -n "Möchtest du das Skript jetzt automatisch aktualisieren? (j/n): "
        read -r update_choice
        if [[ "$update_choice" =~ ^([jJ][aA]|[jJ])$ ]]; then
            if curl -s "$RAW_URL" -o "$0"; then
                echo -e "${GREEN}✓ Skript wurde aktualisiert. Bitte starte es neu.${NC}"
                exit 0
            else
                echo -e "${RED}Fehler beim Herunterladen des Updates.${NC}"
            fi
        fi
    fi
fi

# --- DEPENDENCY CHECK ---
MISSING_DEPS=()
check_cmd whiptail || MISSING_DEPS+=("whiptail")
check_cmd notify-send || MISSING_DEPS+=("libnotify-bin")
check_cmd fwupdmgr || MISSING_DEPS+=("fwupd")
check_cmd lspci || MISSING_DEPS+=("pciutils")
check_cmd curl || MISSING_DEPS+=("curl")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "\n${BOLD}${YELLOW}🔍 PRÜFUNG DER ABHÄNGIGKEITEN${NC}"
    echo -e "${YELLOW}Es fehlen Pakete: ${MISSING_DEPS[*]}${NC}"
    echo -n "Jetzt installieren? (j/n): "
    read -r install_choice
    if [[ "$install_choice" =~ ^([jJ][aA]|[jJ])$ ]]; then sudo apt update && sudo apt install -y "${MISSING_DEPS[@]}"; fi
fi
check_cmd whiptail && USE_GUI=true || USE_GUI=false

# --- SMART HARDWARE DIAGNOSIS ---
echo -e "\n${BOLD}${CYAN}🖥 HARDWARE-CHECK${NC}"
GPU_INFO=$(lspci 2>/dev/null | grep -iE "vga|3d")
# Suche nach 'backports' in allen Quellen, ignoriere aber Kommentare (#)
BACKPORTS_ACTIVE=$(grep -rE "backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -v "^#")

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    if ! lsmod | grep -iq "nvidia"; then
        echo -e "${YELLOW}⚠️  NVIDIA-GPU erkannt, aber der proprietäre Treiber ist NICHT geladen.${NC}"
    else
        echo -e "${GREEN}✓ NVIDIA-Treiber ist aktiv.${NC}"
    fi
fi
if echo "$GPU_INFO" | grep -iqE "amd|ati"; then
    echo -e "${GREEN}✓ AMD-GPU erkannt (Mesa/amdgpu).${NC}"
fi
if [ -z "$BACKPORTS_ACTIVE" ]; then
    echo -e "${YELLOW}ℹ️  Debian Backports sind nicht aktiviert.${NC}"
fi

# --- ROOT-RECHTE ---
if [ "$USE_GUI" = true ]; then
    whiptail --title "$TITLE" --msgbox "Das Skript benötigt Root-Rechte. Bitte gib dein Passwort im Terminal ein." 10 60
fi
echo -e "\n${BOLD}${YELLOW}🔐 AUTHENTIFIZIERUNG${NC}"
if ! sudo -v; then echo -e "${RED}Fehler: Root-Rechte erforderlich.${NC}"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---

# 1. Firmware
if check_cmd fwupdmgr; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [FIRMWARE]${NC} ${CYAN}Hardware-Updates...${NC}"
    sudo fwupdmgr refresh >/dev/null 2>&1
    sudo fwupdmgr get-updates
fi

# 2. Extrepo
if check_cmd extrepo; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [EXTREPO]${NC} ${CYAN}Aktualisiere Quellen...${NC}"
    if sudo extrepo update; then UPDATED+=("Extrepo"); else FAILED+=("Extrepo"); fi
fi

# 3. APT
if check_cmd apt; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [APT SYSTEM]${NC} ${CYAN}System-Update...${NC}"
    sudo apt update
    if sudo apt full-upgrade -y; then
        echo -e "\n${BOLD}${GREEN}🧹 [APT CLEANUP]${NC} ${CYAN}Räumen...${NC}"
        sudo apt autoremove -y && sudo apt autoclean
        UPDATED+=("APT (System)"); 
    else FAILED+=("APT (System)"); fi
fi

# 4. Flatpak
if check_cmd flatpak; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [FLATPAK]${NC} ${CYAN}App-Updates...${NC}"
    if sudo flatpak update -y; then 
        sudo flatpak uninstall --unused -y
        UPDATED+=("Flatpak"); 
    else FAILED+=("Flatpak"); fi
fi

# 5. Snap
if check_cmd snap; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [SNAP]${NC} ${CYAN}Aktualisiere Snaps...${NC}"
    if sudo snap refresh; then UPDATED+=("Snap"); else FAILED+=("Snap"); fi
fi

# 6. deb-get / get-deb
if check_cmd deb-get; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [DEB-GET]${NC} ${CYAN}Aktualisiere Drittanbieter-Apps...${NC}"
    # GitHub API Token setzen, um Rate-Limits zu vermeiden (Token unter https://github.com/settings/tokens erstellen)
    # Empfehlung: Token in ~/.bashrc exportieren, statt hier im Skript zu speichern.
    : "${DEBGET_TOKEN:=DEIN_GITHUB_TOKEN_HIER}"
    export DEBGET_TOKEN
    if sudo -E deb-get update && sudo -E deb-get upgrade -y; then deb-get clean && UPDATED+=("deb-get"); else FAILED+=("deb-get"); fi
elif check_cmd get-deb; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [GET-DEB]${NC} ${CYAN}Aktualisiere...${NC}"
    if sudo get-deb update; then UPDATED+=("get-deb"); else FAILED+=("get-deb"); fi
fi

# 7. Desktop-Spezifisches
CURRENT_DE=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
case "$CURRENT_DE" in
    *cinnamon*)
        if check_cmd cinnamon-spice-updater; then
            echo -e "\n\n${BOLD}${PURPLE}📂 [CINNAMON]${NC} ${CYAN}Aktualisiere Applets...${NC}"
            if cinnamon-spice-updater --update-all; then UPDATED+=("Cinnamon Spices"); fi
        fi
        ;;
    *gnome*) echo -e "\n\n${BOLD}${PURPLE}📂 [GNOME]${NC} ${CYAN}Systempflege via APT/Flatpak.${NC}" ;;
    *xfce*) echo -e "\n\n${BOLD}${PURPLE}📂 [XFCE]${NC} ${CYAN}Systempflege via APT.${NC}" ;;
esac

# 8. NPM
if check_cmd npm; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [NPM]${NC} ${CYAN}Aktualisiere globale Pakete...${NC}"
    if sudo npm update -g; then UPDATED+=("NPM"); else FAILED+=("NPM"); fi
fi

# 9. Gaming
if check_cmd protonup; then
    if [ -d "$STEAM_GE_PATH" ]; then
        echo -e "\n\n${BOLD}${PURPLE}📂 [GAMING]${NC} ${CYAN}GE-Proton Updates...${NC}"
        if protonup -d "$STEAM_GE_PATH"; then UPDATED+=("GE-Proton (Steam)"); fi
    fi
fi

# 10. System-Hygiene
echo -e "\n\n${BOLD}${PURPLE}🧹 [REINIGUNG]${NC} ${CYAN}Logs und Cache...${NC}"
sudo journalctl --vacuum-time=3d >/dev/null 2>&1
rm -rf ~/.cache/thumbnails/*
echo -e "${GREEN}✓ Reinigung abgeschlossen.${NC}"

# --- ZUSAMMENFASSUNG ---
if [ "$USE_GUI" = true ]; then
    SUMMARY="Erfolgreich aktualisiert:\n"
    for item in "${UPDATED[@]}"; do SUMMARY="$SUMMARY ✅ $item\n"; done
    whiptail --title "Zusammenfassung" --msgbox "$SUMMARY" 15 60
else
    echo -e "\n\n${BOLD}${GREEN}🏁 FERTIG!${NC}"
    for item in "${UPDATED[@]}"; do echo -e "  ✅ $item"; done
fi

# Abschluss-Aktion
if [ "$USE_GUI" = true ]; then
    CHOICE=$(whiptail --title "Update Beendet" --menu "Was möchtest du tun?" 15 60 4 \
    "1" "System neu starten (Reboot)" \
    "2" "System ausschalten (Shutdown)" \
    "3" "Skript beenden (Exit)" 3>&1 1>&2 2>&3)
    case $CHOICE in 1) sudo reboot ;; 2) sudo poweroff ;; 3) exit 0 ;; esac
else
    echo -e "\n"; read -p "Neustart? (j/n): " r
    [[ "$r" == "j" ]] && sudo reboot
fi
