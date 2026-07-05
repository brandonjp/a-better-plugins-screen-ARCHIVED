<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Multi-Layer Form Spam Protection Pattern

> A defense-in-depth approach to protecting web forms without relying on any single technique. Each layer is independently toggleable, and all layers compose together — a submission must pass every enabled layer to succeed.
>
> This pattern targets POST-based form submissions (signups, contact forms, registration). It does not apply to GET-based search queries or authenticated admin actions.

---

## Design Principles

1. **Defense in depth** — No single layer is sufficient alone. Stack passive detection (honeypot, timing) with active validation (content, domain, CAPTCHA) so that if any one layer is bypassed, others still catch the spam.
2. **Fail silently** — Return fake success responses (HTTP 200) on spam-protected forms where possible (waitlists, signups). Never reveal which layer rejected the submission. Bots that receive errors will adapt; bots that receive "success" move on.
3. **Independently toggleable** — Each layer has its own on/off switch via environment variable or config. This lets you disable layers that cause false positives in specific environments without weakening the entire stack.
4. **Log everything** — Every rejection is logged with IP, email, submitted content, and which layer(s) triggered. This gives you data to tune thresholds and identify new attack patterns.
5. **CAPTCHA is the last resort, not the first** — Passive layers (honeypot, timing) catch most bots with zero friction. Active validation (content, domain) catches targeted spam. CAPTCHA handles the remainder. Most spam never reaches the CAPTCHA layer.

---

## The Layers

### Layer 1: Honeypot Field

**What it does:** Adds a hidden form field that real users never see or interact with. Bots that auto-fill all fields will populate it, revealing themselves.

**Implementation:**
- Add a hidden input to your form (e.g., `<input type="hidden" name="website_url" />` or use CSS to visually hide it)
- On the server, reject any submission where this field has a value
- The field name should look legitimate to bots (e.g., `website_url`, `company`, `fax`) — not `honeypot` or `trap`
- Use CSS hiding (`position: absolute; left: -9999px`) rather than `type="hidden"` for stronger concealment against smarter bots

**Catches:** ~60-70% of basic bots that blindly fill every field.

### Layer 2: Timing Analysis

**What it does:** Measures the time between page load and form submission. Submissions faster than a human could reasonably type (e.g., under 3 seconds) are rejected.

**Implementation:**
- On page load, generate an encrypted timestamp token and embed it in a hidden field
- On submission, decrypt the token, calculate elapsed time
- Reject if elapsed time is below your threshold (3 seconds is a reasonable default)
- Encrypt the timestamp so bots can't forge it — a plain timestamp in a hidden field is trivially spoofable

**Catches:** Headless bots and scripts that submit forms instantly without rendering.

### Layer 3: Content Analysis

**What it does:** Scans text fields for patterns that indicate spam rather than legitimate input. Applies heuristic rules to the content itself.

**Patterns to detect:**
- **URLs in non-URL fields** — Legitimate names/messages rarely contain `http://` or `https://`
- **Money/currency patterns** — Strings like `$3,222` or `€500` in name fields
- **Mixed scripts** — Latin + Cyrillic characters in the same field (common in phishing spam, rare in legitimate input)
- **Excessive special characters** — If >30% of a field is special characters, it's likely not a real name

**Implementation:**
- Use regex patterns against text input fields (name, message, etc.)
- Don't apply content analysis to email fields or fields where URLs/special chars are expected
- Make each sub-pattern independently toggleable so you can disable specific checks that cause false positives

**Catches:** Targeted spam that passes honeypot and timing checks — the "human-like" bots with spammy payloads.

**Note:** Do NOT apply content analysis to fields where URLs, special characters, or numbers are expected (search fields, URL inputs, etc.).

### Layer 4: Email Domain Blocklist

**What it does:** Blocks submissions from known disposable/throwaway email providers. Maintains a configurable list of blocked domains with automatic subdomain matching.

**Implementation:**
- Extract the domain from the submitted email address
- Check against a blocklist of disposable email providers (start with 40-50 common ones)
- Match subdomains automatically (blocking `example.com` also blocks `mail.example.com`)
- Keep the list in config (not hardcoded) so it can be extended without code changes

**Starting list:** `mailinator.com`, `guerrillamail.com`, `tempmail.com`, `throwaway.email`, `yopmail.com`, `maildrop.cc`, `discard.email`, `trashmail.com`, and similar services.

**Catches:** Bots and humans using throwaway emails to spam signups. Won't catch custom domains, but significantly reduces volume.

### Layer 5: CAPTCHA (Proof-of-Work)

**What it does:** Requires the client to solve a computational challenge before submission is accepted. Proof-of-work CAPTCHAs (mCaptcha, ALTCHA, Cap.js) are privacy-friendly alternatives to image-based CAPTCHAs — no tracking, no cookies, no accessibility issues.

