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
    
    # Fetch the latest version from GitHub API
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Mengambil versi terbaru..." || print_color $GREEN "Fetching latest version..."
    latest_version=$(curl -s https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    if [ -z "$latest_version" ]; then
        [ "$LANG_CHOICE" = "id" ] && print_color $RED "Gagal mengambil versi terbaru. Silakan coba lagi nanti." || print_color $RED "Failed to fetch latest version. Please try again later."
        return 1
    fi
    
    [ "$LANG_CHOICE" = "id" ] && print_color $GREEN "Mengunduh perangkat lunak node validator versi $latest_version..." || print_color $GREEN "Downloading validator node software version $latest_version..."
    wget https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json
    wget "https://github.com/pwrlabs/PWR-Validator/releases/download/${latest_version}/validator.jar"
    
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
ExecStart=/usr/bin/java -jar /root/pwr/validator.jar --ip $IP_ADDRESS --password /root/pwr/password
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
    cd /root/pwr # Ensure we are in the correct directory

    # Assume LANG_CHOICE is set elsewhere, e.g., LANG_CHOICE="en" or LANG_CHOICE="id"
    # For testing, you can uncomment the line below:
    # LANG_CHOICE="en" 

    [ "$LANG_CHOICE" = "id" ] && echo "Pilih opsi pembaruan:" || echo "Choose update option:"
    [ "$LANG_CHOICE" = "id" ] && echo "1. Perbarui config.json saja" || echo "1. Update config.json only"
    [ "$LANG_CHOICE" = "id" ] && echo "2. Perbarui validator dan config.json" || echo "2. Update validator and config.json"
    [ "$LANG_CHOICE" = "id" ] && read -p "Masukkan pilihan (1 atau 2): " choice || read -p "Enter your choice (1 or 2): " choice

    if [ "$choice" -eq 1 ]; then
        ensure_backup_folder
        if [ -f "config.json" ]; then
            mv config.json backup/
            [ "$LANG_CHOICE" = "id" ] && echo "config.json yang ada telah dicadangkan ke folder backup/." || echo "Existing config.json has been backed up to backup/ folder."
        else
            [ "$LANG_CHOICE" = "id" ] && echo "config.json tidak ditemukan, tidak ada yang dicadangkan." || echo "config.json not found, nothing to back up."
        fi
        rm -f config.json # Use -f to suppress error if it doesn't exist after a failed backup or similar
        wget https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json
        if [ $? -ne 0 ]; then
            [ "$LANG_CHOICE" = "id" ] && echo "Gagal mengunduh config.json. Silakan periksa koneksi internet Anda dan URL." || echo "Failed to download config.json. Please check your internet connection and the URL."
            if [ -f "backup/config.json" ]; then # Attempt to restore if backup exists
                 cp backup/config.json .
                 [ "$LANG_CHOICE" = "id" ] && echo "config.json yang dicadangkan telah dipulihkan." || echo "Backed up config.json has been restored."
            fi
            return 1
        fi
        systemctl stop pwr
        pkill -f java # This command kills all Java processes, be cautious if other Java apps are running
        systemctl start pwr
        [ "$LANG_CHOICE" = "id" ] && echo "Anda berhasil memperbarui config.json" || echo "You have successfully updated config.json"
    elif [ "$choice" -eq 2 ]; then
        # Fetch the old version using the current validator.jar
        [ "$LANG_CHOICE" = "id" ] && echo "Mencoba mengambil versi validator saat ini..." || echo "Attempting to fetch current validator version..."
        local old_version_output
        old_version_output=$(java -jar validator.jar get-address password 2>&1)
        local old_version
        old_version=$(echo "$old_version_output" | grep 'INFO.*Main.Main - Version:' | awk -F 'Version: ' '{print $2}')

        if [ -z "$old_version" ]; then
            [ "$LANG_CHOICE" = "id" ] && echo "PERINGATAN: Gagal mengambil versi lama dari validator.jar. Melanjutkan dengan versi 'tidak diketahui'." || echo "WARNING: Failed to retrieve old version from validator.jar. Proceeding with 'unknown' version."
            [ "$LANG_CHOICE" = "id" ] && echo "Output diagnostik validator lama:" || echo "Old validator diagnostic output:"
            echo "$old_version_output"
            old_version="unknown"
        else
            [ "$LANG_CHOICE" = "id" ] && echo "Versi saat ini terdeteksi: $old_version" || echo "Current version detected: $old_version"
        fi

        # Fetch the latest version from GitHub API
        local latest_version
        latest_version=$(curl -s https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
        
        if [ -z "$latest_version" ]; then
            [ "$LANG_CHOICE" = "id" ] && echo "Gagal mengambil versi terbaru dari GitHub. Silakan coba lagi nanti." || echo "Failed to fetch latest version from GitHub. Please try again later."
            return 1
        fi
        [ "$LANG_CHOICE" = "id" ] && echo "Versi terbaru yang tersedia di GitHub: $latest_version" || echo "Latest version available on GitHub: $latest_version"

        # Ask about deleting blocks directory
        local delete_blocks
        [ "$LANG_CHOICE" = "id" ] && read -p "Apakah Anda ingin menghapus direktori blocks? (y/N): " delete_blocks || read -p "Do you want to delete the blocks directory? (y/N): " delete_blocks
        delete_blocks=${delete_blocks:-n}
        
        # Ask about deleting rocksdb directory
        local delete_rocksdb
        [ "$LANG_CHOICE" = "id" ] && read -p "Apakah Anda ingin menghapus direktori rocksdb? (y/N): " delete_rocksdb || read -p "Do you want to delete the rocksdb directory? (y/N): " delete_rocksdb
        delete_rocksdb=${delete_rocksdb:-n}

        # Ask about deleting merkleTree directory
        local delete_merkletree
        [ "$LANG_CHOICE" = "id" ] && read -p "Apakah Anda ingin menghapus direktori merkleTree? (y/N): " delete_merkletree || read -p "Do you want to delete the merkleTree directory? (y/N): " delete_merkletree
        delete_merkletree=${delete_merkletree:-n}

        ensure_backup_folder

        # Backup and remove items that are always replaced/cleared
        [ "$LANG_CHOICE" = "id" ] && echo "Mencadangkan file yang ada..." || echo "Backing up existing files..."
        if [ -f "config.json" ]; then mv config.json backup/config.json_$(date +%Y%m%d_%H%M%S); fi
        if [ -f "validator.jar" ]; then mv validator.jar backup/validator.jar_$(date +%Y%m%d_%H%M%S)_$old_version; fi # Add old version to backup name
        if [ -d "rpcdata" ]; then mv rpcdata backup/rpcdata_$(date +%Y%m%d_%H%M%S); fi
        
        rm -f config.json validator.jar nohup.out # Use -f to suppress errors if files don't exist
        rm -rf rpcdata # Remove directory

        # Handle merkleTree conditionally
        if [ -d "merkleTree" ]; then # Check if merkleTree directory exists
            if [[ "${delete_merkletree,,}" == "y" ]]; then
                [ "$LANG_CHOICE" = "id" ] && echo "Mencadangkan (memindahkan) dan menghapus direktori merkleTree..." || echo "Backing up (moving) and deleting merkleTree directory..."
                mv merkleTree backup/merkleTree_deleted_$(date +%Y%m%d_%H%M%S) # Move to backup with a clear name
                rm -rf merkleTree # Ensure it's removed from the working directory
            else
                [ "$LANG_CHOICE" = "id" ] && echo "Menyimpan direktori merkleTree saat ini. Salinan cadangan dibuat." || echo "Keeping current merkleTree directory. Backup copy created."
                cp -a merkleTree backup/merkleTree_kept_$(date +%Y%m%d_%H%M%S) # Copy to backup, leave original in place
            fi
        else
            [ "$LANG_CHOICE" = "id" ] && echo "Direktori merkleTree tidak ditemukan, tidak ada tindakan untuk merkleTree." || echo "merkleTree directory not found, no action for merkleTree."
        fi
        
        # Delete blocks if requested
        if [[ "${delete_blocks,,}" == "y" ]]; then
            if [ -d "/root/pwr/blocks" ]; then
                [ "$LANG_CHOICE" = "id" ] && echo "Menghapus direktori blocks..." || echo "Deleting blocks directory..."
                rm -rf /root/pwr/blocks
            else
                [ "$LANG_CHOICE" = "id" ] && echo "Direktori blocks tidak ditemukan, tidak ada yang dihapus." || echo "blocks directory not found, nothing to delete."
            fi
        fi

        # Delete rocksdb if requested
        if [[ "${delete_rocksdb,,}" == "y" ]]; then
            if [ -d "/root/pwr/rocksdb" ]; then
                [ "$LANG_CHOICE" = "id" ] && echo "Menghapus direktori rocksdb..." || echo "Deleting rocksdb directory..."
                rm -rf /root/pwr/rocksdb
            else
                [ "$LANG_CHOICE" = "id" ] && echo "Direktori rocksdb tidak ditemukan, tidak ada yang dihapus." || echo "rocksdb directory not found, nothing to delete."
            fi
        fi

        [ "$LANG_CHOICE" = "id" ] && echo "Mengunduh file baru..." || echo "Downloading new files..."
        wget https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json
        if [ $? -ne 0 ]; then
            [ "$LANG_CHOICE" = "id" ] && echo "Gagal mengunduh config.json baru. Memulihkan cadangan jika memungkinkan..." || echo "Failed to download new config.json. Restoring backup if available..."
            if [ -f "backup/config.json_$(date +%Y%m%d_)*" ]; then # Crude way to find a recent backup
                # Attempt to restore the most recent config.json backup
                cp "$(ls -t backup/config.json_* | head -1)" ./config.json
                [ "$LANG_CHOICE" = "id" ] && echo "config.json yang dicadangkan telah dipulihkan." || echo "Backed up config.json has been restored."
            fi
            return 1
        fi

        wget "https://github.com/pwrlabs/PWR-Validator/releases/download/${latest_version}/validator.jar"
        if [ $? -ne 0 ]; then
            [ "$LANG_CHOICE" = "id" ] && echo "Gagal mengunduh validator.jar versi ${latest_version}. Memulihkan file cadangan..." || echo "Failed to download validator.jar version ${latest_version}. Restoring backup files..."
            # Restore backed up validator.jar and config.json
            local latest_validator_backup
            latest_validator_backup=$(ls -t backup/validator.jar_* 2>/dev/null | head -1)
            if [ -n "$latest_validator_backup" ] && [ -f "$latest_validator_backup" ]; then
                cp "$latest_validator_backup" ./validator.jar
                [ "$LANG_CHOICE" = "id" ] && echo "validator.jar yang dicadangkan telah dipulihkan." || echo "Backed up validator.jar has been restored."
            else
                [ "$LANG_CHOICE" = "id" ] && echo "Tidak ada cadangan validator.jar yang ditemukan untuk dipulihkan." || echo "No validator.jar backup found to restore."
            fi
            
            local latest_config_backup
            latest_config_backup=$(ls -t backup/config.json_* 2>/dev/null | head -1)
            if [ -n "$latest_config_backup" ] && [ -f "$latest_config_backup" ]; then # It might have been restored above, but check again
                if [ ! -f "./config.json" ]; then # Only restore if not already present (e.g. download failed before this)
                    cp "$latest_config_backup" ./config.json
                    [ "$LANG_CHOICE" = "id" ] && echo "config.json yang dicadangkan telah dipulihkan." || echo "Backed up config.json has been restored."
                fi
            else
                 [ "$LANG_CHOICE" = "id" ] && echo "Tidak ada cadangan config.json yang ditemukan untuk dipulihkan." || echo "No config.json backup found to restore."
            fi
            return 1
        fi
        
        [ "$LANG_CHOICE" = "id" ] && echo "Menghentikan dan memulai ulang layanan pwr..." || echo "Stopping and restarting pwr service..."
        systemctl stop pwr
        pkill -f java # Again, be cautious with this command
        systemctl start pwr
        
        # Wait a few seconds for the service to initialize before checking version
        [ "$LANG_CHOICE" = "id" ] && echo "Menunggu layanan untuk inisialisasi..." || echo "Waiting for service to initialize..."
        sleep 5 

        [ "$LANG_CHOICE" = "id" ] && echo "Mencoba mengambil versi validator baru..." || echo "Attempting to fetch new validator version..."
        local new_version_output
        new_version_output=$(java -jar validator.jar get-address password 2>&1)
        local new_version
        new_version=$(echo "$new_version_output" | grep 'INFO.*Main.Main - Version:' | awk -F 'Version: ' '{print $2}')

        if [ -z "$new_version" ]; then
            [ "$LANG_CHOICE" = "id" ] && echo "PERINGATAN: Gagal mengambil versi baru dari validator.jar setelah pembaruan." || echo "WARNING: Failed to retrieve new version from validator.jar after update."
            [ "$LANG_CHOICE" = "id" ] && echo "Output diagnostik validator baru:" || echo "New validator diagnostic output:"
            echo "$new_version_output"
            new_version="unknown"
        fi

        [ "$LANG_CHOICE" = "id" ] && echo "validator.jar dan config.json berhasil diperbarui dari versi $old_version ke $new_version (target: $latest_version)" || echo "validator.jar and config.json have been successfully upgraded from version $old_version to $new_version (target: $latest_version)"
    else
        [ "$LANG_CHOICE" = "id" ] && echo "Pilihan tidak valid. Silakan jalankan ulang script dan pilih opsi yang benar." || echo "Invalid choice. Please rerun the script and select a valid option."
        return 1
    fi
    return 0
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

    # Run the Java command to get the PWR address
    ADDRESS=$(java -jar /root/pwr/validator.jar get-address password | grep -oE '0x[a-fA-F0-9]{40}')
    
    if [ -z "$ADDRESS" ]; then
        [ "$LANG_CHOICE" = "id" ] && print_color $RED "Alamat tidak ditemukan. Pastikan node PWR sedang berjalan." || print_color $RED "Address not found. Make sure the PWR node is running."
    else
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
