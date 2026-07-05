# BP.works Company Defaults

> **Universality exception.** Every other document in `shared/supplements/wordpress/` (including the admin-ui-kit) is written to be universal — placeholder slugs only, no references to a specific company or plugin. This file is the ONE intentional exception: it holds the company constants that every BP.works plugin shares. Do not add plugin-specific content here — plugin-specific decisions belong in that plugin's own repo.

---

## Identity

- Company / author name: `BP.works`
- Plugin header lines: `Author: BP.works` and `Author URI: https://bp.works`
- Personal site `https://brandonjp.com` is linked from the bp.works landing page — it is never used as a plugin's `Author URI`.
- Legal status: sole proprietor (no LLC/inc yet) — acceptable for Freemius seller registration.

---

## Monetization constants

- Platform: Freemius acts as merchant of record for every plugin — checkout, EU VAT/sales tax, invoices, refunds, license keys, and pro update delivery all run through Freemius.
- Freemius seller name: `BP.works`.
- Pricing shape for every plugin: an annual auto-renewing subscription (a lapsed license keeps the plugin working — updates and support stop) plus a lifetime tier priced at roughly 3–4× the annual price.
- Site tiers: 1 / 5 / unlimited sites per license.
- Per-plugin price points vary by plugin; the pricing *shape* above does not.

---

## Telemetry endpoints

Pro builds report to the self-hosted OpenPanel instance (product analytics) and the self-hosted GlitchTip instance (error reporting). The actual ingestion URLs and DSNs are configured per project — as constants or environment values — and are NEVER committed to this shared repo. Free (wp.org) builds ship no custom telemetry at all; the only opt-in on the free tier is the Freemius connection itself. See `admin-ui-kit/ANALYTICS.md` for the full policy detail.

---

## Naming & prefix conventions

- Each plugin picks its own short prefix following the kit's placeholder scheme (`mp_` → e.g. `wpr_` for a plugin called WP Reporter).
- PHP namespace root may be `BPWorks\{Plugin}`.
- Text domain = the plugin's slug.
- wp.org readme Author field = `BP.works`.
