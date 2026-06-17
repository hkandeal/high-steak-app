# Kubernetes deployment

High Steak runs on Kubernetes as **2 workloads** (API + web) behind **Kong ingress** on `steaks.apps.hossam.io`. All workloads deploy into the shared **`apps`** namespace (same as `db-apps-mysql-svc`).

## Layout

```
helm/high-steak/              # Source of truth (Helm chart)
.k8s/deployment-manifests/  # Legacy flat YAML (kubectl apply)
apps/high-steak-web/Dockerfile.prod  # Production web image (nginx)
```

## Public URLs

| Purpose | URL |
|---------|-----|
| Web | https://steaks.apps.hossam.io/ |
| API | https://steaks.apps.hossam.io/api |
| Health | https://steaks.apps.hossam.io/api/health |

## Prerequisites

1. **DNS:** `steaks.apps.hossam.io` → Kong load balancer
2. **cert-manager:** ClusterIssuer `letsencrypt-prod` (same as other apps)
3. **MySQL:** Database `high_steak` and user `high_steak` on `db-apps-mysql-svc` (same `apps` namespace)
4. **Secrets** (not committed):

### Shared DB secret (already in cluster)

`mysql-secrets` in `apps` — the API reads the app user password via:

| Secret key | Maps to env |
|------------|-------------|
| `mysql-user-password` | `SPRING_DATASOURCE_PASSWORD` |

Username and JDBC URL come from ConfigMap (`SPRING_DATASOURCE_USERNAME=high_steak`).

### App secret (create before first deploy)

`high-steak-secret` — JWT signing + admin bootstrap on first startup:

```bash
kubectl create secret generic high-steak-secret -n apps \
  --from-literal=JWT_SECRET='...min-32-chars...' \
  --from-literal=BOOTSTRAP_ADMIN_USERNAME='admin' \
  --from-literal=BOOTSTRAP_ADMIN_PASSWORD='...' \
  --from-literal=BOOTSTRAP_ADMIN_EMAIL='admin@high-steak.local' \
  --from-literal=BOOTSTRAP_ADMIN_DISPLAY_NAME='System Admin'
```

`BOOTSTRAP_ADMIN_ENABLED=true` is set in ConfigMap. Bootstrap runs only if no admin user exists yet.

## Build and push images

```bash
# API
docker build -t hossamgbm/high-steak-api:1 apps/high-steak-api
docker push hossamgbm/high-steak-api:1

# Web (VITE_API_URL baked at build time)
docker build -t hossamgbm/high-steak-web:1 \
  --build-arg VITE_API_URL=https://steaks.apps.hossam.io/api \
  -f apps/high-steak-web/Dockerfile.prod apps/high-steak-web
docker push hossamgbm/high-steak-web:1
```

Update image tags in `helm/high-steak/values.yaml` before deploy.


## Argo CD (GitOps)

Apply the Application manifest once (registers the app with Argo CD; does not replace manual secret creation):

```bash
kubectl apply -f .argocd/Application.yaml
```

Argo CD syncs `helm/high-steak` from `main` into the **`apps`** namespace with automated prune and self-heal.

Ensure `mysql-secrets` and `high-steak-secret` exist in `apps` before the first sync, or the API pod will fail until secrets are present.

### Upload size

Per-image limit defaults to **3 MB**. Configure in `helm/high-steak/values.yaml`:

```yaml
uploads:
  maxImageSizeMb: 3
  maxImagesPerPost: 10
```

These map to `APP_MAX_IMAGE_SIZE_MB`, multipart limits, and (for local Docker) the same vars in `docker-compose.yml`. Rebuild the **web** image if you change the client hint (`VITE_MAX_IMAGE_SIZE_MB`).

## Deploy with Helm (recommended)

```bash
helm upgrade --install high-steak ./helm/high-steak \
  -n apps
```

Dry-run / render manifests locally:

```bash
helm template high-steak ./helm/high-steak -n apps
```

## Deploy with raw manifests (legacy)

```bash
kubectl apply -f .k8s/deployment-manifests/
```

Ensure `mysql-secrets` and `high-steak-secret` exist in `apps` before applying.

## Ingress routing

| Path | Backend |
|------|---------|
| `/api` (prefix) | API service → pod :8080 |
| `/` (prefix) | Web service → nginx :80 |

`konghq.com/strip-path: "false"` — the API expects the `/api` context path.

## Troubleshooting

### `Failed to store image` on post upload

The API writes to `/app/uploads` (PVC). The container runs as non-root user `spring` (UID/GID **1001**). The chart sets `podSecurityContext.fsGroup: 1001` so the volume is writable.

After changing the API `Dockerfile` or deployment security context, **rebuild and redeploy the API image**, then restart the pod:

```bash
argocd app sync high-steak --grpc-web
kubectl rollout restart deploy/high-steak-api -n apps
```

## Mobile clients

```bash
flutter run --dart-define=API_BASE_URL=https://steaks.apps.hossam.io/api
```


## CI/CD (GitHub Actions)

Two workflows (same pattern as idea-web-craft):

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `app build workflow.yml` | Push to `main` / `master` (api/web paths) | Builds `high-steak-web` + `high-steak-api`, pushes to Docker Hub, dispatches infra workflow |
| `app infra update workflow.yml` | `repository_dispatch` | Bumps `image.tag` and `apiImage.tag` in `helm/high-steak/values.yaml` on `main` |

**Required GitHub repo secrets:**

| Secret | Purpose |
|--------|---------|
| `API_TOKEN_GITHUB` | Build number + repository dispatch |
| `DOCKERHUB_USERNAME` | Docker Hub login |
| `DOCKERHUB_PASSWORD` | Docker Hub login |
| `GITOPS_SLACK_API` | Slack notifications (optional) |

Images: `hossamgbm/high-steak-web:<build>` and `hossamgbm/high-steak-api:<build>`.

After infra workflow commits new tags, Argo CD syncs the updated Helm values to the cluster.

## Local development

Docker Compose remains the local workflow (`npm run docker:up`). Kubernetes manifests are for cluster deployment only.
