# ADR 004: Automation Engine Design

## Status
Accepted (Phase 1 foundation; Temporal in Phase 2)

## Context
Automations require durable, debuggable, per-contact state with retries, idempotency, and simulation.

## Decision
**Phase 1**: Custom durable workflow engine:
- `AutomationDefinition` (versioned JSON graph)
- `AutomationEnrollment` (per-contact state machine)
- `AutomationStepLog` (debug trail: entered, skipped, exited, reason)
- Worker polls enrollments, executes steps, publishes events

**Phase 2**: Migrate to Temporal for complex long-running workflows.

Key design elements:
- **Idempotency**: Step execution keyed by `(enrollment_id, step_id, attempt)`
- **Dead-letter queue**: Failed steps after max retries
- **Simulation mode**: Dry-run against segment sample without side effects
- **Debug mode**: Full decision log per contact with condition evaluation results

## Consequences
- **Positive**: Full control over debug UX and per-contact explainability
- **Positive**: No Temporal dependency in Phase 1
- **Negative**: Must implement retry/DLQ ourselves initially
- **Mitigation**: Design interfaces compatible with Temporal workflow activities
