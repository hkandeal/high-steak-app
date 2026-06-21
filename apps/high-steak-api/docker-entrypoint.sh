#!/bin/sh
set -e

# Docker Compose: container starts as root so we can fix named-volume ownership (UID drift).
# Kubernetes: pod runs as UID 1001 (runAsUser) with fsGroup 1001 on the PVC — skip chown/su.
if [ "$(id -u)" = "0" ]; then
  chown -R spring:spring /app/uploads 2>/dev/null || true
  JAVA_BIN="$(command -v java)"
  exec su -s /bin/sh spring -c "exec \"${JAVA_BIN}\" -jar /app/app.jar"
fi

exec java -jar /app/app.jar
