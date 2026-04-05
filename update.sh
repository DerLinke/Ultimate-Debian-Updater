#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.5.1
# ------------------------------------------------------------------------------
# Ein all-in-one Update-Skript für Debian-basierte Systeme.
# Unterstützt: APT, Flatpak, deb-get, Hardware-Check, Self-Update, Forced Colors.
#
# GitHub: https://github.com/DerLinke/Ultimate-Debian-Updater
# Copyright (c) 2026 DerLinke
# ==============================================================================

VERSION="2.5.1"
RAW_URL="https://raw.githubusercontent.com/DerLinke/Ultimate-Debian-Updater/main/update.sh"

# --- KONFIGURATION ---
# Alle Variablen können über Umgebungsvariablen überschrieben werden.
: "${STEAM_GE_PATH:=$HOME/.local/share/Steam/compatibilitytools.d/}"
: "${TITLE:=Ultimate Debian Updater}"
: "${CLEANUP_LOG_DAYS:=3d}"
: "${ENABLE_ALIAS_CHECK:=true}"
: "${DEBGET_TOKEN:=DEIN_GITHUB_TOKEN_HIER}"
export DEBGET_TOKEN

# --- INITIALISIERUNG ---
VERSION="2.5.2"
RAW_URL="https://raw.githubusercontent.com/DerLinke/Ultimate-Debian-Updater/main/update.sh"
UPDATED=(); FAILED=(); SKIPPED=()

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

# --- ALIAS CHECK ---
if [[ "$ENABLE_ALIAS_CHECK" == "true" ]]; then
    CURRENT_SCRIPT_PATH=$(readlink -f "$0")
    if ! grep -q "alias update=" ~/.bashrc; then
        echo -e "\n${BOLD}${CYAN}⌨️  SCHNELLSTART-OPTIMIERUNG${NC}"
        echo -e "Möchtest du den Alias '${BOLD}update${NC}' in deiner .bashrc anlegen?"
        echo -e "Dadurch kannst du dieses Skript einfach mit ${BOLD}update${NC} starten."
        echo -n "Drücke [ENTER] zum Bestätigen (Überspringen in 3 Sek...): "
        if read -t 3; then
            echo "alias update='$CURRENT_SCRIPT_PATH'" >> ~/.bashrc
            echo -e "\n${GREEN}✓ Alias 'update' wurde zu ~/.bashrc hinzugefügt!${NC}"
            echo -e "${YELLOW}Info: Wirksam nach Neustart des Terminals.${NC}"
        else
            echo -e "\n${BLUE}ℹ️  Übersprungen.${NC}"
        fi
    else
        echo -e "\n${GREEN}✓ Schnellstart-Alias 'update' ist bereits konfiguriert.${NC}"
    fi
fi

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
REQUIRED_DEPS=("whiptail" "notify-send" "fwupdmgr" "lspci" "curl" "lsb_release" "glxinfo" "vulkaninfo")
# Pakete, die zu den Befehlen gehören:
PKG_MAP=("whiptail:whiptail" "notify-send:libnotify-bin" "fwupdmgr:fwupd" "lspci:pciutils" "curl:curl" "lsb_release:lsb-release" "glxinfo:mesa-utils" "vulkaninfo:vulkan-tools")

MISSING_BINS=()
MISSING_PKGS=()

for dep in "${REQUIRED_DEPS[@]}"; do
    if ! check_cmd "$dep"; then
        MISSING_BINS+=("$dep")
        for mapping in "${PKG_MAP[@]}"; do
            if [[ "$mapping" == "$dep:"* ]]; then MISSING_PKGS+=("${mapping#*:}"); fi
        done
    fi
done

