#!/usr/bin/env bash
# Langkah 9: hapus semua resource supaya tidak ada biaya berjalan.
source "$(dirname "$0")/_env.sh"

read -r -p "Hapus service $SERVICE_NAME, service account, dan image di project $GOOGLE_CLOUD_PROJECT? [y/N] " yn
[[ "$yn" == "y" || "$yn" == "Y" ]] || { echo "Dibatalkan."; exit 0; }

gcloud run services delete "$SERVICE_NAME" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" --quiet || true
gcloud iam service-accounts delete "$SA_EMAIL" --project "$GOOGLE_CLOUD_PROJECT" --quiet || true
# Repository yang otomatis dibuat oleh `gcloud run deploy --source`
gcloud artifacts repositories delete cloud-run-source-deploy --location "$REGION" --project "$GOOGLE_CLOUD_PROJECT" --quiet || true
echo "✅ Cleanup selesai."
