<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# WordPress FSE Block-Theme Workflow

> **Purpose:** How to develop a **custom Full-Site-Editing (block) theme** without losing
> work to the silent drift between theme files and the live Site Editor. Establishes a
> **single source of truth** (the git repo) and a **single-track reconciliation ritual**
> backed by the `wp-fse-sync.sh` tool.
>
> **Scope — WordPress only.** This applies to **WordPress projects with a custom Full-Site-
> Editing (block) theme** whose templates/parts/`theme.json` live in the repo and whose host is
> registered with `wp-host-ops`. Framework facts are WordPress 6.6+ / 7.0. It does **not** apply
> to classic (PHP) themes or to non-WordPress projects.
>
> **Open question — plugins that ship front-end UI/styles/templates.** A companion/custom
> plugin that registers block patterns, block styles, or its own front-end templates *could*
> benefit from the same "repo is source of truth, reconcile DB edits back" discipline — but
> `wp-fse-sync.sh` as written only syncs the **active theme's** `wp_template` /
> `wp_template_part` / `wp_global_styles`. Plugin-provided patterns/styles are normally pure PHP
> (no DB customization layer to reconcile), so the tool isn't needed there *unless* the plugin
> exposes something editable in the Site Editor. Undecided whether to extend the tool for that
> case; revisit per-project rather than assuming it applies.
>
> **Origin:** Distilled while building jpf.ngo (Jewish Peace Fellowship, 2026); intended to
> seed a family of similar custom-theme WordPress projects.

---

## The core problem

In a block theme, two things can render your templates, and they disagree:

1. **Theme files** — `templates/*.html`, `parts/*.html`, `theme.json`, `patterns/*.php`.
   Version-controlled, portable, the *default*.
2. **The DB customization layer** — when anyone edits in the **Site Editor**, WordPress
   does **not** write to the theme files. It writes new posts: `wp_template`,
   `wp_template_part`, and (for the Styles panel) `wp_global_styles`.

**The DB layer always wins.** A customized `wp_template_part` overrides the theme file of
the same slug. So the moment you tweak anything in the Site Editor, the repo is stale and
your next file deploy silently does nothing visible. This is the #1 way block-theme work
gets lost or confused.

## The principle: one source of truth, one save-back path

- **Source of truth = the git repo.** Always. It is durable, reviewable, and seeds sister
  sites.
- **Editing surface = either place.** Edit files directly (in the repo), *or* tweak live in
  the Site Editor — whichever is efficient for the task. Forcing every spacing nudge through
  a code edit is unrealistic for a production site; the Site Editor is a legitimate surface.
- **The invariant that keeps them from fighting:** *at rest*, the theme files (repo == live)
  are authoritative and the **DB customization layer is empty**. The DB layer is only ever a
  temporary working state between a Site-Editor edit and the next `pull`.

### Why NOT the "Create Block Theme" plugin

Create Block Theme's "Save changes to theme" writes Site-Editor changes into the live
theme **files** — but never into your **repo**. So you still have to pull to the repo
afterward, and now there are *two* save-back paths. Two paths is exactly how something ends
up saved-on-live-but-never-committed. Keep it **deactivated**; use the single-track tool
below as the only save-back path. (It also tends to reformat/normalize markup, muddying
diffs.)

## The tool: `wp-fse-sync.sh`

Project-agnostic; all connection details resolve from the `wp-host-ops` registry via a host
alias. Per-project config (`scripts/fse-sync.conf`) supplies only `HOST_ALIAS`,
`THEME_SLUG`, `THEME_DIR`.

```
wp-fse-sync.sh status              # drift report: what's customized in the live DB
wp-fse-sync.sh pull                # DB customizations → repo files (+ export global styles)
wp-fse-sync.sh push [--reset-db]   # repo files → live, flush; --reset-db clears DB layer
```

### The reconciliation ritual

```
wp-fse-sync.sh status                  # 1. see what drifted
wp-fse-sync.sh pull                    # 2. fold live edits into repo files
git add -A && git commit -m "..."      # 3. repo is now truth
wp-fse-sync.sh push --reset-db         # 4. files → live, clear DB so files win again
```

