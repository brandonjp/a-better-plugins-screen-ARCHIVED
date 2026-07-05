<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Email Infrastructure Implementation Guide

> **Purpose:** A cross-project directive for implementing production-grade email infrastructure: environment-based config, rate-limited delivery, async queuing, structured email classes, HTML templates, error handling, and scheduled commands. Framework-agnostic — the implementing AI analyzes the project's actual tech stack before writing any code.
>
> **Companion docs:**
> - [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md) — Env var naming, graceful degradation
> - [Shared Infrastructure Decision Guide](./SHARED_INFRA_DECISION_GUIDE.md) — When/whether to adopt SeeSee
> - [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) — Admin dashboard email log viewer, launchpad links
> - [Project Health Checklist](./PROJECT_HEALTH_CHECKLIST.md) — Background jobs & scheduled tasks (Section 4)

---

## Critical Instruction: Analyze Before Implementing

**Before writing any code, you MUST:**

1. **Examine the project's tech stack** — Identify the language, framework, package manager, existing dependencies, and project structure. Do NOT assume any particular framework (e.g., Laravel, Django, Express, Rails). Let the codebase tell you what to use.
2. **Identify existing patterns** — Look at how the project currently handles configuration, environment variables, services/dependency injection, background jobs, database access, and logging. Match those patterns exactly.
3. **Check for existing email infrastructure** — The project may already have partial email support (e.g., a mailer library, templates, queue system). Build on what exists rather than replacing it.
4. **Use idiomatic solutions** — Use the framework's native mail/queue/config abstractions where they exist. If the project is a plain Node.js app, don't import Laravel-style patterns. If it's Flask, don't introduce Django conventions.

**The guidance below describes WHAT to implement, not HOW.** The "how" must come from the project itself.

---

## Overview

Implement email infrastructure with these capabilities:

1. **Environment-Based Configuration** — All email settings via environment variables (`.env` or equivalent)
2. **Rate-Limited Email Delivery** — Throttled sending to stay within free-tier provider limits
3. **Queued/Async Email Delivery** — Emails sent asynchronously so they don't block request handling
4. **Structured Email Classes/Templates** — Reusable, type-safe email definitions
5. **HTML Email Templates** — Standalone templates with inline CSS for cross-client compatibility
6. **Error Handling & Logging** — Graceful failure that never blocks business operations
7. **Scheduled Email Commands** — CLI commands for automated reminder/digest emails via cron

---

## 1. Environment-Based Configuration

### Approach
All email settings are configured exclusively through environment variables. No database-backed configuration, no admin UI for email setup.

### Naming: provider is ALWAYS the second token

