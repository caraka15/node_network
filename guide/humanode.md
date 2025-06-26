# Snapshot Humanode

instruksi untuk menggunakan snapshot agar dapat mempercepat sinkronisasi node Humanode Anda tanpa harus mengunduh seluruh riwayat blockchain dari awal.

## Prasyarat

- Instalasi node Humanode yang berjalan
- Akses terminal ke node Anda
- Ruang disk yang cukup untuk snapshot

```
{
  "status": "available",
  "file": "humanode_snapshot_latest.tar.lz4",
  "lastModified": "2025-06-26T18:35:19.162Z",
  "size": "18759.36 MB"
}
```

## Menginstal Dependensi

Sebelum Anda memulai, instal alat kompresi LZ4:

```bash
sudo apt install lz4
```

## Menerapkan Snapshot

Ikuti langkah-langkah berikut untuk menerapkan snapshot ke node Humanode Anda:

1. **Hentikan node Humanode Anda**

   Pastikan node Anda benar-benar berhenti sebelum melanjutkan.

2. **Hapus file database yang ada**

   ```bash
   rm -rf ~/.humanode/workspaces/default/substrate-data/chains/humanode_mainnet/db/full/
   ```

3. **Unduh dan ekstrak snapshot**

   ```bash
   curl -L http://146.190.81.160:8089/humanode_snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C ~/.humanode/workspaces/default/substrate-data/chains/humanode_mainnet/db/
   ```

   Perintah ini:

   - Mengunduh snapshot terkompresi dari server
   - Mendekompresi dengan LZ4
   - Mengekstrak file ke direktori database node Anda

4. **Mulai ulang node Humanode Anda**

   Setelah snapshot berhasil diekstrak, mulai ulang node Anda.

5. **Verifikasi sinkronisasi**

   Node Anda sekarang akan mulai sinkronisasi dari ketinggian blok snapshot daripada dari genesis.

## Pemecahan Masalah

Jika Anda mengalami kesalahan:

- Pastikan paket LZ4 terinstal dengan benar
- Periksa bahwa node Anda benar-benar berhenti sebelum menerapkan snapshot
- Verifikasi Anda memiliki ruang disk yang cukup
- Pastikan Anda memiliki izin yang benar untuk direktori database

## Informasi Tambahan

Snapshot biasanya diperbarui secara teratur. Metode ini secara signifikan mengurangi waktu sinkronisasi untuk node Humanode Anda.
