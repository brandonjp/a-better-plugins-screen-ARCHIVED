<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Shared Infrastructure Decision Guide

> **Purpose:** A per-service decision guide for when and whether to adopt each shared infrastructure service across the portfolio. Covers analytics, observability, and infrastructure services -- all self-hosted.
>
> **How to use:** Reference this when bootstrapping a new project, auditing an existing one, or deciding whether a service applies. The [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) covers *how* to implement; this guide covers *whether* to implement.
>
> **Origin:** Distilled from cross-project audit of 8 production codebases (March 2026).

---

## Table of Contents

1. [Service Reference](#1-service-reference)
2. [Decision Matrix](#2-decision-matrix)
3. [New Project Checklist](#3-new-project-checklist)
4. [Cost and Resource Considerations](#4-cost-and-resource-considerations)
5. [Analytics Provider Evaluation Status](#5-analytics-provider-evaluation-status)

---

## 1. Service Reference

### Analytics Providers

#### Umami

**What it does:** Self-hosted, privacy-first web analytics. Tracks page views, referrers, devices, and custom events without cookies. Provides a clean dashboard per site.

**When to adopt:**
- The project has any public-facing UI (web pages, not just an API).
- You want baseline traffic data (page views, referrers, geography).

**When to skip:**
- API-only projects with no rendered pages.
- Purely native mobile apps where the Umami JS script cannot run (use server-side tracking instead if needed).

**Setup complexity:** Low. One `<script>` tag in the base template, plus two env vars (`ANALYTICS_UMAMI_URL`, `ANALYTICS_UMAMI_WEBSITE_ID`). Create a new site in the Umami dashboard and paste the ID.

**Dependencies:** Umami instance running on Coolify. No per-project database or backend changes needed.

---

#### OpenPanel

**What it does:** Product analytics with event tracking, funnels, and user journeys. Script loads from CDN (`openpanel.dev`); data is sent to a self-hosted API endpoint.

**When to adopt:**
- Same criteria as Umami -- any project with a public-facing UI.
- Currently required on all UI projects because we are running providers in parallel for evaluation.

**When to skip:**
- API-only or CLI projects.
- Once evaluation concludes, may be dropped from some or all projects.

**Setup complexity:** Low. Inline init stub + CDN script tag. Three env vars (`ANALYTICS_OPENPANEL_URL`, `ANALYTICS_OPENPANEL_CLIENT_ID`, `ANALYTICS_OPENPANEL_API_URL`). Create a project in the OpenPanel dashboard.

**Dependencies:** OpenPanel API instance running on Coolify.

---

#### Swetrix

**What it does:** Privacy-focused analytics with lightweight tracking. Script loads from CDN (`swetrix.org`); data is sent to a self-hosted API endpoint. Supports custom events, error tracking, and performance metrics.

**When to adopt:**
- Same criteria as Umami and OpenPanel -- any project with a public-facing UI.
- Currently required for evaluation purposes.

**When to skip:**
- API-only projects.
- Once evaluation concludes, may be dropped.

**Setup complexity:** Low. CDN script + init call. Three env vars (`ANALYTICS_SWETRIX_URL`, `ANALYTICS_SWETRIX_PROJECT_ID`, `ANALYTICS_SWETRIX_API_URL`). Critical gotcha: the API URL must end with `/log`.

**Dependencies:** Swetrix API instance running on Coolify.

---

#### Microsoft Clarity

**What it does:** Session recordings and heatmaps. Shows exactly how users interact with pages -- clicks, scrolls, rage clicks, dead clicks. Free (Microsoft-hosted, not self-hosted).

**When to adopt:**
- You are actively doing UX research or debugging a specific interaction problem.
- The project has enough traffic to generate useful recordings.

**When to skip:**
- Most of the time. This is a temporary diagnostic tool, not an always-on service.
- Projects with minimal UI (static sites, simple forms).
- Privacy-sensitive contexts where session recording is inappropriate.

**Setup complexity:** Low. One script tag. No self-hosted infrastructure needed.

**Dependencies:** None. Microsoft-hosted.

---

#### Rybbit

**What it does:** Privacy-focused analytics platform. Currently being evaluated as a potential replacement or complement to the existing provider stack.

**When to adopt:**
- Not yet. Under evaluation only.

**When to skip:**
- All projects, until evaluation concludes and a decision is made.

**Setup complexity:** TBD (evaluation in progress).

**Dependencies:** TBD.

---

### Observability

#### GlitchTip

**What it does:** Self-hosted, Sentry-compatible error tracking. Captures unhandled exceptions, stack traces, and breadcrumbs. Groups errors, tracks frequency, and sends alerts.

**When to adopt:**
- Every project. Error tracking is non-negotiable regardless of project type. Static sites, APIs, mobile apps, games -- all of them.

**When to skip:**
- Never skip this. The only reason to defer is if the project is a throwaway prototype.

**Setup complexity:** Low. Install the Sentry SDK for your framework, set one env var (`GLITCHTIP_DSN`), and call `sentry_sdk.init()` (or equivalent) at startup. Conditional on DSN being set.

**Dependencies:** GlitchTip instance running on Coolify. Create a project in the GlitchTip dashboard to get the DSN.

---

#### Uptime Kuma

**What it does:** Self-hosted uptime monitoring. Pings your services on a schedule and alerts you (email, webhook, etc.) when they go down. Tracks uptime percentage and response time history.

**When to adopt:**
- Any project deployed as a persistent service (web app, API, background worker).
- Anything where downtime matters and you want to know about it before users tell you.

**When to skip:**
- Static sites hosted on a CDN with its own monitoring.
- Local-only or development-only projects.

**Setup complexity:** Low. No code changes in the project itself. Add a monitor in the Uptime Kuma dashboard pointing at your health check endpoint or homepage URL.

**Dependencies:** Uptime Kuma instance running on Coolify. The monitored project should have a stable URL to ping (ideally a `/health` endpoint).

---

### Infrastructure

#### Coolify

**What it does:** Self-hosted PaaS (like Heroku/Vercel but on your own server). Handles deployments, environment variables, SSL certificates, and container orchestration.

**When to adopt:**
- Every project that needs hosting. This is the deployment platform for the entire portfolio.

**When to skip:**
- Projects deployed elsewhere by necessity (e.g., mobile apps go to app stores, npm packages go to npm).
- GitHub Pages or similar static hosting if Coolify would be overkill.

**Setup complexity:** Medium for initial server setup (one-time). Low per-project -- connect a repo, set env vars, deploy.

**Dependencies:** A server (VPS) with Coolify installed.

---

#### PostgreSQL

**What it does:** Primary relational database. Handles structured data, full-text search, JSON columns, and everything else you would expect from a production database.

**When to adopt:**
- The project needs to persist structured data (users, content, transactions, logs).
- The project needs relational queries, transactions, or full-text search.

**When to skip:**
- Static sites with no server-side data.
- Pure frontend apps where all state is local or comes from external APIs.
- Mobile apps that only need local storage (SQLite, MMKV).

**Setup complexity:** Low if using Coolify's managed PostgreSQL. Medium if running your own instance. Per-project: create a database, set `DATABASE_URL`, run migrations.

**Dependencies:** PostgreSQL server (managed by Coolify or standalone).

---

#### Redis

**What it does:** In-memory data store used for caching, session storage, rate limiting, and job queues. Sub-millisecond reads.

**When to adopt:**
- The project makes external API calls that should be cached.
- The project needs rate limiting, session storage, or background job queues.
- The project has performance-sensitive read paths.

**When to skip:**
- Static sites.
- Simple apps where in-memory caching (or no caching) is sufficient.
- Projects with low traffic where the complexity is not justified.

**Setup complexity:** Low. Coolify can run a Redis instance. Per-project: set `REDIS_URL`, add a cache/queue library. Code should degrade gracefully when Redis is unavailable.

**Dependencies:** Redis server (managed by Coolify or standalone).

---

#### SeeSee

**What it does:** Self-hosted email logging service. Records every transactional email sent (recipient, subject, timestamp, status) in a searchable dashboard. Not an email sender -- it logs what your sender sends.

**When to adopt:**
- The project sends transactional email (welcome emails, receipts, notifications, invitations, password resets).

**When to skip:**
- The project does not send email. Do not add this preemptively.

**Setup complexity:** Low. Two env vars (`SEESEE_URL`, `SEESEE_API_KEY`). Add a post-send hook in your email service to log to SeeSee. The [Email Infrastructure](./EMAIL_INFRASTRUCTURE.md) guide (Section 8) has implementation patterns.

**Dependencies:** SeeSee instance running on Coolify. The project must already have email sending capability.

---

## 2. Decision Matrix

Use these tables to track adoption status across your portfolio. Update as services are integrated.

**Legend:**
- **Yes** = Integrated and active
- **No** = Not integrated (and should not be, per the criteria above)
- **Planned** = Should be integrated but is not yet
- **Eval** = Under evaluation, not committed
- **Stub** = Partially wired but incomplete
- **N/A** = Not applicable to this project type

### Analytics Providers

| Project | Umami | OpenPanel | Swetrix | Clarity | Rybbit |
|---------|:-----:|:---------:|:-------:|:-------:|:------:|
| *(project-name)* | | | | | |

### Observability

| Project | GlitchTip | Uptime Kuma |
|---------|:---------:|:-----------:|
| *(project-name)* | | |

### Infrastructure

| Project | Coolify | PostgreSQL | Redis | SeeSee |
|---------|:------:|:----------:|:-----:|:------:|
| *(project-name)* | | | | |

### Summary: Who Needs What

| Project | Has UI | Has DB | Has Admin | Sends Email | Analytics | GlitchTip | SeeSee |
|---------|:------:|:------:|:---------:|:-----------:|:---------:|:---------:|:------:|
| *(project-name)* | | | | | | | |

---

## 3. New Project Checklist

When bootstrapping a new project, work through this list in order. Skip items that do not apply (use the criteria from Section 1).

### Phase 1: Foundation (do first)

- [ ] Deploy to Coolify. Connect the repo, configure build, verify deployment works.
- [ ] Set up PostgreSQL database (if the project stores data). Run initial migrations.
- [ ] Set up Redis (if the project needs caching, queues, or rate limiting).

### Phase 2: Observability (do early)

- [ ] Add GlitchTip. Install the Sentry SDK, set `GLITCHTIP_DSN`, init conditionally at startup.
- [ ] Add Uptime Kuma monitor. Point it at the project's health check endpoint or homepage.

### Phase 3: Analytics (do when UI exists)

- [ ] Create sites/projects in each analytics dashboard (Umami, OpenPanel, Swetrix).
- [ ] Add the analytics abstraction layer (see [Analytics Playbook Section 2](./ANALYTICS_PLAYBOOK.md#2-analytics-abstraction-layer)).
- [ ] Inject scripts on all public pages. Exclude admin routes.
- [ ] Implement minimum event tracking: `page_view`, `session_start`, `session_end`, `external_link_clicked`, `error_occurred`.
- [ ] Set `ANALYTICS_EXCLUDED_IPS` for your own IP.

### Phase 4: Admin and Email (do when applicable)

- [ ] Build admin dashboard with service launchpad (if admin panel exists).
- [ ] Add SeeSee email logging hook (if the project sends email).
- [ ] Wire launchpad links: analytics dashboards, GlitchTip, Coolify, Uptime Kuma, repo.

### Phase 5: Environment Hygiene

- [ ] Create `.env.example` with all shared infra env vars, grouped by category.
- [ ] Verify all integrations degrade gracefully when env vars are empty.
- [ ] Update this decision matrix (Section 2) with the new project's status.

---

## 4. Cost and Resource Considerations

All shared services are self-hosted on Coolify, which means they consume server resources (CPU, RAM, disk) rather than incurring per-unit SaaS fees. There are no per-event charges for analytics, no per-error charges for GlitchTip, and no per-email charges for SeeSee.

### Resource Impact by Service

| Service | RAM Usage | Disk Usage | CPU Impact | Notes |
|---------|-----------|------------|------------|-------|
| Umami | ~200-400 MB | Low (DB rows) | Low | PostgreSQL-backed. Disk grows with event volume. |
| OpenPanel | ~300-500 MB | Moderate | Low-moderate | Includes ClickHouse for analytics storage. |
| Swetrix | ~200-400 MB | Low-moderate | Low | Self-hosted API is lightweight. |
| GlitchTip | ~300-500 MB | Moderate | Low | PostgreSQL + Redis. Disk grows with error volume. Retention policies help. |
| Uptime Kuma | ~100-200 MB | Low | Very low | Minimal footprint. |
| Coolify | ~500 MB+ | Moderate | Moderate | The PaaS itself. Runs all other services. |
| PostgreSQL | ~200-500 MB | Grows with data | Variable | Shared across projects. Biggest cost driver is disk for large datasets. |
| Redis | ~50-200 MB | Low | Very low | In-memory. Size depends on what you cache. |
| SeeSee | ~100-200 MB | Low | Very low | Lightweight logging service. |

### Practical Constraints

- **Adding a new analytics provider to all 8 projects** adds negligible per-project cost (just a script tag) but requires the provider's backend to handle aggregated traffic from all projects.
- **GlitchTip** can accumulate significant disk usage if error volume is high. Set retention policies (e.g., delete errors older than 90 days).
- **Running three analytics providers simultaneously** (Umami + OpenPanel + Swetrix) is temporary for evaluation. Long-term, consolidating to 1-2 providers will reduce server load and maintenance burden.
- **PostgreSQL disk** is the most likely resource to run out first. Monitor it. Each project with a database adds to the total.
- **The server itself** (VPS) is the primary cost. All services share one or a small number of servers. Upgrading the VPS is the scaling lever, not per-service pricing.

### What Costs Money

| Cost | Type | Notes |
|------|------|-------|
| VPS hosting | Monthly | The server(s) running Coolify and all services |
| Domain names | Annual | One per project plus subdomains for services |
| DNS (Cloudflare or similar) | Free tier | Usually no cost |
| SSL certificates | Free | Let's Encrypt via Coolify |
| Microsoft Clarity | Free | Microsoft-hosted, no self-hosting cost |

---

## 5. Analytics Provider Evaluation Status

**Status as of March 2026:** We are running Umami, OpenPanel, and Swetrix in parallel across all UI projects to evaluate which to keep long-term. Rybbit is also being evaluated but is not yet deployed.

### What We Are Evaluating

| Criterion | Umami | OpenPanel | Swetrix | Rybbit |
|-----------|-------|-----------|---------|--------|
| Dashboard usability | Mature, clean | Feature-rich | Functional | TBD |
| Self-hosting reliability | Stable | Stable | Stable | TBD |
| Custom event support | Yes | Yes | Yes | TBD |
| Script size / performance | Small | Moderate | Small | TBD |
| API for data export | Yes | Yes | Yes | TBD |
| Active development | Yes | Yes | Yes | Yes |
| Resource consumption | Low | Moderate (ClickHouse) | Low | TBD |

### Current Plan

1. Continue running all three providers through mid-2026.
2. Compare data accuracy, dashboard utility, and resource usage.
3. Decide which 1-2 providers to keep.
4. Remove dropped providers from all projects (the abstraction layer makes this a config change, not a code change).
5. Evaluate Rybbit independently. If it clearly outperforms the current options, it may replace one or more.

### Rules During Evaluation

- **Do not build features that depend on a specific provider's API.** Do not pull data from Umami/OpenPanel/Swetrix into admin dashboards. Surface internal data (your own database) instead.
- **Do not invest significant time customizing any single provider's dashboard.** Basic setup only.
- **New projects** should still integrate all three providers (or defer analytics entirely if the project is not ready). Do not pick just one -- the whole point is parallel comparison.
- **The abstraction layer is mandatory.** This is what makes switching providers a config change instead of a rewrite.

---

*Created: 2026-03-24*
*Companion to: [Analytics Playbook](./ANALYTICS_PLAYBOOK.md)*
