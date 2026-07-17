# --- Stage 1: Build Dependencies ---
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# --- Stage 2: Final Runtime ---
FROM python:3.12-slim AS runner

WORKDIR /app

# Create non-root system user and set home directory
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser

# Copy installed site-packages from builder
COPY --from=builder /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

# Copy application source code (excluding test files via .dockerignore or selective copy)
COPY app ./app

# Ensure correct file permissions for non-root user
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 18080

# Serve with Gunicorn multi-workers in Production, defaulting command
CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:18080"]
