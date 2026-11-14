#!/usr/bin/env bash
# Langkah 5 (cara manual): deploy agent ke Cloud Run dari source code.
# Cloud Build akan membangun image dari Dockerfile, lalu Cloud Run menjalankannya.
#
# Kenapa --no-cpu-throttling? Trace dikirim ke Cloud Trace di background SETELAH
# response selesai. Tanpa flag ini CPU dibekukan setelah response -> trace bisa hilang.
# Kenapa --session-affinity? Supaya chat dari browser yang sama diarahkan ke instance yang sama.
source "$(dirname "$0")/_env.sh"
cd "$ROOT_DIR"

gcloud run deploy "$SERVICE_NAME" \
  --project "$GOOGLE_CLOUD_PROJECT" \
  --source . \
  --region "$REGION" \
  --service-account "$SA_EMAIL" \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,GOOGLE_CLOUD_LOCATION=$GOOGLE_CLOUD_LOCATION,GOOGLE_GENAI_USE_VERTEXAI=TRUE,MODEL=$MODEL,TRACE_TO_CLOUD=true" \
  --memory 1Gi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 3 \
  --concurrency 20 \
  --timeout 300 \
  --cpu-boost \
  --no-cpu-throttling \
  --session-affinity \
  --allow-unauthenticated \
  --labels "app=kuliner-agent,env=workshop" \
  --quiet

URL=$(gcloud run services describe "$SERVICE_NAME" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" --format="value(status.url)")
echo
echo "✅ Agent live di: $URL"
echo "   Dev UI       : $URL/dev-ui/"
echo "   Health check : $URL/healthz"
