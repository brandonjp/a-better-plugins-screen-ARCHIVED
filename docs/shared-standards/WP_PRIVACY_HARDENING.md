# WordPress Privacy Hardening & Mission-Site Setup

> **Purpose:** The concrete WordPress *how-to* that implements the universal
> [Mission-Driven Web Guide](../../docs/shared-standards/MISSION_DRIVEN_WEB_GUIDE.md) — especially
> its §1 (Data Dignity & Privacy), §5 (Security & Stewardship), and §6 (Performance). That guide
> says *what* and *why*; this one gives the WordPress recipes for *how*.
>
> **Audience:** Nonprofit / faith / peacemaking / advocacy WordPress sites (classic or FSE block
> themes). Examples are drawn from a standalone FSE block theme + companion plugin, but most apply
> to any WP site. Each recipe is tagged **[RECOMMENDED]** or **[OPTIONAL]** to match the guide.
>
> **Companion:** For plugin build conventions see `WP_PLUGIN_DEVELOPMENT_GUIDE.md`.

---

## 1. Self-host fonts (no Google Fonts CDN) [RECOMMENDED]

Implements guide §1.1. The goal: zero requests to `fonts.googleapis.com` / `fonts.gstatic.com`.

**A. Get the font files (subsetted woff2).** From the Google Fonts CSS2 URL, fetch with a modern
browser User-Agent so Google serves `woff2`, then download each `latin` + `latin-ext` file:

```bash
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120 Safari/537.36"
curl -s -A "$UA" \
  "https://fonts.googleapis.com/css2?family=Spectral:wght@400;700&family=Hanken+Grotesk:wght@400;700&display=swap" \
  -o fonts.css
# Then download each woff2 URL in fonts.css into the theme's assets/fonts/.
```

> **Variable-font gotcha:** some families (e.g. Hanken Grotesk) are variable — Google returns the
> **byte-identical** file for every requested weight. Detect duplicates (`md5`); if all weights
> match, store the file **once** and declare it with a weight *range*: `font-weight: 400 800;`.
> Static families (e.g. Spectral) keep one file per weight. Keep the per-subset `unicode-range`
> from Google's CSS so browsers still download only the subset a page needs.

**B. Local `@font-face` CSS** (`assets/css/fonts.css`) — same rules Google ships, pointing at local
files, `unicode-range` preserved, `font-display: swap`.

**C. Enqueue locally and drop the Google calls** (`functions.php`):

```php
// Self-hosted webfonts — see assets/css/fonts.css. No Google CDN (GDPR).
add_action( 'wp_enqueue_scripts', function () {
    $v = wp_get_theme()->get( 'Version' );
    wp_enqueue_style( 'theme-fonts', get_theme_file_uri( 'assets/css/fonts.css' ), [], $v );
    wp_enqueue_style( 'theme-main',  get_theme_file_uri( 'assets/css/main.css' ), [ 'theme-fonts' ], $v );
} );

// Preload the above-the-fold faces so first paint uses the real fonts.
add_action( 'wp_head', function () {
    foreach ( [ 'assets/fonts/heading.woff2', 'assets/fonts/body.woff2' ] as $rel ) {
        printf( "<link rel=\"preload\" href=\"%s\" as=\"font\" type=\"font/woff2\" crossorigin>\n",
            esc_url( get_theme_file_uri( $rel ) ) );
    }
}, 1 );
```

Remove any `wp_resource_hints` preconnect to Google and any remote font `wp_enqueue_style`.

**FSE note:** if you also want the fonts in the **block-editor canvas**, add `fontFace` entries to
`theme.json`. Caveat: `theme.json` `fontFace` can't cleanly express the latin/latin-ext
`unicode-range` split and will double-load alongside `fonts.css`. For front-end correctness,
`fonts.css` is the source of truth; add `theme.json` `fontFace` only if editor WYSIWYG matters.

**Verify (live):**
```bash
curl -s https://EXAMPLE.org/ | grep -i -e fonts.googleapis -e fonts.gstatic   # must be empty
```

---

## 2. Stop WordPress's own third-party / external calls [RECOMMENDED]

WP and many plugins phone home or hotlink by default. Trim what leaks visitor data or weight:

- **Gravatar** — author avatars hotlink `gravatar.com` (leaks commenter/visitor data). Disable
  avatars in **Settings → Discussion**, or filter `get_avatar` to a local placeholder. (guide §1.1)
- **Emoji script** — WP injects `wp-emoji-release.min.js` + a `dns-prefetch` to `s.w.org`. Remove:
  ```php
  remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
  remove_action( 'wp_print_styles', 'print_emoji_styles' );
  add_filter( 'emoji_svg_url', '__return_false' );
  ```
- **Embeds (oEmbed)** — third-party embeds (YouTube, Twitter/X, etc.) load remote scripts and leak
  IPs. Prefer privacy embeds (e.g. `youtube-nocookie.com`, lazy-loaded), or strip the auto-discovery
  links if unused: `remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );`
