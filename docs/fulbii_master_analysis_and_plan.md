# Fulbii Master Analysis and Plan

> **Histórico / supersedido.** Es un análisis de planificación previo. Para el
> estado ejecutable actual consultar [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## 1) Executive Summary
Fulbii is evolving from a Laravel web app (Blade-first) into a mobile-first platform:
- Frontend: Flutter (Android + iOS).
- Backend: Laravel API v1 + MySQL.
- Web: superadmin/backoffice.

This document consolidates:
- Technical analysis of current code and database.
- Functional analysis of existing capabilities and target features.
- Commercial/product analysis and growth model.
- Phased implementation roadmap with acceptance criteria.

## 2) Current State Analysis (Repository + DB)
### 2.1 Stack and Architecture
- Laravel 10 monolith with web routes and Blade views.
- Authentication currently based on email/password (Laravel UI).
- API is minimal (`/api/user` only, Sanctum guard present but no product API surface).
- Data model is mostly represented in `fulbii.sql` (domain-rich), while migrations are mostly Laravel defaults.

### 2.2 Functional Capabilities Already Present
- Users and profiles (`users`, `perfil`, `user_perfil`).
- Clubs/groups (`clubs`, `club_user`, `club_invitations`).
- Ratings/performance (`calificaciones`, aggregate views).
- Field map core (`polideportivo`, `cancha`) and related sports entities (`evento`, `pichanga`, etc.).
- Role logic exists for `superadmin`, `admin`, `miembro` in web controllers.

### 2.3 Gaps vs Target Product
- No mobile-focused API contract for Flutter flows.
- No Google/Apple sign-in flow.
- No push notification infrastructure for closed-app delivery.
- No audience targeting engine (1st/2nd/3rd degree + demographic/skill filters).
- No "renotify" campaign model with cooldown and audit.
- No user-level notification mute per group.
- No complete moderation domain for reports/strikes with policy automation.
- No migration parity for domain tables (operational risk).

## 3) Target Product (Functional Model)
### 3.1 Core Product Flows
1. Social login only (Google/Apple), then mandatory onboarding (`nickname`, `sexo`).
2. Map-first experience for fields/canchas.
3. Group creation and management (closed groups, visibility toggle, multi-admin).
4. Invitations and join requests with explicit accept/reject.
5. Pichanga creation with configurable rules (capacity, status behavior, attendance windows).
6. Audience diffusion by degree:
- 1st degree: direct group members.
- 2nd/3rd degree: external candidates via relation graph, request-approval flow.
7. Pichanga notifications and re-notifications with filtering and reach preview.
8. Pichanga feed/history (attendance, ratings, photos/comments).
9. Field submissions and moderation through backoffice.
10. Report/strike lifecycle with superadmin actions.

### 3.2 Notification Rules
- Per-group mute preference:
  - `always_on`
  - `mute_24h`
  - `mute_1w`
  - `mute_forever`
- Mute affects push only.
- No critical bypass when muted.

### 3.3 Audience Segmentation
- Segment external audience by:
  - Sex.
  - Age range.
  - Minimum skills.
- Mandatory preview before send:
  - "With these filters, N people will be invited."
- Same-group same-day multiple pichangas can target different audiences.
- Open pichangas can also be visibility-filtered by audience criteria.

## 4) Technical Target Architecture
### 4.1 Backend
- Laravel API v1 (REST), Sanctum tokens for mobile sessions.
- Queue workers for push delivery and scheduled reminders.
- Push transport via FCM/APNs.
- Audit tables for notification batches and moderation actions.

### 4.2 Mobile
- Flutter app as primary user surface.
- Onboarding-first auth UX.
- Map, groups, pichangas, notifications, moderation interactions.

### 4.3 Web Backoffice
- Superadmin console for:
  - Field submissions moderation.
  - Reports/strikes review.
  - User/group actions and audit visibility.

## 5) Commercial and Business Analysis
### 5.1 Initial Model
- Launch as free product to maximize activation and retention.
- Instrument monetization hooks early (without immediate paywalls).

### 5.2 Value Proposition
- Faster game organization for closed communities.
- Better fill-rate via diffusion circles and precise filters.
- Trust layer via history, ratings, and moderation.

### 5.3 Potential Monetization (Future)
- Freemium group tools (advanced targeting, analytics, automation).
- Sponsored field placement / promoted pichangas.
- B2B services for sports venues (lead generation, booking integrations).

### 5.4 Product KPIs
- Activation: social login -> onboarding complete -> first group join/create.
- Liquidity: pichanga fill-rate, time-to-confirmation.
- Engagement: weekly active users, pichangas per user, re-notify conversion.
- Quality/safety: report resolution time, strike recurrence, suspension reversals.
- Retention: D7/D30 by role (admin/member).

## 6) Phased Roadmap
1. Phase 0: documentation + ADR decisions.
2. Phase 1: API foundation, social auth, onboarding.
3. Phase 2: groups, membership, invitations, visibility.
4. Phase 3: pichanga core, attendance lifecycle, availability/agenda.
5. Phase 4: diffusion by degree, targeting filters, preview, renotify.
6. Phase 5: per-group notification preferences.
7. Phase 6: fields/favorites, moderation, reports/strikes, feed/history.
8. Phase 7: hardening, analytics, monetization readiness.

## 7) Implementation Status (This Iteration)
The following has been implemented in code as initial execution of the plan:

1. API v1 base routing:
- `GET /api/v1/me`
- `PUT /api/v1/me`
- `POST /api/v1/onboarding`
- `GET /api/v1/clubs/{club}/notification-preference`
- `PUT /api/v1/clubs/{club}/notification-preference`

2. Notification preference domain:
- New table migration: `user_group_notification_prefs`.
- New model: `UserGroupNotificationPref`.
- Modes supported:
  - `always_on`
  - `mute_24h`
  - `mute_1w`
  - `mute_forever`
- Expiration calculation and `isMuted` behavior implemented.

3. Membership and access control:
- Preferences can be read/updated only by:
  - the authenticated user for groups they belong to, or
  - superadmin.

4. Entity relations:
- Added relations/helpers in `User` and `Club` for notification preferences.

5. Mobile profile readiness:
- Added users-table alignment migration for mobile onboarding fields:
  - `nick`, `sexo`, `fec_nac`, `altura_cm`, `estado`
  - `auth_provider`, `provider_uid`, `avatar_url`
- Added API controllers for:
  - onboarding completion (`nick`, `sexo`)
  - profile read/update (`me`)

6. Group configuration readiness:
- Added clubs-table migration with mobile settings:
  - `is_visible`
  - `pichanga_create_scope`
  - `renotify_scope`
  - `renotify_cooldown_minutes`
  - `renotify_max_per_pichanga`
  - `audience_max_degree`

7. Groups and invitations API slice:
- Added clubs endpoints:
  - list (`mine`/`discover`), create, show, update.
  - members list, role change, member removal.
- Added invitations endpoints:
  - list mine, create by nick/email, accept/reject, revoke.
- Added permission checks:
  - admin/superadmin protected mutations.
  - last-admin protection on demotion/removal.

8. Social auth API slice:
- Added `POST /api/v1/auth/social/login`.
- Added `POST /api/v1/auth/logout`.
- Added configurable trusted mode:
  - `SOCIAL_AUTH_TRUSTED_MODE=true` for local app integration.
  - verification mode for provider tokens.

9. Pichanga core + audience + renotify slice:
- New domain tables:
  - `group_pichangas`
  - `group_pichanga_participants`
  - `group_pichanga_external_requests`
  - `group_pichanga_notification_batches`
- New API capabilities:
  - create/list/show pichangas by club and available feed.
  - confirm attendance / withdraw.
  - update pichanga status and audience filters.
  - external request lifecycle (create/list/decision).
  - renotify preview + send with cooldown/max constraints.
- Audience engine:
  - degree expansion (1/2/3) using club-membership graph.
  - profile filters (sex/age) and skill thresholds.
  - mute-by-group filtering before notification accounting.

10. Push + notification inbox slice:
- New tables:
  - `user_devices`
  - `push_notifications`
  - `push_dispatch_logs`
- New capabilities:
  - register/deactivate mobile device tokens.
  - in-app notification inbox + mark read.
- pichanga creation and re-notify now generate push notification records.
- dispatch job logs each device send result.

11. Moderation + safety slice:
- New moderation domain:
  - `reports`
  - `strikes`
  - `field_submissions`
  - `field_submission_photos`
- User safety controls:
  - `users.suspended_until`
  - `users.suspension_reason`
- New APIs:
  - report creation/list for users.
  - field submission creation/list for users.
  - superadmin review/decision endpoints for reports, strikes, suspensions and field submissions.
- Policy:
  - 3 active strikes => automatic temporary suspension.
  - suspended users are blocked by `user.not_suspended` middleware.

12. Pichanga social slice:
- New social tables:
  - `group_pichanga_posts`
  - `group_pichanga_comments`
  - `group_pichanga_ratings`
  - `user_favorite_fields`
- New social APIs:
  - feed posts/comments per pichanga.
  - participant-only ratings per pichanga.
  - user pichanga card (stats + average ratings).
  - personal pichanga history + favorite fields.

## 8) Risks and Technical Constraints
- DB migration parity risk:
  - Domain tables are currently source-of-truth in `fulbii.sql`, not full Laravel migrations.
- API evolution risk:
  - Need stable response contracts and versioning discipline before Flutter scale.
- Notification cost/rate control:
  - Requires queue throttling, cooldown policies, and delivery observability.
- Graph diffusion complexity:
  - 2nd/3rd degree expansion must remain deterministic and query-efficient.

## 9) Recommended Next Implementation Slice
1. Social auth endpoints + provider identity persistence.
2. Group visibility and invitation APIs in v1.
3. Pichanga creation/status APIs with state machine and capacity logic.
4. Notification engine scaffold:
- user devices.
- scheduled jobs.
- pre-send mute filtering using `user_group_notification_prefs`.

## 10) Acceptance Baseline for Current Slice
- User can query and update notification preference per group.
- Modes calculate expected mute period (`24h`, `1w`, `forever`, `always_on`).
- Push mute decision can be consumed by notification jobs through model helper.
- Manual SQL rollout script is available at:
  - `database/sql/fulbii_upgrade_2026_03_19.sql`
  - `database/sql/fulbii_upgrade_2026_03_19_compat.sql` (for older MySQL/MariaDB)
  - `database/sql/fulbii_upgrade_2026_03_19_pichanga_block_compat.sql`
  - `database/sql/fulbii_upgrade_2026_03_19_push_block_compat.sql`
  - `database/sql/fulbii_upgrade_2026_03_19_moderation_block_compat.sql`
  - `database/sql/fulbii_upgrade_2026_03_19_social_block_compat.sql`
