# Automation Engine Design

## Overview

The Pulse automation engine provides durable, debuggable, per-contact workflow execution with visual journey building, simulation, and rollback support.

## Core Concepts

### AutomationDefinition (Versioned Graph)

```json
{
  "id": "uuid",
  "version": 3,
  "name": "Welcome Series",
  "status": "published",
  "trigger": {
    "type": "contact.tagged",
    "config": { "tag": "new-subscriber" }
  },
  "steps": [
    { "id": "s1", "type": "send_email", "config": { "campaignId": "..." } },
    { "id": "s2", "type": "wait", "config": { "duration": "2d" } },
    { "id": "s3", "type": "condition", "config": { "field": "engagement_score", "op": "gte", "value": 5 },
      "branches": { "true": "s4", "false": "s5" } },
    { "id": "s4", "type": "goal", "config": { "name": "engaged" } },
    { "id": "s5", "type": "send_email", "config": { "campaignId": "..." } }
  ],
  "exitConditions": [
    { "type": "unsubscribed" },
    { "type": "goal_reached", "goalId": "s4" }
  ]
}
```

### AutomationEnrollment (Per-Contact State)

| Field | Description |
|-------|-------------|
| contact_id | The enrolled contact |
| automation_id | Which automation |
| version | Definition version at enrollment |
| current_step_id | Current position in graph |
| status | active, waiting, completed, exited, failed |
| entered_at | When contact entered |
| next_action_at | When to process next step (for waits) |
| context_json | Runtime variables and branch decisions |

### AutomationStepLog (Debug Trail)

Every step execution creates a log entry:

```json
{
  "enrollment_id": "uuid",
  "step_id": "s3",
  "action": "evaluated",
  "result": "skipped",
  "reason": "Condition not met: engagement_score (2) < 5",
  "evaluated_at": "2026-07-03T14:00:00Z"
}
```

## Step Types

| Type | Description |
|------|-------------|
| trigger | Entry point (tag, event, segment, date, webhook) |
| send_email | Send campaign email |
| wait | Delay (duration, until date, until event) |
| condition | Branch on contact/event/segment criteria |
| goal | Mark conversion point |
| update_contact | Modify fields, tags, lists |
| webhook | HTTP call with signed payload |
| api_call | Internal API action |
| lead_score | Adjust lead score |
| crm_update | Update deal/task (if CRM enabled) |
| suppression_check | Verify contact can receive email |
| exit | Remove from automation |

## Execution Model

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Trigger    │────▶│  Enrollment  │────▶│  Step Exec  │
│  Evaluator  │     │  Created     │     │  Worker     │
└─────────────┘     └──────────────┘     └──────┬──────┘
                                                 │
                    ┌──────────────┐     ┌──────▼──────┐
                    │  Step Log    │◀────│  Next Step  │
                    │  (debug)     │     │  Resolver   │
                    └──────────────┘     └─────────────┘
```

1. **Trigger Evaluator** — Polls for new trigger matches (events, segment changes)
2. **Enrollment Created** — Idempotent: `(automation_id, contact_id)` unique
3. **Step Executor** — Processes enrollments where `next_action_at <= now()`
4. **Step Log** — Records decision with full condition evaluation
5. **Next Step Resolver** — Follows graph edges, handles branches

## Reliability

- **Idempotency key:** `(enrollment_id, step_id, attempt_number)`
- **Retry policy:** Exponential backoff, max 5 attempts
- **Dead-letter queue:** Failed steps after max retries
- **Circuit breaker:** Per-step-type failure thresholds
- **Safe publish:** Draft → Simulate → Review → Publish pipeline

## Simulation Mode

Before publishing, run against a sample of contacts:

1. Select segment sample (max 100 contacts)
2. Execute all steps except side effects (no sends, no webhooks)
3. Generate report: "847 contacts would receive email, 153 would branch to path B"
4. Show per-contact preview of path taken

## Debug Mode (Production)

For any enrolled contact, show:
- Full step log with timestamps
- Condition evaluation details (field values, operators, results)
- Why contact did/didn't enter (trigger evaluation)
- Current state and next scheduled action

## Phase 2: Temporal Migration

Interfaces designed for Temporal workflow activities:
- `IAutomationWorkflow` → Temporal Workflow
- `IStepActivity` → Temporal Activity
- Enrollment state → Temporal workflow state

Migration path: new automations use Temporal; existing enrollments complete on custom engine.
