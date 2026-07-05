<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Analytics Playbook

> **Purpose:** A cross-project reference for implementing analytics tracking — provider integrations, abstraction layer, event tracking standards, and privacy/compliance. Framework-agnostic.
>
> **Origin:** Distilled from cross-project audit of 8 production codebases (March 2026). Patterns are proven in Python/FastAPI, PHP/Laravel, TypeScript/React Native, TypeScript/Preact, and Astro projects.
>
> **Companion docs:**
> - [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md) — Env var naming, URL normalization, graceful degradation
> - [Shared Infrastructure Decision Guide](./SHARED_INFRA_DECISION_GUIDE.md) — When/whether to adopt each provider, evaluation status
> - [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) — Admin dashboard, launchpad links to analytics dashboards
> - [Error Tracking](./ERROR_TRACKING.md) — GlitchTip/Sentry (separate from analytics)
> - [Email Infrastructure](./EMAIL_INFRASTRUCTURE.md) — Email sending and logging (separate from analytics)

---

## Table of Contents

1. [Analytics Provider Integrations](#1-analytics-provider-integrations)
2. [Analytics Abstraction Layer](#2-analytics-abstraction-layer)
3. [Non-Blocking Analytics Patterns](#3-non-blocking-analytics-patterns)
4. [Event Tracking Standards](#4-event-tracking-standards)
5. [Privacy & Compliance](#5-privacy--compliance)
6. [Audit Checklist](#6-audit-checklist)
7. [Provider Implementation Reference](#7-provider-implementation-reference)

---

## 1. Analytics Provider Integrations

### Required Providers (All Projects)

Every project with a public-facing UI MUST integrate all three of these simultaneously (we are evaluating which to use long-term):

| Provider | Type | Script Source | Self-Hosted |
|----------|------|---------------|-------------|
| **Umami** | Privacy-first web analytics | `{UMAMI_URL}/script.js` | Yes |
| **OpenPanel** | Product analytics | `https://openpanel.dev/op1.js` (always CDN) | API only |
| **Swetrix** | Privacy-focused analytics | `https://swetrix.org/swetrix.js` (always CDN) | API only |

> **⚠️ Self-hosted is the default across this portfolio.** For OpenPanel and Swetrix the *script* always loads from the vendor CDN, but the *data* must be pointed at your self-hosted API (`apiUrl` / `apiURL`). Forgetting this is the #1 analytics bug here — see the [Golden Rule in §7](#critical-common-ai-mistakes-to-avoid) before implementing.

### Optional Providers (Per-Project)

| Provider | When to Use |
|----------|-------------|
| **Microsoft Clarity** | Session recordings & heatmaps (user research phases) |
| **Rybbit** | Additional privacy-focused option being evaluated |

### Environment Variable Convention

All projects MUST use these env var names (prefix varies by framework):

```bash
# Per-site analytics (tracks this specific deployment)
ANALYTICS_UMAMI_URL=https://your-umami.example.com
ANALYTICS_UMAMI_WEBSITE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

ANALYTICS_OPENPANEL_URL=https://your-openpanel.example.com    # Dashboard URL
ANALYTICS_OPENPANEL_CLIENT_ID=your-client-id
ANALYTICS_OPENPANEL_API_URL=https://your-openpanel-api.example.com  # Optional: separate API endpoint

ANALYTICS_SWETRIX_URL=https://your-swetrix.example.com        # Dashboard URL
ANALYTICS_SWETRIX_PROJECT_ID=your-project-id
ANALYTICS_SWETRIX_API_URL=https://your-swetrix-api.example.com  # Optional: separate API endpoint

# Aggregate analytics (optional — unified cross-deployment view)
ANALYTICS_AGGREGATE_UMAMI_WEBSITE_ID=
ANALYTICS_AGGREGATE_OPENPANEL_CLIENT_ID=
ANALYTICS_AGGREGATE_SWETRIX_PROJECT_ID=

# Privacy
ANALYTICS_EXCLUDED_IPS=1.2.3.4,5.6.7.8   # Team/monitoring IPs to exclude
IP_HASH_SALT=random-secret-string          # For hashing IPs (never store raw)
```

**Vite-based projects** use `VITE_` prefix: `VITE_ANALYTICS_UMAMI_URL`, etc.
**Expo/React Native** use `EXPO_PUBLIC_` prefix: `EXPO_PUBLIC_UMAMI_URL`, etc.
**Astro** uses `PUBLIC_` prefix: `PUBLIC_UMAMI_URL`, etc.

The `example.com` hosts above are placeholders. In this portfolio the real defaults are the self-hosted `bpf.fyi` instances — see [Self-hosted hosts (the `bpf.fyi` defaults)](#self-hosted-hosts-the-bpffyi-defaults) in §7 for the exact host per env var, and **confirm with the user before assuming self-hosted vs. vendor cloud**.

See [Shared Integration Patterns](./SHARED_INTEGRATION_PATTERNS.md) for the full env var naming convention and URL normalization rules.

---

## 2. Analytics Abstraction Layer

Every project MUST have an abstraction layer — never call provider SDKs directly from application code.

### Pattern: Composite/Fan-Out

```
Application Code → trackEvent(name, data) → Abstraction Layer → [Umami, OpenPanel, Swetrix]
```

### Key Requirements

1. **Single entry point** — One `trackEvent()` function that fans out to all providers
2. **Graceful degradation** — If a provider SDK isn't loaded (ad-blocker, config missing), skip silently
3. **Try/catch wrapping** — Analytics NEVER throws exceptions that break the app
4. **Provider registration** — Providers added dynamically based on which env vars are configured
5. **NoOp fallback** — If no providers configured, use a no-op implementation (not null)

See [Shared Integration Patterns — Section 4](./SHARED_INTEGRATION_PATTERNS.md#4-adapter--abstraction-pattern) for the full adapter pattern.

---

## 3. Non-Blocking Analytics Patterns

**Cardinal Rule:** Analytics MUST NEVER block user interactions, delay navigation, or cause visible latency.

### Pattern 1: Navigation-First (for link clicks)

```javascript
// CORRECT — navigation happens synchronously first
onPress={() => {
  Linking.openURL(url);           // Synchronous, in trusted-event window
  trackEvent('link_clicked', {    // Async, fire-and-forget (no await)
    url: url,
    source: 'settings'
  });
}}

// WRONG — analytics blocks navigation
onPress={async () => {
  await trackEvent('link_clicked', { url });  // Blocks!
  Linking.openURL(url);                        // Too late, trusted-event window closed
}}
```

### Pattern 2: sendBeacon (for page unload / session end)

```javascript
// Survives tab close — use for session_end, duration events
navigator.sendBeacon('/api/events', JSON.stringify(payload));

// Fallback if sendBeacon unavailable
fetch('/api/events', { method: 'POST', body: JSON.stringify(payload), keepalive: true });
```

### Pattern 3: Queue Job Dispatch (server-side, Laravel)

```php
// Fire-and-forget via queue — never blocks the HTTP response
TrackAnalyticsEvent::dispatch('donation_completed', [
    'amount_cents' => $donation->amount_cents,
])->afterResponse();  // Or use a queue
```

### Pattern 4: Promise.allSettled (composite providers)

```typescript
// Fan out to all providers — return true if ANY succeeds
const results = await Promise.allSettled(
  providers.map(p => p.track(event, data))
);
return results.some(r => r.status === 'fulfilled' && r.value === true);
```

### Pattern 5: Offline Queue (mobile/PWA)

```typescript
// Store events locally when offline, process when connectivity returns
if (await isOnline()) {
  await sendToProviders(event);
} else {
  eventQueue.enqueue(event);  // Persisted to MMKV/localStorage/IndexedDB
}
```

---

## 4. Event Tracking Standards

### Minimum Events for Any Project

Every project with a UI should track at minimum:

| Event | When | Data |
|-------|------|------|
| `page_view` / `screen_viewed` | Page/screen load | `path`, `referrer` |
| `session_start` | App/site opened | `is_first_visit`, `platform` |
| `session_end` | App/tab closed | `duration_ms`, `pages_viewed` |
| `external_link_clicked` | User clicks outbound link | `url`, `source_page` |
| `error_occurred` | Unhandled error | `message`, `stack` (truncated) |

### Additional Events by Project Type

**Content sites:** `article_read`, `scroll_depth`, `search_query`, `search_zero_results`

**Games:** `game_started`, `game_completed`, `score_achieved`, `share_clicked`

**Financial/donation:** `page_created`, `donation_completed`, `user_registered`, `payout_initiated`

**Learning apps:** `lesson_completed`, `streak_milestone`, `setting_changed`

### Event Naming Convention

- Use `snake_case` for event names
- Use `noun_verb` pattern: `link_clicked`, `game_started`, `page_viewed`
- Include `source` or `location` when the same action can happen from multiple places

---

## 5. Privacy & Compliance

### Rules for All Projects

1. **Never store raw IP addresses** — Hash with SHA-256 + salt, store only the hash
2. **No cookies for analytics** — Umami is cookieless; Swetrix and OpenPanel don't require cookies
3. **Respect Do Not Track** — Check `navigator.doNotTrack === '1'` before tracking
4. **Filter bot traffic** — Exclude known monitoring user-agents (Uptime Kuma, UptimeRobot, etc.)
5. **Exclude team IPs** — Use `ANALYTICS_EXCLUDED_IPS` to filter your own traffic
6. **No PII in events** — Never include email, name, or raw user IDs in analytics events
7. **Device IDs are random** — Use `crypto.randomUUID()`, never fingerprinting
8. **Consent when required** — If GDPR applies (financial, EU users), gate scripts behind consent

### IP Hashing Reference

```python
import hashlib
def hash_ip(ip: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{ip}".encode()).hexdigest()[:16]
```

---

## 6. Audit Checklist

Use this checklist to audit analytics implementation in any project. For each item, mark:
- **[x] Done** — Implemented and working
- **[~] Partial** — Exists but incomplete
- **[ ] Not done** — Not yet addressed
- **[n/a]** — Doesn't apply

### Analytics Providers

- [ ] Umami script injected on all public pages
- [ ] OpenPanel script injected on all public pages (CDN script + `apiUrl` set to self-hosted API — verified `POST /track` returns `200`, not `401 "Invalid client id"`)
- [ ] Swetrix script injected on all public pages (CDN script + `apiURL` set to self-hosted API **with `/log` suffix** — not silently falling back to Swetrix Cloud)
- [ ] All three providers use correct env var names per convention
- [ ] Scripts excluded from admin routes
- [ ] Scripts respect consent/DNT where applicable

### Abstraction Layer

- [ ] Single `trackEvent()` entry point exists
- [ ] Fans out to all configured providers
- [ ] Try/catch wrapping — analytics failures never break the app
- [ ] NoOp/fallback when no providers configured
- [ ] Non-blocking — no `await` before user-facing actions

### Event Tracking

- [ ] Page views tracked
- [ ] Session start/end tracked
- [ ] External link clicks tracked
- [ ] Key business events tracked (project-specific)
- [ ] Events use `snake_case` naming convention
- [ ] Event data includes no PII

### Privacy

- [ ] No raw IPs stored anywhere
- [ ] Do Not Track header respected
- [ ] Bot/monitoring traffic filtered
- [ ] Team IPs excludable via env var
- [ ] No PII in analytics events
- [ ] Consent gating (if GDPR applies)

---

## 7. Provider Implementation Reference

### CRITICAL: Common AI Mistakes to Avoid

AI assistants frequently get Swetrix and OpenPanel wrong. These are the CORRECT patterns.

> ### 🚨 GOLDEN RULE: Assume self-hosted unless told otherwise
>
> Across this portfolio, **all three providers are self-hosted** (Umami, OpenPanel, and Swetrix APIs all run on `*.bpf.fyi`). The single most common failure — it has broken tracking in nearly every project — is leaving a provider pointed at its **cloud** endpoint:
>
> - **OpenPanel:** if you omit `apiUrl`, `op1.js` silently posts to OpenPanel **cloud** (`api.openpanel.dev`), which returns **`401 "Invalid client id"`** because your client only exists on your self-hosted instance. **Unless you are explicitly using OpenPanel Cloud, you MUST set `apiUrl` to your self-hosted API.**
> - **Swetrix:** if you omit `apiURL`, the SDK posts to Swetrix **Cloud**, and your self-hosted dashboard stays empty (often with **no visible error**). **Unless you are explicitly using Swetrix Cloud, you MUST set `apiURL` to your self-hosted API, ending in `/log`.**
> - **Umami:** the script is loaded *from* your self-hosted instance (`{UMAMI_URL}/script.js`), so there is no cloud-fallback trap — if the script loads, it reports to the right place.
>
> **Decision:** Are you using the vendor's paid cloud product? If not (the default here), treat every provider as self-hosted and set its API URL explicitly. When in doubt, self-hosted.

### Self-hosted hosts (the `bpf.fyi` defaults)

Projects frequently don't know the expected host values, guess, and end up pointed at vendor cloud (see the Golden Rule above). These are the canonical self-hosted hosts for this portfolio. **They are the default** — unless the project explicitly uses a vendor cloud product or a different self-hosted instance.

> **⚠️ CHECK WITH THE USER FIRST.** Before wiring these values, confirm the project is meant to use the shared `bpf.fyi` self-hosted instances. If the user expects vendor cloud (OpenPanel Cloud, Swetrix Cloud, Umami Cloud) or a project-specific self-hosted host, use *those* instead. Absent any other instruction, use the `bpf.fyi` defaults below.

| Provider | Env var | Default host (`bpf.fyi`) | Notes |
|----------|---------|--------------------------|-------|
| **Umami** | `ANALYTICS_UMAMI_URL` | `https://umami.bpf.fyi` | Script base — the SDK loads from `{URL}/script.js`. Accept the value with or without the `/script.js` suffix and normalize. |
| **Umami** | `ANALYTICS_UMAMI_WEBSITE_ID` | *(per-app)* | Created per site in the Umami dashboard — **not** global. |
| **OpenPanel** | `ANALYTICS_OPENPANEL_API_URL` | `https://api.openpanel.bpf.fyi` | Ingest/API host → the SDK's `apiUrl`. Required for self-hosted; **no** trailing path (the SDK appends `/track`). |
| **OpenPanel** | `ANALYTICS_OPENPANEL_URL` | `https://openpanel.bpf.fyi` | Dashboard host (the human admin view). The full per-project dashboard path is not derivable — see [Dashboard URLs](#dashboard-urls-for-launchpad-links) below. |
| **OpenPanel** | `ANALYTICS_OPENPANEL_CLIENT_ID` | *(per-app)* | Created per project in the OpenPanel dashboard — **not** global. |
| **Swetrix** | `ANALYTICS_SWETRIX_API_URL` | `https://api.swetrix.bpf.fyi` | Ingest/API host → the SDK's `apiURL`, **which MUST end in `/log`** (`https://api.swetrix.bpf.fyi/log`). |
| **Swetrix** | `ANALYTICS_SWETRIX_URL` | `https://swetrix.bpf.fyi` | Dashboard host (the human admin view). |
| **Swetrix** | `ANALYTICS_SWETRIX_PROJECT_ID` | *(per-app)* | Created per project in the Swetrix dashboard — **not** global. |

**The three per-app IDs (`_WEBSITE_ID`, `_CLIENT_ID`, `_PROJECT_ID`) are NOT global.** Each is created in that provider's dashboard for the specific project — never copy another project's ID. Only the *hosts* are shared across the portfolio.

Which value maps to which suffix (per the [URL Triad](./SHARED_INTEGRATION_PATTERNS.md#the-url-triad--three-fixed-suffixes-one-meaning-each)): `_URL` = the base/dashboard/script host, `_API_URL` = the ingest host the SDK posts data to, `_DASHBOARD_URL` = a click-through admin link (when distinct from `_URL`).

### Dashboard URLs (for launchpad links)

Each provider also has a human-facing dashboard URL for the specific project. Store it as `ANALYTICS_{PROVIDER}_DASHBOARD_URL` (the URL triad's `_DASHBOARD_URL` suffix); the admin [launchpad](./SUPER_ADMIN_TOOLING.md) uses these as its "Analytics" links. Umami and Swetrix dashboards derive cleanly from the base `_URL` + the per-app ID, so `_DASHBOARD_URL` there is optional (derive it or set it explicitly). **OpenPanel's path is per-org/per-app and cannot be derived — always set `ANALYTICS_OPENPANEL_DASHBOARD_URL` explicitly.**

| Provider | `_DASHBOARD_URL` pattern | Real example (`bpf.fyi`) | Derivable from `_URL` + ID? |
|----------|-------------------------|--------------------------|-----------------------------|
| **Umami** | `{UMAMI_URL}/websites/{WEBSITE_ID}` | `https://umami.bpf.fyi/websites/d7e41af2-6ed6-489b-92da-134afcd10797` | Yes — base + `WEBSITE_ID` |
| **OpenPanel** | `{OPENPANEL_URL}/{org}/{app}` | `https://openpanel.bpf.fyi/bpffyi/splitgiveapp` | **No** — set explicitly |
| **Swetrix** | `{SWETRIX_URL}/projects/{PROJECT_ID}` | `https://swetrix.bpf.fyi/projects/Ry2D7ojNYqIe` | Yes — base + `PROJECT_ID` |

> The `_URL`, `_API_URL`, and `_DASHBOARD_URL` are three distinct hosts/paths — don't collapse them. For Umami and Swetrix the API/ingest host is `api.{provider}.bpf.fyi` while the dashboard lives on the bare `{provider}.bpf.fyi`. For OpenPanel the ingest host is `api.openpanel.bpf.fyi` and the dashboard is `openpanel.bpf.fyi/{org}/{app}`.

### Copy-paste reference (self-hosted — verified working)

This is a complete, known-good head block with all three providers configured for self-hosted backends. Replace the `bpf.fyi` hosts and IDs with the target project's values. Verified working: a `POST /track` to the self-hosted OpenPanel API with the client ID returns `200`, while the same request to `api.openpanel.dev` returns `401 "Invalid client id"`.

```html
<!-- Umami (self-hosted): script loaded from YOUR instance, auto-tracks page views -->
<script defer src="https://umami.bpf.fyi/script.js"
        data-website-id="UMAMI_WEBSITE_ID"></script>

<!-- OpenPanel (self-hosted): stub + init (apiUrl REQUIRED), then SDK from CDN -->
<script>
window.op=window.op||function(){var n=[];return new Proxy(function(){arguments.length&&n.push([].slice.call(arguments))},{get:function(t,r){return"q"===r?n:function(){n.push([r].concat([].slice.call(arguments)))}},has:function(t,r){return"q"===r}})}();
window.op('init',{
  apiUrl:'https://api.openpanel.bpf.fyi',   // ← self-hosted ingest API; omit ONLY for OpenPanel Cloud
  clientId:'OPENPANEL_CLIENT_ID',
  trackScreenViews:true, trackOutgoingLinks:true, trackAttributes:true
});
</script>
<script src="https://openpanel.dev/op1.js" defer async></script>

<!-- Swetrix (self-hosted): SDK from CDN, then init with apiURL ending in /log -->
<script defer src="https://swetrix.org/swetrix.js"></script>
<script>
document.addEventListener('DOMContentLoaded',function(){
  if(typeof swetrix==='undefined')return;                    // guard against ad-blockers
  swetrix.init('SWETRIX_PROJECT_ID',{
    apiURL:'https://api.swetrix.bpf.fyi/log'                 // ← self-hosted API, MUST end in /log
  });
  swetrix.trackViews();
  swetrix.trackErrors();
});
</script>
<noscript>
  <img src="https://api.swetrix.bpf.fyi/log/noscript?pid=SWETRIX_PROJECT_ID"
       alt="" referrerpolicy="no-referrer-when-downgrade" />
</noscript>
```

The per-provider sections below explain each line and list the failure symptoms.

### Umami — Correct Implementation

```html
<!-- Simple: one script tag, defer, data-website-id -->
<script defer src="{UMAMI_URL}/script.js" data-website-id="{WEBSITE_ID}"></script>
```

- Script loaded from YOUR Umami instance URL (not a CDN) — `{WEBSITE_ID}` comes from `ANALYTICS_UMAMI_WEBSITE_ID`
- Accept the URL **with or without** the `/script.js` suffix — a project may set `ANALYTICS_UMAMI_URL` to either `https://umami.bpf.fyi` or `https://umami.bpf.fyi/script.js`. Normalize to the base and append `/script.js` yourself (see [URL Normalization](./SHARED_INTEGRATION_PATTERNS.md#2-url-normalization)).
- Auto-tracks page views — no init call needed
- Custom events: `umami.track(eventName, eventData)`

### OpenPanel — Correct Implementation

```html
<!-- Step 1: Inline stub that queues calls before SDK loads -->
<script>
// Current OpenPanel Proxy-based stub (what op1.js ships today). The older
// `window.op=window.op||function(){(window.op.q=window.op.q||[]).push(arguments)};`
// stub also still works — either is fine, both queue calls until op1.js loads.
window.op=window.op||function(){var n=[];return new Proxy(function(){arguments.length&&n.push([].slice.call(arguments))},{get:function(t,r){return"q"===r?n:function(){n.push([r].concat([].slice.call(arguments)))}},has:function(t,r){return"q"===r}})}();
window.op('init', {
    apiUrl: '{OPENPANEL_API_URL}',     // ← REQUIRED for self-hosted (your ingest API). Omit ONLY for OpenPanel Cloud.
    clientId: '{CLIENT_ID}',
    trackScreenViews: true,
    trackOutgoingLinks: true,
    trackAttributes: true
});
</script>
<!-- Step 2: Load SDK from CDN (ALWAYS from CDN, even for self-hosted) -->
<script defer async src="https://openpanel.dev/op1.js"></script>
```

**Key gotchas:**
- **`apiUrl` is the whole ballgame for self-hosted.** Omit it and `op1.js` posts to OpenPanel **cloud** (`api.openpanel.dev`), which does not know your client → **`401 "Invalid client id"`** and zero data on your dashboard. Set `apiUrl` to your self-hosted ingest API (e.g. `https://api.openpanel.example.com`). Only omit it if you are genuinely on OpenPanel Cloud.
- `apiUrl` is the **API/ingest** host, which is usually different from the **dashboard** host (e.g. dashboard `openpanel.example.com`, API `api.openpanel.example.com`). Point `apiUrl` at the API host, with **no** trailing path (no `/track` — the SDK appends it).
- SDK ALWAYS loads from `https://openpanel.dev/op1.js` — even self-hosted instances use the CDN for the script itself. Do **not** try to load `op1.js` from your self-hosted host.
- The inline stub MUST come before the SDK script tag.
- Custom events: `op('track', eventName, { key: value })`

**Failure symptoms → cause → fix:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| `401 "Invalid client id"` on `POST .../track` | `apiUrl` omitted → posting to cloud, which lacks your client | Set `apiUrl` to your self-hosted API host |
| No `/track` request fires at all | `op1.js` blocked (ad-blocker) or failed to load | Check the `op1.js` request; guard is expected — degrade silently |
| `400` on `/track` | Malformed payload / empty body | Verify the SDK (not a hand-rolled fetch) is sending events |

**Verify from the CLI** (substitute your host + client id):

```bash
curl -sS -w "\n%{http_code}\n" -X POST "https://api.openpanel.example.com/track" \
  -H "Content-Type: application/json" \
  -H "openpanel-client-id: {CLIENT_ID}" \
  --data '{"type":"track","payload":{"name":"screen_view","properties":{"__path":"/"}}}'
# 200 = client is valid on this host. 401 "Invalid client id" = wrong host (or client lives elsewhere, e.g. cloud).
```

### Swetrix — Correct Implementation

```html
<!-- Step 1: Load SDK from CDN -->
<script defer src="https://swetrix.org/swetrix.js"></script>
<!-- Step 2: Initialize after DOM ready -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    if (typeof swetrix === 'undefined') return;  // Guard against ad-blockers
    swetrix.init('{PROJECT_ID}', { apiURL: '{SWETRIX_API_URL}/log' });
    swetrix.trackViews();
    swetrix.trackErrors();
});
</script>
```

**Key gotchas:**
- **`apiURL` MUST be set AND end with `/log`** — these are the two most common mistakes, and both fail *silently*.
  - Omit `apiURL` entirely → data goes to Swetrix **Cloud**, and your self-hosted dashboard stays empty with no error.
  - Set `apiURL` without the `/log` suffix → requests hit the wrong path (typically `404`) and nothing is recorded.
- SDK ALWAYS loads from `https://swetrix.org/swetrix.js` — even self-hosted. Do not load `swetrix.js` from your own host.
- `apiURL` is the **API** host + `/log` (e.g. `https://api.swetrix.example.com/log`), usually distinct from the dashboard host.
- For self-hosted: auto-derive the API URL from the base URL, then append `/log` (see the auto-derivation snippet below).
- Init **after** `DOMContentLoaded` and guard with `if (typeof swetrix === 'undefined') return;` so an ad-blocker can't throw.
- Don't forget the `<noscript>` pixel — its `src` also points at `{SWETRIX_API_URL}/log/noscript?pid={PROJECT_ID}`.
- Custom events: `swetrix.track({ ev: eventName, meta: { key: value } })`

**Failure symptoms → cause → fix:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| Dashboard empty, **no error** in console | `apiURL` omitted → posting to Swetrix Cloud | Set `apiURL` to your self-hosted API host + `/log` |
| `404` on the log request | `apiURL` missing the `/log` suffix | Append `/log` (e.g. `.../log`, not `.../`) |
| No log request fires at all | `swetrix.js` blocked/failed, or init ran before it loaded | Verify script load; keep the `typeof swetrix` guard + `DOMContentLoaded` |

**Verify from the CLI** (substitute your host + project id):

```bash
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "https://api.swetrix.example.com/log" \
  -H "Content-Type: application/json" \
  --data '{"pid":"{PROJECT_ID}","pg":"/","tz":"UTC"}'
# A 2xx/3xx from YOUR host confirms the path is right. 404 usually means the /log suffix is missing.
```

### Swetrix API URL Auto-Derivation Pattern

```javascript
// If explicit API URL not set, derive from base URL for self-hosted instances
let apiUrl = config.SWETRIX_API_URL || '';
if (!apiUrl && config.SWETRIX_URL) {
    const cloudHosts = ['swetrix.org', 'swetrix.com'];
    const isSelfHosted = !cloudHosts.some(h => config.SWETRIX_URL.includes(h));
    if (isSelfHosted) {
        apiUrl = config.SWETRIX_URL;
    }
}
// ALWAYS ensure /log suffix
if (apiUrl && !apiUrl.endsWith('/log')) {
    apiUrl = apiUrl.replace(/\/$/, '') + '/log';
}
```

---

## Appendix: Cross-Project Status Template

Use this table to track analytics adoption across your portfolio. Update as services are integrated.

| Project | Umami | OpenPanel | Swetrix | Abstraction |
|---------|-------|-----------|---------|-------------|
| *(project-1)* | | | | |
| *(project-2)* | | | | |

**Legend:** Done, Planned, Stub, Missing, N/A

For the full cross-project status matrix (including error tracking, email, infrastructure), see [Shared Infrastructure Decision Guide — Section 2](./SHARED_INFRA_DECISION_GUIDE.md#2-decision-matrix).

---

*Created: 2026-03-27*
*Updated: 2026-07-01 — §7 rewritten with a "self-hosted is the default" Golden Rule, a verified copy-paste reference for all three providers, and per-provider failure-symptom tables + CLI verification (OpenPanel `apiUrl` / Swetrix `apiURL` + `/log` are the recurring traps).*
*Updated: 2026-07-02 — renamed the Umami env var `ANALYTICS_UMAMI_SITE_ID` → `ANALYTICS_UMAMI_WEBSITE_ID` (incl. the aggregate var and the `data-website-id` example) to match the canonical vocabulary in SHARED_INTEGRATION_PATTERNS §1; added a §7 "Self-hosted hosts (the `bpf.fyi` defaults)" table (Umami `umami.bpf.fyi`, OpenPanel API `api.openpanel.bpf.fyi`, Swetrix API `api.swetrix.bpf.fyi/log` + dashboards) with a CHECK-WITH-THE-USER rule; switched the copy-paste reference to the real `bpf.fyi` hosts; and made Umami URL handling accept the value with or without `/script.js`.*
*Updated: 2026-07-02 — added a §7 "Dashboard URLs (for launchpad links)" table with confirmed `_DASHBOARD_URL` patterns + real `bpf.fyi` examples for all three providers (Umami `/websites/{id}` and Swetrix `/projects/{id}` derive from base + ID; OpenPanel `/{org}/{app}` is not derivable — set `ANALYTICS_OPENPANEL_DASHBOARD_URL` explicitly). Sourced from SplitGive's live config.*
*Refocused from the original Analytics and Admin Playbook. Admin dashboard, error tracking, email logging, and launchpad content moved to their respective dedicated docs.*
