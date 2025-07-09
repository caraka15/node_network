#!/bin/bash

# Hentikan skrip jika terjadi kesalahan
set -e

# Pindah ke direktori home, unduh dan install Node.js v20.x
echo "🚀 Memasang Node.js v20.x..."
cd ~ && curl -sL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
sudo bash /tmp/nodesource_setup.sh
sudo apt-get install -y nodejs
echo "✅ Node.js berhasil dipasang:"
node -v
echo "----------------------------------------"

# Kloning repositori dari GitHub
echo "🚀 Mengkloning repositori notif..."
git clone https://github.com/caraka15/notif
cd notif
echo "✅ Repositori berhasil dikloning."
echo "----------------------------------------"

# Pasang dependensi NodeJS
echo "🚀 Memasang dependensi NodeJS (npm)..."
npm install
echo "✅ Dependensi NodeJS berhasil dipasang."
echo "----------------------------------------"

# Pasang dependensi sistem yang diperlukan
echo "🚀 Memasang dependensi sistem (apt)..."
sudo apt-get install -y \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev
echo "✅ Dependensi sistem berhasil dipasang."
echo "----------------------------------------"

# Memberikan izin eksekusi pada skrip
echo "🚀 Memberikan izin eksekusi..."
chmod +x start-admin.sh start-user.sh ws.sh
echo "✅ Izin eksekusi berhasil diberikan."
echo "----------------------------------------"

# Menjalankan skrip aplikasi
echo "🚀 Menjalankan aplikasi (./start-user.sh start)..."
./start-user.sh start

echo "🎉 Semua proses selesai!"
