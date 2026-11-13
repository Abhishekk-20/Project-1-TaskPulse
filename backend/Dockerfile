FROM alpine:3.24.4 AS rds-certs
RUN apk add --no-cache ca-certificates \
    && wget -qO /rds-global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app
COPY --from=rds-certs /rds-global-bundle.pem /etc/ssl/certs/rds-global-bundle.pem
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --no-create-home --home-dir /app --shell /usr/sbin/nologin app

COPY --chown=app:app . .
USER app:app

EXPOSE 5000
CMD ["gunicorn", "--bind=0.0.0.0:5000", "--workers=2", "--threads=4", "--timeout=30", "--access-logfile=-", "--error-logfile=-", "app:app"]
