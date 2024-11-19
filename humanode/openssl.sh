#!/bin/bash

# Script untuk menginstall OpenSSL 1.1.1o pada Ubuntu 22
# Pastikan menjalankan script ini dengan sudo

# Fungsi untuk pengecekan error
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Fungsi untuk logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Cek apakah script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo "Script harus dijalankan dengan sudo"
    exit 1
fi

# 1. Backup konfigurasi SSL yang ada
log "Membuat backup konfigurasi SSL..."
cp -r /etc/ssl /etc/ssl.backup
check_error "Gagal membuat backup SSL"

# 2. Install dependensi yang diperlukan termasuk ca-certificates
log "Menginstall dependensi..."
apt update
apt install -y make gcc perl libssl-dev zlib1g-dev build-essential checkinstall \
    zlib1g-dev ca-certificates openssl
check_error "Gagal menginstall dependensi"

# Update CA certificates
log "Mengupdate CA certificates..."
update-ca-certificates --fresh
check_error "Gagal update CA certificates"

# 3. Hapus OpenSSL yang ada (tetapi pertahankan ca-certificates)
log "Menghapus OpenSSL yang ada..."
apt remove --purge openssl -y
apt autoremove -y
apt clean
check_error "Gagal menghapus OpenSSL lama"

# Reinstall ca-certificates untuk memastikan
log "Reinstall ca-certificates..."
apt install -y ca-certificates
update-ca-certificates --fresh
check_error "Gagal reinstall ca-certificates"

# 4. Download dan extract OpenSSL
log "Downloading OpenSSL 1.1.1o..."
cd /usr/local/src
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1o.tar.gz
check_error "Gagal download OpenSSL"

log "Extracting OpenSSL..."
tar -xf openssl-1.1.1o.tar.gz
check_error "Gagal extract OpenSSL"

cd openssl-1.1.1o
check_error "Gagal masuk ke direktori OpenSSL"

# 5. Konfigurasi dan kompilasi OpenSSL
log "Mengkonfigurasi OpenSSL..."
./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
check_error "Gagal konfigurasi OpenSSL"

log "Kompilasi OpenSSL..."
make clean
make
check_error "Gagal kompilasi OpenSSL"

log "Menjalankan test..."
make test
check_error "Test OpenSSL gagal"

log "Menginstall OpenSSL..."
make install
check_error "Gagal install OpenSSL"

# 6. Konfigurasi sistem
log "Mengkonfigurasi sistem..."
echo "/usr/local/ssl/lib" > /etc/ld.so.conf.d/openssl-1.1.1o.conf
ldconfig
check_error "Gagal konfigurasi library"

# 7. Update environment variables
log "Mengupdate environment variables..."
echo "export PATH=/usr/local/ssl/bin:$PATH" >> /etc/profile
echo "export LD_LIBRARY_PATH=/usr/local/ssl/lib:$LD_LIBRARY_PATH" >> /etc/profile
source /etc/profile
check_error "Gagal update environment variables"

# 8. Buat symlink
log "Membuat symlink..."
ln -sf /usr/local/ssl/bin/openssl /usr/bin/openssl
check_error "Gagal membuat symlink"

# 9. Copy CA certificates ke direktori OpenSSL baru
log "Menyalin CA certificates..."
cp -r /etc/ssl/certs/* /usr/local/ssl/certs/
check_error "Gagal menyalin CA certificates"

# 10. Set permissions yang benar
log "Setting permissions..."
chmod 755 /usr/local/ssl/certs
chmod 644 /usr/local/ssl/certs/*
check_error "Gagal set permissions"

# 11. Verifikasi instalasi
log "Verifikasi instalasi..."
openssl version
check_error "Gagal verifikasi OpenSSL"

# 12. Bersihkan file temporary
log "Membersihkan file temporary..."
cd /usr/local/src
rm -rf openssl-1.1.1o.tar.gz

log "Instalasi OpenSSL 1.1.1o selesai!"
log "Versi OpenSSL yang terinstall:"
openssl version

echo ""
echo "Untuk mengaktifkan environment variables baru, jalankan:"
echo "source /etc/profile"
echo ""
echo "Untuk memverifikasi SSL/TLS connections, coba:"
echo "curl https://www.google.com"