Do this at the end of any session that touched the Site Editor. After it, `status` should
report **no drift**.

### Two surfaces, two directions

- **You edit files (structural / code):** edit repo → `push --reset-db` → commit.
- **You edit live (Site Editor tweaks):** edit → `pull` → commit → `push --reset-db`.

## Gotchas

- **Global Styles are not a file.** The Styles panel saves to `wp_global_styles` (a JSON
  layer), not `theme.json`. `pull` exports it to `.fse-pull/global-styles.<slug>.json` for a
  **manual** merge into `theme.json` — auto-merging a layered JSON is too risky to automate.
  If you `--reset-db` without merging first, those style tweaks are gone. Merge, then reset.
- **Patterns are PHP, not editor-editable.** `patterns/*.php` are registered code, edited in
  the repo only. Editing an *inserted* pattern in the editor just edits the host template/part
  (which `pull` captures). True **synced patterns** are `wp_block` posts — a separate entity
  this tool does not track; avoid them for theme-canonical layout.
- **Navigation `ref` vs inline.** A nav block can reference a `wp_navigation` post by ID
  (`{"ref":123}`) — convenient for editing the menu in the UI, but that ID is site-specific
  and breaks portability. For a canonical theme file, prefer **inline** `navigation-link`
  children so the header is self-contained. (Menus are per-site anyway; they are not shared
  across sister sites.)
- **Page content is not a template.** A static front page lives in a `page` post
  (`post_content`), which is *content*, not theme files — it stays in the DB and is not synced
  by this tool. Only templates/parts/global-styles are theme artifacts.
- **The DB override is invisible until you look.** If a file deploy "does nothing," run
  `status` — there is almost certainly a DB customization shadowing it.

## theme.json controls & client-account gating (the role model)

`theme.json` `settings` are **global** — they gate which editor controls appear *and* drive
front-end rendering and the global-styles CSS. Two consequences:

- **Enable the full design toolset for development** with `"appearanceTools": true` plus
  explicit `border`, `dimensions`, `position`, `shadow`, and `spacing`
  (`blockGap`/`margin`/`padding`/`customSpacingSize`). Without these, the editor hides Gap,
  margin, border, etc. — a common "why are my controls missing?" surprise.
- **Do NOT "close down" theme.json to gate clients.** Disabling, say, `spacing.blockGap`
  globally removes gap rendering for *every visitor* (front-end CSS is generated from the
  global theme.json, not from any per-user editor filter). Default-open is correct; restrict
  clients in a separate PHP layer.

### Recommended gating (build only when a client/designer actually exists)

The real protection is **structural locking**, not hiding controls:

1. **Lock the layout** — `templateLock` on templates/patterns + per-block
   `{"lock":{"move":true,"remove":true}}`. This keeps maintainers from breaking structure
   regardless of which controls show. *This is the load-bearing layer.*
2. **Trim controls for non-admins (optional polish)** — a `block_editor_settings_all` filter
   in the companion plugin, gated on a **custom capability** (e.g. `manage_theme_design`),
   that strips spacing/border/color-custom from `$settings['__experimentalFeatures']` when
   the current user lacks it. Capabilities (not roles) are the right primitive; a role is just
   a bundle.

**Role model — Model A (recommended default):** client = a beefed-up **Editor** (or custom
"Content Editor") role; you = **Administrator**. Design controls *and* the Site Editor are
admin-only by nature, so there is nothing extra to wall off. Most portable across sites.

- *Avoid* Multisite "Super Admin" unless you genuinely run a network (it doesn't exist on
  single-site installs).
- *Avoid* multiple-roles-per-user (needs a plugin; confusing handoffs).
- If a client *must* be a full Administrator, grant the design capability only to **your
  user** (or a "Designer" role you alone hold). Note: cleanly hiding the Site Editor itself
  between two Administrators is fiddly (it keys off `edit_theme_options`), so this path hides
  style controls but not the whole Site Editor.

**Build-it-when-needed:** if the site is solo (just the developer) with a content-only client
later, you often need *neither* a custom role nor the control-stripping filter yet — just
enable the controls and add locking when the client arrives. Document the plan; don't
over-build.
