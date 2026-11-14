#!/usr/bin/env bash
# Langkah 6: kirim beberapa pertanyaan ke agent supaya muncul trace di Cloud Trace.
source "$(dirname "$0")/_env.sh"

URL="${1:-$(gcloud run services describe "$SERVICE_NAME" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" --format='value(status.url)' 2>/dev/null)}"
if [[ -z "$URL" ]]; then
  echo "❌ Service $SERVICE_NAME belum ada di region $REGION. Deploy dulu (Langkah 5)."
  exit 1
fi
APP="kuliner_agent"
USER_ID="peserta-workshop"
SESSION_ID="sesi-$(date +%s)"   # session dibuat otomatis oleh server (auto_create_session)

echo "▶ Target : $URL"
echo "▶ Session: $SESSION_ID"

ask() {
  echo -e "\n🙋 $1"
  local body
  body=$(printf '{"app_name":"%s","user_id":"%s","session_id":"%s","new_message":{"role":"user","parts":[{"text":"%s"}]}}' \
    "$APP" "$USER_ID" "$SESSION_ID" "$1")
  curl -s --max-time 120 -X POST "$URL/run" -H "Content-Type: application/json" -d "$body" | python3 -c '
import sys, json
raw = sys.stdin.read()
try:
    events = json.loads(raw)
except ValueError:
    events = None
if not isinstance(events, list):
    print("⚠️  Respons tidak terduga:", raw[:300])
    sys.exit(0)
texts = [p["text"] for e in events for p in ((e.get("content") or {}).get("parts") or []) if p.get("text")]
print("🤖", texts[-1] if texts else "(tidak ada jawaban teks)")'
}

ask "Rekomendasi kuliner di Surabaya pusat dong"
ask "Antrian di Rawon Setan berapa lama?"
ask "Kalau total makan 150000 buat 4 orang, patungan per orang berapa?"
ask "Ada rekomendasi di area utara?"
ask "Cek antrian Bebek Sinjay Kenjeran sama Sate Klopo Ondomohen"

echo -e "\n✅ Selesai. Tunggu ±1 menit, lalu buka Trace Explorer:"
echo "   https://console.cloud.google.com/traces/explorer?project=$GOOGLE_CLOUD_PROJECT"
