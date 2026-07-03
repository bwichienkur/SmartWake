# ADR 002: Workspace-Level Tenant Isolation

## Status
Accepted

## Context
Enterprise customers require strong data isolation. Organization-level billing must coexist with workspace-level operational boundaries.

## Decision
Use **workspace_id** as the tenant isolation key:
- All tenant-scoped entities include `workspace_id`
- PostgreSQL Row-Level Security policies enforce isolation
- JWT and API key tokens carry `workspace_id` claim
- Middleware validates tenant context on every request

Hierarchy: Organization → Workspace → Brand

## Consequences
- **Positive**: Clean billing (org) vs operations (workspace) separation
- **Positive**: Supports agencies managing multiple client workspaces
- **Negative**: Users in multiple workspaces need workspace switcher UX
- **Mitigation**: Workspace membership table with role assignments per workspace
