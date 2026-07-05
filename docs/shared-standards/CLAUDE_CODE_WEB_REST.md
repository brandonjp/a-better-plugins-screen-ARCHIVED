# Driving WordPress from Claude Code Web (REST + Application Password)

How to let **Claude Code on the web** (the cloud sandbox — no SSH, no FTP, no
secure secret store) make real changes to a live WordPress site, safely, from
your phone. The only channel that works is the **WordPress core REST API** over
HTTPS, authenticated with a **WordPress Application Password**.

Companion script: [`scripts/wp-rest.sh`](../../scripts/wp-rest.sh) (synced to
`<project>/scripts/wp-rest.sh`).

For server-side work that REST can't do (plugins, WP-CLI, DB, logs, code
deploys), use the **`wp-host-ops`** skill from a local machine instead — that's
the SSH + WP-CLI channel. This doc is only the REST/web channel.

---

## What's reachable, what isn't

The dividing line is "is it editable **data in the database**, exposed by the
core REST API?" — not "can WP-CLI do it" (WP-CLI can do far more, but needs a
shell the web sandbox doesn't have).

**Tier 1 — reachable from Claude Code web (this doc):**

| Thing | Endpoint | Min role |
|---|---|---|
| Posts | `/wp/v2/posts` | Author / Editor |
| Pages | `/wp/v2/pages` | Editor |
| Media | `/wp/v2/media` | Author |
| Users | `/wp/v2/users` | Administrator |
| Menus & items | `/wp/v2/menus`, `/wp/v2/menu-items` | Administrator |
| FSE templates / parts (**block themes only**) | `/wp/v2/templates`, `/wp/v2/template-parts` | Administrator |
| Synced patterns (reusable blocks) | `/wp/v2/blocks` | Editor |
| Core settings (small allowlist) | `/wp/v2/settings` | Administrator |

