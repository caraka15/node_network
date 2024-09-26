#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print centered text
print_centered() {
    local text="$1"
    local color="$2"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${color}%*s%s%*s${NC}\n" $padding '' "$text" $padding ''
}

# Function to print a line
print_line() {
    local width=$(tput cols)
    printf '%*s\n' "$width" '' | tr ' ' '-'
}

# Display credits
clear
print_line
print_centered "PWR TOOLS" $YELLOW
print_centered "Created by CRXA NODE" $GREEN
print_line
echo ""

# Language variables
LANG_CHOICE=""
MENU_TITLE=""
MENU_INSTALL=""
MENU_UPDATE=""
MENU_CHECK_PORTS=""
MENU_CHECK_ADDRESS=""
MENU_CHECK_PRIVATE_KEY=""
MENU_EXIT=""
INVALID_OPTION=""

# Function to set language
set_language() {
    print_centered "Pilih bahasa / Choose language:" $BLUE
    echo "1. Bahasa Indonesia"
    echo "2. English"
    read -p "Masukkan pilihan / Enter your choice (1/2): " lang_choice

    if [ "$lang_choice" = "1" ]; then
        LANG_CHOICE="id"
        MENU_TITLE="Menu Alat PWR:"
        MENU_INSTALL="Instal PWR"
        MENU_UPDATE="Perbarui PWR"
        MENU_CHECK_PORTS="Periksa Port"
        MENU_CHECK_ADDRESS="Periksa Alamat"
        MENU_CHECK_PRIVATE_KEY="Periksa Kunci Pribadi"
        MENU_EXIT="Keluar"
        INVALID_OPTION="Pilihan tidak valid. Silakan coba lagi."
    else
        LANG_CHOICE="en"
        MENU_TITLE="PWR Tools Menu:"
        MENU_INSTALL="Install PWR"
        MENU_UPDATE="Update PWR"
        MENU_CHECK_PORTS="Check Ports"
        MENU_CHECK_ADDRESS="Check Address"
        MENU_CHECK_PRIVATE_KEY="Check Private Key"
        MENU_EXIT="Exit"
        INVALID_OPTION="Invalid option. Please try again."
    fi
}

# Function to print in color
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to print in bold
print_bold() {
    echo -e "${BOLD}${1}${NC}"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        [ "$LANG_CHOICE" = "id" ] && print_color $RED "Harap jalankan sebagai root" || print_color $RED "Please run as root"
        exit 1
    fi
}

# Function to ensure backup folder exists
ensure_backup_folder() {
    if [ ! -d "/root/pwr/backup" ]; then
        mkdir -p /root/pwr/backup
    fi
}

