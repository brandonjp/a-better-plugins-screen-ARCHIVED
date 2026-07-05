# Free vs Pro — the Freemius Standard

> How every plugin in this portfolio splits free from paid. This file is universal: it uses the admin-ui-kit placeholder slugs (`MyPlugin`, `mp_`, `{plugin-slug}`, `MYPLUGIN_`) throughout — find/replace them for the plugin you are working in. Company-specific constants (seller name, pricing numbers) live in [`COMPANY_DEFAULTS.md`](./COMPANY_DEFAULTS.md); this doc references the *shape*, not the values.

---

## Decision record

**Freemius is the merchant of record for every plugin.** Freemius handles checkout, EU VAT / US sales tax, invoices, refunds, license-key issuance, and pro-update delivery — and ships a WordPress-native SDK for licensing and gated update channels. That last property is why it wins for a plugin portfolio.

Alternatives considered and rejected:

- **Own Stripe (or Lemon Squeezy) + a self-run license/update server.** Rejected: this puts the entire VAT/sales-tax compliance burden and a piece of always-on licensing infrastructure on the plugin author *before the first release ships*. Freemius absorbs all of that as merchant of record.
- **Paddle or Lemon Squeezy as merchant of record, alone.** They solve tax-as-MoR but offer **no WP-native licensing or gated-update SDK**. You would still have to build the license activation UI, the "is this a pro build" detection, and the premium update channel by hand. Freemius bundles those.

Reference plugins operating at comparable scale on Freemius: **Admin and Site Enhancements (ASE)** and **Code Snippets Pro** — both single-codebase free/pro plugins that ship a wp.org free build and a Freemius premium bundle from one repo.

---

## SDK integration

The Freemius WordPress SDK is vendored into the plugin tree — typically at `vendor/freemius/` — and `require`d once from the main plugin file *before* the SDK is used. The plugin exposes a single global accessor named `{prefix}_fs()` (here `mp_fs()`); everything else calls that.

Initialize with the standard Freemius `fs_dynamic_init()` boilerplate. The plugin ID, slug, and public key are issued by the Freemius dashboard when you register the plugin — the values below are placeholders:

```php
if ( ! function_exists( 'mp_fs' ) ) {
	// Create a helper function for easy SDK access.
	function mp_fs() {
		global $mp_fs;

		if ( ! isset( $mp_fs ) ) {
			// Include Freemius SDK.
			require_once dirname( __FILE__ ) . '/vendor/freemius/start.php';

			$mp_fs = fs_dynamic_init( array(
				'id'                  => '0000',              // Freemius plugin ID.
				'slug'                => '{plugin-slug}',
				'type'                => 'plugin',
				'public_key'          => 'pk_0000000000000000000000000',
				'is_premium'          => true,                // Stripped to false in the wp.org free build.
				'premium_suffix'      => 'Pro',
				'has_premium_version' => true,
				'has_addons'          => false,
				'has_paid_plans'      => true,
				'menu'                => array(
					'slug'    => '{plugin-slug}',
					'parent'  => array( 'slug' => 'options-general.php' ),
				),
			) );
		}

		return $mp_fs;
	}

	// Init Freemius.
	mp_fs();
	// Signal that the SDK was initiated.
	do_action( 'mp_fs_loaded' );
}
```

- **`is_premium` detection** — Freemius sets this per build. In the premium bundle it is `true`; the wp.org deployment strips the premium code and flips it to `false`. Runtime code reads it through the SDK (`mp_fs()->is_premium()`), never from a hand-set constant.
- **The accessor is always `{prefix}_fs()`** — one function, one global, wrapped in the `function_exists()` guard above so a pro build installed alongside a stale free copy cannot fatally redeclare it.

---

## Marking pro code

Freemius gives three mechanisms for separating premium code from the free build. Use whichever fits the granularity; combine freely.

1. **Whole files / directories flagged premium-only in the deployment settings.** Convention: put premium-only PHP under `includes/pro/`. The Freemius deployment step strips these paths out of the generated wp.org free build entirely. Nothing in the free build may hard-`require` a stripped file.

2. **The `__premium_only` function/file-name suffix.** A file named `feature__premium_only.php`, or a function named `mp_render_report__premium_only()`, is automatically excluded from the free build by the Freemius deploy tooling. Handy for a single premium method living beside free ones.

3. **Runtime gating with `mp_fs()->can_use_premium_code()`.** For code that *ships in both builds* but must only execute when a valid license is present:

   ```php
   if ( mp_fs()->can_use_premium_code() ) {
   	mp_render_pro_dashboard();
   }
   ```

> **Invariant:** free code paths must never fatal if pro code is absent. Guard every call into a premium-only file or function with `can_use_premium_code()` (or `is__premium_only()`), and never let a free-build code path reach a symbol that was stripped at deploy time.