**Implementation:**
- Use a driver/adapter pattern so you can swap CAPTCHA providers via config without touching form code
- The CAPTCHA widget renders via a shared component; forms don't know which provider is active
- Server-side verification calls the CAPTCHA provider's API to validate the token
- **Fail-open behavior:** If the CAPTCHA server is unreachable, allow the submission through (log a warning). The other 4 layers still protect you, and blocking all users because your CAPTCHA server is down is worse than letting some spam through

**Driver pattern:**
```
Interface: isEnabled(), verify(request), getTokenFieldName(), getWidgetView(), getScriptView()
Manager:   Resolves active driver from config, caches instance, proxies calls
Drivers:   NullDriver (disabled), McaptchaDriver, AltchaDriver, CapjsDriver, etc.
```

**Catches:** Sophisticated bots that pass all passive checks. PoW CAPTCHAs make automated submissions computationally expensive at scale.

---

## Integration Pattern

### Service Architecture

```
SpamProtectionService.evaluate(request) → string[]  (returns list of triggered layers)
├── isHoneypotTriggered(request)      → bool
├── isTimingTooFast(request)          → bool
├── hasSpamContent(request)           → bool
├── isBlockedEmailDomain(request)     → bool
└── isCaptchaFailed(request)          → bool  (delegates to CaptchaManager)
```

A single `evaluate()` method runs all enabled layers and returns an array of triggered reasons (e.g., `['honeypot', 'content']`). The controller checks if the array is non-empty — if so, it's spam.

### Controller Logic

```
reasons = spamProtection.evaluate(request)
if reasons is not empty:
    log warning with IP, email, name, reasons
    if ajax request:
        return 200 OK with fake success   ← don't tip off the bot
    else:
        redirect back with fake success flash message
    return early (don't save to database)

// Only reaches here if all layers passed
save to database
send notifications
return real success
```

**Note on fail-silent:** The "fake 200" approach applies to public forms (registration, contact). Do NOT use fake success on admin/user login — users need real error feedback to troubleshoot legitimate login issues. For login, use CAPTCHA + rate limiting instead.

### Form Template Pattern

```html
<form method="POST" action="/signup">
    <!-- CSRF token -->
    <!-- Honeypot (hidden from real users via CSS) -->
    <input name="website_url" style="position:absolute;left:-9999px" tabindex="-1" autocomplete="off" />

    <!-- Timing token (encrypted timestamp from page load) -->
    <input type="hidden" name="_timing_token" value="{{ encrypted_timestamp }}" />

    <!-- Real form fields -->
    <input type="email" name="email" required />
    <input type="text" name="name" />

    <!-- CAPTCHA widget (renders based on active driver, or nothing if disabled) -->
    <x-captcha-widget />

    <button type="submit">Sign Up</button>
</form>

<!-- CAPTCHA script (loads JS for active driver, or nothing if disabled) -->
<x-captcha-script />
```

---

## Configuration

Every layer defaults to **enabled** except CAPTCHA (which requires explicit provider setup).

```env
# Honeypot — hidden field trap
SPAM_HONEYPOT_ENABLED=true

# Timing — minimum seconds between page load and submit
SPAM_TIMING_ENABLED=true
SPAM_TIMING_MINIMUM_SECONDS=3

# Content analysis — URL/money/script detection in text fields
SPAM_CONTENT_ENABLED=true

# Email domain blocklist — disposable email providers
SPAM_EMAIL_DOMAIN_ENABLED=true

# CAPTCHA — proof-of-work provider (null = disabled)
CAPTCHA_DRIVER=null
```

---

## Observability

Log every rejection at `warning` level with structured context:

```
[warning] Spam detected on interest signup {
    "ip": "203.0.113.42",
    "email": "spammer@mailinator.com",
    "name": "$3,222 available! Visit https://spam.example.com",
    "reasons": ["content", "email_domain"],
    "route": "interest-signup.store"
}
```

This data lets you:
- Identify which layers are doing the most work
- Spot false positives (legitimate emails in logs with only one trigger)
- Tune thresholds (e.g., lower timing minimum if real users on slow connections are getting caught)
- Discover new disposable email domains to add to the blocklist

---

## What This Pattern Does NOT Cover

- **Rate limiting** — Handled separately at the middleware/route level. Rate limiting and spam protection are complementary but independent concerns.
- **Authentication-based spam** — This pattern protects public/anonymous forms. Authenticated actions need different protections (permissions, audit trails).
- **DDoS** — This is application-layer spam filtering, not network-layer protection. Use a CDN/WAF for volumetric attacks.
- **AI-generated content** — These heuristics catch automated submissions, not manually crafted spam. Content moderation is a separate problem.
- **Search query abuse** — GET-based search is not a form spam vector. Protect search with rate limiting and caching.
