FROM python:3.11-slim

# Install system dependencies (ffmpeg is required for audio transcription & handling)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Hugging Face Spaces standard: use non-root user (UID 1000)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    RAM_STORAGE_DIR=/tmp/voicemail_ephemeral \
    RAM_GREETINGS_DIR=/tmp/voicemail_greetings \
    ENVIRONMENT=production

WORKDIR /home/user/app

# Install Python dependencies
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Copy application code
COPY --chown=user . .

# Hugging Face Spaces requires exposing port 7860
EXPOSE 7860

# Start FastAPI server on port 7860
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]

