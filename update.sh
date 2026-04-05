#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.7.0
# ------------------------------------------------------------------------------
# Ein intelligentes All-in-one Update-Skript für Debian-basierte Systeme.
# Fokus: System-Stabilität, Gaming-Performance (Gamer-Mode) und Hygiene.
#
# GitHub: https://github.com/DerLinke/Ultimate-Debian-Updater
# Copyright (c) 2026 DerLinke
# ==============================================================================

# --- KONFIGURATION (VORGABEN) ---
# Hier kannst du das Standardverhalten festlegen.
: "${DEFAULT_MODE:=full}"           # Optionen: full, system, game
: "${STEAM_GE_PATH:=$HOME/.local/share/Steam/compatibilitytools.d/}"
: "${TITLE:=Ultimate Debian Updater}"
: "${CLEANUP_LOG_DAYS:=3d}"
: "${ENABLE_ALIAS_CHECK:=true}"
: "${DEBGET_TOKEN:=}"               # GitHub Token für deb-get (optional)

# --- KONFIGURATION (GAMER-MODE) ---
: "${GAMER_MODE:=true}"
: "${CHECK_32BIT_LIBS:=true}"
: "${OPTISCALER_PATH:=$HOME/.local/share/optiscaler}"
: "${MANAGE_VULKAN_LAYERS:=true}"

# --- INITIALISIERUNG ---
VERSION="2.7.0"
RAW_URL="https://raw.githubusercontent.com/DerLinke/Ultimate-Debian-Updater/main/update.sh"
UPDATED=(); FAILED=(); SKIPPED=()
export PATH="$HOME/.local/bin:$PATH"

# Steuerungsvariablen basierend auf DEFAULT_MODE
RUN_SYSTEM=true
RUN_GAMING=true

check_cmd() { 
    command -v "$1" >/dev/null 2>&1 || [ -f "$HOME/.local/bin/$1" ] || [ -f "/usr/local/bin/$1" ]
}

# --- FARBEN & STILE ---
if [[ -n "$FORCE_COLOR" ]] || (check_cmd tput && [ $(tput colors 2>/dev/null || echo 0) -ge 8 ]); then
    BOLD=$(tput bold); NC=$(tput sgr0); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); PURPLE=$(tput setaf 5); CYAN=$(tput setaf 6)
fi
: "${BOLD:=}"; : "${NC:=}"; : "${RED:=}"; : "${GREEN:=}"; : "${YELLOW:=}"; : "${BLUE:=}"; : "${PURPLE:=}"; : "${CYAN:=}"

# --- HILFE & PARAMETER ---
show_help() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BOLD}${CYAN}          $TITLE v$VERSION Hilfe          ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo -e "\n${BOLD}NUTZUNG:${NC} update [PARAMETER]"
    echo -e "\n${BOLD}PARAMETER:${NC}"
    echo -e "  ${GREEN}--full${NC}      System- und Gaming-Updates"
    echo -e "  ${GREEN}--system${NC}    Nur System-Updates (APT, Flatpak, Snap, etc.)"
    echo -e "  ${GREEN}--game${NC}      Nur Gaming-Updates (Proton, MangoHud, etc.)"
    echo -e "  ${GREEN}--version${NC}   Zeigt die aktuelle Version des Skripts"
    echo -e "  ${GREEN}--help${NC}      Zeigt diese Hilfe an"
    echo -e "\n${BOLD}INFO:${NC} Der Standard-Modus ist aktuell auf '${CYAN}$DEFAULT_MODE${NC}' gesetzt."
    exit 0
}

# Modus-Steuerung
case "$1" in
    --system) RUN_SYSTEM=true; RUN_GAMING=false ;;
    --game)   RUN_SYSTEM=false; RUN_GAMING=true ;;
    --full)   RUN_SYSTEM=true; RUN_GAMING=true ;;
    --version) echo "v$VERSION"; exit 0 ;;
    --help)    show_help ;;
    "")       
        case "$DEFAULT_MODE" in
            system) RUN_SYSTEM=true; RUN_GAMING=false ;;
            game)   RUN_SYSTEM=false; RUN_GAMING=true ;;
            *)      RUN_SYSTEM=true; RUN_GAMING=true ;;
        esac
        ;;
    *) echo -e "${RED}Unbekannter Parameter: $1${NC}"; show_help ;;
esac

# --- HEADER ---
clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}          🚀 $TITLE v$VERSION 🚀          ${NC}"
echo -e "${YELLOW}           Created by DerLinke (GitHub)           ${NC}"
echo -e "${BLUE}====================================================${NC}"

