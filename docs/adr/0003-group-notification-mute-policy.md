# ADR 0003: Per-Group Notification Mute Policy

> **ADR histórico vigente como decisión arquitectónica.** Para el estado de
> implementación consultar [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Status
Accepted

## Context
Users need notification control by group, while preserving in-app discoverability and reducing push fatigue.

## Decision
- Add per-user, per-group push notification preference:
  - `always_on`
  - `mute_24h`
  - `mute_1w`
  - `mute_forever`
- Mute affects push only.
- No critical bypass when muted.

## Consequences
- Notification workers must evaluate mute preference before enqueue/send.
- UX must expose group-level preference controls.
- Auditability of preference updates is required.
