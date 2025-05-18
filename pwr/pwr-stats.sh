#!/bin/bash

# ==============================================================================
# COOL RESOURCE MONITOR SCRIPT FOR VALIDATOR (English Version - No Nethogs)
# Version with process CPU distribution per core and RAM details
# All user-facing output in English. CPU distribution: 2 cores per line.
# Patched v2: Using awk for more robust rounding in generate_bar.
# ==============================================================================

# Target process name
TARGET_PROCESS_NAME="validator.jar"
# Network interface to monitor for total bandwidth
MONITOR_INTERFACE="eth0"
# Name of the blocks directory, assumed to be relative to validator.jar's CWD
BLOCKS_DIR_NAME="blocks"


# --- ANSI Color Codes ---
C_OFF='\033[0m'      # Reset Color

# Regular Text Colors
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[0;37m'

# Bold Text Colors
B_RED='\033[1;31m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'
B_PURPLE='\033[1;35m'
B_CYAN='\033[1;36m'
B_WHITE='\033[1;37m'

# Background Colors
BG_RED='\033[0;41m'
BG_GREEN='\033[0;42m'
BG_YELLOW='\033[0;43m'
BG_BLUE='\033[0;44m'

# --- Global Variables for Results ---
PID=""
PROCESS_DETAILS_STR=""
CPU_RAM_STR=""
PROCESS_CPU_USAGE_FLOAT="0.0" # Stores %CPU of the process from ps
PER_CORE_CPU_STR="" # For process CPU distribution bars
NET_CONN_STR=""
INTERFACE_BANDWIDTH_STR="" # For eth0 bandwidth
ERROR_NOTES="" # For important error/warning notes

OS_VERSION_STR="N/A"
JAVA_VERSION_STR="N/A"
BLOCKS_DISK_USAGE_STR="N/A"


CURRENT_DATETIME=$(LC_TIME=en_US.UTF-8 date +"%A, %d %B %Y %T %Z") # Force English date format

# --- Global System Specs ---
TOTAL_CPU_CORES="N/A"
TOTAL_RAM_STR="N/A" # String for total RAM display
TOTAL_RAM_KB=0 # Numeric total RAM in KB for calculations

# --- Helper Functions ---
print_line() {
    printf "${B_CYAN}====================================================================================${C_OFF}\n"
}

print_header_section() {
    local title="$1"
    printf "\n${B_PURPLE}--- %-70s ---${C_OFF}\n" "$title"
}


generate_bar() {
    local percentage_float_arg="$1" # Original argument
    local length=${2:-20} # Default length 20 if not provided
    local percentage_float_sanitized # Will hold sanitized float string


    if [[ "$percentage_float_arg" =~ ^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$ || "$percentage_float_arg" =~ ^[-+]?[0-9]+\.?$ ]]; then
        percentage_float_sanitized="$percentage_float_arg"
    else
        percentage_float_sanitized="0.0"
    fi

    local percentage_int
    percentage_int=$(LC_NUMERIC=C awk -v num="$percentage_float_sanitized" 'BEGIN { printf "%.0f", num }' 2>/dev/null)

    if ! [[ "$percentage_int" =~ ^[-+]?[0-9]+$ ]]; then
        percentage_int=0
    fi

    # Ensure percentage is within 0-100 range
    if [ "$percentage_int" -lt 0 ]; then percentage_int=0; fi
    if [ "$percentage_int" -gt 100 ]; then percentage_int=100; fi

    local filled_length=$((percentage_int * length / 100))
    local empty_length=$((length - filled_length))
    # Ensure empty_length is not negative
    if [ "$empty_length" -lt 0 ]; then empty_length=0; fi


    local bar=""
    for ((i=0; i<filled_length; i++)); do bar+="❚"; done # Character for filled part
    for ((i=0; i<empty_length; i++)); do bar+="-"; done # Character for empty part
    
    printf "[%s] %3d%%" "$bar" "$percentage_int"
}


# --- Data Collection Functions ---

get_system_specs() {
    # Get Total CPU Cores
    if command -v nproc &> /dev/null; then
        TOTAL_CPU_CORES=$(nproc --all)
    elif [ -f /proc/cpuinfo ]; then # Fallback if nproc is not available
        TOTAL_CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    else
        TOTAL_CPU_CORES="Not detected"
        ERROR_NOTES+="* Could not detect total CPU cores.\n"
    fi

    # Get Total RAM
    if [ -f /proc/meminfo ]; then
        local mem_total_kb
        mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        if [[ -n "$mem_total_kb" && "$mem_total_kb" -gt 0 ]]; then
            TOTAL_RAM_KB=$mem_total_kb # Store numeric value
            local total_ram_mb=$((mem_total_kb / 1024))
            if [ "$total_ram_mb" -ge 1024 ]; then
                TOTAL_RAM_STR=$(LC_NUMERIC=C awk -v total_mb="$total_ram_mb" 'BEGIN {printf "%.2f GB", total_mb / 1024}')
            else
                TOTAL_RAM_STR="${total_ram_mb} MB"
            fi
        else
            TOTAL_RAM_STR="Not detected"
            ERROR_NOTES+="* Could not detect total system RAM from /proc/meminfo.\n"
        fi
    else
        TOTAL_RAM_STR="Not detected"
        ERROR_NOTES+="* /proc/meminfo not found. Cannot detect total system RAM.\n"
    fi
}

get_os_java_versions() {
    # OS Version
    local os_desc=""
    local os_arch
    os_arch=$(uname -m)

    if command -v lsb_release &> /dev/null; then
        os_desc=$(lsb_release -ds)
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        os_desc="${PRETTY_NAME:-$NAME}"
    elif [ -f /etc/issue ]; then
        os_desc=$(head -n 1 /etc/issue) # Fallback to /etc/issue
    else
        os_desc=$(uname -s -r) # Generic fallback
    fi
    OS_VERSION_STR="${os_desc} (${os_arch})"

    # Java Version
    if command -v java &> /dev/null; then
        local java_ver_full
        java_ver_full=$(java -version 2>&1) # Output often goes to stderr
        if echo "$java_ver_full" | grep -q 'version'; then
            JAVA_VERSION_STR=$(echo "$java_ver_full" | grep 'version' | head -n 1 | awk '{print $3}' | sed 's/"//g')
        elif echo "$java_ver_full" | grep -q 'OpenJDK'; then # Fallback for some OpenJDK formats
            JAVA_VERSION_STR=$(echo "$java_ver_full" | grep 'OpenJDK' | head -n 1)
        else
            JAVA_VERSION_STR="Java installed, version format unrecognized"
        fi
        if [ -z "$JAVA_VERSION_STR" ]; then # If awk parsing failed but java is present
            JAVA_VERSION_STR="Java installed, version parsing failed"
        fi
    else
        JAVA_VERSION_STR="Not installed or not in PATH"
        ERROR_NOTES+="* Java not found in PATH.\n"
    fi
}


find_pid_details() {
    local pids_found
    pids_found=$(pgrep -af "$TARGET_PROCESS_NAME") # -a for full command line

    if [ -z "$pids_found" ]; then
        PROCESS_DETAILS_STR="${B_RED}  ✘ Not Found${C_OFF}: Process '$TARGET_PROCESS_NAME' is not running."
        PID=""
        ERROR_NOTES+="* Process '$TARGET_PROCESS_NAME' not found.\n"
        return 1
    fi

    PID=$(echo "$pids_found" | head -n 1 | awk '{print $1}')
    local full_command
    full_command=$(echo "$pids_found" | head -n 1 | cut -d' ' -f2-)

    local self_pid_check="$$"
    local parent_command_check
    parent_command_check=$(ps -p "$PID" -o comm=)

    if [[ "$PID" -eq "$self_pid_check" ]] || [[ "$parent_command_check" == "pgrep" ]] || [[ "$parent_command_check" == "grep" ]] || { [[ "$parent_command_check" == "bash" ]] && ps -p "$PID" -o args= | grep -qF "$0"; }; then
        PROCESS_DETAILS_STR="${B_RED}  ✘ PID Error${C_OFF}: Search found this script. Ensure '$TARGET_PROCESS_NAME' is unique."
        PID=""
        ERROR_NOTES+="* Error in PID identification (possibly found this script itself).\n"
        return 1
    fi

    PROCESS_DETAILS_STR="${B_GREEN}  ✔ Found${C_OFF}\n"
    PROCESS_DETAILS_STR+="  ${C_CYAN}PID${C_OFF}                  : ${B_WHITE}$PID${C_OFF}\n"
    if [ ${#full_command} -gt 60 ]; then
        full_command="${full_command:0:57}..."
    fi
    PROCESS_DETAILS_STR+="  ${C_CYAN}Command${C_OFF}                : ${C_WHITE}$full_command${C_OFF}"
    return 0
}

get_cpu_ram_info() {
    if [ -z "$PID" ]; then
        CPU_RAM_STR="  ${C_YELLOW}Invalid PID. Cannot fetch CPU/RAM data.${C_OFF}"
        PROCESS_CPU_USAGE_FLOAT="0.0" # Reset if PID is invalid
        return
    fi

    local ps_output
    ps_output=$(LC_NUMERIC=C ps -p "$PID" -o %cpu,%mem,rss,vsz --no-headers)

    if [ -z "$ps_output" ]; then
        CPU_RAM_STR="  ${B_RED}Failed to fetch CPU/RAM data for PID $PID.${C_OFF}"
        ERROR_NOTES+="* Failed to fetch CPU/RAM data (ps error for PID $PID).\n"
        PROCESS_CPU_USAGE_FLOAT="0.0" # Reset if fetch fails
        return
    fi

    local cpu_usage_val mem_usage_percent rss_kb vsz_kb
    cpu_usage_val=$(echo "$ps_output" | awk '{print $1}')
    mem_usage_percent=$(echo "$ps_output" | awk '{print $2}')
    rss_kb=$(echo "$ps_output" | awk '{print $3}')
    vsz_kb=$(echo "$ps_output" | awk '{print $4}')

    PROCESS_CPU_USAGE_FLOAT="$cpu_usage_val" # Store global process %CPU

    local rss_mb=$((rss_kb / 1024))
    local vsz_mb=$((vsz_kb / 1024))

    local used_ram_kb=0
    if [[ "$TOTAL_RAM_KB" -gt 0 && "$(LC_NUMERIC=C echo "$mem_usage_percent > 0" | bc -l 2>/dev/null)" -eq 1 ]]; then
        used_ram_kb=$(LC_NUMERIC=C awk -v total_kb="$TOTAL_RAM_KB" -v percent="$mem_usage_percent" 'BEGIN {printf "%.0f", total_kb * (percent / 100)}')
    elif ! command -v bc &> /dev/null; then
        ERROR_NOTES+="* 'bc' not found, cannot calculate precise 'Used RAM MB of Total MB'.\n"
    fi
    local used_ram_mb=$((used_ram_kb / 1024))
    local total_ram_mb_for_display=$((TOTAL_RAM_KB / 1024))

    CPU_RAM_STR="  ${C_CYAN}CPU Usage (Process)${C_OFF}    : ${B_WHITE}${PROCESS_CPU_USAGE_FLOAT}%${C_OFF} (Overall for process)\n"
    CPU_RAM_STR+="  ${C_CYAN}RAM Usage (Process)${C_OFF}    : ${B_WHITE}${used_ram_mb} MB${C_OFF} of ${B_WHITE}${total_ram_mb_for_display} MB${C_OFF} (${B_WHITE}${mem_usage_percent}%${C_OFF})\n"
    CPU_RAM_STR+="  ${C_CYAN}Physical RAM (RSS)${C_OFF}   : ${B_WHITE}${rss_mb} MB${C_OFF} (${rss_kb} KB)\n"
    CPU_RAM_STR+="  ${C_CYAN}Virtual RAM (VSZ)${C_OFF}    : ${B_WHITE}${vsz_mb} MB${C_OFF} (${vsz_kb} KB)"
}

get_process_cpu_distribution_on_cores() {
    local process_cpu_val_str="$1"
    PER_CORE_CPU_STR="" # Reset

    if ! command -v bc &> /dev/null; then
        PER_CORE_CPU_STR="  ${C_YELLOW}'bc' command not found. Cannot calculate CPU distribution.${C_OFF}"
        ERROR_NOTES+="* 'bc' command not found for CPU distribution calculations.\n"
        return
    fi

    # Ensure process_cpu_val_str is a dot-separated float, as ps output (with LC_NUMERIC=C) should provide this.
    if ! [[ "$process_cpu_val_str" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        PER_CORE_CPU_STR="  ${C_YELLOW}Invalid process CPU usage value ('$process_cpu_val_str') for distribution.${C_OFF}"
        ERROR_NOTES+="* Invalid process CPU usage value for distribution: '$process_cpu_val_str'.\n"
        return
    fi

    if ! [[ "$TOTAL_CPU_CORES" =~ ^[0-9]+$ ]] || [ "$TOTAL_CPU_CORES" -le 0 ]; then
        PER_CORE_CPU_STR="  ${C_YELLOW}Total CPU Cores not available or invalid. Cannot display process CPU distribution.${C_OFF}"
        ERROR_NOTES+="* TOTAL_CPU_CORES invalid for process CPU distribution.\n"
        return
    fi

    local remaining_cpu_to_distribute
    remaining_cpu_to_distribute=$(LC_NUMERIC=C echo "$process_cpu_val_str" | bc -l)

    local COLS_TO_DISPLAY_PER_LINE=2 # Display 2 cores per line

    local core_output_strings=() # Array to store formatted strings for each core

    for core_idx in $(seq 0 $((TOTAL_CPU_CORES - 1))); do
        local usage_for_this_core_float="0.0"
        # Check if remaining_cpu_to_distribute > 0 using bc
        if [ "$(LC_NUMERIC=C echo "$remaining_cpu_to_distribute > 0" | bc -l)" -eq 1 ]; then
            # Check if remaining_cpu_to_distribute > 100 using bc
            if [ "$(LC_NUMERIC=C echo "$remaining_cpu_to_distribute > 100" | bc -l)" -eq 1 ]; then
                usage_for_this_core_float="100.0"
            else
                usage_for_this_core_float="$remaining_cpu_to_distribute"
            fi
        fi
        
        # Ensure usage_for_this_core_float is not negative using bc
        if [ "$(LC_NUMERIC=C echo "$usage_for_this_core_float < 0" | bc -l)" -eq 1 ]; then
             usage_for_this_core_float="0.0"
        fi

        remaining_cpu_to_distribute=$(LC_NUMERIC=C echo "$remaining_cpu_to_distribute - $usage_for_this_core_float" | bc -l)
        
        local core_label_text
        printf -v core_label_text "Core %-2d" "$core_idx" # Left-align core number, reserve 2 spaces
        
        local bar_len=20 # Bar length for 2 columns display

        local single_core_bar_str
        single_core_bar_str=$(generate_bar "$usage_for_this_core_float" "$bar_len")
        core_output_strings+=("$(printf "${C_CYAN}%-8s${C_OFF}: %s" "$core_label_text" "$single_core_bar_str")")
    done

    # Arrange core output strings into lines
    local current_line_item_count=0
    for i in "${!core_output_strings[@]}"; do
        if [ $current_line_item_count -eq 0 ]; then # First item in a line (or only item)
            PER_CORE_CPU_STR+="  ${core_output_strings[i]}" # Initial indent for the line
        else
            PER_CORE_CPU_STR+="  ${core_output_strings[i]}" # Separator space for subsequent items on the same line
        fi
        
        current_line_item_count=$((current_line_item_count + 1))

        if [ $current_line_item_count -eq $COLS_TO_DISPLAY_PER_LINE ] || [ $i -eq $((${#core_output_strings[@]} - 1)) ]; then
            PER_CORE_CPU_STR+="\n" # Add newline after COLS_TO_DISPLAY_PER_LINE items or if it's the last item
            current_line_item_count=0
        fi
    done
    
    # Remove trailing newline if PER_CORE_CPU_STR is not empty
    if [ -n "$PER_CORE_CPU_STR" ]; then
        PER_CORE_CPU_STR=${PER_CORE_CPU_STR%\\n}
    fi

    if [ ${#core_output_strings[@]} -eq 0 ] && [ "$TOTAL_CPU_CORES" -gt 0 ]; then # If cores exist but no output generated
        PER_CORE_CPU_STR="  ${C_YELLOW}Could not generate process CPU distribution bars.${C_OFF}"
    elif [ "$TOTAL_CPU_CORES" -eq 0 ] || ! [[ "$TOTAL_CPU_CORES" =~ ^[0-9]+$ ]]; then
         PER_CORE_CPU_STR="  ${C_YELLOW}CPU core information not available to display distribution.${C_OFF}"
    fi
}


get_net_connections_info() {
    if [ -z "$PID" ]; then
        NET_CONN_STR="  ${C_YELLOW}Invalid PID. Cannot check network connections.${C_OFF}"
        return
    fi

    if ! command -v ss &> /dev/null; then
        NET_CONN_STR="  ${C_YELLOW}'ss' command not found. (Requires 'iproute2' package).${C_OFF}"
        ERROR_NOTES+="* 'ss' command not found.\n"
        return
    fi

    local ss_output_data
    local temp_net_conn_str=""

    if [[ $EUID -ne 0 ]]; then
        ERROR_NOTES+="* 'ss' run without sudo. PID-specific connection info may be incomplete.\n"
    fi

    if [[ $EUID -eq 0 ]]; then # If root
        ss_output_data=$(sudo ss -tulnp 2>/dev/null | grep "pid=$PID,")
    else # Not root
        ss_output_data=$(ss -tulnp 2>/dev/null | grep "pid=$PID,")
    fi

    if [ -n "$ss_output_data" ]; then
        temp_net_conn_str+="  ${C_GREEN}Identified Connections (Process PID: $PID):${C_OFF}\n"
        temp_net_conn_str+=$(echo "$ss_output_data" | awk -v C_WHITE="$B_WHITE" -v C_CYAN="$C_CYAN" -v C_YELLOW_BOLD="$B_YELLOW" -v C_OFF="$C_OFF" '
        {
            type=$1; state=$2; local_addr=$5; peer_addr=$6;
            label_state = (state=="LISTEN" ? C_CYAN "[L]" C_OFF : C_YELLOW_BOLD "[E]" C_OFF); # [L] for Listening, [E] for Established
            printf "    %s Proto: %-4s Local: %-25s Remote: %s\n", \
                   label_state, type, C_WHITE local_addr C_OFF, C_WHITE peer_addr C_OFF;
        }')
        NET_CONN_STR="$temp_net_conn_str"
    else
        NET_CONN_STR="  ${C_YELLOW}No active network connections specifically detected for PID $PID.${C_OFF}"
        if [[ $EUID -ne 0 ]]; then
            NET_CONN_STR+="\n  ${C_YELLOW}(Run with sudo for more accurate detection of connections for PID).${C_OFF}"
        fi
    fi
}

get_interface_bandwidth_info() {
    local iface="$1"
    local rx_file="/sys/class/net/${iface}/statistics/rx_bytes"
    local tx_file="/sys/class/net/${iface}/statistics/tx_bytes"
    local interval_sec=1 # Measurement interval in seconds

    INTERFACE_BANDWIDTH_STR="" # Reset

    if [ ! -f "$rx_file" ] || [ ! -f "$tx_file" ]; then
        INTERFACE_BANDWIDTH_STR="  ${C_YELLOW}Interface ${B_WHITE}${iface}${C_OFF}${C_YELLOW} or its statistics files not found.${C_OFF}"
        ERROR_NOTES+="* Interface $iface or statistics files not found.\n"
        return
    fi

    echo -e "  ${B_YELLOW}INFO:${C_OFF} ${C_YELLOW}Measuring total bandwidth for interface ${B_WHITE}${iface}${C_OFF}. This will take ${interval_sec} second(s)...${C_OFF}"

    local rx_bytes1 tx_bytes1 rx_bytes2 tx_bytes2
    rx_bytes1=$(cat "$rx_file")
    tx_bytes1=$(cat "$tx_file")
    sleep "$interval_sec"
    rx_bytes2=$(cat "$rx_file")
    tx_bytes2=$(cat "$tx_file")

    if ! [[ "$rx_bytes1" =~ ^[0-9]+$ && "$tx_bytes1" =~ ^[0-9]+$ && "$rx_bytes2" =~ ^[0-9]+$ && "$tx_bytes2" =~ ^[0-9]+$ ]]; then
        INTERFACE_BANDWIDTH_STR="  ${C_RED}Error reading byte counts for interface ${B_WHITE}${iface}${C_OFF}${C_RED}.${C_OFF}"
        ERROR_NOTES+="* Error reading byte counts for interface $iface.\n"
        return
    fi
    
    local rx_diff=$((rx_bytes2 - rx_bytes1))
    local tx_diff=$((tx_bytes2 - tx_bytes1))

    local rx_speed_bps=$((rx_diff / interval_sec)) # Bytes per second
    local tx_speed_bps=$((tx_diff / interval_sec)) # Bytes per second

    # Convert to KB/s
    local rx_speed_kbps=$(LC_NUMERIC=C awk -v bytes="$rx_speed_bps" 'BEGIN {printf "%.2f", bytes / 1024}')
    local tx_speed_kbps=$(LC_NUMERIC=C awk -v bytes="$tx_speed_bps" 'BEGIN {printf "%.2f", bytes / 1024}')

    INTERFACE_BANDWIDTH_STR="  ${C_CYAN}Received (on ${iface})${C_OFF} : ${B_WHITE}${rx_speed_kbps} KB/s${C_OFF}\n"
    INTERFACE_BANDWIDTH_STR+="  ${C_CYAN}Sent (on ${iface})${C_OFF}     : ${B_WHITE}${tx_speed_kbps} KB/s${C_OFF}"
    
    echo -e "  ${B_GREEN}INFO:${C_OFF} ${C_GREEN}Interface ${iface} bandwidth measurement complete.${C_OFF}"
}

get_blocks_disk_usage() {
    if [ -z "$PID" ]; then
        BLOCKS_DISK_USAGE_STR="  ${C_YELLOW}PID for '$TARGET_PROCESS_NAME' not found. Cannot determine $BLOCKS_DIR_NAME folder location.${C_OFF}"
        return
    fi

    local validator_cwd=""
    if command -v pwdx &> /dev/null; then
        validator_cwd=$(pwdx "$PID" 2>/dev/null | awk '{print $2}') # pwdx output is "PID: /path"
    else
        BLOCKS_DISK_USAGE_STR="  ${C_YELLOW}'pwdx' command not found. Cannot reliably determine $BLOCKS_DIR_NAME folder location.${C_OFF}"
        ERROR_NOTES+="* 'pwdx' command not found. Cannot check $BLOCKS_DIR_NAME disk usage.\n"
        return
    fi
    
    if [ -z "$validator_cwd" ]; then
        BLOCKS_DISK_USAGE_STR="  ${C_YELLOW}Could not determine Current Working Directory for PID $PID.${C_OFF}"
        ERROR_NOTES+="* Failed to get CWD for PID $PID for $BLOCKS_DIR_NAME disk usage check.\n"
        return
    fi

    local blocks_path="${validator_cwd}/${BLOCKS_DIR_NAME}"

    if [ -d "$blocks_path" ]; then
        if command -v du &> /dev/null; then
            local usage
            usage=$(du -sh "$blocks_path" | awk '{print $1}')
            BLOCKS_DISK_USAGE_STR="  ${C_CYAN}Path${C_OFF}                 : ${B_WHITE}${blocks_path}${C_OFF}\n"
            BLOCKS_DISK_USAGE_STR+="  ${C_CYAN}Usage${C_OFF}                : ${B_WHITE}${usage}${C_OFF}"
        else
            BLOCKS_DISK_USAGE_STR="  ${C_YELLOW}'du' command not found. Cannot check disk usage for ${B_WHITE}${blocks_path}${C_OFF}${C_YELLOW}.${C_OFF}"
            ERROR_NOTES+="* 'du' command not found. Cannot check $BLOCKS_DIR_NAME disk usage.\n"
        fi
    else
        BLOCKS_DISK_USAGE_STR="  ${C_YELLOW}Directory ${B_WHITE}${blocks_path}${C_OFF}${C_YELLOW} not found.${C_OFF}"
        ERROR_NOTES+="* $BLOCKS_DIR_NAME directory not found at $blocks_path.\n"
    fi
}


# --- MAIN SCRIPT SECTION ---

get_system_specs
get_os_java_versions

echo -e "${B_CYAN}Collecting data for '$TARGET_PROCESS_NAME'... Please wait.${C_OFF}"
echo ""

find_pid_details

if [ -n "$PID" ]; then
    get_cpu_ram_info # Sets PROCESS_CPU_USAGE_FLOAT and CPU_RAM_STR
    get_process_cpu_distribution_on_cores "$PROCESS_CPU_USAGE_FLOAT" # Sets PER_CORE_CPU_STR
    get_net_connections_info
    get_blocks_disk_usage
else
    CPU_RAM_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
    PER_CORE_CPU_STR="  ${C_RED}Cannot show CPU distribution because PID was not found.${C_OFF}"
    NET_CONN_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
    BLOCKS_DISK_USAGE_STR="  ${C_RED}Cannot check $BLOCKS_DIR_NAME disk usage because PID was not found.${C_OFF}"
fi

# Always try to get interface bandwidth
get_interface_bandwidth_info "$MONITOR_INTERFACE"


# --- DISPLAY ALL RESULTS AT THE END ---
clear # Clear the screen for a cleaner display

printf "${B_WHITE}${BG_BLUE}           V A L I D A T O R   S T A T U S   R E P O R T           ${C_OFF}\n"
print_line
echo -e "${C_CYAN}Target Process: ${B_WHITE}$TARGET_PROCESS_NAME${C_OFF}"
echo -e "${C_CYAN}Check Time    : ${B_WHITE}$CURRENT_DATETIME${C_OFF}"
print_line

print_header_section "SYSTEM SPECIFICATIONS"
echo -e "  ${C_CYAN}OS Version${C_OFF}           : ${B_WHITE}${OS_VERSION_STR}${C_OFF}"
echo -e "  ${C_CYAN}Java Version${C_OFF}         : ${B_WHITE}${JAVA_VERSION_STR}${C_OFF}"
echo -e "  ${C_CYAN}Total CPU Cores${C_OFF}      : ${B_WHITE}${TOTAL_CPU_CORES}${C_OFF}"
echo -e "  ${C_CYAN}Total System RAM${C_OFF}     : ${B_WHITE}${TOTAL_RAM_STR}${C_OFF} (${TOTAL_RAM_KB} KB)"


print_header_section "PROCESS STATUS ($TARGET_PROCESS_NAME)"
echo -e "${PROCESS_DETAILS_STR:-   ${C_YELLOW}No process status data.${C_OFF}}"

print_header_section "CPU & MEMORY USAGE (by Process)"
echo -e "${CPU_RAM_STR:-   ${C_YELLOW}No CPU & RAM data for the process.${C_OFF}}"

print_header_section "PROCESS CPU DISTRIBUTION ON CORES (Total Cores: ${TOTAL_CPU_CORES:-N/A})"
if [ -n "$PER_CORE_CPU_STR" ]; then
    echo -e "${PER_CORE_CPU_STR}" # PER_CORE_CPU_STR already contains newlines where needed
else
    # This message might already be set within get_process_cpu_distribution_on_cores for specific errors
    # or if PID was not found. This is a fallback.
    if [[ "$PER_CORE_CPU_STR" != *"Cannot show CPU distribution because PID was not found."* ]] && \
       [[ "$PER_CORE_CPU_STR" != *"Total CPU Cores not available or invalid."* ]] && \
       [[ "$PER_CORE_CPU_STR" != *"'bc' command not found."* ]] && \
       [[ "$PER_CORE_CPU_STR" != *"Invalid process CPU usage value"* ]]; then
        echo -e "  ${C_YELLOW}No process CPU distribution data could be generated.${C_OFF}"
    elif [ -z "$PID" ] && [ -z "$PER_CORE_CPU_STR" ]; then # If PID is empty and PER_CORE_CPU_STR is also empty
        echo -e "  ${C_RED}Cannot show CPU distribution because PID was not found.${C_OFF}"
    fi
fi


print_header_section "NETWORK CONNECTIONS (Process PID: ${PID:-N/A})"
echo -e "${NET_CONN_STR:-   ${C_YELLOW}No network connection data for the process.${C_OFF}}"

print_header_section "TOTAL INTERFACE BANDWIDTH (${MONITOR_INTERFACE})"
echo -e "${INTERFACE_BANDWIDTH_STR:-   ${C_YELLOW}No data for interface ${MONITOR_INTERFACE}.${C_OFF}}"

print_header_section "DISK USAGE (${BLOCKS_DIR_NAME} Folder)"
echo -e "${BLOCKS_DISK_USAGE_STR:-   ${C_YELLOW}No disk usage data for ${BLOCKS_DIR_NAME}.${C_OFF}}"


echo ""
print_line
if [ -n "$ERROR_NOTES" ]; then
    printf "${B_YELLOW}IMPORTANT NOTES & WARNINGS:${C_OFF}\n"
    # Ensure each line of ERROR_NOTES starts with an indent for consistency
    echo -e "${ERROR_NOTES}" | sed 's/^/\ /g' | sed 's/^* /  * /g'
fi
printf "${C_GREEN}Check Complete. Run with 'sudo bash script_name.sh' for best results.${C_OFF}\n"
print_line
echo ""

exit 0
