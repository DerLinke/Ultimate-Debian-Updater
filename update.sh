#!/bin/bash
# ==============================================================================
# 🚀 Ultimate Debian Updater v2.7.1
# ------------------------------------------------------------------------------
# Ein intelligentes All-in-one Update-Skript für Debian-basierte Systeme.
# Fokus: System-Stabilität, Gaming-Performance (Gamer-Mode) und Hygiene.
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
VERSION="2.7.1"
RAW_URL="https://raw.githubusercontent.com/DerLinke/Ultimate-Debian-Updater/main/update.sh"
UPDATED=(); FAILED=(); SKIPPED=()
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

check_cmd() { 
    command -v "$1" >/dev/null 2>&1 || [ -f "$HOME/.local/bin/$1" ] || [ -f "/usr/local/bin/$1" ]
}

# --- FARBEN & STILE ---
if [[ -n "$FORCE_COLOR" ]] || (check_cmd tput && [ $(tput colors 2>/dev/null || echo 0) -ge 8 ]); then
    BOLD=$(tput bold); NC=$(tput sgr0); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); PURPLE=$(tput setaf 5); CYAN=$(tput setaf 6)
fi
: "${BOLD:=}"; : "${NC:=}"; : "${RED:=}"; : "${GREEN:=}"; : "${YELLOW:=}"; : "${BLUE:=}"; : "${PURPLE:=}"; : "${CYAN:=}"

# --- MODUS-STEUERUNG ---
RUN_SYSTEM=true; RUN_GAMING=true
case "$1" in
    --system) RUN_SYSTEM=true; RUN_GAMING=false ;;
    --game)   RUN_SYSTEM=false; RUN_GAMING=true ;;
    --full)   RUN_SYSTEM=true; RUN_GAMING=true ;;
    "") [ "$DEFAULT_MODE" == "system" ] && RUN_GAMING=false; [ "$DEFAULT_MODE" == "game" ] && RUN_SYSTEM=false ;;
    *) echo -e "${RED}Unbekannter Parameter: $1${NC}"; exit 1 ;;
esac

# --- HEADER ---
clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${BOLD}${CYAN}          🚀 $TITLE v$VERSION 🚀          ${NC}"
echo -e "${YELLOW}           Created by DerLinke (GitHub)           ${NC}"
echo -e "${BLUE}====================================================${NC}"

