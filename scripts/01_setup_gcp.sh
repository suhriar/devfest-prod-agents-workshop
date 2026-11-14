#!/usr/bin/env bash
# Langkah 2: siapkan project GCP (API + service account + IAM). Cukup sekali.
source "$(dirname "$0")/_env.sh"

echo "▶ Enable API yang dibutuhkan (1-3 menit)..."
gcloud services enable \
  compute.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  aiplatform.googleapis.com \
  cloudtrace.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  --project "$GOOGLE_CLOUD_PROJECT" --quiet

echo "▶ Buat service account khusus agent: $SA_EMAIL"
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project "$GOOGLE_CLOUD_PROJECT" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Kuliner Agent (Cloud Run)" --project "$GOOGLE_CLOUD_PROJECT" --quiet
  sleep 10  # beri waktu service account baru tersebar sebelum diberi role
fi

grant() {
  # Retry karena IAM kadang butuh beberapa detik setelah resource baru dibuat.
  for i in 1 2 3 4 5; do
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT" \
      --member="serviceAccount:$1" --role="$2" --condition=None --quiet >/dev/null 2>&1 && return 0
    sleep 10
  done
  echo "❌ Gagal grant $2 ke $1"; exit 1
}

# Prinsip least-privilege: agent hanya boleh panggil Gemini, kirim trace & tulis log.
for role in roles/aiplatform.user roles/cloudtrace.agent roles/logging.logWriter; do
  echo "  - grant $role -> agent SA"
  grant "$SA_EMAIL" "$role"
done

# Sesuai skill cloud-run-basics: Cloud Build memakai default compute SA dan butuh
# roles/run.builder untuk build dari source.
PROJECT_NUMBER=$(gcloud projects describe "$GOOGLE_CLOUD_PROJECT" --format="value(projectNumber)")
BUILD_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
echo "▶ Tunggu default compute service account tersedia..."
for i in $(seq 1 12); do
  gcloud iam service-accounts describe "$BUILD_SA" --project "$GOOGLE_CLOUD_PROJECT" >/dev/null 2>&1 && break
  sleep 10
done
echo "  - grant roles/run.builder -> $BUILD_SA"
grant "$BUILD_SA" roles/run.builder

echo "✅ Setup GCP selesai. Tunggu ±1 menit agar izin IAM aktif sebelum deploy."
