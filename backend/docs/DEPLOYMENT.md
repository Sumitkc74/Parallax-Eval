# Deployment & Operations Guide — ParallaxLM

## 1. Quickstart with Docker Compose

ParallaxLM includes a production-ready `docker-compose.yml` orchestrating PostgreSQL 16 and the FastAPI application server.

```bash
# 1. Clone repository and navigate to root
cd Parallax-Eval

# 2. Copy environment template
cp .env.example .env

# 3. Start services in background
docker compose up -d --build

# 4. Verify service readiness
curl -f http://localhost:8000/ready
```

---

## 2. Environment Variables Reference

| Variable | Default Value | Description |
|---|---|---|
| `DATABASE_URL` | `sqlite+aiosqlite:///./parallax_eval.db` | Async SQLAlchemy database URI (`postgresql+asyncpg://...` in production). |
| `ENVIRONMENT` | `development` | Environment mode (`development`, `production`, `testing`). |
| `LOG_LEVEL` | `INFO` | Logging threshold (`DEBUG`, `INFO`, `WARNING`, `ERROR`). |
| `LOG_FORMAT` | `text` | Log format: `text` for readable console, `json` for structured log shippers. |
| `USE_MOCK_LLM` | `true` | When `true`, uses offline mock provider (0 paid tokens). Set to `false` for live LLM providers. |
| `OPENAI_API_KEY` | `""` | API key for OpenAI-compatible providers. |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | Base URL for LLM provider endpoint. |
| `MAX_CONCURRENT_EVALS`| `3` | Worker concurrency limit per experiment run. |
| `LLM_TIMEOUT_SECONDS` | `30.0` | Timeout threshold for outbound model provider calls. |
| `LLM_MAX_RETRIES` | `3` | Max retry attempts with exponential backoff on provider errors. |
| `CORS_ORIGINS` | `["*"]` | Allowed CORS origins for Flutter web/mobile API access. |

---

## 3. Container Orchestration & Probes

### 3.1 Kubernetes Probe Configuration
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 3.2 Docker Compose Healthchecks
```yaml
healthcheck:
  test: ["CMD-SHELL", "python -c 'import urllib.request; urllib.request.urlopen(\"http://localhost:8000/ready\")'"]
  interval: 10s
  timeout: 5s
  retries: 3
```

---

## 4. Production Hardening & Operational Best Practices

1. **Structured JSON Logs**: In production, set `LOG_FORMAT=json`. Every log line includes `timestamp`, `level`, `request_id`, `message`, and `location` for seamless ingestion into Prometheus/Loki or Elastic/Logstash.
2. **Readiness Verification**: The `/ready` probe pings PostgreSQL via `SELECT 1`. If DB connectivity drops, load balancers automatically drain traffic away from the instance.
3. **Graceful Worker Recovery**: The Worker Supervisor automatically sweeps orphaned `RUNNING` tasks on startup and updates them to `FAILED` with failure recovery logs.
4. **Zero-Leak Secrets**: API keys are injected solely via environment variables and never logged or serialized into response payloads.

