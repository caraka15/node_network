#!/bin/bash

# ==============================================================================
# COOL RESOURCE MONITOR SCRIPT FOR VALIDATOR (English Version)
# ==============================================================================

# Target process name
TARGET_PROCESS_NAME="validator.jar"
# Network interface to monitor for total bandwidth
MONITOR_INTERFACE="eth0"


# --- ANSI Color Codes ---
C_OFF='\033[0m'       # Reset Color

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
NET_CONN_STR=""
BANDWIDTH_STR=""
INTERFACE_BANDWIDTH_STR="" # For eth0 bandwidth
ERROR_NOTES="" # For important error/warning notes

CURRENT_DATETIME=$(date +"%A, %d %B %Y %T %Z")

# --- Global System Specs ---
TOTAL_CPU_CORES="N/A"
TOTAL_RAM_STR="N/A" # String for total RAM display

# --- Helper Functions ---
print_line() {
    printf "${B_CYAN}====================================================================================${C_OFF}\n"
}

print_header_section() {
    local title="$1"
    printf "\n${B_PURPLE}--- %-70s ---${C_OFF}\n" "$title"
}

# --- Data Collection Functions ---

check_and_install_nethogs() {
    echo -e "  ${C_CYAN}Checking for Nethogs installation...${C_OFF}"
    if ! command -v nethogs &> /dev/null; then
        echo -e "  ${C_YELLOW}Nethogs is not installed.${C_OFF}"
        ERROR_NOTES+="* Nethogs was not initially installed.\n"
        if [[ $EUID -eq 0 ]]; then # Check if running as root, as installation needs sudo
            read -p "  Nethogs is recommended for per-process bandwidth monitoring. Do you want to try to install it now? (y/N): " install_choice
            if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                echo -e "  ${C_CYAN}Attempting to install Nethogs...${C_OFF}"
                local pkg_manager=""
                if command -v apt-get &> /dev/null; then
                    pkg_manager="apt-get"
                    echo -e "  ${C_CYAN}Updating package lists (apt-get update)...${C_OFF}"
                    sudo apt-get update -qq > /dev/null # -qq for quieter output
                    echo -e "  ${C_CYAN}Installing Nethogs using apt-get...${C_OFF}"
                    sudo apt-get install -y nethogs
                elif command -v yum &> /dev/null; then
                    pkg_manager="yum"
                    echo -e "  ${C_CYAN}Installing Nethogs using yum...${C_OFF}"
                    sudo yum install -y nethogs
                elif command -v dnf &> /dev/null; then
                    pkg_manager="dnf"
                    echo -e "  ${C_CYAN}Installing Nethogs using dnf...${C_OFF}"
                    sudo dnf install -y nethogs
                else
                    echo -e "  ${B_RED}Could not determine package manager. Please install Nethogs manually.${C_OFF}"
                    ERROR_NOTES+="* Could not determine package manager to install Nethogs.\n"
                    return 1
                fi

                if command -v nethogs &> /dev/null; then
                    echo -e "  ${B_GREEN}Nethogs installed successfully.${C_OFF}"
                else
                    echo -e "  ${B_RED}Nethogs installation failed. Please install it manually.${C_OFF}"
                    ERROR_NOTES+="* Nethogs installation attempt failed.\n"
                    return 1
                fi
            else
                echo -e "  ${C_YELLOW}Nethogs installation skipped by user.${C_OFF}"
                ERROR_NOTES+="* User skipped Nethogs installation.\n"
                return 1 # Indicate that nethogs is not available for bandwidth check
            fi
        else
            echo -e "  ${B_RED}Script is not running with sudo. Cannot attempt to install Nethogs.${C_OFF}"
            echo -e "  ${C_YELLOW}Please run the script with sudo or install Nethogs manually for per-process bandwidth monitoring.${C_OFF}"
            ERROR_NOTES+="* Cannot install Nethogs without sudo privileges.\n"
            return 1 # Indicate that nethogs is not available
        fi
    else
        echo -e "  ${B_GREEN}Nethogs is already installed.${C_OFF}"
    fi
    echo "" # Add a newline for better readability before next steps
    return 0
}


