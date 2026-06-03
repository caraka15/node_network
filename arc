# Penjelasan Arsitektur Streaming Arcomufar (Proxy System)

> **Pesan utama:** Walaupun di halaman show cuma terlihat **1 tombol server**, di balik layar stream itu sebenarnya **dibagi ke beberapa server sekaligus**. Kalau 1 server mati, yang lain tetap jalan — viewer tidak terganggu.

---

## 🎯 Yang Terlihat vs Yang Sebenarnya Terjadi

### Yang Viewer Lihat:

```
┌──────────────────────────────────┐
│     📺 Halaman Show Arcomufar    │
│                                  │
│   ┌────────────────────────┐     │
│   │   ▶️  Server 1          │     │
│   └────────────────────────┘     │
│                                  │
│   Viewer klik → langsung nonton  │
└──────────────────────────────────┘

"Kok cuma 1 server? Dulu kan ada 4?"
```

### Yang Sebenarnya Terjadi di Balik Layar:

```mermaid
graph TB
    V["👤 Viewer klik<br/>Server 1"]

    subgraph "🧠 Di Balik Layar (Otomatis)"
        M["Master Proxy<br/>(otak pengatur)"]
        W1["🔧 Worker 1<br/>VPS Arco"]
        W2["🔧 Worker 2<br/>VPS Singapore"]
    end

    IDN["🎬 IDN Live"]

    V -->|"klik Server 1"| M
    M -->|"otomatis pilih<br/>worker sehat"| W1
    M -->|"otomatis pilih<br/>worker sehat"| W2

    W1 --> IDN
    W2 --> IDN

    style M fill:#2ecc71,color:#fff
    style W1 fill:#3498db,color:#fff
    style W2 fill:#3498db,color:#fff
    style V fill:#e74c3c,color:#fff
```

> **1 tombol "Server 1" = sebenarnya 2+ server yang bekerja sama di belakang layar.**
> Viewer tidak perlu tahu, tidak perlu pilih manual. Sistem yang atur semuanya.

---

## 🛡️ Apa yang Terjadi Kalau 1 Server Mati?

Ini keunggulan utama sistem proxy: **auto-failover**.

```mermaid
sequenceDiagram
    participant V as 👤 Viewer
    participant M as 🧠 Master Proxy
    participant W1 as 🔧 Worker 1 (Arco)
    participant W2 as 🔧 Worker 2 (Singapore)

    Note over W1: ❌ Server Arco mati!
    W1--xM: Heartbeat berhenti...

    Note over M: Deteksi: Worker 1<br/>tidak melapor 90 detik
    M->>M: Tandai Worker 1 = TIDAK SEHAT

    V->>M: Mau nonton stream
    M->>M: Worker 1 mati, pilih Worker 2
    M->>V: Silakan ambil dari Worker 2 ✅
    V->>W2: Minta stream
    W2->>V: Stream berjalan normal ✅

    Note over V: Viewer tidak tahu ada<br/>server yang mati 🎉
```

| Skenario | Cara Lama (4 tombol server) | Cara Sekarang (1 tombol + proxy) |
|----------|---------------------------|----------------------------------|
| Server 1 mati | ❌ Viewer harus **manual klik server lain** | ✅ **Otomatis pindah**, viewer tidak sadar |
| Semua server sibuk | ❌ Viewer coba satu-satu | ✅ Master pilih yang **paling lowong** |
| Tambah server baru | ❌ Harus update UI, tambahin tombol | ✅ **Auto-connect**, UI tetap sama |

---

## 🔄 Dulu vs Sekarang

### ❌ Cara Lama: 4 Tombol Server = 4 Server Terpisah

```
┌──────────────────────────────────┐
│     📺 Halaman Show              │
│                                  │
│   ┌──────────┐  ┌──────────┐    │
│   │ Server 1 │  │ Server 2 │    │
│   └──────────┘  └──────────┘    │
│   ┌──────────┐  ┌──────────┐    │
│   │ Server 3 │  │ Server 4 │    │
│   └──────────┘  └──────────┘    │
│                                  │
│   Viewer harus pilih sendiri     │
│   Kalau mati? Coba yang lain!    │
└──────────────────────────────────┘
```

- 4 VPS = **biaya besar**
- Server mati → **viewer harus manual coba server lain**
- Tidak ada koordinasi antar server
- Viewer count terpisah-pisah

### ✅ Cara Sekarang: 1 Tombol = Banyak Server di Belakang

```
┌──────────────────────────────────┐
│     📺 Halaman Show              │
│                                  │
│   ┌────────────────────────┐     │
│   │   ▶️  Server 1          │     │
│   └────────────────────────┘     │
│                                  │
│   Tinggal klik, semua otomatis   │
└──────────────────────────────────┘
          │
          ▼ (di balik layar)
    ┌─────────────┐
    │ 🧠 Master   │ ← Otak yang mengatur
    ├─────────────┤
    │ Worker 1    │ ← VPS Arco
    │ Worker 2    │ ← VPS Singapore
    │ Worker 3?   │ ← Bisa ditambah kapan saja
    └─────────────┘
```

- 2 VPS = **lebih hemat**
- Server mati → **otomatis pindah, viewer tidak sadar**
- Ada "otak" (Master) yang koordinasi semuanya
- Viewer count terpusat

---

## 🧠 Cara Kerjanya (Bahasa Sederhana)

Bayangkan kamu pesan ojol:

1. **Kamu buka app** → kamu cuma lihat 1 tombol "Pesan"
2. **Di balik layar**, app cari driver terdekat yang available
3. **Kalau driver 1 sibuk**, otomatis cari driver 2
4. **Kamu tidak perlu tahu** ada berapa driver — tinggal klik, dapat

