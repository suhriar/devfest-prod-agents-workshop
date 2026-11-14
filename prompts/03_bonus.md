# Prompt 3 — Bonus: dari "jalan" ke "production-grade"

Kalau masih ada waktu, coba prompt-prompt berikut di **Gemini CLI**.
Skill `cloud-run-alert-configuration` dan `cloud-logging-query-generation` sudah terinstall di Langkah 5.

### 3a. Perbaiki bottleneck lalu redeploy (skill: `cloud-run-basics`, `cloud-trace-querying`)

```
Berdasarkan analisis trace tadi, ubah tool cek_antrian supaya lebih cepat
(misal: cache hasil per nama_tempat selama 60 detik). Redeploy ke Cloud Run
dengan konfigurasi yang sama seperti sebelumnya, jalankan ./scripts/03_generate_traffic.sh,
lalu bandingkan durasi span execute_tool cek_antrian sebelum dan sesudah dari Cloud Trace.
```

### 3b. Pasang alert (skill: `cloud-run-alert-configuration`)

```
Gunakan skill cloud-run-alert-configuration. Buat alert policy untuk service
kuliner-agent: notifikasi jika latency p95 > 5 detik atau error rate 5xx > 5%
selama 5 menit. Kirim notifikasi ke email saya.
```

### 3c. Cari error di log (skill: `cloud-logging-query-generation`)

```
Gunakan skill cloud-logging-query-generation. Buatkan query Logging untuk
menampilkan semua log ERROR dari Cloud Run service kuliner-agent 1 jam terakhir,
lalu jalankan.
```

### 3d. Review ala production

```
Review deployment kuliner-agent ini (Dockerfile, main.py, dan konfigurasi Cloud Run-nya)
dari sisi keamanan, keandalan, dan biaya. Berikan 5 rekomendasi teratas yang paling berdampak.
```
