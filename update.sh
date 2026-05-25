#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.8.0 (Gamer Edition)
# ------------------------------------------------------------------------------
# Ein intelligentes All-in-one Update-Skript für Debian-basierte Systeme.
# Fokus: System-Stabilität, Gaming-Performance und Desktop-Spezifika.
#
# GitHub: https://github.com/DerLinke/Ultimate-Debian-Updater
# Copyright (c) 2026 DerLinke
# ==============================================================================

# --- KONFIGURATION (VORGABEN) ---
: "${DEFAULT_MODE:=full}"
: "${STEAM_GE_PATH:=$HOME/.local/share/Steam/compatibilitytools.d/}"
: "${TITLE:=Ultimate Debian Updater}"
: "${CLEANUP_LOG_DAYS:=3d}"
: "${ENABLE_ALIAS_CHECK:=true}"
: "${DEBGET_TOKEN:=}"

# --- KONFIGURATION (GAMER-MODE) ---
: "${GAMER_MODE:=true}"
: "${CHECK_32BIT_LIBS:=true}"
: "${OPTISCALER_PATH:=$HOME/.local/share/optiscaler}"
: "${MANAGE_VULKAN_LAYERS:=true}"

# --- INITIALISIERUNG ---
VERSION="2.8.0"
RAW_URL="https://raw.githubusercontent.com/DerLinke/Ultimate-Debian-Updater/main/update.sh"
UPDATED=(); FAILED=(); SKIPPED=()
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

check_cmd() { 
    command -v "$1" >/dev/null 2>&1 || [ -f "$HOME/.local/bin/$1" ] || [ -f "/usr/local/bin/$1" ]
}

# --- SYSTEM REQUIREMENTS CHECK ---
BASIS_DEPS=("curl" "lspci" "lsb_release" "7z")
BASIS_PKGS=("curl" "pciutils" "lsb-release" "p7zip-full")
MISSING_BASIS=()

for i in "${!BASIS_DEPS[@]}"; do
    if ! check_cmd "${BASIS_DEPS[$i]}"; then MISSING_BASIS+=("${BASIS_PKGS[$i]}"); fi
done

