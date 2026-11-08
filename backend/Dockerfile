FROM python:3.11-slim

# Install system dependencies (ffmpeg is required for audio transcription & handling)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    RAM_STORAGE_DIR=/tmp/voicemail_ephemeral \
    RAM_GREETINGS_DIR=/tmp/voicemail_greetings \
    ENVIRONMENT=production \
    PORT=10000

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Copy application code
COPY . .

# Render exposes and scans port 10000
EXPOSE 10000

# Start FastAPI server dynamically binding to Render's $PORT
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-10000}"]