get_system_specs() {
    # Get Total CPU Cores
    if command -v nproc &> /dev/null; then
        TOTAL_CPU_CORES=$(nproc --all)
    elif [ -f /proc/cpuinfo ]; then # Fallback if nproc is not available
        TOTAL_CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    else
        TOTAL_CPU_CORES="Not detected"
    fi

    # Get Total RAM
    if [ -f /proc/meminfo ]; then
        local mem_total_kb
        mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        if [[ -n "$mem_total_kb" && "$mem_total_kb" -gt 0 ]]; then
            local total_ram_mb=$((mem_total_kb / 1024))
            # Format to GB with 2 decimal places if over 1024 MB, otherwise keep as MB
            if [ "$total_ram_mb" -ge 1024 ]; then
                TOTAL_RAM_STR=$(awk -v total_mb="$total_ram_mb" 'BEGIN {printf "%.2f GB", total_mb / 1024}')
            else
                TOTAL_RAM_STR="${total_ram_mb} MB"
            fi
        else
            TOTAL_RAM_STR="Not detected"
        fi
    else
        TOTAL_RAM_STR="Not detected"
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

    # Get PID and command from the first matching line
    PID=$(echo "$pids_found" | head -n 1 | awk '{print $1}')
    local full_command
    full_command=$(echo "$pids_found" | head -n 1 | cut -d' ' -f2-)

    # Basic verification to avoid PID of this script or search processes
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
    PROCESS_DETAILS_STR+="  ${C_CYAN}PID${C_OFF}                 : ${B_WHITE}$PID${C_OFF}\n"
    # Limit command length if too long for display
    if [ ${#full_command} -gt 60 ]; then
        full_command="${full_command:0:57}..."
    fi
    PROCESS_DETAILS_STR+="  ${C_CYAN}Command${C_OFF}             : ${C_WHITE}$full_command${C_OFF}"
    return 0
}

get_cpu_ram_info() {
    if [ -z "$PID" ]; then
        CPU_RAM_STR="  ${C_YELLOW}Invalid PID. Cannot fetch CPU/RAM data.${C_OFF}"
        return
    fi

    local ps_output
    # Only fetch relevant columns: %cpu, %mem, rss (KB), vsz (KB)
    ps_output=$(ps -p "$PID" -o %cpu,%mem,rss,vsz --no-headers)

    if [ -z "$ps_output" ]; then
        CPU_RAM_STR="  ${B_RED}Failed to fetch CPU/RAM data for PID $PID.${C_OFF}"
        ERROR_NOTES+="* Failed to fetch CPU/RAM data (ps error).\n"
        return
    fi

    local cpu_usage mem_usage rss_kb vsz_kb
    cpu_usage=$(echo "$ps_output" | awk '{print $1}')
    mem_usage=$(echo "$ps_output" | awk '{print $2}')
    rss_kb=$(echo "$ps_output" | awk '{print $3}')
    vsz_kb=$(echo "$ps_output" | awk '{print $4}')

    local rss_mb=$((rss_kb / 1024)) # Convert KB to MB
    local vsz_mb=$((vsz_kb / 1024)) # Convert KB to MB

    CPU_RAM_STR="  ${C_CYAN}CPU Usage${C_OFF}           : ${B_WHITE}${cpu_usage}%${C_OFF} (of ${B_WHITE}${TOTAL_CPU_CORES}${C_OFF} Cores)\n"
    CPU_RAM_STR+="  ${C_CYAN}RAM Usage${C_OFF}           : ${B_WHITE}${mem_usage}%${C_OFF} (of Total ${B_WHITE}${TOTAL_RAM_STR}${C_OFF})\n"
    CPU_RAM_STR+="  ${C_CYAN}Physical RAM (RSS)${C_OFF}  : ${B_WHITE}${rss_mb} MB${C_OFF} (${rss_kb} KB)\n"
    CPU_RAM_STR+="  ${C_CYAN}Virtual RAM (VSZ)${C_OFF}   : ${B_WHITE}${vsz_mb} MB${C_OFF} (${vsz_kb} KB)"
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

    # Only search for connections related to the PID
    if [[ $EUID -eq 0 ]]; then # If root
        ss_output_data=$(sudo ss -tulnp 2>/dev/null | grep "pid=$PID,")
    else # Not root
        ss_output_data=$(ss -tulnp 2>/dev/null | grep "pid=$PID,") # May not show all info without sudo
    fi

    if [ -n "$ss_output_data" ]; then
        temp_net_conn_str+="  ${C_GREEN}Identified Connections (Process PID: $PID):${C_OFF}\n"
        temp_net_conn_str+=$(echo "$ss_output_data" | awk -v C_WHITE="$B_WHITE" -v C_CYAN="$C_CYAN" -v C_YELLOW_BOLD="$B_YELLOW" -v C_OFF="$C_OFF" '
        {
            # ss -tunp output: Netid State Recv-Q Send-Q Local-Address:Port Peer-Address:Port Process
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

get_nethogs_bandwidth_info() {
    if [ -z "$PID" ]; then
        BANDWIDTH_STR="  ${C_YELLOW}Invalid PID. Cannot check per-process bandwidth.${C_OFF}"
        return
    fi

    if ! command -v nethogs &> /dev/null; then
        BANDWIDTH_STR="  ${C_YELLOW}'nethogs' not installed. Cannot check per-process bandwidth.${C_OFF}"
        # ERROR_NOTES is already populated by check_and_install_nethogs if installation was skipped or failed
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        BANDWIDTH_STR="  ${B_RED}'nethogs' requires 'sudo' privileges for per-process bandwidth.${C_OFF}"
        ERROR_NOTES+="* 'nethogs' not run with sudo (required for per-process bandwidth monitoring).\n"
        return
    fi

    # Specific loading message for nethogs, displayed directly to the terminal
    echo -e "  ${B_YELLOW}INFO:${C_OFF} ${C_YELLOW}Measuring per-process bandwidth for PID $PID with nethogs. This will run for ~3 seconds...${C_OFF}"
    
    local nethogs_full_output
    local nethogs_raw_output
    
    nethogs_full_output=$(sudo nethogs -t -c 3 -d 1 2>&1)
    nethogs_raw_output=$(echo "$nethogs_full_output" | grep "/$PID/" | tail -n 1)

    if [ -n "$nethogs_raw_output" ]; then
        local data_chunk
        data_chunk=$(echo "$nethogs_raw_output" | awk -F'/' '{print $NF}') 

        if [ -n "$data_chunk" ]; then
            local sent_kbps recv_kbps
            sent_kbps=$(echo "$data_chunk" | awk '{print $2}')
            recv_kbps=$(echo "$data_chunk" | awk '{print $3}')

            if [[ -n "$sent_kbps" && -n "$recv_kbps" ]]; then 
                BANDWIDTH_STR="  ${C_CYAN}Sent (PID $PID)${C_OFF}       : ${B_WHITE}${sent_kbps} KB/s${C_OFF}\n"
                BANDWIDTH_STR+="  ${C_CYAN}Received (PID $PID)${C_OFF}   : ${B_WHITE}${recv_kbps} KB/s${C_OFF}"
            else
                BANDWIDTH_STR="  ${C_YELLOW}Failed to parse sent/recv values from nethogs for PID $PID.${C_OFF}"
                ERROR_NOTES+="* Failed to parse nethogs bandwidth data. Chunk: [$data_chunk]\n"
            fi
        else
            BANDWIDTH_STR="  ${C_YELLOW}Failed to get data chunk from nethogs output for PID $PID.${C_OFF}"
            ERROR_NOTES+="* Failed to get nethogs data chunk. Raw output: [$nethogs_raw_output]\n"
        fi
    else
        BANDWIDTH_STR="  ${C_YELLOW}No nethogs data matched PID $PID (possibly no significant network activity during measurement).${C_OFF}"
        ERROR_NOTES+="* No nethogs lines matched PID $PID.\n"
    fi
    echo -e "  ${B_GREEN}INFO:${C_OFF} ${C_GREEN}Per-process bandwidth measurement complete.${C_OFF}"
}

get_interface_bandwidth_info() {
    local iface="$1"
    local rx_file="/sys/class/net/${iface}/statistics/rx_bytes"
    local tx_file="/sys/class/net/${iface}/statistics/tx_bytes"
    local interval_sec=2 # Measurement interval in seconds

    INTERFACE_BANDWIDTH_STR="" # Reset

    if [ ! -f "$rx_file" ] || [ ! -f "$tx_file" ]; then
        INTERFACE_BANDWIDTH_STR="  ${C_YELLOW}Interface ${B_WHITE}${iface}${C_OFF}${C_YELLOW} or its statistics files not found.${C_OFF}"
        ERROR_NOTES+="* Interface $iface or statistics files not found.\n"
        return
    fi

    echo -e "  ${B_YELLOW}INFO:${C_OFF} ${C_YELLOW}Measuring total bandwidth for interface ${B_WHITE}${iface}${C_OFF}. This will take ${interval_sec} seconds...${C_OFF}"

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
    local rx_speed_kbps=$(awk -v bytes="$rx_speed_bps" 'BEGIN {printf "%.2f", bytes / 1024}')
    local tx_speed_kbps=$(awk -v bytes="$tx_speed_bps" 'BEGIN {printf "%.2f", bytes / 1024}')

    INTERFACE_BANDWIDTH_STR="  ${C_CYAN}Received (on ${iface})${C_OFF} : ${B_WHITE}${rx_speed_kbps} KB/s${C_OFF}\n"
    INTERFACE_BANDWIDTH_STR+="  ${C_CYAN}Sent (on ${iface})${C_OFF}     : ${B_WHITE}${tx_speed_kbps} KB/s${C_OFF}"
    
    echo -e "  ${B_GREEN}INFO:${C_OFF} ${C_GREEN}Interface ${iface} bandwidth measurement complete.${C_OFF}"
}


# --- MAIN SCRIPT SECTION ---

# 0. Get System Specs (CPU Cores, Total RAM) & Check/Install Nethogs
get_system_specs # Call at the beginning
check_and_install_nethogs # Check and offer to install Nethogs

echo -e "${B_CYAN}Collecting data for '$TARGET_PROCESS_NAME'... Please wait.${C_OFF}"
echo ""

# 1. Find PID and Process Details
find_pid_details

# If PID is found, proceed with other data collection
if [ -n "$PID" ]; then
    get_cpu_ram_info
    get_net_connections_info
    get_nethogs_bandwidth_info # Renamed for clarity
else
    # If PID is not found, fill other info strings with error/info messages
    CPU_RAM_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
    NET_CONN_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
    BANDWIDTH_STR="  ${C_RED}Cannot proceed because PID was not found (for per-process Nethogs check).${C_OFF}"
fi

# Always try to get interface bandwidth, regardless of PID status
get_interface_bandwidth_info "$MONITOR_INTERFACE"


# --- DISPLAY ALL RESULTS AT THE END ---
clear # Clear the screen for a cleaner display

printf "${B_WHITE}${BG_BLUE}                V A L I D A T O R   S T A T U S   R E P O R T                ${C_OFF}\n"
print_line
echo -e "${C_CYAN}Target Process: ${B_WHITE}$TARGET_PROCESS_NAME${C_OFF}"
echo -e "${C_CYAN}Check Time    : ${B_WHITE}$CURRENT_DATETIME${C_OFF}"
print_line

print_header_section "SYSTEM SPECIFICATIONS"
echo -e "  ${C_CYAN}Total CPU Cores${C_OFF}     : ${B_WHITE}${TOTAL_CPU_CORES}${C_OFF}"
echo -e "  ${C_CYAN}Total System RAM${C_OFF}    : ${B_WHITE}${TOTAL_RAM_STR}${C_OFF}"


print_header_section "PROCESS STATUS ($TARGET_PROCESS_NAME)"
echo -e "${PROCESS_DETAILS_STR:-  ${C_YELLOW}No process status data.${C_OFF}}"

print_header_section "CPU & MEMORY USAGE (by Process)"
echo -e "${CPU_RAM_STR:-  ${C_YELLOW}No CPU & RAM data.${C_OFF}}"

print_header_section "NETWORK CONNECTIONS (Process PID: ${PID:-N/A})"
echo -e "${NET_CONN_STR:-  ${C_YELLOW}No network connection data for the process.${C_OFF}}"

print_header_section "PER-PROCESS BANDWIDTH (Nethogs for PID: ${PID:-N/A})"
echo -e "${BANDWIDTH_STR:-  ${C_YELLOW}No per-process bandwidth data.${C_OFF}}"

print_header_section "TOTAL INTERFACE BANDWIDTH (${MONITOR_INTERFACE})"
echo -e "${INTERFACE_BANDWIDTH_STR:-  ${C_YELLOW}No data for interface ${MONITOR_INTERFACE}.${C_OFF}}"


echo ""
print_line
if [ -n "$ERROR_NOTES" ]; then
    printf "${B_YELLOW}IMPORTANT NOTES & WARNINGS:${C_OFF}\n"
    echo -e "${C_YELLOW}${ERROR_NOTES}${C_OFF}" # Ensure ERROR_NOTES is printed correctly
fi
printf "${C_GREEN}Check Complete. Run with 'sudo bash script_name.sh' for best results.${C_OFF}\n"
print_line
echo ""

exit 0
