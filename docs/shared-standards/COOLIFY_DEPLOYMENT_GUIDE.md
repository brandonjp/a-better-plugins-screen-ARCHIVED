<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Coolify Deployment Guide

> **Purpose:** A screen-by-screen reference for deploying a project to Coolify (self-hosted PaaS) without re-learning the gotchas every time. Covers the git-connection wizard, the per-build-pack config fields, watch paths, resource limits, and the PostgreSQL resource fields that are easy to misread.
>
> **How to use:** Read this when first deploying a project, or when an AI agent is asked for "deploy instructions." The [Shared Infra Decision Guide](./SHARED_INFRA_DECISION_GUIDE.md) covers *whether* to adopt Coolify/Postgres/Redis; this guide covers *how* to fill in the screens. After the first deploy, record this project's concrete answers in a `DEPLOYMENT.md` at the project root (template at the end) so they never have to be re-derived.
>
> **Scope:** The UI labels and defaults here reflect Coolify v4.x. Field names move between versions — if a label here doesn't match your screen, match by meaning, not by exact string.

---

## Table of Contents

1. [The deploy flow at a glance](#1-the-deploy-flow-at-a-glance)
2. [Choosing a build pack](#2-choosing-a-build-pack)
3. [Config screen — Nixpacks](#3-config-screen--nixpacks)
4. [Config screen — Docker Compose](#4-config-screen--docker-compose)
5. [The General settings screen (after creation)](#5-the-general-settings-screen-after-creation)
6. [Watch Paths](#6-watch-paths)
7. [Resource Limits](#7-resource-limits)
8. [PostgreSQL resource setup](#8-postgresql-resource-setup)
9. [For AI agents giving deploy guidance](#9-for-ai-agents-giving-deploy-guidance)
10. [Per-project `DEPLOYMENT.md` template](#10-per-project-deploymentmd-template)

---

## 1. The deploy flow at a glance

1. **+ New Resource** → pick a source. For a git repo this is *Public Repository*, *Private Repository (GitHub App)*, or a connected Git source.
2. **Configuration screen** — pick the **Branch** and **Build Pack**. The rest of the fields change depending on the build pack (see §3 / §4). Click **Continue**.
3. Coolify creates the resource and drops you on the **General** settings screen (§5), where you set domains, watch paths, build commands, etc.
4. Set **Environment Variables**, **Resource Limits** (§7), and (for databases) the resource-specific fields (§8).
5. **Deploy.**

The single most common mistake is on the Configuration screen (step 2): the **Docker Compose Location** path needs a **leading slash** (see §4).

---

## 2. Choosing a build pack

| Build Pack | Use when | What Coolify needs |
|---|---|---|
| **Nixpacks** | The app is a single service that Nixpacks can auto-detect (Node, Python, Go, Ruby, etc.) and you have no `docker-compose` / `Dockerfile`. Coolify infers the build. | A **Port** the app listens on. |
| **Docker Compose** | The project ships its own `docker-compose*.yml` describing one or more services (app + worker, app + db, etc.). You control the build. | The **path to the compose file** (with a leading slash). |
| **Dockerfile** | A single service with a hand-written `Dockerfile` and no compose orchestration. | The Dockerfile path / build context. |
| **Static** | Pure static output (no server process). | Toggle *"Is it a static site?"* and set the output/publish directory. |

Rule of thumb for these projects: **if the repo has a `docker-compose.prod.yml` (or similar), use Docker Compose.** Otherwise Nixpacks for a quick single-service deploy.

---

## 3. Config screen — Nixpacks

Fields on the Configuration screen when **Build Pack = Nixpacks**:

| Field | Value | Notes |
|---|---|---|
| **Branch** | `main` | The branch Coolify watches and deploys. |
| **Build Pack** | `Nixpacks` | — |
| **Base Directory** | `/` | The subfolder within the repo that is the app root. `/` = repo root. Only change this for a monorepo where the app lives in a subdirectory (e.g. `/apps/web`). |
| **Port** | the port your app **actually listens on** | This is the field people get wrong. It must match the port the process binds (e.g. Next.js `3000`, many Node servers `3000`, Vite preview `4173`, Django `8000`). If the app reads `PORT` from the environment, set that env var to the same number. A mismatch = endless "no available server" / 502s. |
| **Is it a static site?** | unchecked for a server app | Check it only if the build emits static files served with no running process. |

Then **Continue**.

---

## 4. Config screen — Docker Compose

Fields on the Configuration screen when **Build Pack = Docker Compose**:

| Field | Value | Notes |
|---|---|---|
| **Branch** | `main` | — |
| **Build Pack** | `Docker Compose` | — |
| **Base Directory** | `/` | Repo root, unless the compose file lives in a subfolder. |
| **Docker Compose Location** | **`/docker-compose.prod.yml`** | ⚠️ **Leading slash required.** The path is resolved relative to the repo root *as an absolute-style path*. Coolify's own default is `/docker-compose.yaml` — with the slash. Write `/docker-compose.prod.yml`, **not** `docker-compose.prod.yml`. |

### ⚠️ The leading-slash gotcha (read this)

The **Docker Compose Location** is `Base Directory` + the path you type. The field expects a path that **starts with `/`**. Coolify even renders a confirmation hint under the field — *"Compose file location in your repository: `/docker-compose.prod.yml`"* (shown in yellow). **Always glance at that hint** and confirm it points at the real file. If you typed `docker-compose.prod.yml` (no slash) the resolved path will be wrong and the deploy will fail to find the compose file.

> Past guidance has said things like *"set Compose file = `docker-compose.prod.yml`"* — that is missing the leading slash. The correct value is **`/docker-compose.prod.yml`**.

For a compose file in a subfolder, set **Base Directory** to that folder (e.g. `/deploy`) and **Docker Compose Location** to `/deploy/docker-compose.prod.yml` — the location is still written with the leading slash from repo root.

---

## 5. The General settings screen (after creation)

After **Continue**, Coolify shows the **General** tab. Key fields:

- **Name** — Coolify auto-generates something like `petty-sets:main-a3sm0w41…`. Safe to leave; it's just the in-Coolify label. The deployed container/service names derive from it.
- **Build Pack** — same selector as before; can be changed here.
- **Domains**
  - **Domains for app** (and **Domains for importer**, etc., for multi-service compose) — paste your domain or click **Generate Domain** for a `*.sslip.io`-style auto domain to test with. Each service in a compose deploy gets its own domain field.
- **Build**
  - **Base Directory** / **Docker Compose Location** — same values as §3/§4; this is where you fix them later. (Leading-slash rule still applies.)
  - **Preserve Repository During Deployment** — leave unchecked unless you specifically need the checked-out repo to persist in the container.
  - **Custom Build Command** / **Custom Start Command** — leave blank to use the defaults shown as placeholders (`docker compose build` / `docker compose up -d`). Only set these if you know you need to.
  - **Watch Paths** — see §6. **Always set this.**

The left sidebar also has **Environment Variables**, **Persistent Storage**, **Resource Limits** (§7), **Healthcheck**, **Webhooks**, and **Danger Zone**.

Click **Save** after edits, and **Reload Compose File** if you changed the compose file in the repo and want Coolify to re-read service definitions.

---

## 6. Watch Paths

**Watch Paths** control which file changes trigger an auto-redeploy on push. **Set them on every project.** Without them, a docs-only commit, a new test, or a seed-data tweak triggers a full rebuild and redeploy — wasteful and occasionally disruptive.

Coolify's own help text describes the field exactly:

> *"Order-based pattern matching to filter Git webhook deployments. Supports wildcards (`*`, `**`, `?`) and negation (`!`). Last matching pattern wins."*

Because **the last matching pattern wins**, the reliable idiom is **exclude everything first with `!**`, then re-include only the paths that should trigger a deploy**:

```
!**
src/**
app/**
public/**
package.json
package-lock.json
Dockerfile
docker-compose*.yml
docker-compose*.yaml
```

Starting with `!**` means the default is "don't deploy"; every line after it is an explicit allow. This is safer than listing excludes, because anything you forget simply *doesn't* trigger a deploy (fails closed) instead of accidentally triggering one.

Adjust the re-include globs to the stack (`app/**` + `config/**` for Rails, `*.py` + `pyproject.toml` for Python, `wp-content/themes/<slug>/**` for a WP theme, etc.).

**Things that should stay excluded** — i.e. *don't* add re-include lines that match these:

- `**/*.md`, `docs/**`, `README*` — documentation
- `tests/**`, `**/*.test.*`, `**/*.spec.*`, `__tests__/**` — tests
- `seeds/**`, `seed/**`, `db/seeds/**`, `*.seed.*` — seed data
- `samples/**`, `examples/**`, `*.sample`, `fixtures/**` — sample/fixture data
- `.github/**`, editor config, `.vscode/**`

> Because of the leading `!**`, these are excluded automatically unless you re-include them — that's the point of failing closed. Since the **last matching pattern wins**, put `!**` first and any narrow re-includes after it; if you ever need to carve an exception *out* of a re-include, add a more specific `!` line *below* it. After setting watch paths, push a docs-only commit once and confirm it does **not** redeploy, then push a real code change and confirm it **does**.

---

## 7. Resource Limits

Every long-running resource on a shared server should have limits. An unbounded service can consume all server RAM and take **everything else down with it** — this has happened (a Redis cache ballooned and crashed the whole server; it only needed a memory cap + an eviction policy). Set limits at creation, not after the incident.

Coolify's **Resource Limits** tab maps to Docker limits: **Memory Limit**, **Memory Reservation** (soft floor), **Memory Swap**, **CPU Limit** (e.g. `0.5` = half a core), **CPU Shares**. Leave a field blank to mean "no limit."

### Reasonable starting limits (small VPS / hobby-scale apps)

These are conservative starting points — tune up only if the service is genuinely starved (watch the **Metrics** tab). Always cap; an explicit cap that's a bit low is far safer than no cap.

| Service type | Memory Limit | Memory Reservation | CPU Limit | Notes |
|---|---|---|---|---|
| **Web app** (Next/Node/Django/Rails, small) | `512M`–`1G` | `256M` | `0.5`–`1.0` | Start at `512M`; bump if you see OOM restarts. |
| **Background worker / queue consumer** | `256M`–`512M` | `128M` | `0.25`–`0.5` | Usually lighter than the web tier. |
| **PostgreSQL** (small) | `512M`–`1G` | `256M` | `0.5`–`1.0` | DB benefits from RAM for cache; don't starve it. Disk is the thing to watch long-term. |
| **Redis** (cache) | `256M` | — | `0.25` | **Also set `maxmemory` + an eviction policy — see below. This is mandatory, not optional.** |
| **Static site / proxy** | `128M`–`256M` | — | `0.25` | Minimal. |

### Redis — the one that bit us (set BOTH)

A Docker memory limit alone is **not enough** for Redis. If Redis hits the Docker limit with no eviction policy, the kernel **OOM-kills the container** (a hard crash) instead of Redis gracefully evicting keys. You need both:

1. **An eviction policy + `maxmemory` inside Redis**, set a bit *below* the Docker limit, so Redis evicts gracefully before the hard cap. For a cache:
   ```
   --maxmemory 200mb --maxmemory-policy allkeys-lru
   ```
   (Set this as the Redis start command / args, or in a mounted `redis.conf`. `allkeys-lru` evicts least-recently-used keys; use `volatile-lru` if you set TTLs and want to protect un-expiring keys.)
2. **A Docker Memory Limit** (e.g. `256M`) in Resource Limits as a hard backstop above `maxmemory`.

> If Redis is being used as a durable store (not just a cache), do **not** use an `allkeys-*` eviction policy — you'd lose data. Use `noeviction` and size the limit generously, or move that data to Postgres. Caches evict; stores don't.

---

## 8. PostgreSQL resource setup

Create with **+ New Resource → Databases → PostgreSQL**. The **General** tab has four fields people conflate. Here is exactly what each one is:

| Field | What it is | Example | Rules |
|---|---|---|---|
| **Name** | The **Coolify resource label** only. Cosmetic + used to derive the internal hostname. Not a database credential. | `petty-sets-db` | Free-form; pick something readable. |
| **Description** | Free text. Coolify pre-fills a slug like `postgresql-database-to5amwi…`. | leave or edit | Cosmetic. |
| **Image** | The Postgres image/tag. | `postgres:18-alpine` | Pin a major version. |
| **Username** | `POSTGRES_USER` — the **role** the DB is created with. | `postgres` (default) or `petty_sets` | See identifier rules below. |
| **Password** | `POSTGRES_PASSWORD` for that role. | (generated) | — |
| **Initial Database** | `POSTGRES_DB` — the **database** created on first boot. | `petty_sets` | **Letters, numbers, and underscores only.** Don't start with a number; no dashes. (`petty-sets` is invalid → use `petty_sets`.) |

### What "Name / Username / Initial Database" actually do — and the sync trap

The Postgres image only reads `POSTGRES_USER` / `POSTGRES_DB` / `POSTGRES_PASSWORD` **once: on first boot, when the data volume is empty.** That first boot runs the init that creates the role and the database.

This has two consequences agents routinely get wrong:

1. **Setting these on the Coolify screen *before the first deploy* genuinely provisions them.** A fresh resource with `Username = petty_sets`, `Initial Database = petty_sets` will boot with that role and database. Good.
2. **Changing any of these in the Coolify UI *after* the DB has already initialized does NOT change the running database.** The init already ran; the volume isn't empty anymore. Coolify even warns: *"If you change the values in the database, please sync it here, otherwise automations (like backups) won't work."* That warning means the Coolify fields and the live DB are **two separate copies** that can drift:
   - The **live database** is the source of truth for what the role/db/password actually are.
   - The **Coolify fields** are what Coolify *uses* for connection strings, backups, and the internal `Postgres URL`.

   To actually rename a user / database / change a password on an already-initialized DB, you change it **inside the database** (e.g. `ALTER ROLE … RENAME TO …`, `ALTER USER … WITH PASSWORD …`, `CREATE DATABASE …`) **and then update the matching Coolify field to the same value** ("sync it here") so backups and the generated connection URL keep working. Changing only the Coolify field lies about the DB; changing only the DB breaks Coolify's automations.

**Practical rule:** decide the username and database name **up front, before the first deploy**, set them on the create screen, and don't rename later unless you're prepared to do it in SQL + sync both sides. If you just need a fresh name and have no data yet, it's cleaner to delete the resource (which clears the volume) and recreate.

### Other DB fields worth knowing

- **Postgres URL (internal)** — the connection string for *other Coolify services on the same network*. Use this for your app's `DATABASE_URL`; it resolves over Coolify's internal network and doesn't expose the DB publicly.
- **Ports Mappings** / **Make it publicly available** / **Public Port** — leave the DB **not** publicly available unless you truly need external access. If you do expose it, set a strong password and a non-default public port.
- **Initial Database Arguments** / **Host Auth Method** — leave blank for defaults unless you have a specific reason.
- **SSL Configuration → Enable SSL** — off is fine for internal-only DBs; consider on if exposed.

---

## 9. For AI agents giving deploy guidance

When asked for Coolify deploy instructions for a project, **do not give generic steps** — read the repo and give concrete values, and:

- **State the build pack** based on what's actually in the repo (compose file present → Docker Compose; else Nixpacks/Dockerfile).
- **For Docker Compose, always write the compose path with a leading slash** (`/docker-compose.prod.yml`) and tell the user to verify Coolify's yellow "location in your repository" hint.
- **For Nixpacks, state the exact Port** the app listens on (grep the code/config), and note the matching `PORT` env var if used.
- **Always propose Watch Paths** (the `!**`-first allow-list per §6) tailored to the stack.
- **Always propose Resource Limits** for every long-running service (§7), and for Redis include `maxmemory` + an eviction policy — never a Docker limit alone.
- **For PostgreSQL, specify which field is which** (Name vs Username vs Initial Database), use an underscore-safe initial database name, and warn about the post-init sync trap (§8).
- **Write the chosen values into the project's `DEPLOYMENT.md`** (§10) so they're recorded once, not re-derived every session.

---

## 10. Per-project `DEPLOYMENT.md` template

After the first successful deploy, create a `DEPLOYMENT.md` at the **project root** capturing the concrete answers for *this* app. Copy the block below and fill it in. This is the record that ends the "relearn it every time" loop.

```markdown
# Deployment — <project name>

> How this project deploys to Coolify. Concrete values for THIS app.
> General rules live in docs/shared-standards/COOLIFY_DEPLOYMENT_GUIDE.md.

## Coolify resource
- **Server / project:** <coolify server + project name>
- **Resource name:** <e.g. petty-sets:main-…>
- **Build pack:** <Nixpacks | Docker Compose | Dockerfile | Static>
- **Branch:** main
- **Base Directory:** /
- **Docker Compose Location:** /docker-compose.prod.yml   # if compose; LEADING SLASH
- **Port:** <port the app listens on>                      # if Nixpacks/Dockerfile
- **Domain(s):** <app domain(s)>

## Watch Paths
```
!**
<the re-include globs you set>
```

## Resource Limits (per service)
- **app:** mem <512M>, cpu <0.5>
- **worker:** mem <256M>, cpu <0.25>     # if any
- **redis:** docker mem <256M>; redis args: --maxmemory 200mb --maxmemory-policy allkeys-lru   # if any
- **postgres:** mem <512M>, cpu <0.5>    # if any

## PostgreSQL (if any)
- **Coolify resource Name:** <e.g. petty-sets-db>
- **Username (POSTGRES_USER):** <e.g. petty_sets>
- **Initial Database (POSTGRES_DB):** <e.g. petty_sets>   # letters/numbers/underscores only
- **Image:** <e.g. postgres:18-alpine>
- **App connects via:** DATABASE_URL = <internal Postgres URL>
- **Publicly exposed:** no

## Env vars the app needs
- <KEY> — <what it's for>

## First-deploy / gotcha notes
- <anything that tripped us up for this specific app>
```
```
