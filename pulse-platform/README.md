# Pulse Marketing Platform

Enterprise-grade email marketing, automation, CRM, and reporting platform built to compete with ActiveCampaign, Mailchimp, Klaviyo, HubSpot, Braze, Brevo, and Iterable.

## Why Pulse

Pulse directly addresses common pain points in existing platforms:

- **Simpler UX** — Clean interface with guided onboarding, not enterprise bloat
- **Reporting-first** — Analytics and drill-downs are core product surfaces
- **Debuggable automations** — Per-contact decision logs explain every workflow step
- **Transparent deliverability** — Health scores, ISP/domain breakdowns, actionable guidance
- **Tenant isolation** — Workspace-scoped data with RBAC, audit logs, and API key scoping
- **Event-driven architecture** — Reliable outbox/inbox patterns for analytics at scale

## Architecture

```
Organization → Workspace → Brand → Resources
```

| Layer | Technology |
|-------|------------|
| Backend | .NET 9, ASP.NET Core Minimal APIs |
| Frontend | Next.js 15, React 19, TypeScript, Tailwind CSS |
| Database | PostgreSQL 16 |
| Analytics | ClickHouse (PostgreSQL fallback in Phase 1) |
| Cache | Redis 7 |
| Queue | Redpanda/Kafka |
| Storage | MinIO (S3-compatible) |

See [Technical Blueprint](docs/architecture/TECHNICAL_BLUEPRINT.md) and [ADRs](docs/adrs/) for detailed architecture decisions.

## Quick Start

### Prerequisites

- .NET 9 SDK
- Node.js 22+
- Docker & Docker Compose

### Local Development (Docker)

```bash
cd pulse-platform
docker compose up -d postgres redis
```

Run the API:

```bash
cd src/backend
dotnet run --project Pulse.Api
```

Run the frontend:

```bash
cd src/frontend
npm install
npm run dev
```

Open http://localhost:3000 and sign in with demo credentials:

- **Email:** admin@pulse.demo
- **Password:** PulseDemo123!

### Full Stack (Docker Compose)

```bash
docker compose up --build
```

Services:
- **Web:** http://localhost:3000
- **API:** http://localhost:8080
- **Swagger:** http://localhost:8080/swagger
- **PostgreSQL:** localhost:5432
- **Redis:** localhost:6379
- **ClickHouse:** localhost:8123

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ConnectionStrings__Default` | PostgreSQL connection string | See appsettings.json |
| `Jwt__Secret` | JWT signing key (min 32 chars) | dev secret |
| `Jwt__Issuer` | JWT issuer | pulse |
| `Jwt__Audience` | JWT audience | pulse-api |
| `AutoMigrate` | Run migrations on startup | true (dev) |
| `NEXT_PUBLIC_API_URL` | Frontend API base URL | http://localhost:8080 |

## API Overview

Base URL: `/api/v1`

| Endpoint | Description |
|----------|-------------|
| `POST /auth/register` | Create org, workspace, and admin user |
| `POST /auth/login` | Authenticate and receive JWT |
| `GET /contacts` | List contacts (cursor pagination) |
| `POST /contacts` | Create contact |
| `POST /contacts/{id}/events` | Track contact event |
| `POST /events` | Ingest behavioral event |
| `GET /campaigns` | List campaigns |
| `POST /campaigns` | Create campaign |
| `GET /reports/executive` | Executive dashboard metrics |

Authentication: `Authorization: Bearer <token>` or `X-Api-Key: <key>`

## Project Structure

```
pulse-platform/
├── docs/
│   ├── architecture/     # Technical blueprint
│   └── adrs/             # Architecture decision records
├── src/
│   ├── backend/          # .NET modular monolith
│   │   ├── Pulse.Domain/
│   │   ├── Pulse.Application/
│   │   ├── Pulse.Infrastructure/
│   │   ├── Pulse.Api/
│   │   └── Pulse.Workers/
│   └── frontend/         # Next.js web app
├── infrastructure/
│   ├── docker/           # Dockerfiles, ClickHouse schema
│   ├── kubernetes/       # K8s manifests
│   └── terraform/        # IaC skeleton
├── docker-compose.yml
└── .github/workflows/    # CI/CD
```

## Testing

```bash
# Backend unit tests
cd src/backend
dotnet test

# Frontend lint + build
cd src/frontend
npm run lint && npm run build
```

## Deployment

### Kubernetes

```bash
kubectl apply -f infrastructure/kubernetes/
```

### Terraform (AWS skeleton)

```bash
cd infrastructure/terraform
terraform init
terraform plan -var="db_password=YOUR_PASSWORD"
```

## Phase Roadmap

- [x] Phase 1: Multi-tenant foundation, contacts, campaigns, event pipeline, reporting schema
- [ ] Phase 2: Visual automation builder, MJML email editor, deliverability platform
- [ ] Phase 3: Enterprise SSO/SAML/SCIM, AI features, warehouse sync
- [ ] Phase 4: Full ecommerce integrations, predictive segments, send-time optimization

## License

Proprietary — All rights reserved.
