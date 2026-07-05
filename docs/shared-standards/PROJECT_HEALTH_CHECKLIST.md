<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Project Health Checklist (Beyond Shared Infrastructure)

> **Purpose:** A reviewable checklist of concerns that fall *outside* the [Shared Infrastructure Decision Guide](./SHARED_INFRA_DECISION_GUIDE.md) but still matter for project health, security posture, and operational maturity. These apply to any web application with an admin panel and user-facing pages.
>
> **How to use:** Run through each section. For each item, mark one of:
> - **[x] Done** — already implemented and working
> - **[~] Partial** — exists but incomplete or undocumented
> - **[ ] Not done** — not yet addressed
> - **[n/a]** — doesn't apply to this project
>
> Items marked `[ ]` or `[~]` should be triaged: is this blocking, post-launch, or never?
>
> **Origin:** Distilled from cross-project comparison notes. These items kept coming up as valid concerns but didn't belong in the shared infrastructure integration guide.

---

## 1. Session Security

These are application-level auth concerns, not integration patterns. Important for any project with authenticated users, critical for anything financial.

- [ ] **Session lifetime vs. idle timeout are distinct.**
  Absolute lifetime (e.g., 24h) and inactivity timeout (e.g., 30min) are separate values. A session that's been idle for hours shouldn't stay valid just because it was created recently.
  _Check: Are both configured? Are they env-var-driven?_

- [ ] **Admin sessions have tighter limits than user sessions.**
  Admin session lifetime should be shorter (or at minimum, equal) to regular user sessions.
  _Check: Is `ADMIN_SESSION_LIFETIME` (or equivalent) configurable separately?_

- [ ] **Sessions track IP and user agent.**
  Useful for detecting session hijacking and for the session management UI.
  _Check: Is this metadata stored per session?_

- [ ] **Active sessions are viewable and revocable.**
  Admin (or the user themselves) can see active sessions and kill them.
  _Check: Does a UI or admin tool exist for this? Even a CLI command counts._

- [ ] **Session invalidation on privilege change.**
  When a user's role changes or password resets, existing sessions are invalidated.
  _Check: Does changing a password force re-login across all sessions?_

---

## 2. Audit Logging

Error tracking (Sentry/GlitchTip) answers "what broke?" Audit logging answers "who did what?" They are different systems.

- [ ] **Security-critical events are logged.**
  At minimum: `login_failed`, `login_success`, `password_changed`, `role_changed`, `access_denied`, `session_expired`.
  _Check: Search the codebase for these events. Are they logged somewhere persistent (not just stdout)?_

- [ ] **Audit log entries include actor, action, target, timestamp, and IP.**
  "Admin user X changed role of user Y to Z at time T from IP A" — not just "role changed."
  _Check: What fields does each audit log entry contain?_

- [ ] **Audit logs are immutable (append-only).**
  Admin users cannot delete or modify audit log entries through the application.
  _Check: Is there a delete endpoint or soft-delete mechanism on audit logs?_

- [ ] **Audit log retention policy exists.**
  Logs don't grow unbounded. A scheduled cleanup job removes entries older than N days.
  _Check: Is `AUDIT_LOG_RETENTION_DAYS` (or equivalent) configured? Is the cleanup job scheduled?_

- [ ] **Audit events are documented.**
  A catalog of "these are the events we track" exists somewhere — code comments, a doc, or a constants file.
  _Check: Is there a single place listing all tracked audit events?_

---

## 3. Access Control

The adapter pattern handles external integrations. Access control is internal application logic.

- [ ] **Role hierarchy is documented.**
  What roles exist? What can each do? This should be written down, not just implicit in code.
  _Check: Is there a roles/permissions matrix in docs or code?_

- [ ] **Permission checks are centralized, not scattered.**
  Whether it's middleware, decorators, policies, or gates — permission logic lives in one place, not duplicated across every route handler.
  _Check: How many different patterns exist for checking "can this user do X"?_

- [ ] **Granular permissions exist (or are planned) beyond role-level.**
  `can('content:edit')` is more flexible than `is_admin`. Roles *grant* permissions; code *checks* permissions.
  _Check: Does the code check roles directly or permissions? If roles, is a migration path to permissions planned?_

- [ ] **Admin user provisioning has a defined workflow.**
  How does a new admin get added? Direct DB edit, env var bootstrap, invitation flow, or admin UI?
  _Check: Is the workflow documented? Could someone other than you follow it?_

---

## 4. Background Jobs & Scheduled Tasks

The shared infra guide covers deferred work *triggers*. This covers operational visibility of those jobs.