# --- DYNAMISCHE GAMEMODE CONFIG LOGIK ---
setup_gamemode_config() {
    local config_file="$HOME/.config/gamemode.ini"
    local gov_path="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
    local available_govs=""
    [ -f "$gov_path" ] && available_govs=$(cat "$gov_path")

    local high_perf="performance"
    local balanced="powersave"
    [[ "$available_govs" == *"schedutil"* ]] && balanced="schedutil"
    [[ "$available_govs" == *"ondemand"* ]] && balanced="ondemand"

    if [ ! -f "$config_file" ]; then
        echo -e "  ${YELLOW}→ Erstelle optimierte GameMode Konfiguration...${NC}"
        mkdir -p "$HOME/.config"
        echo -e "[general]\nreaper=true\n\n[gpu]\napply_gpu_optimisations=true\ngpu_device=0\namd_performance_level=high\n\n[cpu]\ngovernor=$high_perf\n\n[custom]\nstart=notify-send 'GameMode' 'Optimierungen aktiviert ($high_perf)'\nend=notify-send 'GameMode' 'Optimierungen deaktiviert ($balanced)'" > "$config_file"
    else
        if ! grep -q "governor=$high_perf" "$config_file"; then
            echo -e "  ${YELLOW}→ Aktualisiere CPU-Governor in GameMode Config...${NC}"
            sed -i "s/governor=.*/governor=$high_perf/" "$config_file"
        fi
    fi
}

# --- ABHÄNGIGKEITS-CHECK (GLOBAL) ---
REQUIRED_BINS=("curl" "lspci" "lsb_release")
[[ "$RUN_GAMING" == "true" ]] && REQUIRED_BINS+=("pipx" "glxinfo" "vulkaninfo")

MISSING_BINS=()
for bin in "${REQUIRED_BINS[@]}"; do
    check_cmd "$bin" || MISSING_BINS+=("$bin")
done

