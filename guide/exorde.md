Untuk menjalankan Testnet Exorde ada 2 pilihan yaitu menggunakan conda atau docker. Kekurangan docker adalah perlu mempunyai disk yg cukup besar karena log-nya akan cukup memakan disk

# Tutorial menggunakan Docker

- Jalankan command
  ```
  wget https://raw.githubusercontent.com/zainantum/exorde-auto/main/autoRunDocker.sh && chmod 777 autoRunDocker.sh && ./autoRunDocker.sh
  ```
- Setelah command di atas selesai, kalian bisa mengecek worker kalian dengan menggunakan syntax
  ```
  docker ps
  ```
- Untuk mengecek log dari worker jalankan perintah
  ```
  docker logs --tail=300 exorde1
  ```
- Proses instalasi di atas sudah termasuk dengan auto restart. jadi teman-teman tidak perlu melakukan restart manual jika ada error.
- Jika ada update dari tim dev, silahkan jalankan perintah
  ```
  bash updaterDocker.sh
  ```
- Jika ingin menambah worker baru jalankan
  ```
  bash createWorkerDocker.sh
  ```
  kemudian minimum diisi dengan n+1 dari jumlah worker yg sudah ada dan maksimum worker diisi sesuai keinginan. Misal sudah ada 9 worker dan ingin menambah 1 worker lagi, berarti minimum worker dan maksimum worker sama" diisi dengan 10.

### Untuk melihat ekspektasi reward yang anda dapatkan, serta cek leaderboard

kunjungi [Exorde Reward Explorer](https://crxanode.com/exorde-stats)

### jika node susah login twitter

- install package

  ```
  sudo apt update -y && sudo apt install xfce4 -y && sudo apt install xrdp -y && sudo apt install chromium-browser -y
  ```

- mengatur sesi xRDP

  ```
  echo xfce4-session >~/.xsession
  ```

- start xRDP

  ```
  sudo service xrdp restart
  ```

- login menggunakan software RDP bawaan windows, lalu login twitter disana

# credit [Zainantum](https://github.com/zainantum/exorde-auto/blob/main/tutorial-exorde.md)
