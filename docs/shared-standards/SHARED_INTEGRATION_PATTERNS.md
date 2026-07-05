<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Shared Integration Patterns

> **Purpose:** Cross-cutting patterns for integrating external services (analytics, CAPTCHA, error tracking, email logging) across all projects. These patterns are referenced by multiple implementation guides and ensure consistency regardless of which specific service is being integrated.
>
> **Companion docs:**
> - [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) — Admin dashboard, user management, feature flags, launchpad
> - [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) — Analytics provider integration and event tracking
> - [Error Tracking](./ERROR_TRACKING.md) — GlitchTip/Sentry setup
> - [Email Infrastructure](./EMAIL_INFRASTRUCTURE.md) — Email sending and logging (SeeSee)
> - [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md) — CAPTCHA/PoW and multi-layer form protection

---

## 1. Environment Variable Naming Convention

All integration env vars must follow a **consistent naming pattern** across every project. This eliminates per-project guesswork about what a variable is called and makes Coolify/Doppler/.env management predictable — and, most importantly, it makes vars **safe to copy/paste between projects**: grab a block from a working project, change the values, done. No renaming, no transposition, no discovering three weeks later that email silently stopped because you wrote `MAIL_SMTP_SEESEE_*` in one project and `MAIL_SEESEE_SMTP_*` in another.

### Naming Pattern: `{CATEGORY}_{PROVIDER}_{PROPERTY}`

| Category | Purpose | Examples |
|----------|---------|---------|
| `ANALYTICS_` | Frontend analytics providers | `ANALYTICS_UMAMI_URL`, `ANALYTICS_UMAMI_WEBSITE_ID` |
| `CAPTCHA_` | CAPTCHA / proof-of-work providers | `CAPTCHA_PROVIDER`, `CAPTCHA_ALTCHA_URL`, `CAPTCHA_ALTCHA_SECRET` |
| `ERRORS_` | Error tracking | `ERRORS_GLITCHTIP_DSN`, `ERRORS_GLITCHTIP_SECURITY_ENDPOINT` |
| `MAIL_` | Email sending + logging | `MAIL_PROVIDER`, `MAIL_FASTMAIL_USERNAME`, `MAIL_SEESEE_URL` |
| `LAUNCHPAD_` | Admin tool quick-links (grouped) | `LAUNCHPAD_TOOLS_GLITCHTIP`, `LAUNCHPAD_LINKS_GITHUB`, `LAUNCHPAD_COOLIFY_LOGS` |
| `SUPER_ADMIN_` | Admin bootstrap credentials | `SUPER_ADMIN_EMAIL`, `SUPER_ADMIN_PASSWORD` |
| `ENABLE_` | Feature toggles / boolean flags | `ENABLE_REGISTRATION`, `ENABLE_RETAILER_AMAZON` |
| `SECURITY_` | Security header config | `SECURITY_HEADERS_ENABLED`, `CSP_ENABLED`, `CSP_REPORT_ONLY` |

### The Golden Rule: the PROVIDER is always second — a transport is NOT a category

This is the single rule that prevents the most common (and most silent) breakage.

**`SMTP`, `API`, `SMS`, `WEBHOOK` are transports/interfaces — they are PROPERTIES, never categories.** The provider name always comes immediately after the category prefix. The transport, if needed, comes *after* the provider.

| ✅ Correct | ❌ Wrong (transposition bug) |
|-----------|------------------------------|
| `MAIL_FASTMAIL_USERNAME` | `MAIL_SMTP_FASTMAIL_USER` |
| `MAIL_SEESEE_SMTP_PASSWORD` | `MAIL_SMTP_SEESEE_PASSWORD` |
| `MAIL_SEESEE_API_KEY` | `MAIL_API_SEESEE_KEY` |

Why this matters: when the provider is always in the same slot, you can copy `MAIL_FASTMAIL_*` from one project to the next and only change the credentials. When `SMTP` sometimes jumps into the provider slot, the vars stop matching, the mailer silently falls back to a disabled/no-op provider, and nothing sends until someone notices weeks later.