if [ ${#MISSING_BASIS[@]} -gt 0 ]; then
    echo -e "\n${BOLD}${RED}⚠️  FEHLENDE BASIS-TOOLS${NC}"
    echo -e "Die folgenden Pakete werden für das Skript benötigt: ${BOLD}${MISSING_BASIS[*]}${NC}"
    read -p "Jetzt installieren? [j/n]: " inst_basis
    if [[ "$inst_basis" =~ ^([jJ][aA]|[jJ])$ ]]; then
        sudo apt update && sudo apt install -y "${MISSING_BASIS[@]}"
    else
        echo -e "${RED}Fehler: Ohne diese Tools kann das Skript nicht fortgesetzt werden.${NC}"
        exit 1
    fi
fi

# --- FARBEN & STILE ---
C_RED=$'\e[38;2;255;0;0m'
C_MAGENTA=$'\e[38;2;215;0;70m'
C_PINK=$'\e[38;2;175;0;130m'
C_PURP1=$'\e[38;2;120;0;180m'
C_PURP2=$'\e[38;2;90;0;210m'
C_PURP3=$'\e[38;2;60;0;230m'
C_PURP4=$'\e[38;2;30;0;245m'
C_GRAD1=$'\e[38;2;100;0;200m'
C_GRAD2=$'\e[38;2;70;0;220m'
C_GRAD3=$'\e[38;2;40;0;240m'
C_GRAD4=$'\e[38;2;0;0;255m'
C_BLUE=$'\e[38;2;0;0;255m'
RESET=$'\e[0m'

if [[ -n "$FORCE_COLOR" ]] || (check_cmd tput && [ $(tput colors 2>/dev/null || echo 0) -ge 8 ]); then
    BOLD=$(tput bold); NC=$(tput sgr0); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); PURPLE=$(tput setaf 5); CYAN=$(tput setaf 6)
fi
: "${BOLD:=}"; : "${NC:=}"; : "${RED:=}"; : "${GREEN:=}"; : "${YELLOW:=}"; : "${BLUE:=}"; : "${PURPLE:=}"; : "${CYAN:=}"

# --- SELF-UPDATE LOGIK ---
check_self_update() {
    if [ -d ".git" ] && check_cmd git; then
        echo -e "\n${BOLD}${CYAN}🔄 GIT SELF-UPDATE CHECK${NC}"
        git fetch origin main >/dev/null 2>&1
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        if [ "$LOCAL" != "$REMOTE" ]; then
            echo -e "${BOLD}${YELLOW}✨ Eine neue Version auf GitHub ist verfügbar!${NC}"
            read -p "Soll das Projekt jetzt aktualisiert (git pull) werden? [j/n]: " pull_choice
            if [[ "$pull_choice" =~ ^([jJ][aA]|[jJ])$ ]]; then
                if git pull origin main; then
                    echo -e "${GREEN}✓ Projekt aktualisiert. Bitte starte das Skript neu.${NC}"
                    exit 0
                else
                    echo -e "${RED}Fehler beim Git Update. Bitte manuell prüfen.${NC}"
                fi
            fi
        fi
    elif check_cmd curl; then
        REMOTE_VERSION=$(curl -s --connect-timeout 2 "$RAW_URL" | grep -m1 "^VERSION=" | cut -d'"' -f2)
        if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$VERSION" ]; then
            echo -e "\n${BOLD}${YELLOW}✨ EINE NEUE VERSION IST VERFÜGBAR ($REMOTE_VERSION)!${NC}"
            read -p "Möchtest du das Skript jetzt automatisch aktualisieren? [j/n]: " update_choice
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
}

# --- ALIAS LOGIK ---
setup_alias() {
    if [[ "$ENABLE_ALIAS_CHECK" == "true" ]]; then
        local current_script_path=$(readlink -f "$0")
        if ! grep -q "alias update=" ~/.bashrc; then
            echo -e "\n${BOLD}${CYAN}⌨️  SCHNELLSTART-OPTIMIERUNG${NC}"
            echo -e "Möchtest du den Alias '${BOLD}update${NC}' in deiner .bashrc anlegen?"
            echo -e "Dadurch kannst du dieses Skript einfach mit ${BOLD}update${NC} starten."
            echo -n "Drücke [ENTER] zum Bestätigen (Überspringen in 3 Sek...): "
            if read -t 3; then
                echo "alias update='$current_script_path'" >> ~/.bashrc
                echo -e "\n${GREEN}✓ Alias 'update' wurde zu ~/.bashrc hinzugefügt!${NC}"
                echo -e "${YELLOW}Info: Wirksam nach Neustart des Terminals.${NC}"
            else
                echo -e "\n${BLUE}ℹ️  Übersprungen.${NC}"
            fi
        fi
    fi
}

# --- HARDWARE DETECTION ---
GPU_INFO=$(lspci 2>/dev/null | grep -iE "vga|3d")
IS_NVIDIA=false; IS_AMD=false; IS_INTEL=false
echo "$GPU_INFO" | grep -iq "nvidia" && IS_NVIDIA=true
echo "$GPU_INFO" | grep -iqE "amd|ati" && IS_AMD=true
echo "$GPU_INFO" | grep -iq "intel" && IS_INTEL=true

# --- DESKTOP DETECTION ---
CURRENT_DE=$(echo "${XDG_CURRENT_DESKTOP:-$DESKTOP_SESSION}" | tr '[:upper:]' '[:lower:]')
DE_LABEL="Unbekannt"
[[ "$CURRENT_DE" == *"cinnamon"* ]] && DE_LABEL="Cinnamon"
[[ "$CURRENT_DE" == *"kde"* || "$CURRENT_DE" == *"plasma"* ]] && DE_LABEL="KDE Plasma"
[[ "$CURRENT_DE" == *"mate"* ]] && DE_LABEL="Mate"
[[ "$CURRENT_DE" == *"gnome"* ]] && DE_LABEL="GNOME (Debian)"
[[ "$CURRENT_DE" == *"pop"* ]] && DE_LABEL="GNOME (Pop!_OS)"
[[ "$CURRENT_DE" == *"xfce"* ]] && DE_LABEL="XFCE"
[[ "$CURRENT_DE" == *"gamescope"* ]] && DE_LABEL="Gamescope (SteamOS)"

# --- HILFE & PARAMETER ---
show_help() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BOLD}${CYAN}          $TITLE v$VERSION Hilfe          ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo -e "\n${BOLD}NUTZUNG:${NC} update [PARAMETER]"
    echo -e "\n${BOLD}PARAMETER:${NC}"
    echo -e "  ${GREEN}--full${NC}      System- und Gaming-Updates (Standard)"
    echo -e "  ${GREEN}--system${NC}    Nur System-Updates (APT, Flatpak, etc.)"
    echo -e "  ${GREEN}--game${NC}      Nur Gaming-Updates (Proton, MangoHud, etc.)"
    echo -e "  ${GREEN}--version${NC}   Zeigt die aktuelle Version des Skripts"
    echo -e "  ${GREEN}--help${NC}      Zeigt diese Hilfe an"
    echo -e "\n${BOLD}GITHUB:${NC} https://github.com/DerLinke/Ultimate-Debian-Updater"
    exit 0
}

