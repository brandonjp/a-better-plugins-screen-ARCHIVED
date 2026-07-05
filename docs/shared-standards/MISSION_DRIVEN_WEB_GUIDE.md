<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Mission-Driven Web Guide

> **Purpose:** Best practices for websites whose organization has a *mission* rather than a
> margin — nonprofits, religious and faith communities, peacemaking and reconciliation groups,
> advocacy and human-rights organizations, and the privacy-conscious projects adjacent to them.
> The throughline: **the website should embody the organization's values, not just describe
> them.** A peace organization that leaks every visitor's IP to an ad-tech vendor, or a
> congregation whose donation form uses dark patterns, contradicts itself in code.
>
> **Scope:** Framework-agnostic. Covers *what* to do and *why it's mission-aligned*. For the
> *how* on a specific stack, see the supplements (e.g. WordPress → `WP_PRIVACY_HARDENING.md`).
>
> **How to read this:** Every practice is tagged **[RECOMMENDED]** (a sensible default for
> almost any mission-driven site — adopt unless you have a reason not to) or **[OPTIONAL]**
> (valuable in the right context; weigh against effort and the org's actual needs). None of
> this is a hard requirement — it's a menu to choose from deliberately. When a project's own
> `CLAUDE.md` mandates something (e.g. "self-host fonts"), that always wins.
>
> **Origin:** Distilled while building jpf.ngo (Jewish Peace Fellowship, 2026) and intended to
> seed a family of similar sites (interfaith / peace / reconciliation orgs and their offshoots).

---

## Design Principles

1. **Congruence — the medium is part of the message.** Whatever the org stands for (peace,
   dignity, justice, stewardship, hospitality), the site's technical choices should not quietly
   undercut it. Privacy orgs shouldn't run trackers; anti-surveillance orgs shouldn't embed
   surveillance SDKs; accessibility-minded communities shouldn't ship inaccessible pages.
2. **Data dignity over data extraction.** Treat every visitor's data — IP, behavior, email,
   donation — as something held in trust, collected only when it serves *them* or the mission,
   never hoarded "because we can." Minimize, protect, and be honest about what you collect.
3. **Inclusion is not a feature, it's the baseline.** Mission-driven audiences skew broad: older
   members, low-bandwidth and global visitors, assistive-tech users, multiple languages. The
   default page should work for the person on a 5-year-old Android over 3G with a screen reader.
4. **Stewardship of limited resources.** Most of these orgs run lean — volunteer maintainers,
   small budgets, infrequent updates. Favor low-maintenance, low-cost, durable choices over
   clever ones that rot. The best architecture is the one a non-developer can't easily break.
5. **Trust is the conversion metric.** These sites rarely "sell." They ask for belief, membership,
   donations, attention, trust. Transparency, authenticity, and the absence of manipulation are
   the real optimization targets — not click-through rate.

---

## 1. Data Dignity & Privacy

The core of "the medium is the message" for most of these orgs. **[RECOMMENDED]** as a whole.

### 1.1 Self-host third-party assets [RECOMMENDED]
Fonts, icon sets, scripts, and embeds loaded from a third-party CDN transmit every visitor's IP
(and often a referrer + user-agent fingerprint) to that vendor on page load — usually Google.
- **Google Fonts** is the classic case: a German court (Munich, 2022) ruled that hotlinking it
  transmits visitor IPs without consent, an unlawful GDPR processing. Self-host the `woff2` files.
- The same logic applies to **CDN-hosted JS libraries** (jsDelivr, cdnjs, unpkg), **Gravatar**,
  **embedded maps/videos/social widgets**, and **analytics beacons**. Self-host or proxy what you
  can; lazy-load and consent-gate what you can't (see 1.4).
- **Mission angle:** for a privacy- or rights-focused org, *not* leaking supporters' IPs to ad-tech
  is table stakes. For everyone else it's still a GDPR liability and a speed win.

### 1.2 No surveillance trackers by default [RECOMMENDED]
Do **not** add Meta/Facebook Pixel, Google Ads remarketing, TikTok pixel, or similar behavioral
ad trackers unless there's a specific, consented advertising program that justifies them. They
exist to feed ad networks, follow people across the web, and are exactly what a values-driven
audience distrusts. If marketing genuinely needs conversion tracking, prefer server-side or
first-party measurement and disclose it plainly.

### 1.3 Ethical, privacy-respecting analytics [RECOMMENDED]
You can measure traffic without surveilling people. Prefer **cookieless, IP-anonymizing,
self-hostable** analytics (e.g. Plausible, Fathom, Matomo with anonymization, or a lightweight
self-hosted counter) over Google Analytics 4. Benefits: usually no cookie banner required, no
data sold, far lighter page weight, and a story you can tell supporters with a straight face.
Track what informs decisions (top pages, referrers, conversions), not individuals.

### 1.4 Consent only when truly needed [RECOMMENDED]
If you follow 1.1–1.3, you often need **no cookie banner at all** — the best consent UX is having
nothing to consent to. Add a consent mechanism only when you load something that legally requires
it (ad trackers, non-anonymized analytics, third-party embeds). When you do, make "reject" as easy
as "accept" — no pre-ticked boxes, no nag walls, no dark patterns. A banner that coerces consent
is worse than honest data minimization.

### 1.5 Data minimization on forms [RECOMMENDED]
Ask for the least you need. A newsletter signup needs an email, not a phone number, mailing
address, and date of birth. Every extra field is data you must now protect, justify, and not leak.
Mark optional fields as optional. Don't pre-check "share my info with partners."

### 1.6 Protect supporter / donor / member data [RECOMMENDED]
This data is often *more* sensitive than e-commerce data — political affiliation, religious
membership, and donation history can endanger people in some contexts.
- Never commit secrets, exports, or member lists to the repo.
- Use least-privilege access; don't give every volunteer admin.
- Prefer payment processors that tokenize (Stripe, etc.) so card data never touches your server.
- Have a deletion path: people can ask to be forgotten, and you should be able to honor it.

### 1.7 Honest privacy policy & transparency [RECOMMENDED]
Publish a plain-language privacy policy that actually matches what the site does (if you self-host
everything and run cookieless analytics, *say so* — it's a selling point). Include what you collect,
why, how long you keep it, who it's shared with (ideally "no one"), and how to contact you or
request deletion. Don't paste a boilerplate policy that describes trackers you don't run.

---

## 2. Accessibility & Inclusion

Dignity and inclusion are core values for most of these orgs; an inaccessible site excludes the
very people the mission serves. Target **WCAG 2.1 AA**. **[RECOMMENDED]** as a whole.

- **Semantic HTML & landmarks** — real headings (`h1`→`h2`→`h3` in order), `nav`/`main`/`footer`,
  buttons that are `<button>` and links that are `<a>`. Screen readers and keyboards depend on it.
- **Color contrast** — body text ≥ 4.5:1, large text ≥ 3:1. Check the brand palette against real
  backgrounds, not in isolation. Heritage/muted palettes often fail — verify.
- **Keyboard navigation** — every interactive element reachable and operable by keyboard, with a
  visible focus ring. Test by unplugging the mouse.
- **Alt text** — meaningful images get descriptive alt; decorative images get empty `alt=""`.
  Honor the *content* (a portrait of a historical figure deserves a real description).
- **Reduced motion** — respect `prefers-reduced-motion`; gate animations (marquees, parallax,
  headline effects) behind it. Motion can be a vestibular barrier.
- **Plain language** — write for a broad reading level. Mission audiences include elders, newcomers,
  and non-native speakers.
- **Language & direction [OPTIONAL]** — declare `lang`; if the org works across languages (Hebrew,
  Arabic, etc.), plan for `dir="rtl"`, proper fonts, and translated content early, not bolted on.

---

## 3. Trust, Transparency & Identity

Mission sites run on credibility. **[RECOMMENDED]** unless noted.

- **Unambiguous identity** — who you are, what you believe, where you're based, legal/charity
  status (e.g. 501(c)(3) / registered charity number), and real contact info. Anonymity erodes trust.
- **Financial transparency [OPTIONAL]** — for nonprofits, link annual reports, Form 990 / financial
  statements, or an impact page. Donors increasingly expect it.
- **Authentic representation [RECOMMENDED]** — use real photos and properly licensed imagery; credit
  sources; honor the heritage and the people depicted. Avoid generic stock that misrepresents the
  community. (For JPF: the stamp gallery honoring figures and moments is identity, not decoration.)
- **Governance & people [OPTIONAL]** — board, staff, or leadership visibility builds confidence,
  especially for faith and advocacy orgs.
- **Accurate metadata & sharing** — correct page titles, descriptions, and Open Graph tags so the
  org is represented faithfully when shared. (Self-host OG images too — see 1.1.)

---

## 4. Ethical Fundraising & Donations

Applies when the site takes donations or memberships. **[OPTIONAL]** by presence, **[RECOMMENDED]**
in *how* once present.

- **No dark patterns** — don't pre-select the largest amount, don't sneak recurring donations past
  people, don't hide the decline option, don't guilt-trip with manipulative copy. Coercion betrays
  the mission.
- **Recurring clarity** — if a gift is monthly, say so unmistakably before submit, and make
  cancellation easy and documented.
- **Secure, tokenized payments** — use Stripe/PayPal/Donorbox-style processors so card data never
  hits your server. Serve donation pages over HTTPS only.
- **Donor privacy** — don't expose donor identities without explicit opt-in; offer anonymous giving.
- **Transparent receipts & use of funds** — immediate receipt, clear tax-deductibility language, and
  ideally a sentence on what the gift supports.
- **Low-friction, low-fee** — every percentage point and form field lost is mission money lost.
  Favor processors with nonprofit rates and the fewest steps to give.

---

## 5. Security & Stewardship

Good security *is* good stewardship of a lean org's trust and resources. **[RECOMMENDED]**.

- **Keep the platform updated** — core, themes, plugins, dependencies. Unpatched CMS installs are
  the #1 way small-org sites get defaced or used for spam.
- **Least privilege** — distinct accounts per person, admin only for those who need it, strong/2FA
  auth, and remove accounts when volunteers move on.
- **Backups you've actually restored** — automated, off-site, and test-restored at least once. A
  backup you've never restored is a hope, not a plan.
- **Form spam protection** — mission sites are heavy spam targets (contact, signup, donation forms).
  Use layered, low-friction protection. See **`SPAM_PROTECTION_PATTERN.md`**.
- **HTTPS everywhere**, HSTS, and sane security headers (CSP where feasible — easier once you've
  self-hosted assets per §1).
- **Dependency hygiene** — fewer plugins/packages = smaller attack surface and less to maintain.
  Every dependency is a liability someone must keep patched.
- **Incident basics [OPTIONAL]** — know who to call, where backups are, and how to take the site to
  a maintenance page. Write it down so a volunteer can follow it.

---

## 6. Performance, Sustainability & Reach

Fast, light pages are an *equity* issue, not just a UX nicety. **[RECOMMENDED]**.

- **Lightweight by default** — self-hosted subsetted fonts, compressed/responsive images
  (`woff2`, `webp`/`avif`, lazy-loading), minimal JS. Every megabyte excludes someone on a slow or
  metered connection — and mission audiences are often global and under-resourced.
- **Caching & a CDN for your *own* assets [OPTIONAL]** — page caching and a privacy-respecting CDN
  (one that doesn't profile visitors) for static files improve reach without the §1 tradeoffs.
- **Carbon / sustainability [OPTIONAL]** — lighter pages use less energy; for environmentally-minded
  orgs this is on-mission. Green hosting is a credible, low-effort signal.
- **Resilience on a budget** — prefer architectures that survive a traffic spike (a news mention, a
  campaign) via static caching rather than expensive always-on infrastructure.
- **Core Web Vitals** — fast LCP, low CLS, responsive INP. Good for humans, search, and stewardship.

---

## 7. Content, Tone & Representation [OPTIONAL]

- **Respectful, dignified tone** — match the org's voice (for heritage/peace orgs: warm,
  dignified, heritage-aware). Avoid hype and manipulation.
- **Sensitive topics handled with care** — conflict, persecution, trauma, and interfaith material
  deserve careful framing, content warnings where appropriate, and community review.
- **Image & content licensing** — confirm you have rights to every photo, quote, and font (OFL,
  Creative Commons, or licensed). Credit creators. This protects a small org from liability and
  models the integrity it preaches.
- **Multilingual readiness** — if the community is multilingual, design for it early (translation
  workflow, language switcher, RTL) rather than retrofitting.

---

## 8. Maintainability for Volunteers [OPTIONAL]

- **Editors can't easily break it** — structure content so casual maintainers edit text and images
  safely without touching code or layout. (Pattern: a companion plugin/CPT layer that owns content
  structures so they survive theme changes — as done for jpf.ngo's `jpf-content`.)
- **Document the handoff** — a short "how to update this site" guide (where content lives, how to
  add a post/event, who hosts it, where backups are) outlives any single volunteer.
- **Boring, durable tech** — choose well-supported, widely-known tools a future maintainer can hire
  for, over bespoke or trendy stacks that strand the org.

---

## Quick-Start Baseline (the [RECOMMENDED] minimum)

For any new mission-driven site, treat these as the default checklist:

- [ ] Self-host fonts and other third-party static assets (no Google Fonts CDN, no hotlinked libs)
- [ ] No behavioral ad trackers (no Meta Pixel / Google Ads) unless explicitly justified + consented
- [ ] Cookieless, IP-anonymizing analytics (or none) — avoid GA4 by default
- [ ] No cookie banner needed because there's nothing invasive to consent to
- [ ] Forms collect the minimum; optional fields marked optional; layered spam protection
- [ ] WCAG 2.1 AA: semantic HTML, AA contrast, keyboard access, alt text, `prefers-reduced-motion`
- [ ] HTTPS everywhere; platform + dependencies kept updated; least-privilege accounts; tested backups
- [ ] Honest, plain-language privacy policy that matches reality
- [ ] Light pages (subsetted fonts, `webp`/`avif`, minimal JS) for global/low-bandwidth reach
- [ ] If taking donations: tokenized payments, no dark patterns, clear recurring + receipts
- [ ] Clear org identity, real contact, authentic/licensed imagery

---

## Companion Docs

- **`SPAM_PROTECTION_PATTERN.md`** — layered form spam protection (referenced in §5).
- **`ANALYTICS_PLAYBOOK.md`** — analytics integration patterns (apply the privacy lens in §1.3 here).
- **`UTM_PARAMETER_CONVENTION.md`** — structuring campaign links without leaking more than needed.
- **`PROJECT_HEALTH_CHECKLIST.md`** — general architectural/security health.
- **`EMAIL_INFRASTRUCTURE.md`** — sending + logging email (mind donor/member data per §1.6).
- **Stack supplements** — e.g. `../../supplements/wordpress/WP_PRIVACY_HARDENING.md` for the
  concrete WordPress recipes that implement §1, §5, and §6.
