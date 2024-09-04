#!/bin/bash

# Pilihan bahasa
echo "Pilih bahasa / Select language:"
echo "1. Bahasa Indonesia"
echo "2. English"
read -p "Masukkan pilihan / Enter your choice (1 or 2): " lang_choice

# Fungsi untuk membuat folder backup jika belum ada
function ensure_backup_folder {
    if [ ! -d "backup" ]; then
        mkdir backup
    fi
}

# Bahasa Indonesia
if [ "$lang_choice" -eq 1 ]; then
    # Pindah ke direktori /root/pwr
    cd /root/pwr

    # Menampilkan pilihan kepada pengguna
    echo "Pilih opsi pembaruan:"
    echo "1. Update config.json saja"
    echo "2. Update validator dan config.json"
    read -p "Masukkan pilihan (1 atau 2): " choice

    # Opsi 1: Update config.json saja
    if [ "$choice" -eq 1 ]; then
        ensure_backup_folder
        mv config.json backup/
        rm -rf config.json
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json
        systemctl stop pwr
        pkill -f java
        systemctl start pwr
        echo "Anda berhasil update config.json"

    # Opsi 2: Update validator dan config.json
    elif [ "$choice" -eq 2 ]; then
        old_version=$(curl -s http://localhost:8085/version)
        ensure_backup_folder
        mv config.json validator.jar backup/
        rm -rf config.json validator.jar
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar
        systemctl stop pwr
        pkill -f java
        systemctl start pwr
        new_version=$(curl -s http://localhost:8085/version)
        echo "validator.jar dan config.json berhasil di upgrade dari $old_version ke $new_version"
    else
        echo "Pilihan tidak valid. Silakan jalankan ulang script dan pilih opsi yang benar."
    fi

# English
elif [ "$lang_choice" -eq 2 ]; then
    # Change to the /root/pwr directory
    cd /root/pwr

    # Display options to the user
    echo "Choose an update option:"
    echo "1. Update config.json only"
    echo "2. Update both validator and config.json"
    read -p "Enter your choice (1 or 2): " choice

    # Option 1: Update config.json only
    if [ "$choice" -eq 1 ]; then
        ensure_backup_folder
        mv config.json backup/
        rm -rf config.json
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json
        systemctl stop pwr
        pkill -f java
        systemctl start pwr
        echo "You have successfully updated config.json"

    # Option 2: Update both validator and config.json
    elif [ "$choice" -eq 2 ]; then
        old_version=$(curl -s http://localhost:8085/version)
        ensure_backup_folder
        mv config.json validator.jar backup/
        rm -rf config.json validator.jar
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json
        wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar
        systemctl stop pwr
        pkill -f java
        systemctl start pwr
        new_version=$(curl -s http://localhost:8085/version)
        echo "validator.jar and config.json have been upgraded from $old_version to $new_version"
    else
        echo "Invalid choice. Please rerun the script and select a valid option."
    fi

else
    echo "Pilihan bahasa tidak valid. Silakan jalankan ulang script dan pilih bahasa yang benar."
    echo "Invalid language choice. Please rerun the script and select a valid language."
fi
