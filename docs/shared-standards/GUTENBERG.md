# Gutenberg — the Light Block Standard

> How this portfolio does block-editor work. This file is universal: it uses the admin-ui-kit placeholder slugs (`MyPlugin`, `myplugin/`, `mp_`, `{plugin-slug}`) throughout — find/replace them for the plugin you are working in. This is a deliberately *small* standard; see § Scope for what it intentionally leaves out.

---

## Scope

This is a **light** block-editor standard for a portfolio of mostly admin-page plugins, where blocks are the exception rather than the main surface. It sets just enough convention to keep the occasional block consistent, and no more. The following are **out of scope** on purpose: a shared block **component library** (no cross-plugin React components), an editor **design-token mirror** (the admin-ui-kit tokens are for wp-admin, not for reimplementing in the editor canvas), and block **scaffolding tooling** (no generator — copy an existing block directory). Revisit and grow this standard only when blocks become a **major surface** for a plugin (several interacting blocks, or a block-driven front end); until then, keep it light.

---

## Block vs shortcode vs nothing

Decide before building — most features need no block at all:

- **Ship a block** when the content is **visual and placeable by editors** — something an author positions on a page and wants to see rendered in context (a callout, a card grid, an embed).
- **Keep a shortcode** when output is **dynamic/parameterized** and **legacy (classic / non-block) themes** still matter. A thin block that simply wraps the shortcode's render callback is fine — it gives block-theme users an inserter entry without forking the render logic.
- **Ship neither** when the feature is **admin-only** — configuration, reporting, tooling. It belongs in wp-admin, not the editor.

> **Rule:** never ship a block that is just a settings form. If the block's only job is to collect configuration, those settings belong on a wp-admin page, not in the editor inspector.

---

## Build conventions

- **`block.json`-first registration.** Every block is described by a `block.json`; metadata, attributes, and asset handles live there, not scattered through PHP.
- **One directory per block** under `src/blocks/{block-name}/` (source) building to `build/blocks/{block-name}/`.
- **Namespace `myplugin/{block-name}`** for the block name — one namespace per plugin, matching the plugin slug.
- **Build with `@wordpress/scripts`** — `wp-scripts build` for production, `wp-scripts start` for watch mode. No hand-rolled webpack.
- **Enqueue only via `block.json` assets** (`editorScript`, `script`, `viewScript`, `style`, `editorStyle`) — never manually `wp_enqueue_*` a block's editor bundle.
- **PHP-side registration** points at the built directory so the metadata is read once:

  ```php
  add_action( 'init', function () {
  	register_block_type( __DIR__ . '/build/blocks/{block-name}' );
  } );
  ```

---

## Editor UX invariants

- **Previews render real data in the editor.** Use `ServerSideRender` (for shortcode-backed / PHP-rendered blocks) or properly hydrated attributes so the author sees the actual output. **Never** ship a gray "this block renders on the front end" placeholder box in place of the real preview.
- **Every block has a real placeholder / empty state** for the unconfigured case — a `Placeholder` component with an icon, label, and the control needed to configure it — not a blank rectangle or a raw error.
- **Per-block options go in the inspector sidebar** (`InspectorControls`); **site-wide options go in wp-admin.** Never split the same concern across both — a setting is either per-instance (inspector) or global (admin page), never duplicated in two places.

---

## Pro-gating in the editor

Pro-only blocks, variations, and controls appear **locked** in the free build with the same quiet `PRO` tag as the admin pro-teaser pattern (see [`admin-ui-kit/ADMIN_UX_PATTERNS.md`](./admin-ui-kit/ADMIN_UX_PATTERNS.md) — pro-teaser & post-upgrade marker). Rules:

- Clicking a locked control shows an **inline upgrade hint** (a small notice or link in place) — **never a modal**.
- **Gating is enforced server-side.** The block's render callback checks `mp_fs()->can_use_premium_code()` before emitting premium output; a free build that somehow renders a pro block still produces nothing privileged.
- **The editor lock is UX only** — a presentational affordance so the author sees what Pro adds. It is never the security boundary; the render callback is.

---

## Pre-release checklist

Run before shipping any block (all mechanically checkable):

- [ ] `block.json` validates (no schema errors; block registers without a `register_block_type` warning).
- [ ] `wp-scripts build` completes **clean** (no errors, no unresolved imports).
- [ ] Block **inserts** from the inserter **without console errors**.
- [ ] The **empty / unconfigured state** renders (placeholder shown, no blank box, no raw error).
- [ ] **Keyboard-only insertion** works (open inserter, select, insert — all without a mouse).
- [ ] **Pro-locked controls render correctly in the free build** (visible, locked, quiet `PRO` tag; inline hint on click, no modal).
- [ ] The front-end render matches the editor preview (no "renders on the front end" divergence).
