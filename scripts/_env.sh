# Helper: memuat variabel dari .env (dipakai oleh script lain).
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "❌ File .env belum ada. Jalankan: cp .env.example .env  lalu isi GOOGLE_CLOUD_PROJECT"
  exit 1
fi
set -a; source "$ROOT_DIR/.env"; set +a
if [[ "${GOOGLE_CLOUD_PROJECT:-}" == "" || "$GOOGLE_CLOUD_PROJECT" == "isi-project-id-kamu" ]]; then
  echo "❌ GOOGLE_CLOUD_PROJECT di .env belum diisi."
  exit 1
fi
SA_NAME="${SERVICE_NAME}-sa"
SA_EMAIL="${SA_NAME}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"