### Canonical Property Vocabulary — pick ONE noun, never a synonym

Most real-world drift is not structural — it's the same property spelled a different way in each project (`USER` vs `USERNAME`, `FROM` vs `FROM_ADDRESS`). Pick the canonical noun and **never** use the variant. When copy/pasting, this is what lets values line up.

| Concept | ✅ Canonical | ❌ Never use |
|---------|-------------|-------------|
| Login name | `_USERNAME` | `_USER` |
| Login secret | `_PASSWORD` | `_PASS`, `_PWD` |
| Sender address | `_FROM_ADDRESS` | `_FROM` |
| Sender display name | `_FROM_NAME` | `_FROMNAME`, `_SENDER` |
| OAuth-style public id | `_CLIENT_ID` | `_ID`, `_KEY` |
| OAuth-style secret | `_CLIENT_SECRET` | `_SECRET` (when paired with a client id) |
| Bearer / single API key | `_API_KEY` | `_KEY`, `_TOKEN`, `_API` |
| Key-pair public half | `_KEY_ID` / `_SITE_KEY` | `_PUBLIC_KEY`, `_APP_KEY` |
| Key-pair private half | `_SECRET_KEY` | `_SECRET`, `_ACCOUNT_SECRET`, `_PRIVATE_KEY` |
| Standalone HMAC/single secret | `_SECRET` | `_SECRET_KEY`, `_HMAC` |
| Umami site identifier | `_WEBSITE_ID` | `_SITE_ID` |
| Swetrix / GlitchTip project | `_PROJECT_ID` | `_PROJECT`, `_ID` |
| SeeSee / OpenPanel app id | `_APP_ID` | `_APP`, `_APPID` |

**Rule of thumb:** if a property has a natural counterpart, name them as a pair — `_CLIENT_ID`/`_CLIENT_SECRET`, `_KEY_ID`/`_SECRET_KEY`, `_SITE_KEY`/`_SECRET_KEY`. A provider with a single lone secret uses the bare `_SECRET` (ALTCHA) or `_API_KEY` (Resend, SeeSee bearer).

### The URL Triad — three fixed suffixes, one meaning each

Every service can have up to three URLs. Use exactly these suffixes so `_URL` **always** means "service base" everywhere (this is what the URL-normalization logic in §2 depends on):

| Suffix | Meaning | Example |
|--------|---------|---------|
| `_URL` | Service base URL (script host, dashboard host) | `ANALYTICS_UMAMI_URL=https://umami.bpf.fyi` |
| `_API_URL` | Ingest / API base (when different from the service base) | `ANALYTICS_OPENPANEL_API_URL=https://api.openpanel.bpf.fyi` |
| `_DASHBOARD_URL` | The human admin view you click into | `ANALYTICS_SWETRIX_DASHBOARD_URL=https://swetrix.bpf.fyi/projects/Ry2D7ojNYqIe` |

Do **not** invent `_INSTANCE_URL`, `_PROJECT_URL`, `_HOST_URL`, etc. for these — they collapse into the triad above. (`CAPTCHA_ALTCHA_URL`, not `CAPTCHA_ALTCHA_INSTANCE_URL`.)

### Framework Public-Var Prefixes (`VITE_`, `EXPO_PUBLIC_`, `NEXT_PUBLIC_`)

Client-exposed build tools require a prefix on any var shipped to the browser. When that's mandatory, **prepend the framework token to the *full* canonical name — never let it eat the category.**

| ✅ Correct | ❌ Wrong (category dropped) |
|-----------|-----------------------------|
| `VITE_ANALYTICS_UMAMI_WEBSITE_ID` | `VITE_UMAMI_WEBSITE_ID` |
| `EXPO_PUBLIC_ANALYTICS_OPENPANEL_CLIENT_ID` | `EXPO_PUBLIC_OPENPANEL_CLIENT_ID` |

The canonical name is preserved intact behind the prefix, so the same grep (`ANALYTICS_UMAMI_WEBSITE_ID`) finds it in every project regardless of framework.

### Rules Summary

