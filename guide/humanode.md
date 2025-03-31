
# Snapshot Humanode
instruksi untuk menggunakan snapshot agar dapat mempercepat sinkronisasi node Humanode Anda tanpa harus mengunduh seluruh riwayat blockchain dari awal.

## Prasyarat
- Instalasi node Humanode yang berjalan
- Akses terminal ke node Anda
- Ruang disk yang cukup untuk snapshot

## Menginstal Dependensi
Sebelum Anda memulai, instal alat kompresi LZ4:
```bash
sudo apt install lz4
```

## Informasi Snapshot Terkini

<div id="snapshot-info">Loading snapshot info...</div>

<script>
  fetch('http://159.223.33.210:8089/status')
    .then(response => response.json())
    .then(data => {
      const infoDiv = document.getElementById('snapshot-info');
      infoDiv.innerHTML = `
        <pre>
{
  "status": "${data.status}",
  "file": "${data.file}",
  "lastModified": "${data.lastModified}",
  "size": "${data.size}"
}
        </pre>
      `;
    })
    .catch(error => {
      document.getElementById('snapshot-info').innerHTML = `Error fetching snapshot info: ${error.message}`;
    });
</script>

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
   curl -L http://159.223.33.210:8089/humanode_snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C ~/.humanode/workspaces/default/substrate-data/chains/humanode_mainnet/db/
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

### Alternatif dengan Autorefresh

Jika Anda ingin informasi snapshot diperbarui secara periodik tanpa perlu me-refresh halaman, Anda bisa menggunakan versi script yang diperbarui seperti ini:


# Snapshot Humanode
instruksi untuk menggunakan snapshot agar dapat mempercepat sinkronisasi node Humanode Anda tanpa harus mengunduh seluruh riwayat blockchain dari awal.

## Prasyarat
- Instalasi node Humanode yang berjalan
- Akses terminal ke node Anda
- Ruang disk yang cukup untuk snapshot

## Menginstal Dependensi
Sebelum Anda memulai, instal alat kompresi LZ4:
```bash
sudo apt install lz4
```

## Informasi Snapshot Terkini

<div id="snapshot-info">Loading snapshot info...</div>

<script>
  function fetchSnapshotInfo() {
    fetch('http://159.223.33.210:8089/status')
      .then(response => response.json())
      .then(data => {
        const infoDiv = document.getElementById('snapshot-info');
        const lastUpdate = new Date().toLocaleString();
        infoDiv.innerHTML = `
          <pre>
{
  "status": "${data.status}",
  "file": "${data.file}",
  "lastModified": "${data.lastModified}",
  "size": "${data.size}"
}
          </pre>
          <small>Last checked: ${lastUpdate}</small>
        `;
      })
      .catch(error => {
        document.getElementById('snapshot-info').innerHTML = `Error fetching snapshot info: ${error.message}`;
      });
  }
  
  // Get initial data
  fetchSnapshotInfo();
  
  // Refresh every 5 minutes (300000 ms)
  setInterval(fetchSnapshotInfo, 300000);
</script>

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
   curl -L http://159.223.33.210:8089/humanode_snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C ~/.humanode/workspaces/default/substrate-data/chains/humanode_mainnet/db/
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