---

## Build & deployment pipeline

- **One codebase per plugin.** There is no separate "free repo" and "pro repo" — the working tree contains everything, with premium regions marked per the section above.
- **The Freemius deployment step generates BOTH builds** from that single tree: the **wp.org free build** (premium files/functions stripped, `is_premium` → `false`) and the **premium bundle** (the full tree, `is_premium` → `true`). You do not assemble either zip by hand.
- **Version numbers stay identical across the free and premium builds of a release.** `v1.4.0` free and `v1.4.0` premium are the same release cut from the same commit — never let them drift.
- **The wp.org SVN receives only the Freemius-generated free build** — never the working tree, and never the premium bundle. The premium bundle is delivered exclusively through Freemius's update channel to licensed sites.

---

## Pricing shape

The company pricing standard (see [`COMPANY_DEFAULTS.md`](./COMPANY_DEFAULTS.md) § Monetization constants) applies to every plugin:

- **Annual auto-renewing subscription** — a lapsed license keeps the plugin working; only updates and support stop.
- **A lifetime tier** priced at roughly **3–4× the annual** price.
- **Per-site tiers:** 1 / 5 / unlimited sites per license.

Per-plugin price *points* vary; the shape above does not. Configure these tiers in the Freemius dashboard, not in code.

---

## The never-block invariants

The premium bundle **contains** the free code, which makes three invariants structural rather than aspirational. Every plugin must satisfy all three:

1. **Installing pro always works** — whether free is installed, active, or absent. If free is active, pro deactivates it silently and takes over.
   *How Freemius satisfies it:* because the premium bundle is a superset of the free plugin under the same plugin slug, activating it supersedes the free copy; the SDK deactivates the now-redundant free plugin without a prompt so there is never a "two copies active" fatal.

2. **Settings/data carry over free→pro automatically** — same option keys (a single codebase makes this structural).
   *How Freemius satisfies it:* the premium build reads the exact same `MYPLUGIN_`-prefixed option keys the free build wrote — nothing is migrated or copied because it is one codebase reading one set of options.

3. **No blocking notice ever stands between a paying customer and a feature they paid for.**
   *How Freemius satisfies it:* premium builds auto-connect on license activation (no opt-in screen), and renewal/license messaging is dismissible and non-blocking — a lapsed or pending license never gates access to the UI a customer already paid for.

**Pre-release acceptance checklist** (run before every release):

- [ ] Install the pro bundle over an **active** free copy → free auto-deactivates, no fatal, pro takes over.
- [ ] Install the pro bundle over an **inactive** free copy → activates cleanly.
- [ ] Install the pro bundle on a **clean** site (no free ever present) → activates cleanly.
- [ ] Verify settings saved under free **survive** the upgrade (same option keys, values intact).
- [ ] Verify **zero admin notices demand action** after license activation — no blocking connect/opt-in/renewal wall.

---

## Opt-in & connect policy

- **Free builds show the Freemius connect screen once**, restyled to admin-ui-kit tokens (see [`admin-ui-kit/ADMIN_UX_PATTERNS.md`](./admin-ui-kit/ADMIN_UX_PATTERNS.md) — branded-header / opt-in pattern) rather than stock Freemius chrome. The screen is **always skippable** — a user may decline the connection and keep using the free plugin fully.
- **Premium builds auto-connect on license activation** and never show the opt-in screen. A paying customer's license activation *is* the connection; asking them to opt in again would violate never-block invariant #3.

---

## License UX

- **License activation lives on the plugin's main settings page** — the same admin page the plugin already owns — not behind a separate top-level menu item.
- **A lapsed license keeps the plugin working;** only updates and support stop. Surface this with a **single dismissible** renewal notice — never a blocking wall, never a repeated nag.
- **Deactivating a license never deletes user data.** Deactivation releases the seat and stops updates; the plugin's options, content, and settings remain untouched so re-activating (or dropping to the free tier) is lossless.

---

## Pro visibility policy

- **Pro features are lightly visible in the free build** — rendered in place but locked, with a quiet `PRO` tag (kit tokens, not a loud banner). Free users can see what Pro adds without being nagged.
- **After upgrade the marker remains** as a subtle "included in Pro" label, so paying customers can see what their license unlocked (ASE-style).
- See the **pro-teaser & post-upgrade marker** pattern in [`admin-ui-kit/ADMIN_UX_PATTERNS.md`](./admin-ui-kit/ADMIN_UX_PATTERNS.md) for the exact markup, tokens, and the rule that gating is enforced server-side (`mp_fs()->can_use_premium_code()`) with the editor/UI lock being presentation only.
