#!/bin/bash

# ==============================================================================
# COOL RESOURCE MONITOR SCRIPT FOR VALIDATOR (English Version)
# ==============================================================================

# Target process name
TARGET_PROCESS_NAME="validator.jar"

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

    local all_pid_connections=""
    local ss_listening_output=""
    local ss_established_output=""
    local temp_net_conn_str=""

    if [[ $EUID -eq 0 ]]; then # If root
        # Get all TCP and UDP connections for the specified PID
        all_pid_connections=$(sudo ss -tunp 2>/dev/null | grep "pid=$PID,")

        if [ -n "$all_pid_connections" ]; then
            ss_listening_output=$(echo "$all_pid_connections" | grep 'LISTEN')
            ss_established_output=$(echo "$all_pid_connections" | grep 'ESTAB')
            # You can add filters for other states if needed, e.g.:
            # local ss_syn_sent_output=$(echo "$all_pid_connections" | grep 'SYN-SENT')
        fi
    else # Not root
        ERROR_NOTES+="* 'ss' run without sudo. PID-specific connection info (especially established) may be inaccurate/unavailable.\n"
        # Best effort for common listening ports (may not be accurate for your TARGET_PROCESS_NAME)
        # Example ports, adjust if your validator uses different P2P ports for listening
        ss_listening_output=$(ss -tuln 2>/dev/null | grep -E ":(8085|8231)") # Example ports
        # Established connections for a specific PID cannot be reliably fetched without root.
        ss_established_output=""
    fi

    if [ -n "$ss_listening_output" ]; then
        temp_net_conn_str+="  ${C_GREEN}Listening Sockets (Validator Awaiting Incoming Connections):${C_OFF}\n"
        temp_net_conn_str+=$(echo "$ss_listening_output" | awk -v C_WHITE="$B_WHITE" -v C_CYAN="$C_CYAN" -v C_OFF="$C_OFF" '
        {
            # ss -tunp output: Netid State Recv-Q Send-Q Local-Address:Port Peer-Address:Port Process
            type=$1; local_addr=$5; 
            printf "    %s Proto: %-4s Local: %-25s\n", \
                   C_CYAN "[L]" C_OFF, type, C_WHITE local_addr C_OFF;
        }')
        temp_net_conn_str+="\n" # Add a newline for separation
    else
        temp_net_conn_str+="  ${C_YELLOW}No listening sockets detected for PID $PID (or not accessible).${C_OFF}\n"
    fi

    if [ -n "$ss_established_output" ]; then
        temp_net_conn_str+="  ${C_GREEN}Established Connections (Validator Connected to Others):${C_OFF}\n"
        temp_net_conn_str+=$(echo "$ss_established_output" | awk -v C_WHITE="$B_WHITE" -v C_YELLOW_BOLD="$B_YELLOW" -v C_OFF="$C_OFF" '
        {
            # ss -tunp output: Netid State Recv-Q Send-Q Local-Address:Port Peer-Address:Port Process
            type=$1; local_addr=$5; peer_addr=$6; 
            printf "    %s Proto: %-4s Local: %-25s Remote: %s\n", \
                   C_YELLOW_BOLD "[E]" C_OFF, type, C_WHITE local_addr C_OFF, C_WHITE peer_addr C_OFF;
        }')
    else
        temp_net_conn_str+="  ${C_YELLOW}No outgoing (established) connections detected for PID $PID at this time.${C_OFF}\n"
        temp_net_conn_str+="  ${C_YELLOW}This could mean the validator is idle, not yet synced, or has peer connectivity issues.${C_OFF}"
        if [[ $EUID -ne 0 ]]; then
             temp_net_conn_str+="\n  ${C_YELLOW}(Run with sudo for more accurate detection of established connections for PID).${C_OFF}"
        fi
    fi
    NET_CONN_STR="$temp_net_conn_str"
}

get_bandwidth_info() {
    if [ -z "$PID" ]; then
        BANDWIDTH_STR="  ${C_YELLOW}Invalid PID. Cannot check bandwidth.${C_OFF}"
        return
    fi

    if ! command -v nethogs &> /dev/null; then
        BANDWIDTH_STR="  ${C_YELLOW}'nethogs' not installed. Cannot check bandwidth.${C_OFF}"
        ERROR_NOTES+="* 'nethogs' command not installed.\n"
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        BANDWIDTH_STR="  ${B_RED}'nethogs' requires 'sudo' privileges to run.${C_OFF}"
        ERROR_NOTES+="* 'nethogs' not run with sudo.\n"
        return
    fi

    # Specific loading message for nethogs, displayed directly to the terminal
    echo -e "  ${B_YELLOW}INFO:${C_OFF} ${C_YELLOW}Measuring bandwidth for PID $PID with nethogs. This will run for ~3 seconds...${C_OFF}"
    
    local nethogs_full_output
    local nethogs_raw_output
    
    # Run nethogs for 3 seconds (3 updates, 1-second interval), collect all its output
    nethogs_full_output=$(sudo nethogs -t -c 3 -d 1 2>&1)
    
    # For DEBUG: display all nethogs output before filtering (can be uncommented if needed)
    # echo -e "\n--- Nethogs Full Output (DEBUG) ---"
    # echo -e "PID being searched: $PID"
    # echo "${nethogs_full_output}"
    # echo -e "--- End Nethogs Full Output (DEBUG) ---\n"

    # Filter nethogs output using grep to find lines containing "/PID/"
    # and take the last matching line (nethogs gives multiple updates)
    nethogs_raw_output=$(echo "$nethogs_full_output" | grep "/$PID/" | tail -n 1)

    if [ -n "$nethogs_raw_output" ]; then
        # The part after the last '/' on the matched line should be "UID SENT_RATE RECV_RATE ..."
        local data_chunk
        data_chunk=$(echo "$nethogs_raw_output" | awk -F'/' '{print $NF}') # Get the last field after '/' delimiter

        if [ -n "$data_chunk" ]; then
            # From this chunk, SENT is the 2nd field, RECV is the 3rd field (1st field is UID)
            # awk splits by space by default
            local sent_kbps recv_kbps
            sent_kbps=$(echo "$data_chunk" | awk '{print $2}')
            recv_kbps=$(echo "$data_chunk" | awk '{print $3}')

            # Check if sent_kbps and recv_kbps were successfully extracted and look like numbers
            if [[ -n "$sent_kbps" && -n "$recv_kbps" ]]; then # Basic check
                BANDWIDTH_STR="  ${C_CYAN}Sent${C_OFF}                : ${B_WHITE}${sent_kbps} KB/s${C_OFF}\n"
                BANDWIDTH_STR+="  ${C_CYAN}Received${C_OFF}            : ${B_WHITE}${recv_kbps} KB/s${C_OFF}"
            else
                BANDWIDTH_STR="  ${C_YELLOW}Failed to parse sent/recv values from nethogs for PID $PID.${C_OFF}"
                BANDWIDTH_STR+="\n  ${C_YELLOW}Data Chunk: [$data_chunk], Raw Nethogs Output: [$nethogs_raw_output]${C_OFF}"
                ERROR_NOTES+="* Failed to parse nethogs bandwidth data. Chunk: [$data_chunk]\n"
            fi
        else
            BANDWIDTH_STR="  ${C_YELLOW}Failed to get data chunk (after last '/') from nethogs output for PID $PID.${C_OFF}"
            BANDWIDTH_STR+="\n  ${C_YELLOW}Raw Nethogs Output: [$nethogs_raw_output]${C_OFF}"
            ERROR_NOTES+="* Failed to get nethogs data chunk. Raw output: [$nethogs_raw_output]\n"
        fi
    else
        BANDWIDTH_STR="  ${C_YELLOW}No data lines from nethogs matched PID $PID (possibly no significant network activity during the 3-second measurement).${C_OFF}"
        ERROR_NOTES+="* No nethogs lines matched PID $PID.\n"
    fi
    echo -e "  ${B_GREEN}INFO:${C_OFF} ${C_GREEN}Bandwidth measurement complete.${C_OFF}"
}

# --- MAIN SCRIPT SECTION ---

# 0. Get System Specs (CPU Cores, Total RAM)
get_system_specs # Call at the beginning

echo -e "${B_CYAN}Collecting data for '$TARGET_PROCESS_NAME'... Please wait.${C_OFF}"
echo ""

# 1. Find PID and Process Details
find_pid_details

# If PID is found, proceed with other data collection
if [ -n "$PID" ]; then
    get_cpu_ram_info
    get_net_connections_info
    get_bandwidth_info # This function has its own sudo & nethogs checks, and specific loading message
else
    # If PID is not found, fill other info strings with error/info messages
    CPU_RAM_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
    NET_CONN_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
    BANDWIDTH_STR="  ${C_RED}Cannot proceed because PID was not found.${C_OFF}"
fi

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


print_header_section "PROCESS STATUS"
echo -e "${PROCESS_DETAILS_STR:-  ${C_YELLOW}No process status data.${C_OFF}}"

print_header_section "CPU & MEMORY USAGE (by Process)"
echo -e "${CPU_RAM_STR:-  ${C_YELLOW}No CPU & RAM data.${C_OFF}}"

print_header_section "NETWORK CONNECTIONS (via ss)"
echo -e "${NET_CONN_STR:-  ${C_YELLOW}No network connection data.${C_OFF}}"

print_header_section "BANDWIDTH USAGE (Nethogs Estimate)"
echo -e "${BANDWIDTH_STR:-  ${C_YELLOW}No bandwidth data.${C_OFF}}"

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
