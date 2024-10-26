#!/bin/bash
# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fungsi untuk log dengan warna
log_info() {
  echo -e "${CYAN}[INFO]${NC} $1"
}
log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}
log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}
log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Fungsi untuk menginstall Docker
install_docker() {
  log_info "Memperbarui sistem dan menginstall Docker..."
  sudo apt update && sudo apt upgrade -y && sudo apt install docker.io -y
  
  if [ $? -eq 0 ]; then
    log_success "Docker berhasil diinstall."
  else
    log_error "Gagal menginstall Docker."
    exit 1
  fi
}

# Fungsi untuk membersihkan container yang sedang berjalan
cleanup_containers() {
  log_info "Membersihkan container yang sedang berjalan..."
  docker kill exordetwitter exordenews reddit watchtower 2>/dev/null
  docker rm exordetwitter exordenews reddit watchtower 2>/dev/null
}

# Fungsi untuk menjalankan Exorde Twitter
run_exorde_twitter() {
  cleanup_containers
  
  read -p "Masukkan Twitter Username: " username
  read -p "Masukkan Twitter Auth Token: " auth_token
  
  log_info "Menjalankan Exorde Twitter..."
  docker run -d --cpus="4" --memory="8g" --restart unless-stopped --pull always --name exordetwitter exordelabs/exorde-client --main_address 0x28b8A9aC47E3E43e3A0872028476ef898055871C --twitter_username $username --twitter_password 'xxxxxx' --twitter_email '$auth_token' --mo twitter=https://github.com/zainantum/a7df32de3a60dfdb7a0b --only twitter
  
  if [ $? -eq 0 ]; then
    log_success "Exorde Twitter berhasil dijalankan."
    log_info "Untuk melihat log, jalankan perintah: docker logs -f exordetwitter"
    log_info "Menjalankan watchtower..."
    docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower exordetwitter -i 1800
  else
    log_error "Gagal menjalankan Exorde Twitter."
  fi
}

# Fungsi untuk menjalankan Exorde News
run_exorde_news() {
  cleanup_containers
  
  log_info "Menjalankan Exorde News..."
  docker run -d --cpus="4" --memory="8g" --restart unless-stopped --pull always --name exordenews exordelabs/exorde-client --main_address 0x28b8A9aC47E3E43e3A0872028476ef898055871C --only articlefeed
  
  if [ $? -eq 0 ]; then
    log_success "Exorde News berhasil dijalankan."
    log_info "Untuk melihat log, jalankan perintah: docker logs -f exordenews"
    log_info "Menjalankan watchtower..."
    docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower exordenews -i 1800
  else
    log_error "Gagal menjalankan Exorde News."
  fi
}

# Fungsi untuk menjalankan Exorde Reddit
run_exorde_reddit() {
  cleanup_containers
  
  log_info "Menjalankan Exorde Reddit..."
  docker run -d --cpus="4" --memory="8g" --restart unless-stopped --pull always --name reddit exordelabs/exorde-client --main_address 0x28b8A9aC47E3E43e3A0872028476ef898055871C --only reddit
  
  if [ $? -eq 0 ]; then
    log_success "Exorde Reddit berhasil dijalankan."
    log_info "Untuk melihat log, jalankan perintah: docker logs -f reddit"
    log_info "Menjalankan watchtower..."
    docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower reddit -i 1800
  else
    log_error "Gagal menjalankan Exorde Reddit."
  fi
}

# Tanyakan apakah pengguna ingin menginstall Docker
read -p "Apakah Anda ingin menginstall Docker? (y/n): " install_docker_choice
if [[ "$install_docker_choice" == "y" || "$install_docker_choice" == "Y" ]]; then
  install_docker
else
  log_info "Lewati instalasi Docker."
fi

# Skrip utama
echo -e "${BLUE}Pilih opsi yang ingin dijalankan:${NC}"
echo -e "${YELLOW}1) Exorde Twitter${NC}"
echo -e "${YELLOW}2) Exorde News${NC}"
echo -e "${YELLOW}3) Exorde Reddit${NC}"
read -p "Masukkan pilihan (1, 2, atau 3): " choice

case $choice in
  1)
    run_exorde_twitter
    ;;
  2)
    run_exorde_news
    ;;
  3)
    run_exorde_reddit
    ;;
  *)
    log_warning "Pilihan tidak valid. Harap jalankan kembali script dan pilih opsi yang benar."
    ;;
esac