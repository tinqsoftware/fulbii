# ADR 0001: Mobile-First + Laravel API v1

> **ADR histórico vigente como decisión arquitectónica.** Para el estado de
> implementación consultar [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Status
Accepted

## Context
Current implementation is web-first (Blade) with limited API surface. Product direction requires Flutter as the main user channel for Android/iOS.

## Decision
- Adopt mobile-first architecture.
- Promote Laravel API v1 as the canonical application interface for user-facing flows.
- Keep web as superadmin/backoffice.

## Consequences
- API contract stability and versioning become mandatory.
- Auth/session, push flows, and domain operations must be exposed via API.
- Existing Blade flows can be retained for admin operations without blocking mobile delivery.
