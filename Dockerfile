# ============================================================
# Dockerfile — GROK Coopetition Constitutional AGI Mesh
# Author: Alexandre Pedrosa
# Description: Multi-stage Docker build for the Constitutional
#              AI Interoperability Framework integrating GROK,
#              Copilot, Gemini, Claude, Meta AI, and GPT-5.
#
# Components:
#   - Python Flask web application (Constitutional Mesh UI + API)
#   - Shell scripts (Constitution, Bill of Rights, XAI Codex)
#   - Go symbolic metadata (GrokMeta.go)
#   - Blockchain simulation (AI Interoperability Ledger)
#
# Workflow: azure-container-webapp.yml
#   - Builds and pushes to ghcr.io
#   - Deploys to Azure Web App
# ============================================================

# ----------------------------------------------------------
# Stage 1: Go builder — compile GrokMeta symbolic metadata
# ----------------------------------------------------------
FROM golang:1.22-alpine AS go-builder

WORKDIR /build

# Copy Go source
COPY GrokMeta.go .

# Initialize Go module and build binary
# GrokMeta.go contains symbolic packages (no main); we create a placeholder
# to ensure the COPY --from stage always has a valid source
RUN go mod init grok-coopetition && \
    (go build -o /build/grokmeta GrokMeta.go 2>/dev/null || touch /build/grokmeta)

# ----------------------------------------------------------
# Stage 2: Python application — Constitutional AGI Mesh
# ----------------------------------------------------------
FROM python:3.12-slim

# Metadata labels
LABEL maintainer="Alexandre Pedrosa <alexan01xx@hotmail.com>"
LABEL org.opencontainers.image.title="GROK Coopetition - Constitutional AGI Mesh"
LABEL org.opencontainers.image.description="Constitutional AI Interoperability with Meta, Microsoft, Google, OpenAI, and Claude"
LABEL org.opencontainers.image.source="https://github.com/alexandrepedrosaai/GROK--Coopetition--GitHub-Copilot"
LABEL org.opencontainers.image.licenses="MIT"

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    FLASK_APP=app.py \
    FLASK_ENV=production

# Create non-root user for security
RUN groupadd -r meshai && useradd -r -g meshai -d /app -s /sbin/nologin meshai

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        tini && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .
COPY .github/workflows/main.py ./scripts/main.py

# Copy shell scripts (Constitutional Governance)
COPY constitution_mesh.sh ./scripts/
COPY billofrights_mesh.sh ./scripts/
COPY xai_codex_entry.sh ./scripts/

# Copy symbolic and governance files
COPY GrokMeta.go ./symbolic/
COPY "DAVO'S" ./symbolic/
COPY Code-High-Alalisys..yml ./symbolic/
COPY README.md .
COPY CODE_OF_CONDUCT.md .

# Copy Go binary from builder (if it was built)
COPY --from=go-builder /build/grokmeta ./bin/grokmeta

# Make shell scripts executable
RUN chmod +x ./scripts/*.sh 2>/dev/null || true

# Generate initial governance logs at build time
RUN bash ./scripts/constitution_mesh.sh > ./logs_constitution.txt 2>&1 || true && \
    bash ./scripts/billofrights_mesh.sh > ./logs_billofrights.txt 2>&1 || true && \
    bash ./scripts/xai_codex_entry.sh > ./logs_xai_codex.txt 2>&1 || true && \
    python3 ./scripts/main.py > ./logs_agimesh.txt 2>&1 || true

# Set ownership
RUN chown -R meshai:meshai /app

# Switch to non-root user
USER meshai

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Use tini as init system for proper signal handling
ENTRYPOINT ["tini", "--"]

# Run with gunicorn for production
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8080", \
     "--workers", "2", \
     "--threads", "4", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app:app"]
