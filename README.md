# Enterprise SMS Platform

A production-grade, compliance-first SMS messaging platform built with **.NET 9**, **React**, and **PostgreSQL**. Designed to address the pain points of incumbent providers (Twilio, Vonage, MessageBird) with built-in compliance, AI intelligence, multi-provider failover, and transparent architecture.

## Market Research & Problem Statement

Analysis of leading SMS platforms reveals recurring enterprise pain points:

| Pain Point | Incumbent Gap | Our Solution |
|------------|---------------|--------------|
| **Compliance burden** | TCPA/CTIA checks left to application code; 10DLC registration takes weeks | Compliance engine at the router layer: opt-out, quiet hours, content scanning |
| **Unpredictable costs** | Hidden surcharges, carrier fees, premium support tiers | Per-message cost tracking, provider abstraction for competitive routing |
| **Silent carrier filtering** | Messages blocked without clear signals | AI compliance risk scoring + content optimization before send |
| **Poor observability** | Basic delivery logs; carrier detail requires support tickets | Full message lifecycle audit trail with typed event codes |
| **Vendor lock-in** | Migrating providers requires re-registering campaigns, porting numbers | Provider abstraction with automatic failover (Twilio → Mock → future Vonage/Plivo) |
| **Limited AI** | AI features siloed in premium tiers or separate products | Built-in sentiment analysis, smart routing, content studio |
| **Scale friction** | Rate limits and queue management are DIY | RabbitMQ-backed async pipeline with worker service |

## Architecture

Clean Architecture with clear separation of concerns:

```
src/
├── SmsPlatform.Domain/          # Entities, enums, business rules
├── SmsPlatform.Application/     # Use cases, interfaces, DTOs
├── SmsPlatform.Infrastructure/  # EF Core, Redis-ready, RabbitMQ, Twilio, AI
├── SmsPlatform.Api/             # REST API, auth, rate limiting, Swagger
└── SmsPlatform.Worker/          # Scheduled messages + queue consumer
frontend/                        # React enterprise dashboard
```

### Key Design Decisions

- **Compliance at the router** — Every outbound message passes through opt-out lookup, quiet-hour gating, spam detection, and rate limits before dispatch (addresses TCPA liability)
- **Async message pipeline** — API accepts messages instantly; workers process via RabbitMQ (or in-process for dev) for fault tolerance
- **Provider failover** — Automatic routing with health tracking; unhealthy providers circuit-break after consecutive failures
- **AI layer** — Heuristic engine by default; optional OpenAI integration for advanced compliance analysis
- **Multi-tenant** — Organization-scoped API keys with SHA-256 hashing
- **Idempotency** — Duplicate send prevention via idempotency keys

## Features

### Messaging
- Send/receive SMS with delivery status webhooks
- Message intent classification (OTP, Transactional, Marketing, etc.)
- Priority-based routing for inbound messages
- Idempotent send API

### Compliance (TCPA / CTIA / 10DLC-ready)
- Automatic STOP/UNSUBSCRIBE/END keyword processing
- Quiet hours enforcement for marketing (8 PM – 8 AM recipient local time)
- Spam content detection with review queue
- Campaign registry tracking
- Compliance dashboard with block reason analytics

### AI Intelligence
- **Outbound**: Compliance risk scoring, content optimization (auto-add opt-out language)
- **Inbound**: Sentiment analysis, urgency detection, priority routing
- **AI Studio**: Pre-send content analysis with issue detection and suggestions
- Optional OpenAI/Azure OpenAI backend

### Enterprise Operations
- Provider health monitoring with success rates
- Rate limiting per organization (100 req/min default)
- Structured audit events per message
- Correlation ID tracing
- Swagger/OpenAPI documentation

## Quick Start

### Prerequisites
- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- [Node.js 18+](https://nodejs.org/)
- PostgreSQL 16+ (optional — SQLite used by default for dev)
- RabbitMQ (optional — in-process queue used when not configured)

### 1. Clone and configure

```bash
git clone <repo-url>
cd sms-application
cp .env.example .env
```

### 2. Run the API

```bash
export PATH="$HOME/.dotnet:$PATH"
cd src/SmsPlatform.Api
dotnet run
```

On first run, a demo API key is printed to the console. Copy it.

### 3. Run the dashboard

```bash
cd frontend
cp .env.example .env
# Set VITE_API_KEY to your demo API key
npm install
npm run dev
```

- **API**: http://localhost:5000 (or port shown in console)
- **Swagger**: http://localhost:5000/swagger
- **Dashboard**: http://localhost:5173

### 4. Send a test message

```bash
curl -X POST http://localhost:5000/api/messages/send \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -d '{"to": "+15559876543", "body": "Hello from Enterprise SMS Platform!", "enableAiOptimization": true}'
```

## Configuration

| Variable | Description |
|----------|-------------|
| `UseSqlite` | `true` for SQLite (dev), `false` for PostgreSQL |
| `ConnectionStrings:DefaultConnection` | PostgreSQL connection string |
| `Twilio:AccountSid` | Twilio account SID (optional — mock provider used if empty) |
| `Twilio:AuthToken` | Twilio auth token |
| `Twilio:FromNumber` | Sender phone number |
| `Intelligence:Provider` | `Heuristic` or `OpenAI` |
| `Intelligence:OpenAiApiKey` | OpenAI API key for advanced AI |
| `RabbitMQ:Host` | RabbitMQ host (empty = in-process queue) |

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/messages/send` | Queue outbound SMS |
| GET | `/api/messages` | List messages (paginated) |
| GET | `/api/analytics/stats` | Dashboard statistics |
| GET | `/api/analytics/compliance` | Compliance report |
| GET | `/api/analytics/providers` | Provider health status |
| POST | `/api/ai/analyze` | AI content analysis |
| GET/POST/DELETE | `/api/contacts` | Contact management |
| POST | `/api/webhooks/twilio/incoming` | Inbound SMS webhook |
| POST | `/api/webhooks/twilio/status` | Delivery status callback |

All endpoints require `X-Api-Key` header except webhooks and health checks.

## Docker (Production)

```bash
docker compose up --build
```

Services: PostgreSQL, Redis, RabbitMQ, API, Worker, Frontend.

## Tests

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet test
```

## Scaling Considerations

- **Horizontal API scaling** — Stateless API behind load balancer
- **Worker scaling** — Multiple worker instances consume RabbitMQ queue
- **Database** — PostgreSQL with read replicas for analytics
- **Caching** — Redis integration point for rate limits and opt-out lookups
- **Provider pool** — Add Vonage/Plivo adapters implementing `ISmsProvider`

## License

MIT