# --- SYMLINK LOGIK (FÜR GOverlay & Steam) ---
fix_system_paths() {
    local tools=("protontricks" "gamemoderun")
    # FGMOD Spezial-Check
    local fgmod_local="$HOME/.local/share/goverlay/fgmod/fgmod"
    [ -f "$fgmod_local" ] && tools+=("fgmod:$fgmod_local")

    for tool_info in "${tools[@]}"; do
        local tool=${tool_info%%:*}
        local custom_path=${tool_info#*:}
        [ "$custom_path" == "$tool" ] && custom_path=$(which "$tool" 2>/dev/null || echo "$HOME/.local/bin/$tool")

        if [ -f "$custom_path" ] && [ ! -f "/usr/local/bin/$tool" ]; then
            echo -e "  ${YELLOW}→ Erstelle System-Symlink für '$tool' (für GOverlay/Steam)...${NC}"
            sudo ln -sf "$custom_path" "/usr/local/bin/$tool" && UPDATED+=("Symlink: $tool")
        fi
    done
}

# --- DYNAMISCHE GAMEMODE CONFIG ---
setup_gamemode_config() {
    local config_file="$HOME/.config/gamemode.ini"
    local gov_available=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
    local high_perf="performance"; local balanced="powersave"
    [[ "$gov_available" == *"schedutil"* ]] && balanced="schedutil"
    
    if [ ! -f "$config_file" ] || ! grep -q "governor=$high_perf" "$config_file"; then
        echo -e "  ${YELLOW}→ Konfiguriere GameMode ($high_perf <-> $balanced)...${NC}"
        mkdir -p "$HOME/.config"
        echo -e "[general]\nreaper=true\n\n[gpu]\napply_gpu_optimisations=true\ngpu_device=0\namd_performance_level=high\n\n[cpu]\ngovernor=$high_perf\n\n[custom]\nstart=notify-send 'GameMode' 'Optimierungen aktiviert ($high_perf)'\nend=notify-send 'GameMode' 'Optimierungen deaktiviert ($balanced)'" > "$config_file"
        SKIPPED+=("GameMode Config (OK)")
    fi
}

# --- DIAGNOSE ---
if [[ "$RUN_GAMING" == "true" ]]; then
    echo -e "\n${BOLD}${CYAN}🕹 GAMING-DIAGNOSE${NC}"
    echo -e "${BLUE}----------------------------------------------------${NC}"
    
    # Check 32-Bit
    dpkg --print-foreign-architectures | grep -q "i386" && echo -e "  ${GREEN}✓ 32-Bit Architektur (i386) ist aktiv.${NC}"

    # Gaming Tools Check
    GAMING_TOOLS_DB=(
        "MangoHud:mangohud:mangohud"
        "GOverlay:goverlay:goverlay"
        "vkBasalt:/usr/share/vulkan/implicit_layer.d/vkBasalt.json:vkbasalt"
        "Protontricks:protontricks:pipx-protontricks"
        "GameMode:gamemoderun:gamemode"
    )

    MISSING_GAMING=()
    for tool_info in "${GAMING_TOOLS_DB[@]}"; do
        label=${tool_info%%:*}; tmp=${tool_info#*:}; check=${tmp%:*}; pkg=${tool_info##*:}
        
        if ([ -f "$check" ] || check_cmd "$check"); then
            echo -e "  ${GREEN}✓ $label:${NC} erkannt."
            [ "$check" == "gamemoderun" ] && setup_gamemode_config
        else
            echo -e "  ${RED}✗ $label:${NC} fehlt."
            MISSING_GAMING+=("$pkg")
        fi
    done

    # Symlinks fixen bevor der Bericht kommt
    fix_system_paths

    # Auto-Install
    if [ ${#MISSING_GAMING[@]} -gt 0 ]; then
        echo -e "\n${BOLD}${YELLOW}Fehlende Gaming-Tools installieren?${NC}"
        read -p "[j/n]: " inst_gaming
        if [[ "$inst_gaming" =~ ^([jJ][aA]|[jJ])$ ]]; then
            TO_INSTALL_APT=()
            for p in "${MISSING_GAMING[@]}"; do
                if [[ "$p" == "pipx-protontricks" ]]; then
                    check_cmd pipx || TO_INSTALL_APT+=("pipx")
                    pipx install protontricks && UPDATED+=("Protontricks (Neu)")
                else TO_INSTALL_APT+=("$p"); fi
            done
            [ ${#TO_INSTALL_APT[@]} -gt 0 ] && sudo apt update && sudo apt install -y "${TO_INSTALL_APT[@]}" && UPDATED+=("Gaming-Tools (APT)")
            fix_system_paths # Nochmal nach Installation
        fi
    fi
fi

# --- AUTHENTIFIZIERUNG ---
echo -e "\n${BOLD}${YELLOW}🔐 AUTHENTIFIZIERUNG${NC}"
if ! sudo -v; then echo -e "${RED}Fehler: Root-Rechte erforderlich.${NC}"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- UPDATE LOGIK ---
echo -e "\n${BOLD}${CYAN}🔄 UPDATE-PROZESS STARTET${NC}"
echo -e "${BLUE}====================================================${NC}"

if [[ "$RUN_SYSTEM" == "true" ]]; then
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
        [[ "$LATEST_MANGO" > "$INSTALLED_MANGO" ]] && UPDATED+=("MangoHud (Update available)") || SKIPPED+=("MangoHud (Aktuell)")
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