RUN_SYSTEM=true; RUN_GAMING=true
case "$1" in
    --system) RUN_SYSTEM=true; RUN_GAMING=false ;;
    --game)   RUN_SYSTEM=false; RUN_GAMING=true ;;
    --full)   RUN_SYSTEM=true; RUN_GAMING=true ;;
    --version) echo "v$VERSION"; exit 0 ;;
    --help)    show_help ;;
    "") [ "$DEFAULT_MODE" == "system" ] && RUN_GAMING=false; [ "$DEFAULT_MODE" == "game" ] && RUN_SYSTEM=false ;;
    *) echo -e "${RED}Unbekannter Parameter: $1${NC}"; show_help ;;
esac

# --- HEADER ---
clear
echo -e "            ${C_PINK}██${RESET}            ${C_GRAD1}█${C_GRAD2}█${C_GRAD3}█${C_GRAD4}█${RESET}"
echo -e "      ${C_MAGENTA}██${RESET}                        ${C_BLUE}██${RESET}"
echo -e "${C_RED}██${RESET}                  ${C_PURP1}█${C_PURP2}█${C_PURP3}█${C_PURP4}█${RESET} ${BOLD}${CYAN}${TITLE} v${VERSION}${NC}"
echo -e "      ${C_MAGENTA}██${RESET}                        ${C_BLUE}██${RESET}"
echo -e "            ${C_PINK}██${RESET}            ${C_GRAD1}█${C_GRAD2}█${C_GRAD3}█${C_GRAD4}█${RESET}"
echo -e "${YELLOW}           Desktop: $DE_LABEL | GPU: $([ "$IS_NVIDIA" = true ] && echo "NVIDIA" || ([ "$IS_AMD" = true ] && echo "AMD" || echo "Intel/Andere"))${NC}"
echo -e "${BLUE}====================================================${NC}"

# --- SYMLINK LOGIK ---
fix_system_paths() {
    local tools=("protontricks" "gamemoderun")
    for tool in "${tools[@]}"; do
        local custom_path=$(which "$tool" 2>/dev/null || echo "$HOME/.local/bin/$tool")
        if [ -f "$custom_path" ] && [ ! -f "/usr/local/bin/$tool" ]; then
            echo -e "  ${YELLOW}→ Erstelle System-Symlink für '$tool'...${NC}"
            sudo ln -sf "$custom_path" "/usr/local/bin/$tool" && UPDATED+=("Symlink: $tool")
        fi
    done
}

# --- INITIALISIERUNG VON ALIAS & UPDATE ---
check_self_update
setup_alias