**Tier 2 — NOT reachable over core REST (use `wp-host-ops` / WP-CLI / a
companion plugin):** plugin settings (e.g. "turn off the custom wp-admin login
path" — that's a security plugin's option), classic-theme PHP templates,
code-registered block patterns, theme/plugin file edits, the database, server
config. If you need these from the web, the only path is a **companion plugin**
on the site that exposes the specific operation over its own authenticated REST
endpoint.

> Design tip for sites you build: keep client-editable chrome (button labels,
> headings, CTAs) in **editable content** — blocks, menus, FSE templates — not
> hardcoded in theme PHP. Then the whole class of "change X to Y" requests
> becomes Tier 1.

---

## One-time setup per site

### 1. WordPress side — least-privilege user + application password

- Create (or pick) a dedicated WP user with the **lowest role** that covers your
  needs: **Editor** for content-only sites (the blog), **Administrator** only if
  you need to edit menus, FSE templates, or settings.
- As that user: **Users → Profile → Application Passwords** → add one named for
  this use (e.g. `claude-web`). Copy the generated password (spaces are fine).
- Application passwords are **scoped to that user, independently revocable, and
  never your real login**. If one leaks, revoke just that one — zero impact on
  the account password.
- **One application password per site.** A leak is then contained to that site.

### 2. Claude Code web — environment variables

In the cloud environment (Settings → environment), set:

```
WP_URL=https://example.com
WP_USER=claude-web-user
WP_APP_PW=xxxx xxxx xxxx xxxx xxxx xxxx
```

and set **Network access = Full** (or a custom allowlist that includes the
site's domain).

Notes on the (acknowledged) credential tradeoff:

- Claude Code web's env-var box is **not** a secret store — it warns "visible to
  anyone using this environment." That warning is really about *shared/team*
  environments. On a **solo account** the exposure narrows to "anyone who
  compromises your Claude account."
- This is an acceptable risk **because** the credential is a scoped, revocable
  application password — not a master key. Keep it that way: least-privilege
  role, one per site, rotate occasionally, 2FA on the Claude account, don't
  enable environment sharing.
- `scripts/wp-rest.sh` references `$WP_APP_PW` by name and passes it to curl via
  a config stream, so the literal value never lands in the transcript.
- **One environment per site** keeps each session scoped to a single site's
  credential. The variable *names* are identical everywhere — only the values
  differ — so it's a 30-second copy, not a custom profile.

### 3. Repo side — almost nothing

- This doc + `scripts/wp-rest.sh` (both arrive via the normal shared-docs sync).
- **Nothing secret is committed.** The app password lives only in the
  environment. `WP_URL` isn't secret, but keeping it an env var lets this doc
  stay byte-identical across every site.
- No `.mcp.json` (we use direct REST, not MCP — and the common WordPress MCP is
  a local stdio server that won't run on the web anyway).
- No GitHub Actions / CI. Zero workflow minutes consumed.

---

## Cheat-sheet

All commands assume `scripts/wp-rest.sh` and the three env vars. Run
`scripts/wp-rest.sh help` for the interface.

**Verify auth** (do this first):
```bash
scripts/wp-rest.sh me
```

**Create a draft post:**
```bash
echo '{"title":"June meeting — Part 1","status":"draft",
       "content":"<!-- wp:paragraph --><p>Starter copy…</p><!-- /wp:paragraph -->"}' \
  | scripts/wp-rest.sh post /wp/v2/posts
```
(`"status":"publish"` to go live. `excerpt`, `categories`, `tags`, `slug`,
`featured_media` all accepted.)

**Find a page by slug** (get its ID + current block content):
```bash
scripts/wp-rest.sh get '/wp/v2/pages?slug=home&context=edit'
```

**Edit a page** (e.g. change a button label) — send the full updated `content`
(block markup), POST to the page ID:
```bash
echo '{"content":"<!-- wp:button --><div class=\"wp-block-button\">
       <a class=\"wp-block-button__link\">Give</a></div><!-- /wp:button -->"}' \
  | scripts/wp-rest.sh post /wp/v2/pages/42
```
Workflow: `get` the page with `context=edit`, edit the returned block markup,
POST the whole `content` back. Preserve the surrounding blocks you didn't touch.

**Rename a menu item:**
```bash
scripts/wp-rest.sh get '/wp/v2/menu-items?menus=3&context=edit'   # find the item id
echo '{"title":"Give"}' | scripts/wp-rest.sh post /wp/v2/menu-items/57
```

**Edit an FSE template part** (block themes — e.g. the header):
```bash
scripts/wp-rest.sh get '/wp/v2/template-parts?context=edit'      # find the id (theme//slug)
echo '{"content":"…updated block markup…"}' \
  | scripts/wp-rest.sh post '/wp/v2/template-parts/theme-slug//header'
```

**Read / update a core setting:**
```bash
scripts/wp-rest.sh get '/wp/v2/settings'
echo '{"title":"New Site Title"}' | scripts/wp-rest.sh post /wp/v2/settings
```

**Anything else:** `get` / `post` / `put` / `delete` against any core REST path.
If a `post`/`put` returns a `rest_cannot_edit` / `403`, the app-password user's
role is too low — raise the role or do it via `wp-host-ops`.

---

## Limits & gotchas

- **Block content is HTML + block comments.** To change text you usually `get`
  the post/page/template with `context=edit`, modify the returned `content`, and
  POST it back whole. Don't hand-write block markup from scratch unless you must.
- **Page builders** (Elementor, Divi, Beaver) store layout in post meta, not in
  `content` — editing them over REST is fiddly and builder-specific. Treat as
  Tier 2 unless you know the meta shape.
- **403 / `rest_cannot_*`** → role too low (or app passwords disabled on the
  host). **401** → bad/expired app password. **404 on `/wp-json`** → permalinks
  not set to "pretty" (REST needs them) or REST disabled by a plugin.
- **Tier 2 is genuinely out of reach** here. Don't try to toggle plugin settings
  or edit theme PHP over core REST — switch to `wp-host-ops` (SSH + WP-CLI).