if [ ${#MISSING_BINS[@]} -gt 0 ]; then
    echo -e "\n${BOLD}${YELLOW}🔍 PRÜFUNG DER ABHÄNGIGKEITEN${NC}"
    echo -e "${RED}Es fehlen wichtige Tools: ${BOLD}${MISSING_BINS[*]}${NC}"
    echo -e "${YELLOW}Benötigte Pakete: ${BOLD}${MISSING_PKGS[*]}${NC}"
    echo -e "\n${CYAN}Möchtest du diese Pakete jetzt automatisch installieren?${NC}"
    read -p "[j/n]: " install_choice
    if [[ "$install_choice" =~ ^([jJ][aA]|[jJ])$ ]]; then 
        echo -e "${BLUE}Installiere Abhängigkeiten...${NC}"
        sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
    else
        echo -e "${RED}Abgebrochen. Einige Funktionen werden möglicherweise nicht korrekt angezeigt.${NC}"
    fi
fi
check_cmd whiptail && USE_GUI=true || USE_GUI=false

# --- SMART HARDWARE DIAGNOSIS ---
echo -e "\n${BOLD}${CYAN}🖥 HARDWARE-CHECK${NC}"
echo -e "${BLUE}----------------------------------------------------${NC}"
GPU_INFO=$(lspci 2>/dev/null | grep -iE "vga|3d")
# Suche nach 'backports' in allen Quellen, ignoriere aber Kommentare (#)
BACKPORTS_ACTIVE=$(grep -rE "backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -v "^#")

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    if ! lsmod | grep -iq "nvidia"; then
        echo -e "  ${YELLOW}⚠️  NVIDIA-GPU erkannt, aber der proprietäre Treiber ist NICHT geladen.${NC}"
    else
        echo -e "  ${GREEN}✓ NVIDIA-Treiber ist aktiv.${NC}"
        if check_cmd nvidia-smi; then
            NVIDIA_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
            echo -e "     ${BLUE}NVIDIA Driver:${NC} $NVIDIA_VER"
        fi
    fi
fi
if echo "$GPU_INFO" | grep -iqE "amd|ati"; then
    echo -e "  ${GREEN}✓ AMD-GPU erkannt (Mesa/amdgpu).${NC}"
fi
if echo "$GPU_INFO" | grep -iq "intel"; then
    echo -e "  ${GREEN}✓ Intel-GPU erkannt.${NC}"
fi

# Mesa & Vulkan Versionen (Universal für alle GPUs)
if check_cmd glxinfo; then
    MESA_VER=$(glxinfo -B | grep "OpenGL version string" | cut -d' ' -f4-)
    echo -e "     ${BLUE}Mesa:${NC} $MESA_VER"
fi
if check_cmd vulkaninfo; then
    VULKAN_VER=$(vulkaninfo --summary | grep "driverVersion" | head -n1 | awk '{print $3}')
    echo -e "     ${BLUE}Vulkan Driver:${NC} $VULKAN_VER"
fi

if [ -n "$BACKPORTS_ACTIVE" ]; then
    echo -e "  ${GREEN}✓ Debian Backports sind aktiv.${NC}"
else
    echo -e "  ${YELLOW}ℹ️  Debian Backports sind nicht aktiviert.${NC}"
fi

# --- MANAGER OVERVIEW ---
echo -e "\n${BOLD}${CYAN}🔍 PAKETMANAGER-ÜBERSICHT${NC}"
echo -e "${BLUE}----------------------------------------------------${NC}"
MANAGERS=("apt" "flatpak" "snap" "deb-get" "npm" "cinnamon-spice-updater" "protonup")
for m in "${MANAGERS[@]}"; do
    if check_cmd "$m"; then
        echo -e "  ${GREEN}✓${NC} $m"
    else
        echo -e "  ${RED}✗${NC} $m ${CYAN}(übersprungen)${NC}"
    fi
done

# --- ROOT-RECHTE ---
echo -e "\n${BOLD}${YELLOW}🔐 AUTHENTIFIZIERUNG${NC}"
echo -e "${BLUE}----------------------------------------------------${NC}"
if ! sudo -v; then echo -e "${RED}Fehler: Root-Rechte erforderlich.${NC}"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---
echo -e "\n${BOLD}${CYAN}🔄 UPDATE-PROZESS STARTET${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Firmware
if check_cmd fwupdmgr; then
    echo -e "\n${BOLD}${PURPLE}📂 [1/10] FIRMWARE${NC} ${CYAN}Hardware-Updates...${NC}"
    sudo fwupdmgr refresh >/dev/null 2>&1
    sudo fwupdmgr get-updates
fi

# 2. Extrepo
if check_cmd extrepo; then
    echo -e "\n${BOLD}${PURPLE}📂 [2/10] EXTREPO${NC} ${CYAN}Aktualisiere Quellen...${NC}"
    if sudo extrepo update; then UPDATED+=("Extrepo"); else FAILED+=("Extrepo"); fi
fi

# 3. APT
if check_cmd apt; then
    echo -e "\n${BOLD}${PURPLE}📂 [3/10] APT SYSTEM${NC} ${CYAN}System-Update...${NC}"
    sudo apt update
    APT_COUNT=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
    if sudo apt full-upgrade -y; then
        echo -e "\n${BOLD}${GREEN}🧹 [3/10] APT CLEANUP${NC} ${CYAN}Räumen...${NC}"
        # Erfasse Anzahl der entfernten Pakete (grob geschätzt durch autoremove Output)
        AUTOREMOVE_OUT=$(sudo apt autoremove -y)
        CLEAN_COUNT=$(echo "$AUTOREMOVE_OUT" | grep -c "Entfernen von")
        sudo apt autoclean
        UPDATED+=("APT (System: $APT_COUNT Pakete, $CLEAN_COUNT bereinigt)"); 
    else FAILED+=("APT (System)"); fi
fi

# 4. Flatpak
if check_cmd flatpak; then
    echo -e "\n${BOLD}${PURPLE}📂 [4/10] FLATPAK${NC} ${CYAN}App-Updates...${NC}"
    FLAT_COUNT=$(flatpak remote-ls --updates | wc -l)
    if sudo flatpak update -y; then 
        sudo flatpak uninstall --unused -y
        UPDATED+=("Flatpak ($FLAT_COUNT Updates)"); 
    else FAILED+=("Flatpak"); fi
fi

# 5. Snap
if check_cmd snap; then
    echo -e "\n${BOLD}${PURPLE}📂 [5/10] SNAP${NC} ${CYAN}Aktualisiere Snaps...${NC}"
    SNAP_COUNT=$(snap refresh --list 2>/dev/null | grep -c "   ")
    if sudo snap refresh; then UPDATED+=("Snap ($SNAP_COUNT Updates)"); else FAILED+=("Snap"); fi
fi

# 6. deb-get / get-deb
if check_cmd deb-get; then
    echo -e "\n${BOLD}${PURPLE}📂 [6/10] DEB-GET${NC} ${CYAN}Aktualisiere Drittanbieter-Apps...${NC}"
    # GitHub API Token setzen, um Rate-Limits zu vermeiden (Token unter https://github.com/settings/tokens erstellen)
    # Empfehlung: Token in ~/.bashrc exportieren, statt hier im Skript zu speichern.
    : "${DEBGET_TOKEN:=DEIN_GITHUB_TOKEN_HIER}"
    export DEBGET_TOKEN
    if sudo -E deb-get update && sudo -E deb-get upgrade -y; then deb-get clean && UPDATED+=("deb-get"); else FAILED+=("deb-get"); fi
elif check_cmd get-deb; then
    echo -e "\n${BOLD}${PURPLE}📂 [6/10] GET-DEB${NC} ${CYAN}Aktualisiere...${NC}"
    if sudo get-deb update; then UPDATED+=("get-deb"); else FAILED+=("get-deb"); fi
fi

# 7. Desktop-Spezifisches
CURRENT_DE=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
case "$CURRENT_DE" in
    *cinnamon*)
        if check_cmd cinnamon-spice-updater; then
            echo -e "\n${BOLD}${PURPLE}📂 [7/10] CINNAMON${NC} ${CYAN}Aktualisiere Applets...${NC}"
            if cinnamon-spice-updater --update-all; then UPDATED+=("Cinnamon Spices"); fi
        fi
        ;;
    *gnome*) echo -e "\n${BOLD}${PURPLE}📂 [7/10] GNOME${NC} ${CYAN}Systempflege via APT/Flatpak.${NC}" ;;
    *xfce*) echo -e "\n${BOLD}${PURPLE}📂 [7/10] XFCE${NC} ${CYAN}Systempflege via APT.${NC}" ;;