# --- DIAGNOSE ---
if [[ "$RUN_GAMING" == "true" ]]; then
    echo -e "\n${BOLD}${CYAN}🕹 SYSTEM-DIAGNOSE${NC}"
    echo -e "${BLUE}----------------------------------------------------${NC}"
    
    # 32-Bit Architektur
    dpkg --print-foreign-architectures | grep -q "i386" && echo -e "  ${GREEN}✓ 32-Bit Architektur (i386) ist aktiv.${NC}"

    # NVIDIA Specifics
    if [ "$IS_NVIDIA" = true ]; then
        if lsmod | grep -iq "nvidia"; then
            echo -e "  ${GREEN}✓ NVIDIA-Treiber aktiv.${NC}"
            check_cmd nvidia-smi && echo -e "     ${BLUE}Version:${NC} $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
        else echo -e "  ${RED}✗ NVIDIA-GPU erkannt, aber Treiber NICHT geladen.${NC}"; fi
    fi

    # Gaming Tools Check
    GAMING_TOOLS_DB=(
        "MangoHud:mangohud:mangohud"
        "GOverlay:goverlay:goverlay"
        "vkBasalt:/usr/share/vulkan/implicit_layer.d/vkBasalt.json:vkbasalt"
        "Protontricks:protontricks:pipx-protontricks"
        "GameMode:gamemoderun:gamemode"
        "ProtonUp:protonup:pipx-protonup"
    )

    MISSING_GAMING=()
    for tool_info in "${GAMING_TOOLS_DB[@]}"; do
        label=${tool_info%%:*}; tmp=${tool_info#*:}; check=${tmp%:*}; pkg=${tool_info##*:}
        if ([ -f "$check" ] || check_cmd "$check"); then
            echo -e "  ${GREEN}✓ $label:${NC} erkannt."
        else
            echo -e "  ${RED}✗ $label:${NC} fehlt."
            MISSING_GAMING+=("$pkg")
        fi
    done

    # Auto-Install
    if [ ${#MISSING_GAMING[@]} -gt 0 ]; then
        echo -e "\n${BOLD}${YELLOW}Fehlende Gaming-Tools installieren?${NC}"
        read -p "[j/n]: " inst_gaming
        if [[ "$inst_gaming" =~ ^([jJ][aA]|[jJ])$ ]]; then
            TO_INSTALL_APT=()
            TO_INSTALL_PIPX=()
            
            for tool_info in "${GAMING_TOOLS_DB[@]}"; do
                label=${tool_info%%:*}; tmp=${tool_info#*:}; check=${tmp%:*}; pkg=${tool_info##*:}
                if ! ([ -f "$check" ] || check_cmd "$check"); then
                    if [[ "$pkg" == "pipx-"* ]]; then
                        check_cmd pipx || TO_INSTALL_APT+=("pipx")
                        TO_INSTALL_PIPX+=("${pkg#pipx-}")
                    else
                        TO_INSTALL_APT+=("$pkg")
                    fi
                fi
            done

            # Phase 1: APT Installationen
            if [ ${#TO_INSTALL_APT[@]} -gt 0 ]; then
                echo -e "  ${BLUE}Installiere System-Pakete...${NC}"
                sudo apt update && sudo apt install -y "${TO_INSTALL_APT[@]}"
                UPDATED+=("Gaming-Tools (APT)")
            fi

            # Phase 2: Pipx Initialisierung & Pakete
            if [ ${#TO_INSTALL_PIPX[@]} -gt 0 ]; then
                if check_cmd pipx; then
                    echo -e "  ${BLUE}Konfiguriere pipx...${NC}"
                    pipx ensurepath --force >/dev/null 2>&1
                    export PATH="$HOME/.local/bin:$PATH"
                    
                    for p in "${TO_INSTALL_PIPX[@]}"; do
                        echo -e "  ${BLUE}Installiere $p via pipx...${NC}"
                        pipx install "$p" --force && UPDATED+=("$p (Neu via pipx)")
                    done
                else
                    echo -e "  ${RED}Fehler: pipx konnte nicht installiert werden. Überspringe pipx-Tools.${NC}"
                fi
            fi
        fi
    fi
    fix_system_paths
fi

# --- ROOT-RECHTE ---
echo -e "\n${BOLD}${YELLOW}🔐 AUTHENTIFIZIERUNG${NC}"
if ! sudo -v; then echo -e "${RED}Fehler: Root-Rechte erforderlich.${NC}"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---
echo -e "\n${BOLD}${CYAN}🔄 UPDATE-PROZESS STARTET${NC}"
echo -e "${BLUE}====================================================${NC}"

if [[ "$RUN_SYSTEM" == "true" ]]; then
    # 1. Firmware
    check_cmd fwupdmgr && (echo -e "\n${BOLD}${PURPLE}📂 FIRMWARE${NC}"; sudo fwupdmgr refresh >/dev/null 2>&1; sudo fwupdmgr get-updates && UPDATED+=("Firmware"))
    
    # 2. Desktop-Spezifisches
    echo -e "\n${BOLD}${PURPLE}📂 DESKTOP-PFLEGE ($DE_LABEL)${NC}"
    case "$CURRENT_DE" in
        *cinnamon*)
            if check_cmd cinnamon-spice-updater; then
                echo -e "  ${BLUE}Cinnamon:${NC} Aktualisiere Applets & Spices..."
                cinnamon-spice-updater --update-all && UPDATED+=("Cinnamon Spices")
            fi
            ;;
        *kde*|*plasma*)
            if check_cmd pkcon; then
                echo -e "  ${BLUE}KDE:${NC} System-Update via PackageKit (pkcon)..."
                sudo pkcon update -y && UPDATED+=("KDE System (pkcon)")
            fi
            ;;
        *mate*)
            echo -e "  ${BLUE}Mate:${NC} Optimiere Mate-Umgebung via APT..."
            sudo apt install --only-upgrade "mate-*" -y >/dev/null 2>&1
            UPDATED+=("Mate Maintenance")
            ;;
        *xfce*)
            echo -e "  ${BLUE}XFCE:${NC} Optimiere XFCE-Komponenten via APT..."
            sudo apt install --only-upgrade "xfce4-*" -y >/dev/null 2>&1
            UPDATED+=("XFCE Maintenance")
            ;;
        *gnome*|*pop*)
            echo -e "  ${BLUE}GNOME/Pop!_OS:${NC} Systempflege via APT..."
            sudo apt install --only-upgrade "gnome-shell" "gnome-control-center" -y >/dev/null 2>&1
            UPDATED+=("GNOME Maintenance")
            ;;
        *gamescope*)
            if [ -f "/usr/bin/steamos-update" ]; then
                echo -e "  ${BLUE}SteamOS:${NC} Prüfe auf System-Updates..."
                sudo steamos-update check && UPDATED+=("SteamOS Update")
            fi
            ;;
    esac

    # 3. Standard-Paketmanager
    check_cmd extrepo && (echo -e "\n${BOLD}${PURPLE}📂 EXTREPO${NC}"; sudo extrepo update && UPDATED+=("Extrepo"))
    if check_cmd apt; then
        echo -e "\n${BOLD}${PURPLE}📂 APT SYSTEM${NC}"
        sudo apt update && sudo apt full-upgrade -y && (sudo apt autoremove -y >/dev/null 2>&1; UPDATED+=("APT System"))
    fi
    check_cmd flatpak && (echo -e "\n${BOLD}${PURPLE}📂 FLATPAK${NC}"; flatpak update -y --user >/dev/null 2>&1; sudo flatpak update -y >/dev/null 2>&1; UPDATED+=("Flatpak"))
    check_cmd snap && (echo -e "\n${BOLD}${PURPLE}📂 SNAP${NC}"; sudo snap refresh && UPDATED+=("Snap"))
    check_cmd deb-get && (echo -e "\n${BOLD}${PURPLE}📂 DEB-GET${NC}"; sudo -E deb-get update && sudo -E deb-get upgrade -y && UPDATED+=("deb-get"))
    check_cmd npm && (echo -e "\n${BOLD}${PURPLE}📂 NPM${NC}"; sudo npm update -g && UPDATED+=("NPM Global"))
    check_cmd pipx && (echo -e "\n${BOLD}${PURPLE}📂 PIPX${NC}"; pipx upgrade-all && UPDATED+=("Pipx Apps"))
fi

if [[ "$RUN_GAMING" == "true" ]]; then
    echo -e "\n${BOLD}${PURPLE}📂 GAMING-TOOLS${NC}"
    
    # ProtonUpdate
    if check_cmd protonup && [ -d "$STEAM_GE_PATH" ]; then
        CURRENT_PROTON=$(ls -1 "$STEAM_GE_PATH" | grep "GE-Proton" | tail -n1)
        echo -e "  ${BLUE}Proton:${NC} Aktuell: ${GREEN}${CURRENT_PROTON:-Keines}${NC}"
        protonup -d "$STEAM_GE_PATH" >/dev/null 2>&1 && UPDATED+=("GE-Proton ($([ -n "$CURRENT_PROTON" ] && echo "Checked" || echo "Neu"))")
    fi

    # MangoHud Source Check
    if check_cmd mangohud; then
        LATEST_MANGO=$(curl -s https://api.github.com/repos/flightlessmango/MangoHud/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')
        INSTALLED_MANGO=$(mangohud --version 2>/dev/null | head -n1 | sed 's/v//' | cut -d'-' -f1)
        if [[ "$LATEST_MANGO" > "$INSTALLED_MANGO" ]]; then
            echo -e "  ${YELLOW}→ MangoHud Update verfügbar ($LATEST_MANGO).${NC}"
            UPDATED+=("MangoHud (Update available)")
        else
            SKIPPED+=("MangoHud (Aktuell: $INSTALLED_MANGO)")
        fi
    fi

    # GOverlay Source Check (für manuell installierte Binary in /usr/local/bin)
    if check_cmd goverlay && [ -f /usr/local/bin/goverlay ]; then
        LATEST_GOVERLAY=$(curl -s https://api.github.com/repos/benjamimgois/goverlay/releases/latest | grep tag_name | cut -d'"' -f4)
        INSTALLED_GOVERLAY=$(strings /usr/local/bin/goverlay 2>/dev/null | grep -E "^1\.[0-9]+\.[0-9]+$" | head -n 1)
        
        if [[ "$LATEST_GOVERLAY" != "" ]] && [[ "$LATEST_GOVERLAY" != "$INSTALLED_GOVERLAY" ]]; then
            echo -e "  ${YELLOW}→ GOverlay Update verfügbar ($LATEST_GOVERLAY). Lade herunter...${NC}"
            DL_URL="https://github.com/benjamimgois/goverlay/releases/download/${LATEST_GOVERLAY}/goverlay_${LATEST_GOVERLAY//./_}.tar.xz"
            
            # Im Hintergrund laden und ersetzen
            (
                cd /tmp || exit 1
                if wget -q "$DL_URL" -O goverlay_update.tar.xz; then
                    tar -xf goverlay_update.tar.xz
                    if [ -f "goverlay" ]; then
                        sudo mv goverlay /usr/local/bin/goverlay
                        sudo chmod +x /usr/local/bin/goverlay
                    fi
                fi
                rm -f goverlay_update.tar.xz
            )
            
            # Direkt markieren, da wir von Erfolg ausgehen
            if [ -f /usr/local/bin/goverlay ]; then
                UPDATED+=("GOverlay ($LATEST_GOVERLAY)")
            else
                FAILED+=("GOverlay Update fehlgeschlagen")
            fi
        else
            SKIPPED+=("GOverlay (Aktuell: ${INSTALLED_GOVERLAY:-Unbekannt})")
        fi
    fi
fi

# --- ABSCHLUSS ---
echo -e "\n${BOLD}${PURPLE}🧹 REINIGUNG${NC}"
sudo journalctl --vacuum-time="${CLEANUP_LOG_DAYS}" >/dev/null 2>&1
rm -rf ~/.cache/thumbnails/*
echo -e "  ${GREEN}✓ Reinigung abgeschlossen.${NC}"

echo -e "\n\n${BOLD}${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}              ABSCHLUSS-BERICHT                    ${NC}"
echo -e "${BOLD}${BLUE}====================================================${NC}"
for item in "${UPDATED[@]}"; do echo -e "  ✅ $item"; done
for item in "${SKIPPED[@]}"; do echo -e "  ℹ️  $item"; done
[ ${#FAILED[@]} -gt 0 ] && (echo -e "\n${BOLD}${RED}⚠️  FEHLER:${NC}"; for item in "${FAILED[@]}"; do echo -e "  ❌ $item"; done)

echo -e "\n"; read -p "Update beendet. Neustart erforderlich? [j/n]: " r
[[ "$r" =~ ^([jJ][aA]|[jJ])$ ]] && sudo reboot
