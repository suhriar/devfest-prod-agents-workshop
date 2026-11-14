FROM python:3.12-slim

# Jalankan sebagai user non-root (praktik production).
RUN useradd --create-home appuser
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --chown: ADK menulis session lokal ke kuliner_agent/.adk, jadi folder harus bisa ditulis appuser.
COPY --chown=appuser:appuser . .
USER appuser

ENV PORT=8080
CMD ["python", "main.py"]
