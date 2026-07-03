# ADR 001: Modular Monolith First

## Status
Accepted

## Context
Pulse must ship quickly while supporting enterprise scale. Microservices from day one add operational complexity without proven extraction boundaries.

## Decision
Build as a **modular monolith** with strict bounded contexts:
- Separate projects per layer (Domain, Application, Infrastructure, Api, Workers)
- No cross-context direct database access
- Domain events for cross-context communication via outbox pattern
- Each module owns its tables and migrations

## Consequences
- **Positive**: Faster development, simpler deployment, easier debugging
- **Positive**: Clear extraction path when a context needs independent scaling
- **Negative**: Requires discipline to prevent coupling
- **Mitigation**: Architecture tests, code review guidelines, bounded context folders
