#!/usr/bin/env bash
# Langkah 1: inisialisasi workshop di Cloud Shell.
# - Cek berjalan di Cloud Shell
# - Buat file .env dari project gcloud yang aktif
# - Cek billing project
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${CLOUD_SHELL:-}" != "true" ]]; then
  echo "⚠️  Sepertinya ini bukan Cloud Shell. Workshop ini dirancang untuk Cloud Shell:"
  echo "    https://shell.cloud.google.com"
fi

PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ Project belum dipilih. Jalankan: gcloud config set project <PROJECT_ID>"
  exit 1
fi
echo "✅ Project aktif : $PROJECT_ID"
echo "✅ Akun          : $(gcloud config get-value account 2>/dev/null)"

echo "▶ Cek billing..."
gcloud services enable cloudbilling.googleapis.com --project "$PROJECT_ID" --quiet >/dev/null 2>&1 || true
BILLING="$(gcloud billing projects describe "$PROJECT_ID" --format='value(billingEnabled)' 2>/dev/null || echo unknown)"
case "$BILLING" in
  True|true) echo "✅ Billing aktif" ;;
  False|false)
    echo "❌ Billing BELUM aktif di project $PROJECT_ID."
    echo "   Aktifkan di: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    exit 1 ;;
  *) echo "⚠️  Tidak bisa mengecek billing (mungkin kurang izin). Pastikan billing aktif sebelum lanjut." ;;
esac

cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
sed -i.bak "s/isi-project-id-kamu/$PROJECT_ID/" "$ROOT_DIR/.env" && rm -f "$ROOT_DIR/.env.bak"
echo "✅ File .env dibuat:"
grep -v '^#' "$ROOT_DIR/.env" | grep -v '^$' | sed 's/^/   /'
