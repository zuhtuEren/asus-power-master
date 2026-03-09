#!/bin/bash
# Asus Power Master - Main Control File v2.6 (Final Gold)

# --- LIBRARY LOADING ---
# Searches for library files in system directory or local 'lib'
if [ -d "/usr/local/share/asus-pwr/lib" ]; then
    LIB_DIR="/usr/local/share/asus-pwr/lib"
else
    LIB_DIR="$(dirname "$(readlink -f "$0")")/lib"
fi

for lib in extra battery performance dashboard persistence; do
    if [ -f "$LIB_DIR/$lib.sh" ]; then 
        source "$LIB_DIR/$lib.sh"
    else 
        echo "[ERROR] $lib.sh missing!"; exit 1 
    fi
done

# --- CONFIG LOADER ---
# Safely reads configuration without executing code
load_config() {
    [ ! -f "/etc/asus-power.conf" ] && return
    # Read allowed keys only
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Whitelist allowed keys to prevent variable injection
        case "$key" in
            BATTERY_LIMIT|TURBO_BOOST|FAN_MODE|\
            AC_FAN|AC_TURBO|AC_KBD|\
            BAT_FAN|BAT_TURBO|BAT_KBD)
                # Remove quotes if present
                value="${value%\"}"
                value="${value#\"}"
                # Sanitize value (alphanumeric only)
                if [[ "$value" =~ ^[a-zA-Z0-9]+$ ]]; then
                    declare -g "$key=$value"
                fi
                ;;
        esac
    done < "/etc/asus-power.conf"
}

# --- WATCHDOG ENGINE ---
# Main loop checking power source changes every 2 seconds
monitor_ac_status() {
    local kbd_pref="$1"
    echo -e "\e[34m[INFO]\e[0m Smart Watchdog active. Monitoring power states..."
    local last_status=""

    while true; do
        # Refreshes user settings from file in every loop (For instant response)
        load_config
        
        local current_status=$(get_ac_status)
        if [ "$current_status" != "$last_status" ]; then
            apply_auto_profile "$kbd_pref"
            last_status=$current_status
        fi
        sleep 2
    done
}

# --- PERMISSION CHECK ---
[[ $EUID -ne 0 ]] && echo -e "\e[31m[ERROR]\e[0m Root privileges required. Please use sudo." && exit 1

# --- COMMAND ROUTING ---
case $1 in
    -s|--status)   show_dashboard ;;
    -b|--battery)  set_battery_limit "$2"; [[ "$3" == "-p" ]] && save_setting "BATTERY_LIMIT" "$2" && enable_persistence ;;
    -t|--turbo)    set_turbo_boost "$2";  [[ "$3" == "-p" ]] && save_setting "TURBO_BOOST" "$2" && enable_persistence ;;
    -f|--fan)      set_fan_mode "$2";     [[ "$3" == "-p" ]] && save_setting "FAN_MODE" "$2" && enable_persistence ;;
    -k|--keyboard) set_kbd_brightness "$2" ;;
    
    --set-ac|--set-bat)
        # Detects profile type (AC/BAT)
        if [[ "$1" == "--set-ac" ]]; then profile_type="AC"; else profile_type="BAT"; fi
        shift
        while [[ "$#" -gt 0 ]]; do
            case $1 in
                -f|--fan)      save_setting "${profile_type}_FAN" "$2"; shift ;;
                -t|--turbo)    save_setting "${profile_type}_TURBO" "$2"; shift ;;
                -k|--keyboard) save_setting "${profile_type}_KBD" "$2"; shift ;;
            esac
            shift
        done
        enable_persistence
        echo -e "\e[32m[SUCCESS]\e[0m $profile_type profile updated in /etc/asus-power.conf"
        ;;

    --monitor)
        # Get current brightness or start with parameter
        kbd_arg=$(cat "$KBD_PATH/brightness" 2>/dev/null || echo 0)
        [[ "$2" == "-k" ]] && kbd_arg="$3"
        monitor_ac_status "$kbd_arg"
        ;;

    --apply)
        # Applies settings saved at system boot
        load_config
        
        # Wait loop to ensure hardware paths are ready
        # Drivers may sometimes load a few seconds late during boot
        for i in {1..5}; do
            source "$LIB_DIR/extra.sh"
            [[ -n "$BAT_DIR" ]] && break
            sleep 1
        done

        # Apply if settings are defined
        [[ -n "$BATTERY_LIMIT" ]] && set_battery_limit "$BATTERY_LIMIT"
        [[ -n "$TURBO_BOOST" ]] && set_turbo_boost "$TURBO_BOOST"
        [[ -n "$FAN_MODE" ]] && set_fan_mode "$FAN_MODE"
        
        # Reset exit code for service to close with 'Success'
        exit 0
        ;;

    -h|--help|*)
        echo -e "\e[34mAsus Power Master v2.6 - Usage Guide\e[0m"
        echo "-------------------------------------------------------"
        echo "  -s, --status              Show dashboard status"
        echo "  -b, --battery [60-100]    Set charge limit (-p for persistence)"
        echo "  -t, --turbo [on/off]      Toggle CPU Turbo (-p for persistence)"
        echo "  -f, --fan [0|1|2]         Set Fan Mode (0:Bal, 1:Turbo, 2:Sil)"
        echo "  -k, --keyboard [0-3]      Set Backlight level"
        echo ""
        echo -e "\e[1mPROFILE MANAGEMENT:\e[0m"
        echo "  --set-ac [options]        Customize AC (Plugged) profile"
        echo "  --set-bat [options]       Customize Battery profile"
        echo "  --monitor [-k level]      Start smart background watchdog"
        ;;
esac
