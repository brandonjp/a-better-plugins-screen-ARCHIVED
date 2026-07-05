<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Super Admin Tooling Implementation Prompt

> **Usage:** Provide this prompt to Claude Code (or any AI coding assistant) to implement production-grade super admin tooling for your application. The prompt is intentionally **framework-agnostic** — the AI should analyze your project's actual tech stack before writing any code.
>
> **Companion docs:**
> - [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md) — Env var naming, URL normalization, graceful degradation (referenced by Sections 0b–0d)
> - [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) — Analytics provider integration and event tracking
> - [Error Tracking](./ERROR_TRACKING.md) — GlitchTip/Sentry setup
> - [Email Infrastructure](./EMAIL_INFRASTRUCTURE.md) — Email sending and logging (SeeSee)
> - [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md) — CAPTCHA/PoW and multi-layer form protection
> - [Project Health Checklist](./PROJECT_HEALTH_CHECKLIST.md) — Security, audit logging, session management

---

## Critical Instruction: Analyze Before Implementing

**Before writing any code, you MUST:**

1. **Examine the project's tech stack** — Identify the language, framework, package manager, existing dependencies, and project structure. Do NOT assume any particular framework (e.g., Laravel, Django, Express, Rails). Let the codebase tell you what to use.
2. **Identify existing patterns** — Look at how the project currently handles authentication, authorization, middleware, configuration, database access, and routing. Match those patterns exactly.
3. **Check for existing admin infrastructure** — The project may already have partial admin support (e.g., an `is_admin` flag, role columns, middleware). Build on what exists rather than replacing it.
4. **Use idiomatic solutions** — Use the framework's native auth/middleware/ORM abstractions where they exist.
5. **Make the architecture decision** — Read Section 0 below and decide which deployment model fits this project, then document your reasoning before proceeding.

**The guidance below describes WHAT to implement, not HOW.** The "how" must come from the project itself.

---

## 0. Architecture Decision: Embedded vs. Separate Admin

Before writing any code, evaluate this project and decide which model fits best. **Document your choice and reasoning in the project README or a dedicated `ADMIN.md` file.**

### Option A: Embedded Admin (Buried Routes)

The admin panel lives inside the main application as protected routes.

**Choose this when:**
- The project is a monolith (single deployable unit)
- The admin needs to share models, services, and database connections with the main app
- The team is small and a single codebase is easier to maintain
- The admin is lightweight (settings, user management, basic dashboards)
- You want admin features available immediately without extra infrastructure

**Implementation pattern:**
- Admin routes live under a prefix (e.g., `/admin/...`) with middleware protection
- Admin views/pages are in a subdirectory of the main app's templates
- Access is controlled by middleware that checks an `is_super_admin` flag or role
- The admin route group can be conditionally registered based on an env flag (e.g., `ADMIN_ENABLED=true`) for extra security

### Option B: Separate Admin App

The admin panel is a standalone application that connects to the same database (or communicates via API).

**Choose this when:**
- The main app is an API-only backend or SPA where server-rendered admin pages don't fit
- The project uses microservices and the admin should be independently deployable
- Security policy requires the admin to be on a separate domain/network
- The admin has significant custom UI that would bloat the main app
- Multiple applications share the same admin tooling

**Implementation pattern:**
- Separate project directory (e.g., `admin/` or a dedicated repo)
- Shares the database directly OR communicates via internal API
- Can use a different framework than the main app (e.g., main app is an Express API, admin is a Next.js app)
- Deployed to a separate URL (e.g., `admin.yourapp.com`)

### Option C: Hybrid (Recommended Default)

Start embedded, but structure the code so it can be extracted later.

**Implementation pattern:**
- All admin code lives in a clearly separated namespace/directory (e.g., `app/Admin/`, `src/admin/`, `modules/admin/`)
- Admin routes, controllers, views, and services are self-contained — they import from the main app but the main app never imports from admin
- A single env flag (`ADMIN_ENABLED=true`) gates the entire admin module
- If extraction is needed later, the admin directory can be pulled out into its own app with minimal refactoring

**Choose this when you're unsure** — it's the safest starting point.

---

## 0b. Environment Variable Naming Convention

All integration env vars follow the pattern `{CATEGORY}_{PROVIDER}_{PROPERTY}` — e.g., `ANALYTICS_UMAMI_URL`, `CAPTCHA_ALTCHA_SECRET`, `MAIL_SEESEE_API_KEY`. Empty = disabled (no boolean toggles needed). `LAUNCHPAD_*` vars are only for tools with no functional env var in the app.

