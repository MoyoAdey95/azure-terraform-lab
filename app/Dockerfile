# Container Apps has no arm64 support, so the image is built for linux/amd64
# even on an Apple Silicon Mac:
#   docker buildx build --platform linux/amd64 -t azure-lab-api:dev app

# build stage: install deps into an isolated prefix
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# runtime stage: copy only what we need
FROM python:3.12-slim

# Base images often ship Debian packages with known CVEs that Debian has
# already fixed, because the upstream python image has not been rebuilt yet.
# Upgrading at build time pulls those fixes in. The trade-off is that two
# builds on different days can differ.
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1001 appuser

WORKDIR /app
COPY --from=builder /install /usr/local

# COPY keeps the file mode from the build host and makes root the owner. A
# source file with mode 600 would be unreadable by appuser, which is what
# happened in k8s-observability-lab. --chown makes appuser the owner.
COPY --chown=appuser:appuser main.py .

USER appuser

ENV PORT=8080
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
