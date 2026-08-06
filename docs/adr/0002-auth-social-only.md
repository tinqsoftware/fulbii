# ADR 0002: Social Authentication Only (Google/Apple)

> **ADR histórico vigente como decisión arquitectónica.** Para el estado de
> implementación consultar [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Status
Accepted

## Context
Product requires low-friction onboarding and consistent mobile identity flows.

## Decision
- Primary mobile auth methods are Google and Apple sign-in.
- Onboarding requires `nickname` and `sexo` after first login.
- Email/password is not part of mobile UX.

## Consequences
- Provider identity fields and token verification pipeline are required.
- Existing password flows can remain only for operational compatibility where needed.
- Fraud/abuse controls should be attached to provider-linked identity.
