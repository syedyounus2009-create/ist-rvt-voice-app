# IST-RVT Backend — Production Dockerfile
# Optimized for Railway, Render, AWS ECS, Azure Container Apps

FROM python:3.11-slim

# System deps for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu \
    -r requirements.txt

# Copy app code
COPY . .

# Create upload directory
RUN mkdir -p /app/uploads

# Expose port (Railway uses PORT env var)
EXPOSE ${PORT:-8000}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT:-8000}/health')" || exit 1

# Run with uvicorn
CMD ["python", "-m", "uvicorn", "main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--ws-ping-interval", "20", \
     "--ws-ping-timeout", "30"]