- [ ] **Scheduled tasks are inventoried.**
  A list of "these cron jobs / scheduled tasks run" exists somewhere.
  _Check: Is there a schedule definition file? Can you list all recurring jobs?_

- [ ] **Job failures are surfaced.**
  Failed background jobs trigger an alert, log an error, or appear in a dashboard — not silently lost.
  _Check: If a scheduled job fails at 3am, how do you find out?_

- [ ] **Job status is visible to admins.**
  Last run time, success/failure, next scheduled run.
  _Check: Is there a queue dashboard (Horizon, Flower, Bull Board, etc.) or an admin panel section?_

- [ ] **Long-running jobs have timeouts.**
  A job that hangs doesn't block the queue forever.
  _Check: Are timeouts configured per job or globally?_

---

## 5. Admin Notifications & Digests

Not shared infrastructure (that's email *sending*). This is "does the admin know what's happening?"

- [ ] **Critical events trigger real-time alerts.**
  Login failures above threshold, error rate spikes, disk usage warnings.
  _Check: Beyond error tracking (Sentry), are there operational alerts?_

- [ ] **Periodic digest exists (or is planned).**
  Daily or weekly summary: new users, key metrics, errors, failed jobs.
  _Check: Is this built, planned, or not needed?_

- [ ] **Alert fatigue is considered.**
  If everything alerts, nothing alerts. Only genuinely actionable events should notify.
  _Check: Would the current alert volume (if any) be sustainable?_

---

## 6. Data Lifecycle

- [ ] **User data retention policy exists (if applicable).**
  How long is user data kept? Is there a deletion path?
  _Check: Can a user (or admin) delete an account and its data?_

- [ ] **Soft delete vs. hard delete is intentional.**
  If records are soft-deleted, is there a process to eventually hard-delete them?
  _Check: Are soft-deleted records cleaned up on a schedule?_

- [ ] **Database backups are configured and tested.**
  Backups exist, are automated, and have been tested with a restore.
  _Check: When was the last restore test? (If "never," schedule one.)_

- [ ] **Cache invalidation strategy is documented.**
  When does cached data expire? What events trigger invalidation?
  _Check: Is there a single place describing the caching strategy?_

---

## 7. Development & Operational Hygiene

These aren't features — they're "is the house in order?" checks.

- [ ] **Version numbers are consistent across all files.**
  README, CHANGELOG, pyproject.toml / package.json, any version constants.
  _Check: `grep -r` for the version string. Do all references match?_

- [ ] **LICENSE file exists.**
  If open source (or planned to be), the license file should be present, not just mentioned.
  _Check: Is there a LICENSE file in the repo root?_

- [ ] **`.env.example` is complete and current.**
  Every env var the app reads has a corresponding entry with a comment.
  _Check: Diff the env vars actually read by the app against `.env.example`._

- [ ] **Linting / formatting is configured.**
  Consistent code style is enforced by tooling, not convention.
  _Check: Is there a linter config (ruff, eslint, phpstan, etc.)? Does CI run it?_

- [ ] **CI pipeline exists (or is planned).**
  Tests, linting, and build run automatically on push/PR.
  _Check: Is there a CI config file? Does it run on every push?_

- [ ] **Dependency updates have a process.**
  Whether it's Dependabot, Renovate, or a manual monthly check — stale dependencies are a security risk.
  _Check: When were dependencies last updated? Is there an automated process?_

---

## 8. AI Integration Readiness (Future Reference)

Not relevant until AI features are in scope, but the patterns are worth noting now.

- [ ] **AI provider abstraction follows the adapter pattern.**
  Same pattern as analytics/CAPTCHA: interface + concrete providers + NoOp + factory.
  _Check: When AI features are planned, is the abstraction layer designed?_

- [ ] **Per-provider cost tracking is planned.**
  AI API costs can surprise you. Track spend per provider, per task type, per day.
  _Check: Is there a budget/alert mechanism for API costs?_

- [ ] **Task-specific routing is considered.**
  Different AI tasks (summarization, classification, embedding) may warrant different models/providers.
  _Check: Is routing logic separated from business logic?_

---

## How to Use This Checklist

### For a quick review:
```
Read this file. For each item, check the codebase and mark the status.
Report back with:
1. Items that are [x] Done
2. Items that are [~] Partial (with what's missing)
3. Items that are [ ] Not done (with a recommendation: blocking, post-launch, or skip)
4. Items that are [n/a]
Do not make any changes — just report.
```

### For a planning session:
```
Read this file and the project's ROADMAP. For each [ ] or [~] item,
determine whether it's:
- Already on the roadmap (note which phase)
- Missing from the roadmap but should be added
- Not needed for this project (explain why)
Produce a prioritized list of gaps to address.
```