Follow the [Shared Integration Patterns — Env Var Naming Convention](./SHARED_INTEGRATION_PATTERNS.md#1-environment-variable-naming-convention). The one rule that matters most for email — because getting it wrong fails **silently** and can go unnoticed for weeks — is the **Golden Rule**: the provider name comes immediately after the `MAIL_` prefix. A transport like `SMTP` or `API` is a *property*, so it comes **after** the provider, never before it.

| ✅ Correct | ❌ Wrong (silently breaks sending) |
|-----------|-----------------------------------|
| `MAIL_FASTMAIL_USERNAME` | `MAIL_SMTP_FASTMAIL_USER` |
| `MAIL_SEESEE_SMTP_PASSWORD` | `MAIL_SMTP_SEESEE_PASSWORD` |
| `MAIL_RESEND_API_KEY` | `MAIL_API_RESEND_KEY` |

Also use the canonical property nouns: `_USERNAME` (not `_USER`), `_PASSWORD` (not `_PASS`), `_FROM_ADDRESS` (not `_FROM`).

### Required Environment Variables

**Single-provider app** (simplest — one active sender):

```env
# Active provider + sender defaults
MAIL_PROVIDER=smtp              # smtp, resend, fastmail, gmail, ses, postmark, sendgrid, log
MAIL_FROM_ADDRESS=noreply@yourapp.com
MAIL_FROM_NAME=YourAppName

# Generic SMTP transport (when MAIL_PROVIDER=smtp)
MAIL_SMTP_HOST=smtp.example.com
MAIL_SMTP_PORT=587
MAIL_SMTP_USERNAME=your_username
MAIL_SMTP_PASSWORD=your_password
MAIL_ENCRYPTION=tls             # tls, ssl, none

# Rate limiting (see Section 2)
MAIL_RATE_LIMIT_PER_HOUR=100    # Max emails per hour (match your provider's free tier)
MAIL_RATE_LIMIT_PER_MINUTE=10   # Max emails per minute (burst limit)

# Queue settings
QUEUE_CONNECTION=database       # database, redis, sync (sync = no async, dev only)
```

**Multi-provider app** (several senders wired, one active — the same var lines up in every project so you can copy/paste a provider block between projects and only change credentials):

```env
MAIL_PROVIDER=resend                    # which provider is active right now
MAIL_ENABLED_PROVIDERS=resend,fastmail  # optional: all wired providers
MAIL_FROM_ADDRESS=noreply@yourapp.com

# — Resend (API provider) —
MAIL_RESEND_API_KEY=
MAIL_RESEND_FROM_ADDRESS=

# — Fastmail (SMTP provider) — note: provider first, SMTP props follow
MAIL_FASTMAIL_HOST=smtp.fastmail.com
MAIL_FASTMAIL_PORT=587
MAIL_FASTMAIL_ENCRYPTION=tls
MAIL_FASTMAIL_USERNAME=
MAIL_FASTMAIL_PASSWORD=
MAIL_FASTMAIL_FROM_ADDRESS=
```

### Implementation Notes
- Load these at application startup using the project's standard config pattern
- Validate that critical values (`MAIL_FROM_ADDRESS`, active-provider credentials) are present before attempting to send
- Support a `log` provider that writes emails to the application log instead of sending (for development/testing)
- `MAIL_PROVIDER` is the single selector for the active sender; keep provider-specific credentials under `MAIL_{PROVIDER}_*` so switching providers is a one-line change to `MAIL_PROVIDER`

---

## 2. Rate-Limited Email Delivery (Critical)

### Why This Matters
We are using a free-tier email service with hard rate limits. Exceeding these limits means emails get rejected or the account gets suspended. The email system MUST enforce rate limits at the application level.

### Rate Limiting Strategy

Implement a **token bucket** or **sliding window** rate limiter with two tiers:

| Limit | Default | Purpose |
|-------|---------|---------|
| Per-minute burst | 10 | Prevents short bursts from tripping provider limits |
| Per-hour sustained | 100 | Stays within free-tier hourly/daily caps |

These defaults should be configurable via `MAIL_RATE_LIMIT_PER_HOUR` and `MAIL_RATE_LIMIT_PER_MINUTE` environment variables.

### Implementation Requirements

```
EmailRateLimiter
├── canSend() → bool          # Check if sending is allowed right now
├── recordSend()              # Record that an email was sent (update counters)
├── getWaitTime() → seconds   # How long to wait before next send is allowed
└── getRemainingQuota() → int # How many emails can still be sent this hour
```

**Storage for rate limit counters:** Use whatever the project already has — database, Redis, cache, or even a simple file-based counter for low-volume apps. The counter must persist across requests but does NOT need to survive server restarts (it's self-healing — limits reset naturally).

### Behavior When Rate Limited

When the rate limit is reached, the system should:

1. **For queued emails:** Re-queue the email with a delay equal to `getWaitTime()`. Do NOT drop it.
2. **For synchronous sends:** Log a warning and return a "rate limited" status. The caller decides whether to retry.
3. **Always log:** Record rate limit events so operators can see if limits need adjustment.

### Priority Sending (Optional but Recommended)

If the project sends both transactional and non-critical emails, implement a simple priority system:

- **High priority:** Password resets, account verification, payment receipts — these skip ahead in the queue
- **Normal priority:** Notifications, updates, reminders — these yield to high-priority sends
- **Low priority:** Digests, marketing, bulk — these only send when there's remaining quota

This can be as simple as separate queues/channels or a priority field on the job.

### Monitoring & Visibility

Add a CLI command or log output that shows current rate limit status:

```
$ your-app email:status
Emails sent this hour:  47 / 100
Emails sent this minute: 3 / 10
Queue depth:            12 pending
Next send allowed:      now
```

---

## 3. Queue System for Email Delivery

### Requirements
- All emails should be sent asynchronously by default
- Use the project's existing queue/job system if one exists
- If no queue system exists, implement a simple database-backed job queue or use the framework's recommended approach
- Provide a fallback synchronous mode for development (`QUEUE_CONNECTION=sync` or equivalent)

### Queue Worker
- Provide clear instructions (in a README or comments) for running the queue worker in development and production
- The worker should respect rate limits (Section 2) — if rate limited, delay the job rather than failing it
- Failed emails should be logged and retried (up to 3 attempts with exponential backoff)

### Required Infrastructure
Ensure the project has the necessary tables/storage for:
- **Job queue** — pending jobs with payload, attempts, scheduled time
- **Failed jobs** — jobs that exceeded retry attempts, with error details for debugging

---

## 4. Structured Email Definitions

### Pattern
Each email type gets its own class/module. The exact structure depends on the framework, but each email definition should encapsulate:

- **Subject line** (can be dynamic based on data)
- **Template reference** (which HTML template to render)
- **Data/context** (variables passed to the template)
- **Priority level** (high, normal, low — for rate limiting)

### Typical Email Types to Implement

Adapt these to the project's domain. Common categories:

**Transactional (triggered by user actions):**
- Receipts/confirmations (e.g., purchase receipt, order confirmation)
- Invitation emails (with unique token-based claim URLs)
- Status change notifications (e.g., order shipped, payment processed)
- Action-required emails (e.g., consent requests with approve/decline links)

**Automated (triggered by schedule or system events):**
- Reminder emails (configurable schedule, e.g., days 3, 6, 13 after signup)
- Digest emails (daily/weekly/monthly summary)

### Dynamic Subjects

Subjects should be computed based on model/data state:

```
# Pseudocode — adapt to your language/framework
subject = switch(model.status):
    "expired"  → "Your item has expired"
    "failed"   → "Action failed for your item"
    default    → "Update about your item"
```

---

## 5. Email Templates (HTML)

### Location
Create a dedicated directory for email templates (e.g., `templates/emails/`, `resources/views/emails/`, `src/emails/templates/` — follow the project's convention).

### Template Approach
Use **self-contained HTML templates** with inline CSS. Do NOT rely on a shared layout component — this makes each template independently portable and avoids rendering issues across email clients.

### Template Structure

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Subject</title>
    <style>
        /* Inline all CSS — email clients strip <link> tags */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header { text-align: center; margin-bottom: 30px; }
        .content {
            background: #f9fafb;
            border-radius: 8px;
            padding: 30px;
            margin: 20px 0;
        }
        .button {
            display: inline-block;
            background: #4F46E5;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 600;
        }
        .footer {
            text-align: center;
            color: #6b7280;
            font-size: 14px;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">{{ appName }}</div>
    </div>

    <div class="content">
        <p>Hi {{ userName }},</p>
        <p>Your email body content here.</p>

        <!-- CTA button -->
        <div style="text-align: center;">
            <a href="{{ actionUrl }}" class="button">Take Action</a>
        </div>
    </div>

    <div class="footer">
        <p>If you have any questions, reply to this email.</p>
    </div>
</body>
</html>
```

### Key Template Patterns
- **Tables for data display** (e.g., order line items, invoice rows) — use `<table>` with inline styles, as email clients handle tables better than flexbox/grid
- **Conditional sections** — use template conditionals for optional content
- **CTA buttons** — use inline-styled `<a>` tags, not `<button>` elements
- **Token-based action URLs** — for approve/decline flows, pass signed URLs with unique tokens

---

## 6. Error Handling

### Principle
Email failures must **never block business operations**. Wrap every email send in error handling and log the failure.

```
# Pseudocode
function notifyUser(user, emailData):
    try:
        rateLimiter.waitIfNeeded()
        mailService.queue(user.email, new SomeEmail(emailData))
    catch Exception as e:
        log.error("Failed to send email", {
            user_id: user.id,
            email_type: "SomeEmail",
            error: e.message
        })
        # Do NOT re-throw — the business operation should continue
```

### Duplicate Prevention
For critical emails like receipts, track whether they've been sent:

```
# Pseudocode
function sendReceipt(order):
    if order.receipt_sent_at is not null:
        return  # Already sent — skip

    mailService.queue(order.email, new ReceiptEmail(order))
    order.update({ receipt_sent_at: now() })
```

---

## 7. Scheduled Email Commands

### Artisan/CLI Command for Automated Reminders

Create a CLI command that can be invoked by cron:

```
$ your-app emails:send-reminders
Sending reminders...
Sent 7 reminder(s).
```

### Reminder Logic

```
# Pseudocode
REMINDER_DAYS = [3, 6, 13]  # Days after signup to send reminders

function getRecipientsNeedingReminders():
    recipients = {}
    for day in REMINDER_DAYS:
        targetDate = today() - day
        users = User.where(needs_reminder: true, created_at_date: targetDate)
        if users.isNotEmpty():
            recipients[day] = users
    return recipients

function sendDueReminders():
    sent = 0
    for day, users in getRecipientsNeedingReminders():
        for user in users:
            mailService.queue(user.email, new ReminderEmail(user, day))
            sent++
    return sent
```

### Schedule Registration
Register the command to run via cron (e.g., daily at 8:00 AM). Use the project's native scheduling mechanism.

---

## 8. Token-Based Email Actions

### Purpose
Some emails need actionable links (approve/decline, claim invitation, etc.). Use cryptographically random tokens stored in the database.

### Token Generation

```
# Pseudocode
function generateUniqueToken():
    do:
        token = randomString(64)  # Cryptographically secure
    while Model.where(token_column: token).exists()
    return token
```

### Token Routes (Public, No Auth Required)

```
GET  /claim/{token}   → Show claim/action page
POST /claim/{token}   → Process the action
```

---

## 9. Security Considerations

- **Never log email credentials** in application logs
- **Use unique, random tokens** (64+ chars) for email action links — not sequential IDs
- **Validate email inputs** on all endpoints
- **Rate-limit** email-triggering endpoints (e.g., verification resend: max 6/minute)
- **Use signed/expiring URLs** for sensitive email actions when the framework supports them

---

## 10. Scaling Notes

### Current Stage (Free Tier — Start Here)
- Environment-based config only (no admin UI)
- Application-level rate limiting matched to provider limits
- Database-backed queue (simplest, no external dependencies)
- Single mail provider, no failover

### When You Outgrow Free Tier
- Increase `MAIL_RATE_LIMIT_*` values to match paid tier limits
- Add failover provider support (try primary, fall back to secondary)
- Switch to Redis-backed queue for higher throughput
- Add per-recipient rate limiting to prevent spam complaints

### Heavy-Weight (Future Considerations)
- Dedicated `email_logs` table tracking every email (recipient, subject, status, sent_at, opened_at)
- Webhook endpoints for bounce/complaint handling from providers
- Email template management in the database (editable by non-developers)
- Unsubscribe link management (CAN-SPAM compliance)
- Dedicated email queues (e.g., `high` for transactional, `low` for bulk)

---

## File Checklist

When implementing, you should create or modify these files (adapt names and locations to the project's conventions):

### Core Service Layer
- [ ] Email sending service — wraps provider-specific logic, applies rate limiting
- [ ] Rate limiter — token bucket or sliding window implementation
- [ ] Queue integration — async email dispatch with retry logic

### Configuration
- [ ] Mail provider config — loaded from environment variables
- [ ] Queue config — driver selection, retry settings

### Database / Storage
- [ ] Migration: Job queue tables (if using database-backed queue)
- [ ] Migration: Failed jobs table
- [ ] Rate limit counter storage (database, cache, or file-based)

### Email Definitions
- [ ] One class/module per email type
- [ ] One HTML template per email type (in the project's template directory)

### CLI Commands
- [ ] `emails:send-reminders` — scheduled reminder sender
- [ ] `email:status` — rate limit and queue status display

### Documentation
- [ ] Update README with email setup instructions (env vars, queue worker, cron)

---

## 8. Email Logging (SeeSee)

### Purpose

SeeSee is a self-hosted email logging service. Projects that send transactional email should log every outbound email to SeeSee for visibility and debugging. Sending and logging are **separate concerns** — the email sender and the email logger are independent abstractions composed together.

### When to Adopt

- The project sends transactional email (welcome emails, receipts, notifications, invitations, password resets).
- **Do not** add this preemptively if the project does not send email.

### Environment Variables

```env
MAIL_SEESEE_URL=                    # Base URL (code appends /api/v1/log, /api/v1/emails, etc.)
MAIL_SEESEE_API_KEY=                # Bearer token for authentication (API interface)
MAIL_SEESEE_APP_ID=                 # App ID for building dashboard URLs
# SeeSee also exposes an SMTP interface. SMTP is a property AFTER the provider —
# MAIL_SEESEE_SMTP_*, never MAIL_SMTP_SEESEE_*.
MAIL_SEESEE_SMTP_USERNAME=          # SMTP interface username (usually the app slug)
MAIL_SEESEE_SMTP_PASSWORD=          # SMTP interface password
```

> **Always include `MAIL_SEESEE_APP_ID`** even if you also set an explicit `LAUNCHPAD_TOOLS_SEESEE_EMAIL` link — the app id is what lets the admin dashboard and launchpad derive the SeeSee links, and it's cheap insurance.

### Architecture

```
EmailProvider (ABC):       # For sending — wrap your existing mailer
    send(to, subject, body) → bool

EmailLogger (ABC):         # For logging — separate from sending
    log(to, subject, status, provider) → void

EmailService (composite):  # Orchestrates both
    send_and_log(to, subject, body)
        → calls provider.send()
        → calls logger.log() (fire-and-forget, non-blocking)

SeeSeeLogger implements EmailLogger:
    → POST to {MAIL_SEESEE_URL}/api/v1/log with Authorization: Bearer {api_key}
    → Falls back to Python/app logger if SeeSee unreachable

LoggingEmailLogger implements EmailLogger:
    → Writes to application log (dev/fallback)
```

### Key Rules

- **Fire-and-forget** — Logging must never block email delivery or the HTTP response
- **Fail silently** — If SeeSee is unreachable, fall back to the application logger. Never fail the page or the email send.
- **Separate abstractions** — The email sender knows nothing about logging. The logger knows nothing about sending. The composite EmailService wires them together.

### Admin Dashboard Integration

Query SeeSee API live to display recent emails — no local email_logs table needed:
- `GET {MAIL_SEESEE_URL}/api/v1/emails?app_id={app_id}&limit=25`
- Display: To, Subject, Status, Sent At
- If SeeSee unreachable or not configured, show "Email logs unavailable" — never fail the page

### Launchpad Auto-Derivation

When `MAIL_SEESEE_URL` + `MAIL_SEESEE_APP_ID` are configured, the admin launchpad auto-derives:
- "Emails" link → `{url}/emails?app_id={app_id}`
- "App Config" link → `{url}/apps/{app_id}`

See [Super Admin Tooling — Launchpad](./SUPER_ADMIN_TOOLING.md#11-launchpad-external-tools-hub) for the full auto-derivation pattern.

### Audit Checklist

- [ ] SeeSee integration configured (`MAIL_SEESEE_URL`, `MAIL_SEESEE_API_KEY`, `MAIL_SEESEE_APP_ID`)
- [ ] Emails logged after send (fire-and-forget)
- [ ] Fallback to app logger if SeeSee unreachable
- [ ] Recent emails displayed in admin dashboard (if admin panel exists)
- [ ] Link to SeeSee dashboard in admin launchpad
