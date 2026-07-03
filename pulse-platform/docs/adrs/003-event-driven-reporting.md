# ADR 003: Event-Driven Reporting Pipeline

## Status
Accepted

## Context
Reporting must handle billions of events. Transactional PostgreSQL is unsuitable for analytical queries at scale.

## Decision
Implement **CQRS with dual write path**:
1. Domain events persisted to PostgreSQL outbox (same transaction as state change)
2. Outbox relay publishes to Kafka
3. Analytics consumer writes to ClickHouse fact tables
4. Inbox pattern prevents duplicate processing

Near-real-time operational metrics served from ClickHouse materialized views.
Historical batch OLAP uses partitioned ClickHouse tables.

## Consequences
- **Positive**: Transactional consistency + analytical scale
- **Positive**: Replayable events for backfill and debugging
- **Negative**: Eventual consistency for dashboards (seconds, not instant)
- **Mitigation**: Operational metrics cache in Redis; "last updated" timestamps on dashboards
