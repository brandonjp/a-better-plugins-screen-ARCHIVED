<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Error Tracking (GlitchTip / Sentry)

> **Purpose:** Implementation guide for self-hosted, Sentry-compatible error tracking across all projects. GlitchTip is the primary provider; any Sentry-compatible service works with the same SDK and configuration.
>
> **Companion docs:**
> - [Shared Infrastructure Decision Guide](./SHARED_INFRA_DECISION_GUIDE.md) — When/whether to adopt GlitchTip (spoiler: every project)
> - [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md) — Env var naming, graceful degradation
> - [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) — Launchpad links and admin dashboard integration

---

## When to Adopt

**Every project.** Error tracking is non-negotiable regardless of project type — static sites, APIs, mobile apps, games, CLI tools. The only reason to defer is if the project is a throwaway prototype.

---

## Environment Variables

```bash
ERRORS_GLITCHTIP_DSN=https://key@your-glitchtip.example.com/1
ERRORS_GLITCHTIP_SECURITY_ENDPOINT=https://your-glitchtip.example.com/api/1/security/

# Framework-specific prefixes:
# Expo/React Native: EXPO_PUBLIC_GLITCHTIP_DSN=...
# Astro:            PUBLIC_GLITCHTIP_DSN=...
# Vite:             VITE_GLITCHTIP_DSN=...
```

---

## Implementation Pattern

### Dynamic Loading (Astro / Static Sites)

```javascript
if (dsn) {
  const Sentry = await import('@sentry/browser');  // or framework SDK
  Sentry.init({ dsn, environment: 'production' });
}
```

### Server-Side (Python / Node / PHP)

```python
# Python example
import sentry_sdk

dsn = os.environ.get("ERRORS_GLITCHTIP_DSN", "")
if dsn:
    sentry_sdk.init(
        dsn=dsn,
        environment=os.environ.get("APP_ENV", "production"),
        traces_sample_rate=0.1,  # Adjust for your traffic volume
    )
```

---

## Key Rules

1. **Separate from analytics** — Error tracking is NOT analytics. Don't conflate them in code or configuration.
2. **Environment-gated** — Enable in staging + production only, disable in development.
3. **Conditional on DSN** — If `ERRORS_GLITCHTIP_DSN` is empty, skip initialization entirely. No errors, no overhead.
4. **Never block the app** — Error tracking initialization and reporting must be wrapped in try/catch. A failing error tracker must never take down the application it monitors.

---

## Noise Filtering

Filter out errors that aren't actionable:

- **404s and validation errors** — These are expected application behavior, not bugs
- **Rate limit responses** — Expected under load
- **Bot/crawler errors** — Bots hitting non-existent routes
- **Network timeouts from client-side** — User's connection, not your bug

```python
# Example: Sentry before_send filter
def before_send(event, hint):
    if "exc_info" in hint:
        exc = hint["exc_info"][1]
        if isinstance(exc, Http404):
            return None  # Drop 404s
        if isinstance(exc, ValidationError):
            return None  # Drop validation errors
    return event

sentry_sdk.init(dsn=dsn, before_send=before_send)
```

---

## CSP Integration

If your project uses Content Security Policy headers, auto-add the `report-uri` directive from `ERRORS_GLITCHTIP_SECURITY_ENDPOINT`:

```
Content-Security-Policy: ...; report-uri https://your-glitchtip.example.com/api/1/security/
```

This routes CSP violations to GlitchTip alongside application errors, giving you a unified view of both runtime errors and security policy violations.

See [Super Admin Tooling — Security Headers](./SUPER_ADMIN_TOOLING.md#14-security-headers--dynamic-csp) for the full dynamic CSP pattern.

---

## Admin Integration

- **Launchpad link** — Auto-derived from `ERRORS_GLITCHTIP_DSN` (parse hostname), or use `LAUNCHPAD_GLITCHTIP_URL` override for the full project URL with org slug
- **Dashboard status** — Show GlitchTip connection status in the admin launchpad
- **Error count** — Optionally display recent error count on the admin dashboard (from your own logs, not by querying GlitchTip API)

---

## Audit Checklist

- [ ] GlitchTip DSN configured (`ERRORS_GLITCHTIP_DSN`)
- [ ] Sentry SDK initialized in production/staging
- [ ] Initialization is conditional (no DSN = no init)
- [ ] Error tracking doesn't run in development
- [ ] Noise filtering configured (404s, validation errors excluded)
- [ ] GlitchTip link in admin launchpad
- [ ] CSP report-uri configured (if CSP is enabled)

---

*Created: 2026-03-27*
*Extracted from Analytics and Admin Playbook Section 6.*