Sistem streaming ini **persis sama**:

1. **Viewer klik "Server 1"** → cuma lihat 1 tombol
2. **Master proxy cek** worker mana yang sehat (CPU rendah, bandwidth aman)
3. **Kalau Worker 1 penuh**, otomatis pakai Worker 2
4. **Viewer tidak perlu tahu** ada berapa server — tinggal nonton

### Detail Teknis (Sederhana):

Setiap worker **lapor ke Master setiap 30 detik**:
- "Bos, CPU saya 20%, bandwidth 100 Mbps, saya handle 30 viewer"
- Kalau worker overload → Master **stop kirim viewer baru ke situ**
- Kalau worker mati (tidak lapor 90 detik) → Master **coret dari daftar**
- Viewer lama di worker yang masih jalan **tetap aman**

---

## 💡 Kenapa 1 Tombol Lebih Baik dari 4 Tombol?

| Aspek | 4 Tombol (Lama) | 1 Tombol + Proxy (Sekarang) |
|-------|----------------|----------------------------|
| **UX Viewer** | Bingung pilih server mana | Tinggal klik, beres |
| **Server mati** | Manual pindah | Otomatis, viewer tidak sadar |
| **Biaya VPS** | 4 server = mahal | 2 server = hemat |
| **Tambah kapasitas** | Ribet, harus update UI | Install worker baru, selesai |
| **Load balancing** | Tidak ada | Otomatis dari Master |
| **Viewer count** | Pecah per server | Terpusat, akurat |

---

## 🔌 Mau Tambah Kapasitas? Gampang!

Kalau traffic makin besar, tinggal:

1. Beli VPS baru
2. Install proxy, set mode `worker saja`
3. Kasih alamat Master
4. **Selesai** — Worker baru otomatis terdeteksi

```mermaid
graph TB
    subgraph "Server 1 - Arco"
        M["🧠 Master"]
        W1["Worker 1"]
    end

    subgraph "Server 2 - Singapore"
        W2["Worker 2"]
    end

    subgraph "Server 3 - BARU ✨"
        W3["Worker 3"]
    end

    W1 -.->|heartbeat| M
    W2 -.->|heartbeat| M
    W3 -.->|heartbeat| M

    style W3 fill:#f39c12,color:#fff
    style M fill:#2ecc71,color:#fff
```

**Tidak perlu ubah kode, tidak perlu ubah UI.** Tombol di halaman show tetap 1, tapi sekarang ada 3 server yang kerja di belakang.

---

## 🔗 Soal Ngidolihub dan Teras48

Ngidolihub dan Teras48 itu **bukan server terpisah** — mereka adalah **sumber data (source)** yang hasilnya sama, yaitu stream dari IDN Live.

```mermaid
graph LR
    IDN["🎬 IDN Live<br/>(sumber asli)"]
    NH["Ngidolihub"]
    T48["Teras48"]

    IDN --> NH
    IDN --> T48

    NH -->|"data sama"| PROXY["🧠 Proxy Arcomufar"]
    T48 -->|"data sama"| PROXY

    style NH fill:#9b59b6,color:#fff
    style T48 fill:#9b59b6,color:#fff
```

Keduanya cukup didaftarkan sebagai **source berbeda** di dashboard admin proxy. **Tidak perlu server tambahan** untuk memisahkan mereka — data yang dihasilkan sama.

---

## 📝 Jawaban untuk Admin

> "kita punya 2 server, mau beli tambahan?"

**→** Untuk sekarang **2 server cukup**. Sistem proxy membuat 2 server ini bekerja seperti 4 server dulu. Kalau traffic naik, tinggal tambah VPS baru sebagai worker — auto-connect, tidak ribet.

> "waktu itu 4 sampe 3 server kan? biar gw tulis 3 atau 4 server nih"

**→** Tulis saja **2 server fisik**. Tapi jelaskan bahwa kemampuannya **setara atau lebih baik dari 4 server** karena ada sistem proxy yang mengatur distribusi otomatis + auto-failover.

> "pisah aja gasih ngidoli teras?"

**→** Tidak perlu dipisah. Ngidolihub dan Teras48 datanya sama (dari IDN Live). Cukup daftarkan sebagai source berbeda di dashboard — jalan di server yang sama.

---

## 🏗️ Ringkasan

```
                    YANG VIEWER LIHAT
            ┌─────────────────────────┐
            │    ▶️ "Server 1"         │   ← Cuma 1 tombol
            └────────────┬────────────┘
                         │
          ═══════════════╪═══════════════
                         │
              YANG TERJADI DI BALIK LAYAR
                         ▼
            ┌─────────────────────────┐
            │    🧠 Master Proxy      │   ← Otak pengatur
            │    (di VPS Arco)        │
            └──────┬──────────┬───────┘
                   │          │
            ┌──────▼──┐ ┌────▼─────┐
            │Worker 1 │ │ Worker 2 │
            │VPS Arco │ │VPS SG    │      ← Beberapa server
            └─────────┘ └──────────┘        kerja bareng

  ✅ 1 tombol, banyak server di belakang
  ✅ Server mati? Otomatis pindah
  ✅ Viewer tidak perlu tahu, tidak perlu pilih
```

> [!TIP]
> **Intinya simpel:** Dulu 4 tombol server = viewer harus pilih sendiri, kalau mati harus manual pindah. Sekarang 1 tombol = di belakangnya ada beberapa server yang kerja bareng, kalau 1 mati yang lain otomatis ambil alih. Viewer tinggal klik dan nonton, tidak perlu pusing.
