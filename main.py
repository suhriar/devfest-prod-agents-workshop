"""Entry point FastAPI untuk Cloud Run.

`get_fast_api_app` dari ADK otomatis menyediakan:
  - REST API (/list-apps, /run, /run_sse, sessions, dll)
  - Dev UI (kalau web=True)
  - Export trace OpenTelemetry ke Cloud Trace (kalau trace_to_cloud=True)
"""

import os

import uvicorn
from google.adk.cli.fast_api import get_fast_api_app

AGENT_DIR = os.path.dirname(os.path.abspath(__file__))

app = get_fast_api_app(
    agents_dir=AGENT_DIR,
    web=os.getenv("SERVE_WEB_UI", "true").lower() == "true",
    # Kirim semua span (agent, LLM call, tool call) ke Cloud Trace.
    # Butuh env GOOGLE_CLOUD_PROJECT terisi.
    trace_to_cloud=os.getenv("TRACE_TO_CLOUD", "true").lower() == "true",
    # Buat session otomatis kalau belum ada, jadi client cukup memanggil /run.
    auto_create_session=True,
)


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


if __name__ == "__main__":
    # Cloud Run menyuntikkan $PORT dan mewajibkan listen di 0.0.0.0.
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
