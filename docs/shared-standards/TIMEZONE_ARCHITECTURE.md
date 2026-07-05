<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Timezone Architecture Audit & Implementation

> **Purpose:** A cross-project directive for implementing consistent timezone handling. Covers storage (always UTC), admin display timezone, user-facing display options, and scope boundaries between admin and user contexts. Language- and framework-agnostic — applies to Python, JS/TS, PHP, WordPress, or any stack with a database.
>
> **Companion docs:**
> - [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) — Admin dashboard patterns (Section 5)
> - [Project Health Checklist](./PROJECT_HEALTH_CHECKLIST.md) — Architectural health and security

You are auditing and implementing timezone handling for this project. This applies regardless of language, framework, or database.

## Step 1: Assess the Project

Before making ANY changes, research and report:

1. **Stack identification**: What language, framework, database (if any), and frontend tooling does this project use?
2. **Current timezone handling**: Search the entire codebase for:
   - Any existing timezone configuration (env vars, config files, settings)
   - All date/time formatting in templates, views, API responses, and frontend components
   - All date/time storage (database writes, inserts, migrations)
   - Any existing user timezone preferences (DB columns, localStorage, cookies)
   - Framework-specific timezone settings (e.g., Laravel `config/app.php` `timezone`, Django `TIME_ZONE`, etc.)