# Function to install PWR
install_pwr() {
    [ "$LANG_CHOICE" = "id" ] && print_bold "Memulai Instalasi Node Validator PWR..." || print_bold "Starting PWR Validator Node Installation..."
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Membuat direktori /root/pwr dan pindah ke dalamnya..." || print_color $GREEN "Creating directory /root/pwr and changing to it..."
    mkdir -p /root/pwr
    cd /root/pwr
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Memperbarui paket OS..." || print_color $GREEN "Updating OS packages..."
    sudo apt update
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Menginstal OpenJDK 19..." || print_color $GREEN "Installing OpenJDK 19..."
    sudo apt install -y openjdk-19-jre-headless
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Mengunduh perangkat lunak node validator..." || print_color $GREEN "Downloading validator node software..."
    wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar -O validator.jar
    wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json -O config.json
    
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Alamat IP terdeteksi: $IP_ADDRESS" || print_color $GREEN "Detected IP Address: $IP_ADDRESS"
    
    [ "$LANG_CHOICE" = "id" ] && print_bold "Masukkan kata sandi yang diinginkan:" || print_bold "Enter your desired password:"
    read -s PASSWORD
    echo $PASSWORD | sudo tee /root/pwr/password > /dev/null
    
    [ "$LANG_CHOICE" = "id" ] && print_bold "Pilih opsi:" || print_bold "Choose an option:"
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "1. Buat dompet baru" || print_color $GREEN "1. Create new wallet"
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "2. Pulihkan dompet yang ada" || print_color $GREEN "2. Recover existing wallet"
    [ "$LANG_CHOICE" = "id" ] && read -p "Masukkan pilihan Anda (1 atau 2): " WALLET_OPTION || read -p "Enter your choice (1 or 2): " WALLET_OPTION
    
    if [ "$WALLET_OPTION" = "2" ]; then
        [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Memulihkan dompet yang ada..." || print_color $GREEN "Recovering existing wallet..."
        [ "$LANG_CHOICE" = "id" ] && print_bold "Masukkan kunci pribadi Anda:" || print_bold "Enter your private key:"
        read -s PRIVATE_KEY
        sudo java -jar validator.jar --import-key $PRIVATE_KEY password
        [ "$LANG_CHOICE" = "id" ] && print_bold "Proses pemulihan dompet selesai." || print_bold "Wallet recovery process completed."
        [ "$LANG_CHOICE" = "id" ] && read -p "Tekan Enter untuk melanjutkan..." || read -p "Press Enter to continue..."
    fi
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Membuat file layanan systemd..." || print_color $GREEN "Creating systemd service file..."
    sudo tee /etc/systemd/system/pwr.service <<EOF
[Unit]
Description=PWR Validator Node
After=network-online.target
Wants=network-online.target
[Service]
User=root
WorkingDirectory=/root/pwr
ExecStart=/usr/bin/java -jar /root/pwr/validator.jar /root/pwr/password $IP_ADDRESS
Restart=always
RestartSec=30
[Install]
WantedBy=multi-user.target
EOF
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Memuat ulang systemd..." || print_color $GREEN "Reloading systemd..."
    sudo systemctl daemon-reload
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Mengaktifkan dan memulai layanan validator..." || print_color $GREEN "Enabling and starting the validator service..."
    sudo systemctl enable pwr
    sudo systemctl start pwr
    
    [ "$LANG_CHOICE" = "id" ] && print_bold "Mengambil alamat validator..." || print_bold "Fetching validator address..."
    sleep 60
    ADDRESS=$(curl -s http://localhost:8085/address/)
    
    if [ -z "$ADDRESS" ]; then
        [ "$LANG_CHOICE" = "id" ] && print_bold "Alamat tidak ditemukan. Jika alamat tidak muncul, tunggu beberapa menit dan jalankan 'curl -s http://localhost:8085/address/' untuk mengambilnya." || print_bold "Address not found. If the address does not appear, wait a few minutes and run 'curl -s http://localhost:8085/address/' to retrieve it."
    else
        [ "$LANG_CHOICE" = "id" ] && print_bold "Alamat Anda: $ADDRESS" || print_bold "Your address: $ADDRESS"
    fi
    
    [ "$LANG_CHOICE" = "id" ] && print_bold "Untuk memeriksa log layanan node validator, gunakan perintah berikut:" || print_bold "To check the logs of the validator node service, use the following command:"
    print_color $GREEN "journalctl -fu pwr -o cat"
    [ "$LANG_CHOICE" = "id" ] && print_bold "Instalasi dan pengaturan selesai." || print_bold "Installation and setup complete."
}

# Function to update PWR
update_pwr() {
    cd /root/pwr
    [ "$LANG_CHOICE" = "id" ] && echo "Pilih opsi pembaruan:" || echo "Choose update option:"
    [ "$LANG_CHOICE" = "id" ] && echo "1. Perbarui config.json saja" || echo "1. Update config.json only"
    [ "$LANG_CHOICE" = "id" ] && echo "2. Perbarui validator dan config.json" || echo "2. Update validator and config.json"
    [ "$LANG_CHOICE" = "id" ] && read -p "Masukkan pilihan (1 atau 2): " choice || read -p "Enter your choice (1 or 2): " choice

    if [ "$choice" -eq 1 ]; then
        ensure_backup_folder
        mv config.json backup/
        rm -rf config.json
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json
        systemctl stop pwr
        pkill -f java
        systemctl start pwr
        [ "$LANG_CHOICE" = "id" ] && echo "Anda berhasil memperbarui config.json" || echo "You have successfully updated config.json"
    elif [ "$choice" -eq 2 ]; then
        old_version=$(curl -s http://localhost:8085/version/)
        ensure_backup_folder
        mv config.json validator.jar backup/
        rm -rf config.json validator.jar
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar
        systemctl stop pwr
        pkill -f java
        systemctl start pwr
        new_version=$(curl -s http://localhost:8085/version/)
        [ "$LANG_CHOICE" = "id" ] && echo "validator.jar dan config.json berhasil diperbarui dari $old_version ke $new_version" || echo "validator.jar and config.json have been successfully upgraded from $old_version to $new_version"
    else
        [ "$LANG_CHOICE" = "id" ] && echo "Pilihan tidak valid. Silakan jalankan ulang script dan pilih opsi yang benar." || echo "Invalid choice. Please rerun the script and select a valid option."
    fi
}

# Function to check ports
check_ports() {
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Memeriksa port PWR..." || print_color $GREEN "Checking PWR ports..."
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    
    check_port() {
        if nc -z -w2 $IP_ADDRESS $1; then
            [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Port $1 terbuka" || print_color $GREEN "Port $1 is open"
        else
            [ "$LANG_CHOICE" = "id" ] && print_color $RED "Port $1 tertutup" || print_color $RED "Port $1 is closed"
        fi
    }

    check_port 8231  # TCP
    check_port 7621  # UDP
    check_port 8085  # TCP
}

# Function to check address
check_address() {
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Memeriksa alamat PWR..." || print_color $GREEN "Checking PWR address..."
    ADDRESS=$(curl -s http://localhost:8085/address/)
    if [ -z "$ADDRESS" ]; then
        [ "$LANG_CHOICE" = "id" ] && print_color $RED "Alamat tidak ditemukan. Pastikan node PWR sedang berjalan." || print_color $RED "Address not found. Make sure the PWR node is running."
    else
        # Add "0x" prefix to the address
        ADDRESS="0x$ADDRESS"
        [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Alamat PWR Anda: $ADDRESS" || print_color $GREEN "Your PWR address: $ADDRESS"
    fi
}

# Function to check private key
check_private_key() {
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Memeriksa kunci pribadi PWR..." || print_color $GREEN "Checking PWR private key..."
    
    cd /root/pwr
    if [ -f "/root/pwr/password" ]; then
        PRIVATE_KEY=$(sudo java -jar validator.jar get-private-key /root/pwr/password)
        if [ -n "$PRIVATE_KEY" ]; then
            [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Kunci pribadi Anda:" || print_color $GREEN "Your private key:"
            echo $PRIVATE_KEY
            [ "$LANG_CHOICE" = "id" ] && print_color $RED "PERINGATAN: Jangan bagikan kunci pribadi Anda dengan siapa pun!" || print_color $RED "WARNING: Do not share your private key with anyone!"
        else
            [ "$LANG_CHOICE" = "id" ] && print_color $RED "Tidak dapat mengambil kunci pribadi. Pastikan validator.jar dan file password ada dan benar." || print_color $RED "Unable to retrieve private key. Make sure validator.jar and password file exist and are correct."
        fi
    else
        [ "$LANG_CHOICE" = "id" ] && print_color $RED "File password tidak ditemukan. Pastikan Anda telah menjalankan instalasi dengan benar." || print_color $RED "Password file not found. Make sure you have run the installation correctly."
    fi
}

# Main menu
set_language
check_root

while true; do
    clear
    print_line
    print_centered "$MENU_TITLE" $BLUE
    print_line
    echo "1. $MENU_INSTALL"
    echo "2. $MENU_UPDATE"
    echo "3. $MENU_CHECK_PORTS"
    echo "4. $MENU_CHECK_ADDRESS"
    echo "5. $MENU_CHECK_PRIVATE_KEY"
    echo "6. $MENU_EXIT"
    print_line
    
    [ "$LANG_CHOICE" = "id" ] && read -p "Masukkan pilihan Anda: " choice || read -p "Enter your choice: " choice
    
    case $choice in
        1) install_pwr ;;
        2) update_pwr ;;
        3) check_ports ;;
        4) check_address ;;
        5) check_private_key ;;
        6) 
           clear
           print_line
           [ "$LANG_CHOICE" = "id" ] && print_centered "Terima kasih telah menggunakan PWR Tools!" $GREEN || print_centered "Thank you for using PWR Tools!" $GREEN
           print_line
           exit 0
           ;;
        *) print_color $RED "$INVALID_OPTION" ;;
    esac

    [ "$LANG_CHOICE" = "id" ] && read -p "Tekan Enter untuk kembali ke menu utama..." || read -p "Press Enter to return to the main menu..."
done
