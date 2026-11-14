# Production-Grade AI Agents: Automated Cloud Run Deployment & End-to-End Tracing with Google Agent Skills

Workshop hands-on: membangun AI agent sederhana dengan **Google ADK**, men-deploy-nya ke
**Cloud Run** secara otomatis menggunakan **Gemini CLI + [Google Agent Skills](https://github.com/google/skills)**,
lalu menelusuri setiap langkah agent (panggilan LLM, panggilan tool) lewat **Cloud Trace**.

Semua langkah dikerjakan di **Google Cloud Shell**, jadi setiap peserta punya lingkungan yang sama
dan tidak perlu menginstall apa pun di laptop.

⏱️ Durasi: ±90 menit  ·  🎯 Level: pemula–menengah  ·  💰 Biaya: sangat kecil (tertutup free trial, asal cleanup di akhir)

---

## Daftar Isi

1. [Gambaran Besar](#1-gambaran-besar)
2. [Persiapan Sebelum Workshop](#2-persiapan-sebelum-workshop)
3. [Struktur Project](#3-struktur-project)
4. [Langkah-langkah Workshop](#4-langkah-langkah-workshop)
5. [Troubleshooting](#5-troubleshooting)
6. [Apa yang Membuat Ini "Production-Grade"?](#6-apa-yang-membuat-ini-production-grade)

---

## 1. Gambaran Besar

Kita akan membuat **"Arek Kuliner"** 🍜, AI agent pemandu kuliner Surabaya dengan 3 tool:

| Tool | Fungsi | Catatan |
|---|---|---|
| `cari_kuliner(area)` | Rekomendasi tempat makan per area | data dummy |
| `cek_antrian(nama_tempat)` | Perkiraan lama antrian | **sengaja lambat 1–4 detik** 🐢 untuk latihan tracing |
| `hitung_budget(total_harga, jumlah_orang)` | Hitung patungan + pajak 10% | |

```mermaid
flowchart LR
    Dev["👩‍💻 Kamu di Cloud Shell"] -->|prompt| CA["🤖 Gemini CLI"]
    SK["📚 Google Agent Skills<br/>cloud-run-basics<br/>cloud-trace-querying"] -.->|panduan| CA
    CA -->|gcloud run deploy| CR["☁️ Cloud Run<br/>kuliner-agent (ADK)"]
    User["🙋 User"] -->|HTTP| CR
    CR -->|Vertex AI| G["✨ Gemini"]
    CR -->|OpenTelemetry spans| CT["🔍 Cloud Trace"]
    CA -->|query trace| CT
```

**Apa itu Agent Skills?** Skill adalah folder berisi `SKILL.md`, dokumen referensi, dan script yang mengajari
coding agent cara mengerjakan tugas tertentu sesuai best practice resmi Google. Kita tidak perlu
hafal semua flag `gcloud`; cukup minta ke Gemini CLI, dan Gemini CLI mengikuti panduan dari skill.

Skill yang dipakai:

| Skill | Dipakai untuk |
|---|---|
| [`cloud-run-basics`](https://github.com/google/skills/tree/main/skills/cloud/cloud-run-basics) | Deploy & konfigurasi Cloud Run |
| [`gcloud`](https://github.com/google/skills/tree/main/skills/cloud/gcloud) | Menjalankan perintah gcloud dengan benar |
| [`cloud-trace-querying`](https://github.com/google/skills/tree/main/skills/cloud/cloud-trace-querying) | Mencari & membedah trace, menemukan bottleneck latency |
| [`cloud-run-alert-configuration`](https://github.com/google/skills/tree/main/skills/cloud/cloud-run-alert-configuration) | *(bonus)* Alert latency & error |
| [`cloud-logging-query-generation`](https://github.com/google/skills/tree/main/skills/cloud/cloud-logging-query-generation) | *(bonus)* Query log |

---

## 2. Persiapan Sebelum Workshop

### Yang perlu disiapkan peserta (H-1, maksimal 10 menit)

| # | Kebutuhan | Keterangan |
|---|---|---|
| 1 | **Laptop + browser Chrome** | Tidak perlu install apa pun |
| 2 | **Akun Google pribadi (Gmail)** | Hindari akun kantor/kampus, karena sering dibatasi admin (Cloud Shell atau IAM bisa diblokir) |
| 3 | **Project Google Cloud dengan billing aktif** | Buat di [console.cloud.google.com/projectcreate](https://console.cloud.google.com/projectcreate), lalu hubungkan ke billing. Bisa pakai [free trial $300](https://cloud.google.com/free) atau kredit dari panitia |
| 4 | **Catat Project ID** | Contoh: `workshop-agent-12345`. Project ID **bukan** nama project |

> ⚠️ Billing yang belum aktif adalah penyebab error nomor 1 di workshop. Pastikan sudah aktif sebelum hari H.

### Yang sudah tersedia di Cloud Shell (tidak perlu diinstall)

| Tool | Dipakai untuk |
|---|---|
| `gcloud` (sudah login otomatis) | Deploy, IAM, API |
| `gemini` (Gemini CLI) | Coding agent yang menjalankan skill |
| Node.js + `npx` | Install Google Agent Skills |
| Python 3 + `venv` | Menjalankan agent di Cloud Shell & script skill trace |
| `git`, `curl` | Clone repo, test API |

### Yang akan diinstall selama workshop

| Apa | Perintah | Di langkah |
|---|---|---|
| Google ADK (`google-adk[gcp]`) | `pip install -r requirements.txt` | Langkah 4 (opsional, untuk uji coba di Cloud Shell) |
| Google Agent Skills | `npx skills add google/skills ...` | Langkah 5 |

---

## 3. Struktur Project

```
.
├── kuliner_agent/
│   ├── __init__.py
│   └── agent.py               # ⭐ Definisi agent + 3 tool (ADK)
├── main.py                    # Server FastAPI + export trace ke Cloud Trace
├── Dockerfile                 # Container untuk Cloud Run
├── requirements.txt           # google-adk[gcp] (versi dikunci)
├── .env.example               # Template konfigurasi
├── .gcloudignore              # File yang tidak ikut di-upload saat deploy
├── scripts/
│   ├── 00_init.sh             # Cek project & billing, buat .env
│   ├── 01_setup_gcp.sh        # Enable API + service account + IAM
│   ├── 02_deploy.sh           # Deploy manual (cadangan kalau Gemini CLI bermasalah)
│   ├── 03_generate_traffic.sh # Kirim pertanyaan ke agent -> menghasilkan trace
│   └── 99_cleanup.sh          # Hapus semua resource
└── prompts/
    ├── 01_deploy.md           # Prompt deploy otomatis (skill cloud-run-basics)
    ├── 02_trace.md            # Prompt analisis trace (skill cloud-trace-querying)
    └── 03_bonus.md            # Alert, logging, perbaikan latency
```

Inti tracing hanya **satu argumen** di `main.py`:

```python
app = get_fast_api_app(agents_dir=AGENT_DIR, web=True, trace_to_cloud=True, ...)
```

ADK otomatis membuat span untuk setiap langkah agent:

```
invoke_workflow kuliner_agent
└── invoke_agent kuliner_agent
    ├── generate_content gemini-3.5-flash   ← Gemini memutuskan memanggil tool
    ├── execute_tool cek_antrian            ← 🐢 si lambat (1–4 detik)
    └── generate_content gemini-3.5-flash   ← Gemini menyusun jawaban
```

---

## 4. Langkah-langkah Workshop

> 💡 **Konvensi:** blok kode yang diawali `$` dijalankan di **terminal Cloud Shell**.
> Blok di dalam Gemini CLI ditandai **"di Gemini CLI"**.

### Langkah 1 — Buka Cloud Shell & ambil kode (5 menit)

1. Buka **https://shell.cloud.google.com** dan login dengan akun Google kamu.
   Kalau muncul dialog **Authorize Cloud Shell**, klik **Authorize**.
2. Set project. Ganti `PROJECT_ID_KAMU` dengan Project ID kamu:

   ```bash
   export GOOGLE_CLOUD_PROJECT=PROJECT_ID_KAMU
   gcloud config set project $GOOGLE_CLOUD_PROJECT
   ```

   Prompt terminal akan berubah menampilkan project ID berwarna kuning.

3. Clone repo workshop dan masuk ke foldernya:

   ```bash
   cd ~
   git clone https://github.com/suhriar/devfest-prod-agents-workshop.git
   cd ~/devfest-prod-agents-workshop
   ```

> 🔁 **Kalau Cloud Shell terputus** (idle terlalu lama, atau tab ditutup), file kamu tetap aman. Setelah reconnect,
> jalankan lagi tiga perintah ini:
> ```bash
> export GOOGLE_CLOUD_PROJECT=PROJECT_ID_KAMU
> gcloud config set project $GOOGLE_CLOUD_PROJECT
> cd ~/devfest-prod-agents-workshop
> ```

### Langkah 2 — Inisialisasi (1 menit)

```bash
./scripts/00_init.sh
```

Script ini mengecek project & billing, lalu membuat file `.env`. Output yang diharapkan:

```
✅ Project aktif : workshop-agent-12345
✅ Akun          : kamu@gmail.com
✅ Billing aktif
✅ File .env dibuat:
   GOOGLE_CLOUD_PROJECT=workshop-agent-12345
   ...
```

### Langkah 3 — Siapkan Google Cloud (3–5 menit, cukup sekali)

```bash
./scripts/01_setup_gcp.sh
```

Yang dilakukan script:
1. Mengaktifkan API: Compute, Cloud Run, Cloud Build, Artifact Registry, Vertex AI, Cloud Trace, Logging, Monitoring, dan Gemini for Google Cloud (untuk Gemini CLI).
2. Membuat service account `kuliner-agent-sa` dengan **hak akses minimum**: memanggil Gemini, mengirim trace, menulis log.
3. Memberi Cloud Build role `roles/run.builder`, sesuai panduan skill `cloud-run-basics`.

Tunggu sampai muncul `✅ Setup GCP selesai`, lalu **tunggu ±1 menit** agar izin IAM aktif.

### Langkah 4 — (Opsional) Coba agent langsung di Cloud Shell (10 menit)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -q -r requirements.txt
adk web --host 0.0.0.0 --port 8080
```

1. Klik tombol **Web Preview** (ikon 👁️ / `<>` di toolbar Cloud Shell) → **Preview on port 8080**.
2. Pilih `kuliner_agent` di kiri atas, lalu tanya: *"Rekomendasi kuliner di Surabaya timur dan cek antriannya"*.
3. Klik tab **Trace** di Dev UI untuk melihat langkah-langkah agent. Ini versi lokal dari apa yang nanti kita lihat di Cloud Trace.
4. Selesai? Tekan `Ctrl+C` lalu jalankan `deactivate`.

### Langkah 5 — Install Google Agent Skills & buka Gemini CLI (5 menit)

Pastikan kamu ada di folder `~/devfest-prod-agents-workshop`, lalu install skill yang dibutuhkan:

```bash
npx -y skills add google/skills \
  -s cloud-run-basics \
  -s gcloud \
  -s cloud-trace-querying \
  -s cloud-run-alert-configuration \
  -s cloud-logging-query-generation \
  -a gemini-cli -y
```

Output yang diharapkan: 5 baris `✓ <nama-skill> (copied) → ./.agents/skills/<nama-skill>` diakhiri `Done!`.

Buka Gemini CLI **dari folder project**:

```bash
gemini
```

- Kalau ditanya *trust folder*, pilih **Trust folder**.
- Kalau ditanya metode login, pilih **Use Cloud Shell user credentials** (atau **Login with Google**).

Verifikasi skill terbaca. Ketik **di Gemini CLI**:

```
/skills list
```

Lima skill tadi harus muncul. Kalau perintah `/skills` tidak dikenali, tanyakan saja: *"skill apa saja yang tersedia?"*

### Langkah 6 — 🚀 Deploy otomatis ke Cloud Run dengan skill (10–15 menit)

Buka [`prompts/01_deploy.md`](prompts/01_deploy.md) (bisa lewat **Open Editor** di Cloud Shell), salin prompt-nya,
lalu tempel **di Gemini CLI**.

Yang akan terjadi:
1. Gemini CLI memuat skill `cloud-run-basics` dan menyusun rencana deploy.
2. Setiap perintah `gcloud` akan **meminta persetujuanmu**. Baca dulu, lalu pilih *Allow once*.
3. Cloud Build membangun image dari `Dockerfile`, kemudian Cloud Run menjalankannya (±3–5 menit).
4. Gemini CLI menampilkan URL service dan mengetes `/healthz`.

✅ **Berhasil jika** muncul URL seperti `https://kuliner-agent-xxxxxxxx.us-central1.run.app` dan `/healthz` membalas `{"status":"ok"}`.

<details>
<summary>🛟 <b>Cara cadangan</b>: deploy tanpa Gemini CLI</summary>

Keluar dari Gemini CLI (`/quit`), lalu di terminal:

```bash
./scripts/02_deploy.sh
```

Script ini menjalankan perintah `gcloud run deploy` yang sama persis dengan konfigurasi production di prompt.
</details>

### Langkah 7 — Coba agent & hasilkan traffic (5 menit)

1. Buka `https://<URL-SERVICE>/dev-ui/` di tab browser baru, lalu chat dengan agent.
2. Di terminal Cloud Shell, buka tab baru (ikon **+**) dan kirim 5 pertanyaan otomatis:

   ```bash
   cd ~/devfest-prod-agents-workshop
   ./scripts/03_generate_traffic.sh
   ```

   Setiap pertanyaan menghasilkan 1 trace. Tunggu **±1 menit** sampai trace masuk ke Cloud Trace.

### Langkah 8 — 🔍 End-to-end tracing (20 menit)

**8a. Lihat lewat Console**, supaya paham tampilannya:

1. Buka [Trace Explorer](https://console.cloud.google.com/traces/explorer).
2. Klik salah satu trace untuk melihat *waterfall* span: `invoke_workflow` → `invoke_agent` → `generate_content` / `execute_tool`.
3. Klik span `generate_content ...` dan lihat atribut `gen_ai.*`: model dan jumlah token input/output.
4. Klik span `execute_tool cek_antrian` dan perhatikan durasinya 🐢.

**8b. Lewat Gemini CLI + skill `cloud-trace-querying`:**

Buka [`prompts/02_trace.md`](prompts/02_trace.md) dan jalankan prompt 2a → 2d secara berurutan **di Gemini CLI**.
Gemini CLI akan menjalankan script dari skill (`search_traces`, `fetch_entire_trace`, `fetch_related_logs`,
`generate_links`) dan menyimpulkan bahwa **`cek_antrian` adalah bottleneck**.

> 💡 Inti workshop: coding agent tidak hanya bisa men-deploy, tapi juga **mengobservasi** dan
> **mendiagnosis** sistem production dengan data nyata.

### Langkah 9 — Bonus: lebih production-ready (opsional)

Lihat [`prompts/03_bonus.md`](prompts/03_bonus.md):
- Perbaiki bottleneck, redeploy, lalu bandingkan latency sebelum & sesudah.
- Pasang **alert** latency & error rate (`cloud-run-alert-configuration`).
- Query **log** error (`cloud-logging-query-generation`).

### Langkah 10 — 🧹 Cleanup (WAJIB, 2 menit)

```bash
cd ~/devfest-prod-agents-workshop
./scripts/99_cleanup.sh
```

Ketik `y` untuk konfirmasi. Script menghapus Cloud Run service, service account, dan image di Artifact Registry.
Mau benar-benar bersih? Hapus seluruh project di
[Manage resources](https://console.cloud.google.com/cloud-resource-manager).

---

## 5. Troubleshooting

| Masalah | Solusi |
|---|---|
| `00_init.sh`: *Project belum dipilih* | Jalankan `gcloud config set project PROJECT_ID_KAMU`. |
| `00_init.sh`: *Billing BELUM aktif* | Buka link yang ditampilkan script, hubungkan ke billing account, lalu ulangi. |
| `01_setup_gcp.sh`: `Billing account ... is not found` | Sama seperti di atas. Billing wajib untuk enable API. |
| `PERMISSION_DENIED` saat setup/deploy | Pastikan akunmu **Owner** di project (otomatis kalau kamu yang membuat project). Tunggu 1–2 menit setelah setup, lalu ulangi. |
| Deploy gagal di tahap build (`Build failed`) | Biasanya karena izin IAM belum aktif. Tunggu 1 menit, lalu jalankan ulang `./scripts/01_setup_gcp.sh` dan deploy lagi. |
| Deploy gagal: `allow-unauthenticated ... organization policy` | Akunmu dibatasi kebijakan organisasi. Pakai Gmail pribadi dengan project baru. |
| Gemini CLI error `Gemini for Google Cloud API has not been used` | Jalankan `gcloud services enable cloudaicompanion.googleapis.com`, tunggu 1 menit, buka lagi `gemini`. |
| Gemini CLI tidak menemukan skill | Keluar (`/quit`), pastikan berada di `~/devfest-prod-agents-workshop` (ada folder `.agents/skills`), lalu jalankan lagi `gemini`. |
| Agent membalas error `404 ... model not found` | Ubah `MODEL` di `.env` (misal `gemini-2.5-flash`), lalu deploy ulang. |
| Trace tidak muncul | Tunggu 1–2 menit dan refresh. Pastikan deploy memakai flag `--no-cpu-throttling` dan env `TRACE_TO_CLOUD=true`. |
| Script skill trace: `Could not automatically determine credentials` | Jalankan `gcloud auth application-default login` di terminal Cloud Shell. |
| Cloud Shell terputus / file seperti hilang | Reconnect, lalu `cd ~/devfest-prod-agents-workshop`. Folder home tetap tersimpan. |
| Lihat log error service | `gcloud run services logs read kuliner-agent --region us-central1 --limit 50` |

---

## 6. Apa yang Membuat Ini "Production-Grade"?

**Sudah diterapkan di workshop ini:**

- ✅ **Service account khusus** dengan prinsip *least privilege*, bukan default compute SA.
- ✅ **Container non-root** yang listen di `0.0.0.0:$PORT`, plus endpoint `/healthz`.
- ✅ **Autoscaling terkontrol**: `min-instances 0` (hemat), `max-instances 3` (batas biaya), `concurrency`, `timeout`, startup CPU boost.
- ✅ **Telemetry yang andal**: `--no-cpu-throttling` agar trace yang dikirim di background tidak hilang.
- ✅ **Session affinity** agar percakapan dari user yang sama diarahkan ke instance yang sama.
- ✅ **Konfigurasi lewat env var**, bukan hard-code (model, project, toggle tracing).
- ✅ **Versi dependency dikunci** (`google-adk[gcp]==2.14.1`) agar build bisa diulang dengan hasil sama.
- ✅ **Observability end-to-end**: setiap panggilan LLM & tool tercatat di Cloud Trace (OpenTelemetry, konvensi `gen_ai.*`).
- ✅ **Label resource** untuk tracking biaya.

**Langkah berikutnya untuk production sungguhan:**

- 🔒 Matikan `--allow-unauthenticated`; pakai IAM / IAP / API Gateway.
- 💾 Simpan session di database (Cloud SQL / Firestore / Agent Platform Sessions), bukan di disk instance.
- 🔁 CI/CD otomatis dengan Cloud Build trigger atau GitHub Actions (skill `cloud-build-basics`).
- 📊 Alert & SLO (skill `cloud-run-alert-configuration`, `google-cloud-slo-alert-configuration`).
- 🧪 Evaluasi kualitas agent sebelum rilis (lihat [agents-cli](https://github.com/google/agents-cli)).
- 🙈 Hati-hati merekam isi prompt/response di trace jika berisi data pribadi.

---

## Referensi

- Google Agent Skills: https://github.com/google/skills
- Agent Development Kit (ADK): https://google.github.io/adk-docs/
- Cloud Shell: https://cloud.google.com/shell/docs
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Cloud Run: https://cloud.google.com/run/docs
- Cloud Trace: https://cloud.google.com/trace/docs
