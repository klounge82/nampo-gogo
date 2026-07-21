# --- Stage 1: Build Dependencies ---
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# --- Stage 2: Final Runtime ---
FROM python:3.12-slim AS runner

WORKDIR /app

# Set writeable home directory for non-root user
ENV HOME=/tmp

# Copy installed site-packages from builder with numeric ownership
COPY --from=builder --chown=10001:10001 /root/.local /tmp/.local
ENV PATH=/tmp/.local/bin:$PATH

# Copy application source code and migrations config
COPY --chown=10001:10001 app ./app
COPY --chown=10001:10001 alembic.ini ./alembic.ini
COPY --chown=10001:10001 migrations ./migrations
COPY --chown=10001:10001 scripts ./scripts

# Ensure correct file permissions for non-root user
RUN chown -R 10001:10001 /app


USER 10001:10001

EXPOSE 18080

# Serve with Gunicorn multi-workers in Production, defaulting command
CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:18080"]
