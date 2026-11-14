# Prompt 1 — Deploy otomatis ke Cloud Run

> Skill yang dipakai: `cloud-run-basics`
> Salin prompt di bawah, lalu tempel di **Antigravity CLI** (dibuka dari folder `~/devfest-prod-agents-workshop`).

```
Gunakan skill cloud-run-basics.

Deploy project Python ADK di folder ini ke Cloud Run. Ketentuan:
- Baca konfigurasi dari file .env (GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_LOCATION, REGION, SERVICE_NAME, MODEL).
- Deploy dari source dengan Dockerfile yang sudah ada. JANGAN mengubah file apa pun di project.
- Service account: <SERVICE_NAME>-sa@<GOOGLE_CLOUD_PROJECT>.iam.gserviceaccount.com (sudah dibuat).
- Env vars: GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_LOCATION, GOOGLE_GENAI_USE_VERTEXAI=TRUE, MODEL, TRACE_TO_CLOUD=true.
- Konfigurasi production: memory 1Gi, cpu 1, min-instances 0, max-instances 3, concurrency 20,
  timeout 300, startup CPU boost, no-cpu-throttling (agar trace terkirim), session affinity,
  label app=kuliner-agent dan env=workshop.
- Izinkan akses publik (allow-unauthenticated) karena ini workshop.

Tampilkan dulu perintah lengkap yang akan dijalankan dan jelaskan arti setiap flag.
Setelah deploy selesai, tampilkan URL service lalu test endpoint /healthz dengan curl.
```

✅ **Berhasil jika:** muncul URL `https://kuliner-agent-xxxxxxxx.us-central1.run.app` dan `/healthz` membalas `{"status":"ok"}`.

🛟 **Kalau gagal:** buka tab terminal baru, lalu jalankan `cd ~/devfest-prod-agents-workshop && ./scripts/02_deploy.sh`.