3. **User-facing vs admin-facing**: Identify which views/routes are admin-only vs user-facing
4. **Framework conflicts**: Check if the framework has a built-in timezone config key that we must NOT override or repurpose (e.g., Laravel's `APP_TIMEZONE` controls internal Carbon/DB behavior — we must not change it from UTC)

**Present your findings before proceeding. Do not start implementation until the audit is complete.**

## Step 2: Environment Variable — Display Timezone

### Naming Rules

The env var for admin/app display timezone must:
- **NOT** conflict with any framework, OS, or language-level timezone variable
- **NOT** be `TZ` (POSIX system timezone), `APP_TIMEZONE` (Laravel/framework internal), `TIMEZONE` (too generic), or `SERVER_TIMEZONE`
- **MUST** clearly communicate it controls *display formatting only*, not storage
- **Recommended name: `APP_DISPLAY_TIMEZONE`**
- Default value: `UTC`
- Format: IANA timezone string (e.g., `America/Chicago`, `America/New_York`, `Europe/London`)

### What this variable controls
- How dates/times are DISPLAYED in admin/super-admin interfaces
- How admin date-range filters interpret input dates
- How admin reports aggregate data by day/week/month boundaries
- Business-context calculations like "today's signups" in admin dashboards

### What this variable must NEVER control
- Database storage (always UTC)
- API response timestamps (always UTC / ISO 8601)
- User-facing date display (that uses the user's own timezone — see Step 4)
- Framework internal timezone (that stays UTC)

### Implementation pattern

Create a thin helper/utility scoped to the project's language:

**The helper should provide:**
- Get the display timezone from env (with UTC fallback)
- Format a UTC datetime for display in the admin timezone
- Convert a date-only input (from admin filter) to UTC start/end of day in admin timezone
- Get "now", "today start", "month start", etc. in the admin timezone

**The helper must NOT:**
- Mutate global timezone state
- Change the framework's default timezone
- Be used in user-facing contexts

## Step 3: Database & Storage — Always UTC

Verify and enforce:
- [ ] Framework/app timezone config is set to `UTC`
- [ ] All database `timestamp`/`datetime` columns store UTC
- [ ] All ORM/query builder date operations assume UTC
- [ ] Any raw SQL date functions use UTC
- [ ] All API responses return ISO 8601 UTC timestamps
- [ ] Any cron jobs or scheduled tasks operate in UTC internally
- [ ] Logs use UTC timestamps

If any of these are violated, fix them (with migration if needed) or flag as a breaking change requiring discussion.

## Step 4: User-Facing Timezone — Assess & Implement

Evaluate the project and choose the best approach. Consider these options in order of preference based on fit:

### Option A: Client-Side Only (recommended default)
**Best for:** Projects with a JS frontend, public-facing pages, anonymous users, projects without user accounts, projects where simplicity wins.

Pattern:
- Server sends UTC timestamps in `<time datetime="...">` elements (HTML) or ISO 8601 strings (JSON APIs)
- A small JS utility reads the browser's `Intl.DateTimeFormat().resolvedOptions().timeZone` and formats dates locally
- No database column needed, no user setting needed
- Works for logged-in AND anonymous users
- Automatically adjusts if user travels

Implementation:
- Create a reusable component/utility for the project's frontend framework
- For server-rendered HTML: use `<time datetime="{{ utc_iso_string }}">{{ utc_fallback_display }}</time>` with JS enhancement
- For SPAs/API-driven: format on the client from ISO 8601 response data
- Provide a readable fallback if JS is disabled (UTC with timezone label)

### Option B: User Profile Setting + Client-Side Detection
**Best for:** Projects with user accounts where timezone-sensitive features matter (scheduling, notifications, reports, billing cycles).

Pattern:
- Add a `timezone` column (nullable string/varchar 50) to the users table
- On first login or registration, detect via `Intl.DateTimeFormat().resolvedOptions().timeZone` and store it
- Let users override in their profile/account settings
- Server uses this for: email timestamps, scheduled notifications, PDF reports, any pre-rendered content
- Client still uses browser timezone for live UI (covers the "user is traveling" case)
- Fallback chain: user profile setting → browser detection → UTC

### Option C: Client-Side with localStorage Preference
**Best for:** Projects without a traditional database backend, heavy localStorage usage, or static sites with JS interactivity.

Pattern:
- Detect timezone from browser
- Store preference in localStorage
- All date formatting happens client-side
- No server component needed

### Decision criteria (use this to choose):
| Factor | Option A | Option B | Option C |
|--------|----------|----------|----------|
| Has user accounts | Optional | Yes | Optional |
| Has database | Optional | Yes | No/Optional |
| Sends emails with dates | No | Yes | No |
| Generates PDF/reports | No | Yes | No |
| Server-rendered HTML | Partial | Yes | No |
| SPA / client-rendered | Yes | Yes | Yes |
| Anonymous users matter | Yes | Partial | Yes |
| Simplicity priority | Highest | Lowest | High |

**State which option you're choosing and why before implementing.**

## Step 5: Scope Boundaries — Admin vs User

This is critical. Ensure clean separation:

### Admin/Super-Admin views:
- Use the `APP_DISPLAY_TIMEZONE` env var exclusively
- All admin date formatting goes through the timezone helper from Step 2
- Admin date filters convert to UTC using the admin timezone
- Admin reports aggregate using the admin timezone boundaries

### User-facing views:
- NEVER reference `APP_DISPLAY_TIMEZONE`
- Use the approach chosen in Step 4 (client-side, user profile, or localStorage)
- If a shared service/function is used by BOTH admin and user contexts, it must accept a timezone parameter (or the caller must handle timezone conversion)

### Shared code (services, models, utilities called by both):
- Date aggregation functions (e.g., "this month's total") should either:
  - Accept an explicit timezone parameter, OR
  - Use UTC boundaries by default and let the caller adjust, OR
  - Accept that using the business timezone (`APP_DISPLAY_TIMEZONE`) for boundary calculations is acceptable when the difference is negligible (only affects data near midnight at the UTC offset boundary)
- Document which approach was chosen and why

### API responses:
- Always return UTC ISO 8601
- Let the consuming client handle timezone display
- Never embed a formatted local time in an API response

## Step 6: Implementation Checklist

After completing all changes:

- [ ] `APP_DISPLAY_TIMEZONE` env var is defined and documented (with default of UTC)
- [ ] `.env.example` includes `APP_DISPLAY_TIMEZONE=UTC` with a comment
- [ ] Admin views use the timezone helper for all date/time display
- [ ] User-facing views use the client-side (or chosen) approach
- [ ] No admin timezone logic leaks into user-facing code paths
- [ ] All database writes store UTC
- [ ] API responses use UTC ISO 8601
- [ ] Framework internal timezone remains UTC
- [ ] Fallback behavior is graceful (invalid timezone → UTC, no JS → readable UTC display)
- [ ] Existing tests still pass
- [ ] New tests cover: timezone helper functions, user-facing display component, edge cases at DST transitions

## Step 7: Documentation

Add a brief section to the project's README, CLAUDE.md, or equivalent developer doc:

```
## Timezone Handling
- **Storage:** All dates stored in UTC. Framework timezone is UTC. Do not change this.
- **Admin display:** Controlled by `APP_DISPLAY_TIMEZONE` env var (default: UTC). Used only in admin views via [helper name].
- **User display:** [Chosen approach] — dates are displayed in the user's local timezone via [mechanism].
- **API responses:** Always UTC ISO 8601.
```

## Important Notes

- Do NOT change the framework's internal timezone from UTC — this breaks date comparisons, caching, scheduling, and storage
- Do NOT use PHP's `date_default_timezone_set()`, Python's `os.environ['TZ']`, or any global timezone mutation
- Do NOT assume all users are in the same timezone as the admin
- DO handle DST transitions gracefully (use timezone-aware libraries, never manual UTC offset math)
- DO test with timezones that have non-hour offsets (e.g., `Asia/Kolkata` is UTC+5:30, `Pacific/Chatham` is UTC+12:45) to verify your implementation handles edge cases
- For emails: include a clear timezone label if you can't determine the recipient's timezone (e.g., "January 15, 2026 at 3:00 PM CST")

Work autonomously. Only ask if you encounter a genuine architectural decision that could go either way with significant tradeoffs.