- **`dns-prefetch`/preconnect to third parties** — audit `wp_resource_hints` output; remove hints to
  domains you no longer call once fonts/embeds are local.
- **Jetpack / stats / "phone-home" plugins [OPTIONAL]** — many route visitor data through Automattic
  or vendor servers. Use only with intent; prefer self-hosted alternatives (see §3).

---

## 3. Privacy-respecting analytics [RECOMMENDED]

Implements guide §1.3. Avoid GA4. Good WP-friendly options:

- **Koko Analytics** — self-hosted, cookieless, stores data in your own WP DB; no banner needed.
- **Plausible / Fathom** — hosted but cookieless and IP-anonymizing (lightweight script; an EU host
  option exists for Plausible). Disclose in the privacy policy.
- **Matomo (self-hosted)** with IP anonymization + cookieless mode for orgs wanting full control.

Whichever you pick: confirm **no cookies are set** for anonymous visitors, so you can avoid a
consent banner entirely (guide §1.4). Verify in DevTools → Application → Cookies on a fresh visit.

---

## 4. Trim metadata leakage & lock down the REST surface [RECOMMENDED]

- **Remove the WP version meta** (`<meta name="generator">`): `remove_action( 'wp_head', 'wp_generator' );`
- **User enumeration** — the REST `…/wp-json/wp/v2/users` endpoint and `?author=1` redirects can
  leak usernames. Restrict the users endpoint to authenticated requests, and block `?author=`
  enumeration (many security plugins do both). (guide §1.6 / §5)
- **XML-RPC [OPTIONAL]** — if unused, disable `xmlrpc.php` (brute-force + pingback amplification
  vector): `add_filter( 'xmlrpc_enabled', '__return_false' );`
- **Pingbacks/trackbacks** — usually noise + an SSRF/DDoS vector; disable in Discussion settings.

---

## 5. Security & stewardship on WordPress [RECOMMENDED]

Implements guide §5.

- **Auto-update minor core + trusted plugins**; review majors. Keep PHP current (the host's served
  PHP, not just CLI — see `wp-host-ops` PHP-version trap).
- **Least privilege** — give editors the `editor` role, not `administrator`; one account per person;
  enforce strong passwords + 2FA (e.g. via a security plugin). Remove stale accounts.
- **Disable the theme/plugin file editor** so a compromised admin can't edit PHP:
  `define( 'DISALLOW_FILE_EDIT', true );` in `wp-config.php`.
- **Backups** — automated off-site backups (DB + uploads), test-restored at least once.
- **Form spam** — implement the layered approach in
  [`SPAM_PROTECTION_PATTERN.md`](../../docs/shared-standards/SPAM_PROTECTION_PATTERN.md); on WP this
  is honeypot + timing + content checks, with a privacy-respecting CAPTCHA (e.g. hCaptcha/Turnstile)
  only as the last layer.
- **Security headers [OPTIONAL]** — set HSTS, `X-Content-Type-Options`, `Referrer-Policy`, and a CSP
  (far easier once §1–§2 removed third-party origins) via the server, a plugin, or `functions.php`.

---

## 6. Performance & reach [RECOMMENDED]

Implements guide §6.

- **Images** — serve `webp`/`avif`, add `loading="lazy"` + `width`/`height` to avoid CLS, and ship
  responsive sizes. A conversion plugin or build step handles bulk.
- **Page caching** — a caching plugin (e.g. WP Super Cache / a host cache) so a traffic spike from a
  campaign or news mention is served from static HTML.
- **Fewer plugins** — each is page weight + attack surface + maintenance (guide §5). Audit and prune.
- **Self-host everything visual** (fonts §1, icons, OG images) so pages don't depend on third-party
  uptime and don't leak IPs.

---

## 7. Content structure that volunteers can't break [OPTIONAL]

Implements guide §8. For editable, mission-critical content (campaigns, partners, work areas,
events), register **custom post types + meta in a small companion plugin**, not in the theme — so
the content survives theme switches and casual maintainers edit safe fields instead of layout. See
`WP_PLUGIN_DEVELOPMENT_GUIDE.md` for the companion-plugin pattern. Pair with an FSE block theme that
*renders* those structures via patterns/templates.

---

## WordPress Privacy Quick-Check

- [ ] No `fonts.googleapis.com` / `fonts.gstatic.com` / `gravatar.com` in served HTML
- [ ] Emoji script + `s.w.org` dns-prefetch removed; unused oEmbed discovery stripped
- [ ] Analytics is cookieless/self-hosted (or none); **no cookies set for anonymous visitors**
- [ ] `wp_generator` meta removed; REST users endpoint + `?author=` enumeration restricted
- [ ] `DISALLOW_FILE_EDIT` set; editors aren't admins; 2FA on; stale accounts removed
- [ ] XML-RPC/pingbacks disabled if unused
- [ ] Off-site backups configured and test-restored
- [ ] Layered form spam protection in place
- [ ] Images are `webp`/`avif`, lazy-loaded, with dimensions; page caching on
- [ ] Editable content lives in a companion plugin (CPT/meta), not hard-coded in the theme