**Full convention, rules, and `.env.example` template:** See [Shared Integration Patterns — Section 1](./SHARED_INTEGRATION_PATTERNS.md#1-environment-variable-naming-convention).

---

## 0c. URL Normalization

Always store the base URL in env vars. Strip known path suffixes at config load time, then append the correct path in code. This ensures consistency regardless of what the developer pastes (full script URL, API path, or bare domain).

**Full pattern, suffix map, and normalization logic:** See [Shared Integration Patterns — Section 2](./SHARED_INTEGRATION_PATTERNS.md#2-url-normalization).

---

## 0d. Integration Initialization & Graceful Degradation

All integrations initialize as module-level singletons at app startup via a single `init_integrations(settings)` function. Each provider is health-pinged during init. Critical rule: never let a monitoring tool take down the app it monitors — all external integration calls are wrapped in try/catch and fail silently.

**Full startup pattern, init order, degradation rules, and template globals:** See [Shared Integration Patterns — Section 3](./SHARED_INTEGRATION_PATTERNS.md#3-integration-initialization--graceful-degradation).

---

## 1. Super Admin Role System

### User Model Additions

Add these fields to the existing user model (via migration or schema change):

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `is_super_admin` | boolean | false | Full admin access flag |
| `role` | string, nullable | null | Granular role for non-super-admin staff |
| `account_status` | string | "active" | active, suspended, blocked |
| `suspension_reason` | text, nullable | null | Why the account was suspended/blocked |
| `suspended_at` | datetime, nullable | null | When the action was taken |
| `suspended_until` | datetime, nullable | null | Auto-restore date (null = indefinite) |
| `suspended_by` | foreign key to users, nullable | null | Which admin took the action |

### Role Hierarchy

```
Super Admin    → Full access to everything. Controlled by is_super_admin flag.
Developer      → Logs, feature flags, system health. Cannot manage other admins.
Support        → User management, limited settings. Cannot change system config.
Stakeholder    → Read-only access to analytics and reports. Cannot modify anything.
```

Roles are optional — if the project doesn't need granular roles, just use `is_super_admin` as a boolean gate and skip the `role` column entirely.

### Key User Methods to Implement

```
isSuperAdmin()     → bool       # Check is_super_admin flag
hasAdminAccess()   → bool       # Super admin OR has any role
hasRole(role)      → bool       # Check specific role
isActive()         → bool       # Account status check (auto-restore expired suspensions)
isSuspended()      → bool       # Check suspended status
isBlocked()        → bool       # Check blocked status
suspend(reason, until, adminId) → void   # Suspend with optional end date
block(reason, adminId)          → void   # Permanently block
restore()                       → void   # Clear all suspension fields, set active
```

### Account Status Behavior

- **Active:** Normal access
- **Suspended:** Logged out on next request. Optional end date for auto-restore.
- **Blocked:** Logged out on next request. Requires admin to manually restore.

Auto-restore: When checking `isActive()` or `isSuspended()`, if `suspended_until` has passed, automatically restore the account and return the appropriate status.

---

## 2. Middleware Stack

Implement these as middleware (or the framework's equivalent — guards, decorators, hooks, etc.):

### Admin Access Middleware
Protects admin routes. Returns 403 if the user is not a super admin (or doesn't have admin access, depending on the route).

### Account Status Middleware
Runs on **all authenticated requests** (not just admin). If the user is suspended or blocked, log them out and redirect to login with an appropriate message.

### Two-Factor Authentication Middleware (Optional)
If 2FA is implemented, this middleware checks whether the admin has verified their 2FA for the current session. If not, redirects to the 2FA challenge page.

### Middleware Application

```
All web routes:         → Account Status check
Admin routes (setup):   → Auth + Admin Access (no 2FA — needed for 2FA setup itself)
Admin routes (main):    → Auth + Admin Access + 2FA (if implemented)
```

---

## 3. Super Admin Auto-Provisioning

### Purpose
Automatically create or promote the super admin account from environment variables on first application start, so there's no manual database step required during deployment.

### Environment Variables

```env
SUPER_ADMIN_EMAIL=admin@yourapp.com
SUPER_ADMIN_PASSWORD=                      # Optional
SUPER_ADMIN_PASSWORD_ENABLED=false         # Must be true to use password in production
ADMIN_ENABLED=true                         # Master toggle for admin module
```

### Provisioning Logic (runs at app startup)

```
# Pseudocode
function ensureSuperAdminExists():
    adminEmail = env("SUPER_ADMIN_EMAIL")
    if not adminEmail: return
    if running CLI migrations: return      # Don't run during migrations

    # Cache to avoid DB query every request
    cacheKey = "super_admin_ensured_" + hash(adminEmail + passwordConfig)
    if cache.has(cacheKey): return

    user = User.findByEmail(adminEmail)

    if user exists:
        if not user.is_super_admin:
            user.update({ is_super_admin: true })
        # Update password if configured and different
    else:
        User.create({
            email: adminEmail,
            password: configuredPassword OR randomSecurePassword(),
            is_super_admin: true,
            email_verified: true
        })

    cache.set(cacheKey, true, ttl: 24 hours)
```

### Key Rules
- In production, password-from-env requires an explicit opt-in flag (`SUPER_ADMIN_PASSWORD_ENABLED=true`)
- If no password is configured, generate a random secure password — admin must use password reset
- Pre-verify the email so the admin can log in immediately
- Wrap everything in error handling — if the database isn't ready yet (fresh deploy, running migrations), fail silently

---

## 4. Two-Factor Authentication (2FA) — Optional

If the project warrants it, implement TOTP-based 2FA for admin accounts.

### Setup Flow
1. Admin navigates to 2FA setup page
2. System generates a TOTP secret, displays QR code
3. Admin scans with authenticator app, enters 6-digit code to confirm
4. System generates 8 recovery codes (format: `XXXX-XXXX`), displays once
5. 2FA is now active for this account

### Login Challenge Flow
1. Admin logs in normally (email + password)
2. Middleware detects 2FA is enabled but not verified for this session
3. Redirects to challenge page — admin enters TOTP code or recovery code
4. On success, session is marked as 2FA-verified

### User Model Fields for 2FA

| Field | Type | Purpose |
|-------|------|---------|
| `two_factor_secret` | encrypted text | TOTP secret key |
| `two_factor_recovery_codes` | encrypted text/json | Array of recovery codes |
| `two_factor_confirmed_at` | datetime, nullable | When 2FA was confirmed (null = pending) |

### Emergency Bypass
- An env variable (`ADMIN_2FA_BYPASS_KEY`) can be used as a one-time emergency bypass
- Accessed via a specific URL with the key as a parameter
- Completely resets 2FA for the admin account
- Must be audit-logged, and the key should be rotated after use

### Security Requirements
- Secrets and recovery codes must be encrypted at rest
- Recovery codes are single-use — consumed when used
- Disabling 2FA requires both a valid TOTP code AND the current password
- 2FA verification is session-scoped — logging out requires re-verification

---

## 5. Admin Dashboard

### Purpose
A landing page for admins showing platform health, key metrics, and quick links.

### Dashboard Sections

**Platform Statistics (Cards/Tiles):**
- Total users (and growth trend)
- Active users (today/week/month)
- Domain-specific counts (total orders, total posts, total revenue — adapt to your app)
- System health indicators (queue depth, failed jobs, error rate)

**Recent Activity Feed:**
- Last N audit log entries (admin actions)
- Last N user registrations
- Last N significant system events

**Quick Status Indicators:**
- Registration: open/closed/invite-only
- 2FA: enabled/disabled for current admin
- Queue: running/stopped, depth
- Domain-specific status flags

**Admin Quick Actions:**
- Link to user management
- Link to settings
- Link to launchpad (see Section 11)

### Data Sourcing Principle

For admin dashboard metrics, display data from your own application database — user counts, activity, business metrics. These work regardless of which external providers are active. For traffic analytics (page views, referrers, device breakdown), link to provider dashboards via the launchpad (Section 11) rather than building API integrations that pull provider data into your app. This avoids coupling to providers that may be swapped or removed, and keeps the dashboard functional independently.

---

## 6. User Management

### Endpoints

```
LIST    /admin/users                  → Paginated list with search, role/status filters
VIEW    /admin/users/{id}             → Detail view with stats and activity
EDIT    /admin/users/{id}             → Edit role, admin status
UPDATE  /admin/users/{id}             → Save changes
SUSPEND /admin/users/{id}/suspend     → Suspend (with reason and optional duration)
BLOCK   /admin/users/{id}/block       → Block permanently
RESTORE /admin/users/{id}/restore     → Restore to active
```

### Safety Guards (Critical — Always Implement)

1. **No self-demotion:** Admins cannot remove their own `is_super_admin` status
2. **No self-suspension:** Admins cannot suspend or block themselves
3. **No lateral attacks:** Non-super-admins cannot modify super admin accounts
4. **Audit everything:** Every user management action gets logged (see Section 8)

### Suspension Model

```
# Temporary suspension
user.suspend(reason: "Violated ToS", until: 30 days from now, adminId: currentUser.id)

# Permanent block
user.block(reason: "Repeated violations", adminId: currentUser.id)

# Restore
user.restore()  → Clears all suspension fields, sets status to active
```

---

## 7. Platform Settings

### Purpose
A key-value settings store that can be managed from the admin UI. This is the same table used by the email infrastructure if both prompts are implemented.

### Settings Table Schema

| Column | Type | Purpose |
|--------|------|---------|
| `key` | string, unique | Setting identifier |
| `value` | text, nullable | Setting value (stored as string, cast on retrieval) |
| `type` | string, default "string" | Type hint: string, boolean, integer, json |
| `group` | string, default "general" | Grouping for admin UI tabs |
| `description` | text, nullable | Human-readable description |

### Required Methods

```
Settings.get(key, default)          → mixed     # Get with type casting
Settings.set(key, value, group?)    → void      # Set and clear cache
Settings.getAllCached()             → dict       # All settings from cache
Settings.clearCache()              → void       # Bust the cache
Settings.getByGroup(group)         → collection # All settings in a group
```

### Caching Strategy
- Cache all settings permanently (or with a long TTL)
- Clear the cache whenever any setting is updated
- Handle graceful fallback if cache or database is unavailable

### Suggested Setting Groups

Adapt to your domain:

| Group | Example Settings |
|-------|-----------------|
| `general` | app_name, maintenance_mode, maintenance_message |
| `registration` | registration_enabled, invite_only, registration_closed_message |
| `branding` | primary_color, secondary_color, logo_path, favicon_path |
| `meta` | og_title, og_description, meta_description, theme_color |
| `features` | (or use Feature Flags — Section 10) |

### Admin UI Pattern
Use a tabbed interface — one tab per settings group. Each tab shows a form with the settings for that group and their current values. Persist the active tab across saves (via query parameter or similar).

---

## 8. Audit Trail

### Purpose
A complete log of every admin action for security, debugging, and accountability.

### Audit Log Schema

| Column | Type | Purpose |
|--------|------|---------|
| `id` | primary key | — |
| `user_id` | foreign key | Admin who performed the action |
| `action` | string, indexed | Action identifier (e.g., `user.update`, `settings.update`) |
| `auditable_type` | string, nullable | Model/entity type that was affected |
| `auditable_id` | integer, nullable | ID of the affected entity |
| `old_values` | json, nullable | State before the change |
| `new_values` | json, nullable | State after the change |
| `ip_address` | string, nullable | Request IP |
| `user_agent` | text, nullable | Request user agent |
| `description` | text, nullable | Human-readable summary |
| `created_at` | datetime | When it happened |

### Action Naming Convention

Use `entity.verb` format:

```
user.view, user.update, user.create, user.suspend, user.block, user.restore
settings.update
feature_flag.toggle, feature_flag.create, feature_flag.delete
invite_code.create, invite_code.bulk_create, invite_code.toggle, invite_code.delete
admin.login, admin.2fa_verified, admin.emergency_access
two_factor.enabled, two_factor.disabled, two_factor.recovery_used
```

### Audit Service

Create a centralized service (not scattered logging in each controller) with convenience methods:

```
AuditService.log(action, model?, oldValues?, newValues?, description?)
AuditService.logView(model, description?)
AuditService.logUpdate(model, oldValues, newValues, description?)
AuditService.logCreate(model, newValues?, description?)
AuditService.logDelete(model, oldValues?, description?)
AuditService.logSettingsChange(oldValues, newValues, description?)
```

**Critical:** Never log passwords, secrets, tokens, or other sensitive values. Strip them from old/new value dicts before saving.

### Admin Endpoints

```
LIST   /admin/audit-logs              → Filterable list (action, user, date range, search)
EXPORT /admin/audit-logs/export       → CSV or JSON export of filtered results
```

### Filtering Options
- By action type (dropdown of unique actions found in the logs)
- By admin user
- By date range
- By search text (searches description, IP address)

---

## 9. Invite Code System

### Purpose
Control registration access with distributable invite codes.

### Invite Code Schema

| Column | Type | Purpose |
|--------|------|---------|
| `id` | primary key | — |
| `code` | string, unique | The invite code (auto-generated, 12 chars uppercase) |
| `description` | string, nullable | Internal note about the code's purpose |
| `max_uses` | integer, nullable | Usage cap (null = unlimited) |
| `uses_count` | integer, default 0 | Current usage count |
| `expires_at` | datetime, nullable | Expiration (null = never) |
| `is_active` | boolean, default true | Manual toggle |
| `created_by` | foreign key, nullable | Which admin created it |

### Key Methods

```
InviteCode.generateUniqueCode(length=12)  → string     # Crypto-random, unique
InviteCode.findValidByCode(code)          → model|null  # Active + not expired + not used up
inviteCode.isValid()                      → bool        # Check all validity conditions
inviteCode.incrementUsage()               → bool        # Increment and return success
inviteCode.remainingUses                  → int|null    # null = unlimited
inviteCode.statusLabel                    → string      # "Active", "Expired", "Exhausted", "Inactive"
```

### Admin Endpoints

```
LIST    /admin/invite-codes              → List with search and status filter
CREATE  /admin/invite-codes              → Create single code
BULK    /admin/invite-codes/bulk         → Create up to 100 codes at once
EDIT    /admin/invite-codes/{id}         → Edit description, max_uses, expiration
TOGGLE  /admin/invite-codes/{id}/toggle  → Activate/deactivate
DELETE  /admin/invite-codes/{id}         → Delete
```

### Registration Integration

In the registration flow, check if invite-only mode is enabled (via settings or env), validate the provided code, and increment usage on successful registration.

---

## 10. Feature Flags

### Purpose
Database-backed feature toggles that can be flipped from the admin UI without redeployment.

### Feature Flag Schema

| Column | Type | Purpose |
|--------|------|---------|
| `id` | primary key | — |
| `key` | string, unique | Lookup key used in code (e.g., `new_checkout_flow`) |
| `name` | string | Human-readable name |
| `description` | text, nullable | What this flag controls |
| `enabled` | boolean, default false | Current state |
| `group` | string, default "general" | Grouping for admin UI |

### Key Methods

```
FeatureFlag.isEnabled(key, default=false)  → bool    # Cached lookup
FeatureFlag.enable(key)                    → void
FeatureFlag.disable(key)                   → void
FeatureFlag.toggle(key)                    → bool    # Returns new state
FeatureFlag.getAllCached()                 → dict    # key → enabled
FeatureFlag.clearCache()                   → void
```

### Usage in Application Code

```
# In business logic
if FeatureFlag.isEnabled("new_checkout_flow"):
    # new behavior
else:
    # old behavior

# In templates
if featureEnabled("show_beta_banner"):
    render beta banner
```

### Admin Endpoints

```
LIST    /admin/feature-flags              → List grouped by group
CREATE  /admin/feature-flags              → Create new flag
TOGGLE  /admin/feature-flags/{id}/toggle  → Toggle on/off
UPDATE  /admin/feature-flags/{id}         → Edit name, description, group
DELETE  /admin/feature-flags/{id}         → Delete
```

---

## 11. Launchpad (External Tools Hub)

### Purpose
A single admin page with organized links to all related external tools and services for this project. This is the admin's "home base" for jumping to any tool they need.

### Implementation

Create a launchpad page at `/admin/launchpad` that displays categorized link cards. **Most links are auto-derived from functional env vars** — only tools without a functional env var need explicit `LAUNCHPAD_*` vars.

### Auto-Derivation Pattern (Key Innovation)

The launchpad should **minimize manual configuration** by reading URLs from functional env vars that are already set for other purposes:

```
Functional env var exists?           → Auto-derive launchpad link + dashboard URL
No functional env var for this tool? → Use LAUNCHPAD_* manual env var
Neither?                             → Link is hidden
All links hidden in a category?      → Category is hidden
```

**How dashboard URLs are derived from base URLs:**

| Functional Env Var | Auto-Derived Dashboard URL |
|--------------------|----------------------------|
| `ANALYTICS_UMAMI_URL` + `ANALYTICS_UMAMI_WEBSITE_ID` | `{url}/websites/{website_id}` — e.g. `https://umami.bpf.fyi/websites/d7e41af2-…` |
| `ANALYTICS_SWETRIX_URL` + `ANALYTICS_SWETRIX_PROJECT_ID` | `{url}/projects/{project_id}` — e.g. `https://swetrix.bpf.fyi/projects/Ry2D7ojNYqIe` |
| `ANALYTICS_OPENPANEL_DASHBOARD_URL` (explicit — path is per-org/per-app, **not** derivable) | Used as-is — e.g. `https://openpanel.bpf.fyi/bpffyi/splitgiveapp` |
| `ANALYTICS_CLARITY_PROJECT_ID` | `https://clarity.microsoft.com/projects/view/{id}/dashboard` |
| `ERRORS_GLITCHTIP_DSN` | Parse hostname from DSN URL |
| `MAIL_SEESEE_URL` + `MAIL_SEESEE_APP_ID` | `{url}/emails?app_id={app_id}` |
| `CAPTCHA_ALTCHA_URL` | Direct link to ALTCHA admin |
| `CAPTCHA_CAPJS_URL` | Direct link to CapJS admin |

**Override pattern:** When auto-derivation produces the wrong URL, set the canonical explicit var — for OpenPanel (whose per-org/per-app dashboard path can't be guessed from the script URL) that is `ANALYTICS_OPENPANEL_DASHBOARD_URL`; a `LAUNCHPAD_*` override (`LAUNCHPAD_OPENPANEL_URL`, `LAUNCHPAD_GLITCHTIP_URL`) also works and wins when both are set.

### Launchpad Categories

```
# Categories adapt to your domain. Hide empty categories automatically.

Analytics:
  - Umami          → auto from ANALYTICS_UMAMI_URL
  - OpenPanel      → LAUNCHPAD_OPENPANEL_URL (can't auto-derive dashboard path)
  - Swetrix        → auto from ANALYTICS_SWETRIX_URL
  - Clarity        → auto from ANALYTICS_CLARITY_PROJECT_ID
  - Click Analytics → internal: /admin/analytics (if applicable)

Infrastructure:
  - Hosting (Coolify)  → LAUNCHPAD_HOSTING_URL (manual — no functional var)
  - Uptime Monitoring  → LAUNCHPAD_MONITORING_URL (manual)
  - Health Check       → internal: /health
  - ALTCHA Admin       → auto from CAPTCHA_ALTCHA_URL
  - CapJS Admin        → auto from CAPTCHA_CAPJS_URL

Email:
  - SeeSee Emails    → auto from MAIL_SEESEE_URL + MAIL_SEESEE_APP_ID
  - SeeSee App Config → auto from MAIL_SEESEE_URL + MAIL_SEESEE_APP_ID

Error Tracking:
  - GlitchTip → auto from ERRORS_GLITCHTIP_DSN (or LAUNCHPAD_GLITCHTIP_URL override)

Data:
  - Database Admin → LAUNCHPAD_DB_URL (manual)

Project:
  - GitHub/GitLab → LAUNCHPAD_REPO_URL (manual)
  - Project Board → LAUNCHPAD_BOARD_URL (manual)

Finance (if applicable):
  - Stripe       → LAUNCHPAD_STRIPE_URL (manual)
  - Revenue Reports → internal: /admin/reports/revenue
```

### Behavior
- Links with empty URLs are hidden (unconfigured services don't show blank cards)
- Internal links route within the admin panel
- External links open in a new tab (`target="_blank" rel="noopener"`)
- Each link card shows: name, description, and an "external" icon if it opens a new tab
- Link source tracked as `auto` (from functional env var) or `manual` (from `LAUNCHPAD_*` var)

### Environment Variables for Launchpad

Only `LAUNCHPAD_*` vars are needed here — everything else auto-derives from functional env vars defined in Section 0b:

```env
# ── Launchpad — Manual Links Only ─────────
# Auto-derived links come from functional env vars (ANALYTICS_*, ERRORS_*, MAIL_*, CAPTCHA_*).
# These are only for tools with NO functional env var in this app.
LAUNCHPAD_HOSTING_URL=https://coolify.yourapp.com
LAUNCHPAD_MONITORING_URL=https://uptime.yourapp.com
LAUNCHPAD_DB_URL=
LAUNCHPAD_REPO_URL=https://github.com/yourorg/yourapp
LAUNCHPAD_BOARD_URL=
LAUNCHPAD_OPENPANEL_URL=           # Override when auto-derivation doesn't work
LAUNCHPAD_GLITCHTIP_URL=           # Override: full project URL with org slug
LAUNCHPAD_STRIPE_URL=https://dashboard.stripe.com
```

---

## 12. Lightweight Convenience Tooling

These are simple, low-effort admin pages that provide outsized value for debugging and oversight. They should be searchable/filterable but otherwise minimal — no complex UIs needed.

### 12a. Recent Emails Log

**Purpose:** Show the last ~200 emails sent by the application so admins can verify delivery, debug email issues, and check what users received.

**Schema (new table):**

| Column | Type | Purpose |
|--------|------|---------|
| `id` | primary key | — |
| `to_address` | string | Recipient email |
| `to_name` | string, nullable | Recipient name |
| `subject` | string | Email subject line |
| `email_type` | string | Class/template name (e.g., `ReceiptEmail`, `ReminderEmail`) |
| `status` | string | queued, sent, failed |
| `error_message` | text, nullable | Error details if failed |
| `metadata` | json, nullable | Extra context (user_id, order_id, etc.) |
| `queued_at` | datetime | When it entered the queue |
| `sent_at` | datetime, nullable | When it was actually sent |

**Implementation notes:**
- Log every email at queue time (status: queued), update to sent/failed after processing
- Keep only the last ~200-500 records (or last 30 days) — this is a convenience view, not a permanent archive
- Implement a simple cleanup command or auto-prune on insert

**Admin endpoint:**

```
GET /admin/emails    → Searchable list (by recipient, subject, type, status)
```

**Display:** A simple table with columns: Sent At, To, Subject, Type, Status. Click a row to see metadata and error details. Filterable by status (sent/failed/queued) and searchable by recipient or subject.

### 12b. Recent Activity Log

**Purpose:** A lightweight feed of significant application events (not admin audit logs — those are in Section 8). This captures user-facing events for quick debugging.

**What to log (adapt to your domain):**
- User registrations
- Login attempts (especially failures)
- Password resets
- Key transactions (purchases, submissions, etc.)
- Webhook receipts
- Background job completions/failures

**Schema (new table):**

| Column | Type | Purpose |
|--------|------|---------|
| `id` | primary key | — |
| `event` | string, indexed | Event identifier (e.g., `user.registered`, `payment.completed`) |
| `user_id` | foreign key, nullable | Associated user (if any) |
| `description` | text | Human-readable summary |
| `metadata` | json, nullable | Structured event data |
| `ip_address` | string, nullable | Request IP |
| `created_at` | datetime | When it happened |

**Admin endpoint:**

```
GET /admin/activity    → Searchable, filterable list (last 500 entries)
```

**Retention:** Auto-prune to last 500-1000 records or last 30 days.

### 12c. Error & Debug Log Viewer

**Purpose:** View recent application errors and debug logs without SSHing into the server.

**Implementation approach (choose based on project):**

**Option 1: Read from log files** — Parse the application's existing log files and display the last N entries. Most frameworks write to a log file (e.g., `storage/logs/laravel.log`, `logs/app.log`). Read the tail of the file and present it.

**Option 2: Database-backed log** — If the project already uses a database log handler, query that table.

**Option 3: GlitchTip/Sentry integration** — If an error tracking service is configured, just link to it from the launchpad and skip the in-app viewer.

**Admin endpoint:**

```
GET /admin/logs            → Recent error log entries
GET /admin/logs?level=error&search=timeout    → Filtered view
```

**Display:** A searchable, filterable view with columns: Timestamp, Level (error/warning/info/debug), Message, Context. Click to expand full stack trace. Filter by level and search by message text.

**Security:** Be careful about what's displayed — strip sensitive data (passwords, tokens) from log output. Consider restricting this to super admins only (not support/stakeholder roles).

---

## 13. Related Implementation Guides

The following concerns are covered by dedicated companion docs. They integrate with the admin tooling described above (launchpad links, dashboard status indicators, admin viewers) but their implementation details live in their own documents.

### Analytics & Event Tracking

Provider integration, abstraction layer, script injection, event naming, and privacy/compliance.

**See:** [Analytics Playbook](./ANALYTICS_PLAYBOOK.md)

### CAPTCHA / Proof-of-Work

Multi-layer spam protection with adapter pattern for ALTCHA, CapJS, and other PoW providers. Fail-open behavior, form integration patterns.

**See:** [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md)

### Email Logging (SeeSee)

Logging sent emails to a centralized service. Sending and logging are separate concerns — the email sender and email logger are independent abstractions composed together. Includes admin dashboard integration for displaying recent emails.

**See:** [Email Infrastructure](./EMAIL_INFRASTRUCTURE.md)

### Error Tracking (GlitchTip/Sentry)

Sentry-compatible error tracking setup, environment gating, noise filtering, CSP report-uri integration.

**See:** [Error Tracking](./ERROR_TRACKING.md)

---

## 14. Security Headers & Dynamic CSP

### Purpose
Apply standard security headers to all responses, with a Content Security Policy that **automatically adapts** to which analytics/CAPTCHA/error tracking providers are configured.

### Static Headers (Always Apply)

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Strict-Transport-Security: max-age=63072000; includeSubDomains  (HTTPS only)
```

### Dynamic CSP

The CSP is **built at startup from configured providers**. Add or remove a provider → CSP updates automatically. No manual CSP editing needed.

```
Base:         'self' for scripts, styles, images, connect-src
Per-request:  'nonce-{random}' for inline scripts (analytics init code)
+ Each analytics provider's script domain (read from config)
+ Each CAPTCHA provider's widget domain (read from config)
+ Error tracking endpoint (parsed from DSN)
+ CSP report-uri (from ERRORS_GLITCHTIP_SECURITY_ENDPOINT)
```

### Per-Request Nonce

Generate a cryptographically random nonce for each request. Pass it to templates via request state. All inline `<script>` tags must include `nonce="{nonce}"`.

```python
# Middleware
nonce = secrets.token_urlsafe(16)
request.state.csp_nonce = nonce
# Add nonce to CSP: script-src 'self' 'nonce-{nonce}'
```

### Environment Variables

```env
SECURITY_HEADERS_ENABLED=true       # Master toggle
CSP_ENABLED=false                   # Start disabled, enable after testing
CSP_REPORT_ONLY=true                # Start in report-only mode
```

---

## 15. Security Considerations

- **Encrypt secrets at rest** — 2FA secrets, recovery codes, any stored credentials
- **Never log passwords** — Strip from audit trails, log output, and error reports. Define a sensitive fields list: `password`, `password_hash`, `secret_key`, `api_key`, `dsn`, `session_token`, etc.
- **Self-protection guards** — Admins cannot demote themselves, suspend themselves, or modify their own admin status downward
- **Session-scoped 2FA** — Re-verification required after every logout
- **Emergency bypass is audited** — And the bypass key should be rotated after use
- **Account status checked every request** — Suspended/blocked users are immediately logged out
- **Admin module can be disabled** — `ADMIN_ENABLED=false` should completely hide admin routes
- **Log viewer sanitization** — Strip sensitive data before displaying in the error log viewer
- **Rate limit admin login** — Prevent brute force on admin accounts (5/minute per IP recommended)
- **Hash IP addresses in audit logs** — Use a salted hash (via `IP_HASH_SALT` env var) so IPs can be correlated within the app but not reverse-engineered from the database
- **Dynamic CSP** — Build Content Security Policy from configured providers at startup (see Section 13d)

---

## 16. Route Structure

### Two Route Groups (if 2FA is implemented)

```
# Group 1: Pre-2FA routes (accessible before 2FA challenge)
/admin/two-factor/setup
/admin/two-factor/challenge
/admin/two-factor/verify
/admin/emergency-access

# Group 2: Main admin routes (require 2FA if enabled)
/admin/dashboard
/admin/users/...
/admin/settings/...
/admin/audit-logs/...
/admin/invite-codes/...
/admin/feature-flags/...
/admin/launchpad
/admin/emails
/admin/activity
/admin/logs
/admin/reports/...
```

### Route File Organization
Keep admin routes in a dedicated routes file (e.g., `routes/admin.*`), separate from the main application routes. Conditionally load this file based on `ADMIN_ENABLED`.

---

## Scaling Notes

### Light-Weight Apps (Start Here)
- Just `is_super_admin` boolean, skip granular roles
- Skip 2FA (add later if needed)
- Skip invite codes if registration is open
- Skip feature flags (use env/config values)
- Dashboard with just key counts
- Launchpad with external links only
- Log viewers as stretch goals

### Heavy-Weight Apps (Scale Up)
- Fine-grained permissions with a dedicated permissions table
- User impersonation ("login as user") for support
- API token management for admin users
- IP whitelisting for admin routes
- Scheduled audit log cleanup
- Admin action rate limiting
- Real-time admin notifications (Slack/email for critical events)
- Multi-tenant admin support
- Custom report builder
- Data export across all admin sections

---

## File Checklist

Adapt names and locations to the project's conventions.

### Core Auth & Middleware
- [ ] Admin access middleware (super admin check)
- [ ] Account status middleware (suspend/block enforcement)
- [ ] 2FA middleware (optional)
- [ ] Middleware registration in app bootstrap

### Models / Entities
- [ ] User model updates (admin fields, status fields, 2FA fields, methods)
- [ ] Settings model (key-value store with caching)
- [ ] Audit log model
- [ ] Invite code model (with auto-generation)
- [ ] Feature flag model (with caching)
- [ ] Email log model
- [ ] Activity log model

### Services
- [ ] Audit service (centralized logging, sensitive field stripping)
- [ ] Analytics manager + provider adapters (Umami, OpenPanel, Swetrix, Clarity, etc.)
- [ ] CAPTCHA provider adapter (ALTCHA, CapJS) + NoOp fallback
- [ ] Email logger adapter (SeeSee) + fallback logger
- [ ] URL normalization utility (suffix stripping, auto-https)

### Admin Controllers / Handlers
- [ ] Dashboard
- [ ] Settings (with per-group update methods)
- [ ] User management
- [ ] 2FA controller (optional)
- [ ] Audit log viewer + export
- [ ] Invite code management
- [ ] Feature flag management
- [ ] Launchpad
- [ ] Email log viewer
- [ ] Activity log viewer
- [ ] Error log viewer

### Admin Views / Pages
- [ ] Dashboard
- [ ] Settings (tabbed interface)
- [ ] User list, detail, edit views
- [ ] 2FA setup, manage, challenge views (optional)
- [ ] Audit log list
- [ ] Invite code list, create, edit
- [ ] Feature flag list
- [ ] Launchpad
- [ ] Email log list
- [ ] Activity log list
- [ ] Error log viewer

### Middleware
- [ ] Security headers middleware (static headers + dynamic CSP with per-request nonce)
- [ ] Rate limiting on login endpoint (5/minute per IP)

### Configuration
- [ ] Admin config (2FA bypass, require_2fa, audit retention, admin_enabled)
- [ ] Launchpad links config (auto-derivation from functional env vars + manual LAUNCHPAD_* vars)
- [ ] Analytics provider config — see [Analytics Playbook](./ANALYTICS_PLAYBOOK.md)
- [ ] CAPTCHA provider config — see [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md)
- [ ] Error tracking config — see [Error Tracking](./ERROR_TRACKING.md)
- [ ] Email logging config — see [Email Infrastructure](./EMAIL_INFRASTRUCTURE.md)
- [ ] Super admin provisioning env variables (SUPER_ADMIN_*)
- [ ] URL normalization suffix map — see [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md)

### Routes
- [ ] Dedicated admin routes file
- [ ] Conditional loading based on ADMIN_ENABLED

### Migrations / Schema Changes
- [ ] User model: is_super_admin, role, account_status, suspension fields
- [ ] User model: 2FA fields (optional)
- [ ] Settings table
- [ ] Audit logs table
- [ ] Invite codes table
- [ ] Feature flags table
- [ ] Email logs table
- [ ] Activity logs table

### Integration Initialization
- [ ] `init_integrations()` startup function — orchestrates all provider init
- [ ] Health pings at startup (HEAD request to each configured service)
- [ ] Template globals setup (inject singletons for analytics_manager, captcha_provider)
- [ ] Graceful degradation for all external services (NoOp fallback, try/catch)

### Documentation
- [ ] `ADMIN.md` — Architecture decision (embedded vs. separate), setup instructions
- [ ] `.env.example` — Grouped by category per [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md)
- [ ] README updates — Admin env variables, how to run, how to access

---

*Created: 2026-03-27*
*Origin: Distilled from cross-project audit of 8 production codebases (March 2026).*