if [ ${#MISSING_BINS[@]} -gt 0 ]; then
    echo -e "\n${BOLD}${YELLOW}🔍 PRÜFUNG DER ABHÄNGIGKEITEN${NC}"
    echo -e "${RED}Es fehlen wichtige Tools: ${BOLD}${MISSING_BINS[*]}${NC}"
    read -p "Sollen diese jetzt via APT installiert werden? [j/n]: " inst_deps
    if [[ "$inst_deps" =~ ^([jJ][aA]|[jJ])$ ]]; then
        sudo apt update && sudo apt install -y "${MISSING_BINS[@]}"
        [[ " ${MISSING_BINS[*]} " == *" pipx "* ]] && pipx ensurepath
    fi
fi

# --- DIAGNOSE (HARDWARE & GAMING) ---
echo -e "\n${BOLD}${CYAN}🖥 HARDWARE- & DIAGNOSE-CHECK${NC}"
echo -e "${BLUE}----------------------------------------------------${NC}"

# GPU Info
GPU_INFO=$(lspci 2>/dev/null | grep -iE "vga|3d")
if echo "$GPU_INFO" | grep -iq "nvidia"; then
    check_cmd nvidia-smi && echo -e "  ${GREEN}✓ NVIDIA GPU:${NC} $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
elif echo "$GPU_INFO" | grep -iqE "amd|ati"; then
    echo -e "  ${GREEN}✓ AMD GPU detected (Mesa).${NC}"
fi

# 32-Bit Check
if [[ "$RUN_GAMING" == "true" ]]; then
    dpkg --print-foreign-architectures | grep -q "i386" && echo -e "  ${GREEN}✓ 32-Bit Architektur (i386) ist aktiv.${NC}" || echo -e "  ${RED}✗ 32-Bit Architektur fehlt.${NC}"
fi

# Gaming Tools Diagnosis
if [[ "$RUN_GAMING" == "true" ]]; then
    # Label:Check-Path/Cmd:Package-Name
    GAMING_TOOLS_DB=(
        "MangoHud:mangohud:mangohud"
        "GOverlay:goverlay:goverlay"
        "vkBasalt:/usr/share/vulkan/implicit_layer.d/vkBasalt.json:vkbasalt"
        "Protontricks:protontricks:pipx-protontricks"
        "GameMode:gamemoderun:gamemode"
    )

    MISSING_GAMING=()
    for tool_info in "${GAMING_TOOLS_DB[@]}"; do
        label=${tool_info%%:*}
        tmp=${tool_info#*:}
        check=${tmp%:*}
        pkg=${tool_info##*:}

        found=false
        if [[ "$check" == /* ]] && [ -f "$check" ]; then found=true;
        elif check_cmd "$check"; then found=true; fi

        if [ "$found" = true ]; then
            case "$check" in
                mangohud) echo -e "  ${GREEN}✓ $label:${NC} $(mangohud --version 2>/dev/null | head -n1)"; SKIPPED+=("$label (OK)") ;;
                protontricks) echo -e "  ${GREEN}✓ $label:${NC} $(protontricks --version 2>/dev/null | head -n1)"; SKIPPED+=("$label (OK)") ;;
                gamemoderun) echo -e "  ${GREEN}✓ $label:${NC} erkannt."; setup_gamemode_config; SKIPPED+=("$label (Config OK)") ;;
                *) echo -e "  ${GREEN}✓ $label:${NC} erkannt."; SKIPPED+=("$label (OK)") ;;
            esac
        else
            echo -e "  ${RED}✗ $label:${NC} fehlt."
            MISSING_GAMING+=("$pkg")
        fi
    done

    # Automatische Installation Gaming-Tools
    if [ ${#MISSING_GAMING[@]} -gt 0 ]; then
        echo -e "\n${BOLD}${YELLOW}Fehlende Gaming-Tools installieren?${NC}"
        read -p "[j/n]: " inst_gaming
        if [[ "$inst_gaming" =~ ^([jJ][aA]|[jJ])$ ]]; then
            TO_INSTALL_APT=()
            for p in "${MISSING_GAMING[@]}"; do
                if [[ "$p" == "pipx-protontricks" ]]; then
                    pipx install protontricks && UPDATED+=("Protontricks (Neu)")
                else
                    TO_INSTALL_APT+=("$p")
                fi
            done
            [ ${#TO_INSTALL_APT[@]} -gt 0 ] && sudo apt update && sudo apt install -y "${TO_INSTALL_APT[@]}" && UPDATED+=("Gaming-Tools (APT)")
        fi
    fi
fi

# --- MANAGER OVERVIEW ---
echo -e "\n${BOLD}${CYAN}🔍 MANAGER-ÜBERSICHT${NC}"
echo -e "${BLUE}----------------------------------------------------${NC}"
SYSTEM_MANAGERS=("apt" "flatpak" "snap" "deb-get" "npm" "pipx")
echo -n "  ${BOLD}Status:${NC} "
for m in "${SYSTEM_MANAGERS[@]}"; do
    if check_cmd "$m"; then echo -ne "${GREEN}✓${NC} $m  "; else echo -ne "${RED}✗${NC} $m  "; fi
done
echo -e ""

# --- AUTHENTIFIZIERUNG ---
echo -e "\n${BOLD}${YELLOW}🔐 AUTHENTIFIZIERUNG${NC}"
if ! sudo -v; then echo -e "${RED}Fehler: Root-Rechte erforderlich.${NC}"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---
echo -e "\n${BOLD}${CYAN}🔄 UPDATE-PROZESS STARTET${NC}"
echo -e "${BLUE}====================================================${NC}"

if [[ "$RUN_SYSTEM" == "true" ]]; then
    # 1. Firmware, 2. Extrepo, 3. APT
    check_cmd fwupdmgr && (echo -e "\n${BOLD}${PURPLE}📂 FIRMWARE${NC}"; sudo fwupdmgr refresh >/dev/null 2>&1; sudo fwupdmgr get-updates && UPDATED+=("Firmware"))
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
    check_cmd protonup && [ -d "$STEAM_GE_PATH" ] && (protonup -d "$STEAM_GE_PATH" >/dev/null 2>&1 && UPDATED+=("GE-Proton"))
    if check_cmd mangohud; then
        LATEST_MANGO=$(curl -s https://api.github.com/repos/flightlessmango/MangoHud/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')
        INSTALLED_MANGO=$(mangohud --version 2>/dev/null | head -n1 | sed 's/v//' | cut -d'-' -f1)
        [[ "$LATEST_MANGO" > "$INSTALLED_MANGO" ]] && UPDATED+=("MangoHud (Source Update)") || SKIPPED+=("MangoHud (Aktuell)")
        flatpak list | grep -q "MangoHud" && sudo flatpak uninstall -y org.freedesktop.Platform.VulkanLayer.MangoHud >/dev/null 2>&1
    fi
fi

# 10. Reinigung
echo -e "\n${BOLD}${PURPLE}🧹 REINIGUNG${NC}"
sudo journalctl --vacuum-time="${CLEANUP_LOG_DAYS}" >/dev/null 2>&1
rm -rf ~/.cache/thumbnails/*
echo -e "  ${GREEN}✓ Reinigung abgeschlossen.${NC}"

# --- ZUSAMMENFASSUNG ---
echo -e "\n\n${BOLD}${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}              ABSCHLUSS-BERICHT                    ${NC}"
echo -e "${BOLD}${BLUE}====================================================${NC}"
for item in "${UPDATED[@]}"; do echo -e "  ✅ $item"; done
for item in "${SKIPPED[@]}"; do echo -e "  ℹ️  $item"; done
[ ${#FAILED[@]} -gt 0 ] && (echo -e "\n${BOLD}${RED}⚠️  FEHLER:${NC}"; for item in "${FAILED[@]}"; do echo -e "  ❌ $item"; done)

echo -e "\n"; read -p "Update beendet. Neustart erforderlich? (j/n): " r
[[ "$r" == "j" ]] && sudo reboot