1. **Category first** — related vars group together when sorted.
2. **Provider second** — always the same slot; a transport (`SMTP`/`API`) is a property, not a category (see Golden Rule).
3. **Canonical property last** — one noun per concept (see vocabulary table), never a synonym.
4. **Empty = disabled** — an empty string means off. No `ANALYTICS_ENABLED=false` toggles; just leave the URL/key blank.
5. **`_URL` always means base URL** — use the URL triad for the other two flavors.
6. **Framework prefixes wrap the full name** — `VITE_`/`EXPO_PUBLIC_`/`NEXT_PUBLIC_` prepend, never replace, the category.

### Launchpad Links: explicit is the reliable default; derivation is a bonus

Ideally the admin launchpad *derives* its links from the functional env vars already present (e.g. build the SeeSee "Emails" link from `MAIL_SEESEE_URL` + `MAIL_SEESEE_APP_ID`). Do this where it works — it's DRY and there's nothing extra to maintain.

**But derivation has proven unreliable across projects** (different frameworks, missing app-ids, dashboard URLs that don't follow a derivable pattern), and a launchpad link that silently fails to render is exactly the kind of papercut that erodes trust in the admin panel. So the standard is a **hybrid**:

- **Explicit `LAUNCHPAD_*` vars are always acceptable and are the reliable default.** When you want a link to definitely appear, set it explicitly. This is also the most copy/paste-friendly across projects — grab the whole `LAUNCHPAD_*` block, swap the slugs.
- **Derivation is a bonus, not a requirement.** Derive when the pattern is clean; fall back to explicit whenever derivation is flaky.
- **When both exist for the same tool, the explicit `LAUNCHPAD_*` var wins.** (This intentionally relaxes the old "never duplicate" rule for launchpad links specifically — the reliability of an always-present link is worth the one duplicated URL.)

**Launchpad taxonomy — grouped, no `_URL` suffix:** `LAUNCHPAD_{GROUP}_{ITEM}`. The `LAUNCHPAD_` prefix already implies "a link," so no `_URL` suffix. Standard groups:

| Group | Purpose | Examples |
|-------|---------|----------|
| `LAUNCHPAD_LINKS_` | First-party / external destinations | `LAUNCHPAD_LINKS_GITHUB`, `LAUNCHPAD_LINKS_STRIPE_DASHBOARD`, `LAUNCHPAD_LINKS_FASTMAIL` |
| `LAUNCHPAD_TOOLS_` | Self-hosted ops tools | `LAUNCHPAD_TOOLS_GLITCHTIP`, `LAUNCHPAD_TOOLS_DB_ADMINER`, `LAUNCHPAD_TOOLS_UPTIMEKUMA`, `LAUNCHPAD_TOOLS_SEESEE_EMAIL` |
| `LAUNCHPAD_ANALYTICS_` | Analytics dashboards | `LAUNCHPAD_ANALYTICS_UMAMI`, `LAUNCHPAD_ANALYTICS_OPENPANEL`, `LAUNCHPAD_ANALYTICS_SWETRIX` |
| `LAUNCHPAD_COOLIFY_` | Hosting sub-pages | `LAUNCHPAD_COOLIFY_CONFIG`, `LAUNCHPAD_COOLIFY_DEPLOYS`, `LAUNCHPAD_COOLIFY_ENV`, `LAUNCHPAD_COOLIFY_LOGS`, `LAUNCHPAD_COOLIFY_TERMINAL` |

### .env.example Formatting

Group by category with section headers. Empty values = disabled. Include brief comments explaining what each section does. This block is the copy/paste reference — the property names here are the canonical ones:

```env
# ── Super Admin ───────────────────────────
SUPER_ADMIN_EMAIL=
SUPER_ADMIN_PASSWORD=

# ── Analytics — Self-Hosted ───────────────
# Any/all can be active simultaneously. Empty = disabled.
# Frontend script injection only (public pages). Defaults are the bpf.fyi
# self-hosted instances — confirm before assuming cloud (see ANALYTICS_PLAYBOOK §7).
# _URL = base/script/dashboard host; _API_URL = ingest host; _DASHBOARD_URL = click-through admin link.
# Umami: _URL is accepted with OR without a trailing /script.js — normalize to the base.
ANALYTICS_UMAMI_URL=
ANALYTICS_UMAMI_WEBSITE_ID=
ANALYTICS_UMAMI_DASHBOARD_URL=                 # {UMAMI_URL}/websites/{WEBSITE_ID} (derivable)
ANALYTICS_OPENPANEL_URL=
ANALYTICS_OPENPANEL_API_URL=
ANALYTICS_OPENPANEL_CLIENT_ID=
ANALYTICS_OPENPANEL_CLIENT_SECRET=
ANALYTICS_OPENPANEL_DASHBOARD_URL=             # {OPENPANEL_URL}/{org}/{app} — NOT derivable, set explicitly
ANALYTICS_SWETRIX_URL=
ANALYTICS_SWETRIX_API_URL=
ANALYTICS_SWETRIX_PROJECT_ID=
ANALYTICS_SWETRIX_DASHBOARD_URL=               # {SWETRIX_URL}/projects/{PROJECT_ID} (derivable)

# ── Analytics — Third-Party ───────────────
ANALYTICS_CLARITY_PROJECT_ID=
ANALYTICS_POSTHOG_API_KEY=
ANALYTICS_POSTHOG_HOST=
ANALYTICS_GA4_MEASUREMENT_ID=

# ── CAPTCHA ───────────────────────────────
# Provider: "altcha", "capjs", or leave empty to disable.
CAPTCHA_PROVIDER=
CAPTCHA_ALTCHA_URL=
CAPTCHA_ALTCHA_SECRET=
CAPTCHA_CAPJS_URL=
CAPTCHA_CAPJS_KEY_ID=
CAPTCHA_CAPJS_SECRET_KEY=

# ── Error Tracking ────────────────────────
ERRORS_GLITCHTIP_DSN=
ERRORS_GLITCHTIP_SECURITY_ENDPOINT=

# ── Email — Sending ───────────────────────
# MAIL_PROVIDER selects the active sender: "smtp", "resend", "fastmail", "gmail", "log".
# MAIL_ENABLED_PROVIDERS (optional) lists all wired providers for multi-provider setups.
# Provider is ALWAYS the second token; SMTP is a property, not a category.
MAIL_PROVIDER=
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME=
# — Resend (API) —
MAIL_RESEND_API_KEY=
MAIL_RESEND_FROM_ADDRESS=
# — Fastmail (SMTP) —
MAIL_FASTMAIL_HOST=smtp.fastmail.com
MAIL_FASTMAIL_PORT=587
MAIL_FASTMAIL_ENCRYPTION=tls
MAIL_FASTMAIL_USERNAME=
MAIL_FASTMAIL_PASSWORD=
MAIL_FASTMAIL_FROM_ADDRESS=

# ── Email — Logging (SeeSee) ──────────────
# Sent-email log aggregator. Empty = disabled. Has BOTH an API and an SMTP interface —
# note SMTP is a property AFTER the provider: MAIL_SEESEE_SMTP_*.
MAIL_SEESEE_URL=
MAIL_SEESEE_API_KEY=
MAIL_SEESEE_APP_ID=
MAIL_SEESEE_SMTP_USERNAME=
MAIL_SEESEE_SMTP_PASSWORD=

# ── Launchpad — Admin Quick-Links ─────────
# Explicit links are the reliable default; grouped, no _URL suffix.
# Copy this block between projects and swap the slugs.
LAUNCHPAD_LINKS_GITHUB=
LAUNCHPAD_LINKS_STRIPE_DASHBOARD=
LAUNCHPAD_TOOLS_GLITCHTIP=
LAUNCHPAD_TOOLS_DB_ADMINER=
LAUNCHPAD_TOOLS_UPTIMEKUMA=
LAUNCHPAD_TOOLS_SEESEE_EMAIL=
LAUNCHPAD_ANALYTICS_UMAMI=
LAUNCHPAD_ANALYTICS_OPENPANEL=
LAUNCHPAD_ANALYTICS_SWETRIX=
LAUNCHPAD_COOLIFY_CONFIG=
LAUNCHPAD_COOLIFY_DEPLOYS=
LAUNCHPAD_COOLIFY_LOGS=

# ── Security Headers ─────────────────────
SECURITY_HEADERS_ENABLED=true
CSP_ENABLED=false
CSP_REPORT_ONLY=true

# ── Feature Toggles ──────────────────────
ENABLE_REGISTRATION=false
ENABLE_SEARCH_TRACKING=false
```

---

## 2. URL Normalization

### The Problem

Different analytics/CAPTCHA/email tools require URLs in different forms:
- Umami script: `https://umami.example.com/script.js`
- OpenPanel script: `https://panel.example.com/op.js`
- Swetrix API endpoint: `https://api.swetrix.example.com/log`
- ALTCHA challenge endpoint: `https://altcha.example.com/api/v1/challenge`
- SeeSee logging endpoint: `https://seesee.example.com/api/v1/log`

Developers paste whatever URL they have — sometimes the base URL, sometimes the full script/API path. This causes inconsistency across projects and broken integrations.

### The Solution

**Always store the base URL in the env var. Always strip paths in the config validator. Always append paths in the code.**

Define a **suffix map** per integration — a list of known path suffixes to strip during config validation:

```python
# Pseudocode — adapt to your language
INTEGRATION_URL_SUFFIXES = {
    "analytics_umami_url":    ["/script.js"],
    "analytics_openpanel_url": ["/op.js"],
    "analytics_swetrix_url":  ["/swetrix.js"],
    "captcha_altcha_url":     ["/widget/altcha.min.js", "/js/altcha.min.js",
                               "/api/challenge/*", "/api/verify/*", "/api/v1/challenge"],
    "captcha_capjs_url":      ["/assets/widget.js", "/assets/floating.js"],
    "mail_seesee_url":        ["/api/v1/log", "/api/v1"],
}
```

### Normalization Logic

```python
def normalize_url(raw_url: str, field_name: str) -> str:
    """Strip known path suffixes, ensure https://, return base URL only."""
    if not raw_url:
        return ""

    url = raw_url.strip().rstrip("/")

    # Auto-prepend https:// if no protocol
    if not url.startswith(("http://", "https://")):
        url = f"https://{url}"

    # Strip known suffixes for this field
    suffixes = INTEGRATION_URL_SUFFIXES.get(field_name, [])
    for suffix in suffixes:
        if "*" in suffix:
            # Wildcard match: "/api/challenge/*" matches "/api/challenge/proj123"
            prefix = suffix.split("*")[0]
            if prefix in url:
                url = url[:url.index(prefix)].rstrip("/")
                break
        elif url.endswith(suffix):
            url = url[:-len(suffix)].rstrip("/")
            break

    return url
```

### How This Works in Practice

| Developer pastes | Field | Normalized to | Code appends |
|------------------|-------|---------------|--------------|
| `https://umami.bpf.fyi/script.js` | `ANALYTICS_UMAMI_URL` | `https://umami.bpf.fyi` | `/script.js` |
| `https://umami.bpf.fyi` | `ANALYTICS_UMAMI_URL` | `https://umami.bpf.fyi` | `/script.js` |
| `umami.bpf.fyi` | `ANALYTICS_UMAMI_URL` | `https://umami.bpf.fyi` | `/script.js` |
| `https://altcha.bpf.fyi/api/v1/challenge` | `CAPTCHA_ALTCHA_URL` | `https://altcha.bpf.fyi` | `/api/v1/challenge` |
| `https://seesee.bpf.fyi/api/v1/log` | `MAIL_SEESEE_URL` | `https://seesee.bpf.fyi` | `/api/v1/log` |

**Result:** It doesn't matter what the developer pastes — the system always ends up with the correct base URL, and the code appends the correct path.

### Where to Apply

Run normalization at **config load time** (not at usage time). In Python/Pydantic this is a model validator. In Laravel it's a config service provider. In Node it's the config module initialization.

```python
# Pydantic example (BookLink.fyi pattern)
class Settings(BaseSettings):
    analytics_umami_url: str = ""
    analytics_umami_website_id: str = ""
    # ...

    @model_validator(mode="after")
    def _normalize_integration_urls(self):
        for field_name, suffixes in INTEGRATION_URL_SUFFIXES.items():
            value = getattr(self, field_name, "")
            if value:
                setattr(self, field_name, normalize_url(value, field_name))
        return self
```

---

## 3. Integration Initialization & Graceful Degradation

### Startup Pattern

All integrations initialize as **module-level singletons** at app startup. A single `init_integrations(settings)` function orchestrates everything:

```python
# Pseudocode
analytics_manager = AnalyticsManager()          # Empty until init
captcha_provider = NoOpCaptchaProvider()         # Safe default
email_service = None

def init_integrations(settings):
    global analytics_manager, captcha_provider, email_service

    # Analytics — multiple providers simultaneously
    analytics_manager = init_analytics(settings)  # Returns manager with 0+ providers

    # CAPTCHA — single active provider
    captcha_provider = init_captcha(settings)      # Returns provider or NoOp

    # Email logging
    email_service = init_email(settings)           # Returns service or None

    # Error tracking — side-effect only (Sentry init)
    init_error_tracking(settings)
```

### Health Pings at Startup

Each provider is **pinged** during initialization. A HEAD request (falling back to GET on 405) verifies the service is reachable. Unreachable providers log a warning and are either skipped or degraded.

### Graceful Degradation Rules

| Situation | Behavior |
|-----------|----------|
| Env var empty | Factory returns NoOp. Zero overhead. |
| Env var set but service unreachable | Log warning. Skip provider (analytics) or use NoOp (CAPTCHA). |
| Service configured and reachable | Normal operation. |
| Service goes down after startup | Individual calls fail silently, log warning. App continues. |

**Critical rule:** Never let a monitoring tool take down the app it monitors. All external integration calls are wrapped in try/catch and fail silently.

### Init Order

```
Database        → REQUIRED (fail fast if unavailable)
Redis/Cache     → Recommended (degrade gracefully)
Error tracking  → Independent (best-effort, side-effect init)
Analytics       → Independent (0+ providers, all best-effort)
CAPTCHA         → Independent (NoOp fallback)
Email logging   → Independent (NoOp fallback)
```

### Template Globals

After init, inject singletons into template globals so templates can render script tags and widgets without per-request lookups:

```python
# Set once at startup
templates.env.globals["analytics_manager"] = analytics_manager
templates.env.globals["captcha_provider"] = captcha_provider
```

---

## 4. Adapter / Abstraction Pattern

Every external integration follows the same structural pattern. This is not optional — it's what makes swapping providers a config change instead of a rewrite.

### Pattern

```
Interface/ABC          → Defines the contract (verify, render, track, log, etc.)
ConcreteProvider(s)    → One per provider (Umami, ALTCHA, SeeSee, GlitchTip, etc.)
NoOpProvider           → Returns safe defaults when disabled (empty string, True, None)
Factory                → Reads env vars, returns the right provider (or NoOp)
Manager (if multi)     → Holds 0+ providers and fans out calls (analytics)
```

### Examples by Domain

| Domain | Interface | Providers | Multi? |
|--------|-----------|-----------|--------|
| Analytics | `AnalyticsProvider` | Umami, OpenPanel, Swetrix, Clarity, PostHog | Yes (fan-out via Manager) |
| CAPTCHA | `CaptchaProvider` | ALTCHA, CapJS | No (single active) |
| Email Logging | `EmailLogger` | SeeSee, LoggingLogger | No (single active) |
| Error Tracking | Side-effect init | GlitchTip/Sentry | No (single active) |

### Key Rules

1. **Application code never references a specific provider** — it calls the interface
2. **NoOp is always safe** — `verify()` returns True, `render()` returns empty string, `track()` does nothing
3. **Factory reads env vars once at startup** — provider selection is not per-request
4. **Providers are independently testable** — each provider class can be unit tested in isolation

---

*Created: 2026-03-27*
*Extracted from cross-project patterns observed across 8 production codebases.*
