#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.3
# ------------------------------------------------------------------------------
# Ein all-in-one Update-Skript für Debian-basierte Systeme.
# Unterstützt: APT, Flatpak, Hardware-Check (NVIDIA/AMD), System-Hygiene.
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

# --- FARBEN & STILE (tput für maximale Kompatibilität) ---
if check_cmd tput && [ -t 1 ]; then
    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
        BOLD=$(tput bold); NC=$(tput sgr0); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); PURPLE=$(tput setaf 5); CYAN=$(tput setaf 6)
    fi
fi
: "${BOLD:=}"; : "${NC:=}"; : "${RED:=}"; : "${GREEN:=}"; : "${YELLOW:=}"; : "${BLUE:=}"; : "${PURPLE:=}"; : "${CYAN:=}"

# --- HEADER ---
clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}          🚀 Ultimate Debian Updater v2.3 🚀          ${NC}"
echo -e "${YELLOW}           Created by DerLinke (GitHub)           ${NC}"
echo -e "${BLUE}====================================================${NC}"

# --- DEPENDENCY CHECK ---
MISSING_DEPS=()
check_cmd whiptail || MISSING_DEPS+=("whiptail")
check_cmd notify-send || MISSING_DEPS+=("libnotify-bin")
check_cmd fwupdmgr || MISSING_DEPS+=("fwupd")

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
GPU_INFO=$(lspci | grep -iE "vga|3d")
BACKPORTS_ACTIVE=$(grep -r "^deb.*backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null)

# NVIDIA Check
if echo "$GPU_INFO" | grep -iq "nvidia"; then
    if ! lsmod | grep -iq "nvidia"; then
        echo -e "${YELLOW}⚠️  NVIDIA-GPU erkannt, aber der proprietäre Treiber ist NICHT geladen.${NC}"
        echo -e "   Tipp: Installiere 'nvidia-driver' und aktiviere 'non-free' Quellen für volle Leistung."
    else
        echo -e "${GREEN}✓ NVIDIA-Treiber ist aktiv.${NC}"
    fi
fi

# AMD Check
if echo "$GPU_INFO" | grep -iqE "amd|ati"; then
    echo -e "${GREEN}✓ AMD-GPU erkannt (Mesa/amdgpu).${NC}"
    echo -e "   Tipp: Stelle sicher, dass 'firmware-amd-graphics' (ggf. aus Backports) installiert ist."
fi

# Backports Check
if [ -z "$BACKPORTS_ACTIVE" ]; then
    echo -e "${YELLOW}ℹ️  Debian Backports sind nicht aktiviert.${NC}"
    echo -e "   Empfohlen für neuere Grafik-Firmware und Kernel-Komponenten."
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

# 2. APT
if check_cmd apt; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [APT SYSTEM]${NC} ${CYAN}System-Update...${NC}"
    sudo apt update
    if sudo apt full-upgrade -y; then
        echo -e "\n${BOLD}${GREEN}🧹 [APT CLEANUP]${NC} ${CYAN}Räumen...${NC}"
        sudo apt autoremove -y && sudo apt autoclean
        UPDATED+=("APT (System)"); 
    else FAILED+=("APT (System)"); fi
fi

# 3. Flatpak
if check_cmd flatpak; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [FLATPAK]${NC} ${CYAN}App-Updates...${NC}"
    if sudo flatpak update -y; then 
        sudo flatpak uninstall --unused -y
        UPDATED+=("Flatpak"); 
    else FAILED+=("Flatpak"); fi
fi

# 4. Snap
if check_cmd snap; then
    echo -e "\n\n${BOLD}${PURPLE}📂 [SNAP]${NC} ${CYAN}Aktualisiere Snaps...${NC}"
    if sudo snap refresh; then UPDATED+=("Snap"); else FAILED+=("Snap"); fi
fi

# 5. Desktop-Spezifisches
CURRENT_DE=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
case "$CURRENT_DE" in
    *cinnamon*)
        if check_cmd cinnamon-spice-updater; then
            echo -e "\n\n${BOLD}${PURPLE}📂 [CINNAMON]${NC} ${CYAN}Aktualisiere Applets & Extensions...${NC}"
            if cinnamon-spice-updater --update-all; then UPDATED+=("Cinnamon Spices"); fi
        fi
        ;;
    *gnome*)
        echo -e "\n\n${BOLD}${PURPLE}📂 [GNOME]${NC} ${CYAN}System-Komponenten werden via APT/Flatpak gepflegt.${NC}"
        ;;
    *xfce*)
        echo -e "\n\n${BOLD}${PURPLE}📂 [XFCE]${NC} ${CYAN}Umgebung wird via APT gepflegt.${NC}"
        ;;
esac

# 6. Gaming
if check_cmd protonup; then
    if [ -d "$STEAM_GE_PATH" ]; then
        echo -e "\n\n${BOLD}${PURPLE}📂 [GAMING]${NC} ${CYAN}GE-Proton Updates...${NC}"
        if protonup -d "$STEAM_GE_PATH"; then UPDATED+=("GE-Proton (Steam)"); fi
    fi
fi

# 7. System-Hygiene
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