esac

# 8. NPM
if check_cmd npm; then
    echo -e "\n${BOLD}${PURPLE}📂 [8/10] NPM${NC} ${CYAN}Aktualisiere globale Pakete...${NC}"
    NPM_COUNT=$(npm outdated -g --depth=0 2>/dev/null | grep -c "  ")
    if sudo npm update -g; then UPDATED+=("NPM ($NPM_COUNT Updates)"); else FAILED+=("NPM"); fi
fi

# 9. Gaming
if check_cmd protonup; then
    if [ -d "$STEAM_GE_PATH" ]; then
        echo -e "\n${BOLD}${PURPLE}📂 [9/10] GAMING${NC} ${CYAN}GE-Proton Updates...${NC}"
        if protonup -d "$STEAM_GE_PATH"; then UPDATED+=("GE-Proton (Steam)"); fi
    fi
fi

# 10. System-Hygiene
echo -e "\n${BOLD}${PURPLE}🧹 [10/10] REINIGUNG${NC} ${CYAN}Logs und Cache...${NC}"
sudo journalctl --vacuum-time="${CLEANUP_LOG_DAYS}" >/dev/null 2>&1
rm -rf ~/.cache/thumbnails/*
echo -e "  ${GREEN}✓ Reinigung abgeschlossen.${NC}"

# --- ZUSAMMENFASSUNG ---
echo -e "\n\n${BOLD}${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}              ZUSAMMENFASSUNG                      ${NC}"
echo -e "${BOLD}${BLUE}====================================================${NC}"

if [ "$USE_GUI" = true ]; then
    SUMMARY="Erfolgreich aktualisiert:\n"
    for item in "${UPDATED[@]}"; do SUMMARY="$SUMMARY ✅ $item\n"; done
    if [ ${#FAILED[@]} -gt 0 ]; then
        SUMMARY="$SUMMARY\nFehlgeschlagen:\n"
        for item in "${FAILED[@]}"; do SUMMARY="$SUMMARY ❌ $item\n"; done
    fi
    whiptail --title "Zusammenfassung" --msgbox "$SUMMARY" 18 70
else
    echo -e "\n${BOLD}${GREEN}🏁 AKTUALISIERUNG ABGESCHLOSSEN!${NC}"
    for item in "${UPDATED[@]}"; do echo -e "  ✅ $item"; done
    if [ ${#FAILED[@]} -gt 0 ]; then
        echo -e "\n${BOLD}${RED}⚠️  FEHLER AUFGETRETEN:${NC}"
        for item in "${FAILED[@]}"; do echo -e "  ❌ $item"; done
    fi
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
