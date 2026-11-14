# Prompt 2 — Analisis trace end-to-end

> Skill yang dipakai: `cloud-trace-querying`
> Jalankan **setelah** `./scripts/03_generate_traffic.sh` dan tunggu ±1 menit.
> Tempel setiap prompt di **Gemini CLI**, berurutan.

Struktur span yang dibuat ADK (untuk referensi):

```
invoke_workflow kuliner_agent
└── invoke_agent kuliner_agent
    ├── generate_content <model>
    ├── execute_tool <nama_tool>
    └── generate_content <model>
```

### 2a. Lihat trace terbaru

```
Gunakan skill cloud-trace-querying.
Project ID ada di file .env (GOOGLE_CLOUD_PROJECT).
Cari trace dalam 30 menit terakhir dengan filter 'span:invoke_agent'.
Tampilkan dalam tabel: trace_id, durasi, jumlah span, ada error atau tidak.
```

### 2b. Bedah satu trace (end-to-end)

```
Ambil trace yang paling lama dari hasil tadi. Tampilkan seluruh hierarki span-nya
sebagai ASCII timeline. Span mana yang paling lama, dan berapa persen dari total durasi?
```

### 2c. Root-cause latency

```
Cari trace dengan filter 'span:execute_tool latency:3s'. Tool apa yang paling sering
menjadi penyebab lambat? Lihat kodenya di kuliner_agent/agent.py dan jelaskan penyebabnya.
Jangan ubah file dulu.
```

✅ **Jawaban yang diharapkan:** span `execute_tool cek_antrian` adalah bottleneck,
karena ada `time.sleep(random.uniform(1.0, 4.0))` yang sengaja kita taruh di sana.

### 2d. Korelasi dengan log & link console

```
Untuk trace paling lama tadi, ambil log aplikasi yang terkait (correlated logs),
lalu buatkan link Cloud Console untuk membuka trace tersebut.
```

Klik link yang diberikan untuk membuka trace di Cloud Console.
