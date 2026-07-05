# WordPress Plugin Development Guide

> **Purpose:** WordPress-specific standards and patterns that supplement the universal [shared-standards docs](./). Those docs cover *what* to do (analytics patterns, health checks, infrastructure decisions, spam protection). This guide covers *how* to apply them within the WordPress plugin ecosystem.
>
> **Companion docs (universal, apply to all projects):**
> - [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) — Analytics provider integration and event tracking
> - [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) — Admin dashboards, user management, launchpad
> - [Project Health Checklist](./PROJECT_HEALTH_CHECKLIST.md) — Architectural health and security
> - [Shared Infrastructure Decision Guide](./SHARED_INFRA_DECISION_GUIDE.md) — When/whether to adopt each service
> - [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md) — Multi-layer form protection

---

## Table of Contents

1. [Monorepo Structure](#1-monorepo-structure)
2. [Two Contexts: Plugin vs. Marketing Site](#2-two-contexts-plugin-vs-marketing-site)
3. [WordPress Coding Standards Checklist](#3-wordpress-coding-standards-checklist)
4. [Plugin Telemetry](#4-plugin-telemetry)
5. [Data Storage Decisions](#5-data-storage-decisions)
6. [Uninstall Cleanup](#6-uninstall-cleanup)
7. [New Plugin Bootstrap Checklist](#7-new-plugin-bootstrap-checklist)

---

## 1. Monorepo Structure

Each WordPress plugin project is a monorepo containing the free plugin, pro plugin, and companion site(s):

```
plugin-name/
├── free/                        # Free plugin (wordpress.org compliant)
│   ├── plugin-name.php          # Main plugin file
│   ├── includes/
│   ├── assets/
│   ├── languages/
│   ├── readme.txt               # wp.org readme
│   ├── uninstall.php
│   └── ...
├── pro/                         # Pro plugin (extends free)
│   ├── plugin-name-pro.php
│   ├── includes/
│   └── ...
├── site/                        # Marketing/docs site (may be combined)
│   └── ...
├── docs/
│   └── shared-standards/        # Universal standards (same across all projects)
├── scripts/                     # Build, release, deployment scripts
├── CLAUDE.md
├── CHANGELOG.md
├── README.md
├── composer.json
├── phpcs.xml
├── .gitignore
└── LICENSE
```

**Key principles:**
- Free and pro share common code (pro extends/overrides free, does not fork it)
- The marketing/docs site is a deployable project — the full [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) applies to it
- Shared standards docs are identical across all projects — never modify them per-project

---

## 2. Two Contexts: Plugin vs. Marketing Site

WordPress plugin projects have a split when it comes to applying the shared standards:

| Concern | Marketing/Docs Site (you control) | Plugin (runs on user's WordPress) |
|---------|-----------------------------------|-----------------------------------|
| **Analytics** | Full stack: Umami, OpenPanel, Swetrix per [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) | Opt-in telemetry only (see [Section 4](#4-plugin-telemetry)) |
| **Error tracking** | GlitchTip via Sentry SDK per [Infra Guide](./SHARED_INFRA_DECISION_GUIDE.md) | Opt-in error reporting, consent-gated |
| **Spam protection** | Full [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md) on contact/signup forms | Only if plugin has user-facing forms |
| **Admin dashboard** | Service launchpad per [Super Admin Tooling](./SUPER_ADMIN_TOOLING.md) Section 5 & 11 | Plugin settings page (not a service dashboard) |
| **Infrastructure** | Coolify, PostgreSQL, Redis per [Infra Guide](./SHARED_INFRA_DECISION_GUIDE.md) | Uses the site owner's WordPress DB and hosting |

**Never** inject analytics tracking scripts (Umami, OpenPanel, etc.) into the user's WordPress site from your plugin. That's their site, their analytics. Your plugin only sends telemetry about your plugin's own feature usage, with explicit consent.

---

## 3. WordPress Coding Standards Checklist

These are WordPress-specific implementation details for the concerns covered in the universal [Project Health Checklist](./PROJECT_HEALTH_CHECKLIST.md). Use both — the universal checklist covers *what* to think about (session security, audit logging, access control, data lifecycle); this section covers *how WordPress implements it*.

### Input Validation & Output Escaping

- [ ] All user input sanitized on receipt: `sanitize_text_field()`, `sanitize_email()`, `absint()`, `wp_kses()`, `wp_kses_post()`. Never trust `$_GET`/`$_POST`/`$_REQUEST` directly.
- [ ] All output escaped at render: `esc_html()`, `esc_attr()`, `esc_url()`, `esc_js()`. Escape late — at the `echo` statement.
- [ ] All DB queries use `$wpdb->prepare()`. Never concatenate user input into SQL.

### Auth & CSRF Protection

- [ ] Nonces protect all form submissions: `wp_nonce_field()` / `wp_verify_nonce()`.
- [ ] AJAX handlers verify both nonce and capability: `check_ajax_referer()` + `current_user_can()`.
- [ ] REST API endpoints have `permission_callback` (never `__return_true` in production).
- [ ] Admin pages registered with appropriate capability (not just `read`).
- [ ] Capability checks use specific capabilities, not role name checks.

### File Security

- [ ] Every PHP file starts with: `if ( ! defined( 'ABSPATH' ) ) { exit; }`
- [ ] No hardcoded secrets in code — keys/tokens in `wp_options` or `wp-config.php` constants.

### Coding Standards

- [ ] PHPCS configured (`phpcs.xml`) with WordPress rulesets (WordPress, WordPress-Core, WordPress-Extra).
- [ ] Plugin header complete: Name, URI, Description, Version, Author, License, Text Domain, Domain Path.
- [ ] Version numbers consistent across: plugin header, `readme.txt`, CHANGELOG, version constant.
- [ ] Text domain matches plugin slug. Loaded via `load_plugin_textdomain()` on `init`.
- [ ] No deprecated WordPress functions.

### Internationalization (i18n)

- [ ] All user-facing strings wrapped in `__()`, `_e()`, `esc_html__()`, `_n()`, `_x()`.
- [ ] No string concatenation inside translation functions — use `sprintf()` with placeholders.
- [ ] `.pot` file exists (or build command to generate one).

### Background Jobs (WP-Cron)

- [ ] Cron events registered on activation, cleared on deactivation.
- [ ] Cron callbacks verify they should still run (plugin active, feature enabled).
- [ ] Intervals are reasonable (hourly minimum for wp.org plugins).
- [ ] Long-running tasks have safeguards (batching, time/memory limits).

### Admin Notices

- [ ] Notices are dismissible with persisted dismissal state.
- [ ] Notices scoped to relevant admin screens only.
- [ ] Critical-only approach — no marketing/upsell/review nags on activation.

### Performance

- [ ] Assets (CSS/JS) loaded only on screens where needed (`admin_enqueue_scripts` with hook suffix).
- [ ] No queries inside loops (N+1 problem).
- [ ] External HTTP requests cached via transients.
- [ ] No blocking external requests on front-end page loads.

### Compatibility

- [ ] Minimum WP version declared and enforced.
- [ ] Minimum PHP version declared and enforced.
- [ ] No function/class name conflicts — use namespaces or consistent prefix.
- [ ] Multisite compatibility considered.

---

## 4. Plugin Telemetry

### Free vs. Pro: Consent Model

| | Free Plugin (wp.org) | Pro Plugin |
|---|---|---|
| **Default state** | Off (opt-in) | On (opt-out) |
| **Consent mechanism** | Admin notice on activation + settings toggle | Settings toggle |
| **Why** | wp.org policy requires explicit opt-in | User has an existing purchase relationship |
| **When disabled** | Zero tracking code runs, zero HTTP requests | Same — completely silent |

The pro plugin settings page should include a simple toggle to disable telemetry. No elaborate attention drawn to it — just a clear control alongside other settings.

### What to Track (with consent)

| Data Point | Why |
|-----------|-----|
| Plugin version | Know which versions are in the wild |
| WordPress version | Compatibility planning |
| PHP version | Minimum version decisions |
| Active theme (name only) | Compatibility testing priorities |
| Multisite yes/no | Feature planning |
| Plugin settings (which features enabled/disabled) | Know which features matter |
| Feature usage counts | Prioritize development |
| Locale/language | i18n priorities |

### Never Track

- Post content, page titles, or any user content
- Emails, names, or any personal data
- Domain name or site URL
- Raw IP addresses
- Full list of installed plugins
- Database contents
- Authentication tokens or credentials

### Implementation Architecture

```
Plugin Code → Telemetry Service → WP-Cron Batch → Phone-Home API → Analytics DB
                    │
              [Consent Check]
              If not consented → NoOp (do nothing)
```

### Telemetry Service Pattern

```php
interface Telemetry_Provider {
    public function is_enabled(): bool;
    public function track( string $event, array $data = [] ): void;
    public function send_batch(): void;
}

class Remote_Telemetry_Provider implements Telemetry_Provider {
    public function is_enabled(): bool {
        return (bool) get_option( 'myplugin_telemetry_enabled', false );
    }

    public function track( string $event, array $data = [] ): void {
        if ( ! $this->is_enabled() ) { return; }
        $buffer = get_transient( 'myplugin_telemetry_buffer' ) ?: [];
        $buffer[] = [
            'event'     => $event,
            'data'      => $data,
            'timestamp' => time(),
        ];
        set_transient( 'myplugin_telemetry_buffer', $buffer, DAY_IN_SECONDS );
    }

    public function send_batch(): void {
        if ( ! $this->is_enabled() ) { return; }
        $buffer = get_transient( 'myplugin_telemetry_buffer' );
        if ( empty( $buffer ) ) { return; }

        wp_remote_post( MYPLUGIN_TELEMETRY_ENDPOINT, [
            'body'     => wp_json_encode( [
                'plugin'    => 'myplugin',
                'version'   => MYPLUGIN_VERSION,
                'wp'        => get_bloginfo( 'version' ),
                'php'       => PHP_VERSION,
                'locale'    => get_locale(),
                'multisite' => is_multisite(),
                'events'    => $buffer,
            ] ),
            'headers'  => [ 'Content-Type' => 'application/json' ],
            'timeout'  => 5,
            'blocking' => false,
        ] );
        delete_transient( 'myplugin_telemetry_buffer' );
    }
}

class NoOp_Telemetry_Provider implements Telemetry_Provider {
    public function is_enabled(): bool { return false; }
    public function track( string $event, array $data = [] ): void {}
    public function send_batch(): void {}
}
```

### Standard Telemetry Events

| Event | When | Data |
|-------|------|------|
| `plugin_activated` | First activation | `wp_version`, `php_version`, `locale`, `multisite` |
| `plugin_updated` | Version change detected | `previous_version`, `new_version` |
| `plugin_deactivated` | Deactivation hook | `days_active`, `features_used` |
| `settings_changed` | Settings saved | `changed_keys` (names only, not values) |
| `feature_used` | Key feature invoked | `feature_name`, `count_this_period` |
| `environment_snapshot` | Weekly via WP-Cron | `wp_version`, `php_version`, `theme`, `locale` |

### Opt-In Error Reporting (consent-gated)

```php
function myplugin_report_error( $exception ) {
    if ( ! get_option( 'myplugin_telemetry_enabled', false ) ) { return; }

    wp_remote_post( MYPLUGIN_ERROR_ENDPOINT, [
        'body'     => wp_json_encode( [
            'error'   => $exception->getMessage(),
            'file'    => basename( $exception->getFile() ),  // filename only, no paths
            'line'    => $exception->getLine(),
            'plugin'  => MYPLUGIN_VERSION,
            'wp'      => get_bloginfo( 'version' ),
            'php'     => PHP_VERSION,
        ] ),
        'headers'  => [ 'Content-Type' => 'application/json' ],
        'timeout'  => 5,
        'blocking' => false,
    ] );
}
```

### Environment-Aware Behavior

Auto-disable telemetry in local/development environments:

```php
if ( function_exists( 'wp_get_environment_type' ) ) {
    $env = wp_get_environment_type();
    if ( in_array( $env, [ 'local', 'development' ], true ) ) {
        // Use NoOp provider regardless of user setting
    }
}
```

---

## 5. Data Storage Decisions

| Data Type | Storage | Example |
|-----------|---------|---------|
| Plugin settings | `wp_options` via Settings API | Toggles, API keys, preferences |
| Per-post metadata | `wp_postmeta` | Custom fields on posts/pages |
| Content-like data | Custom Post Type | Portfolio items, entries, templates |
| Structured relational data | Custom tables | Click logs, events, transactions |
| Cached data | Transients API | API response caches |
| User preferences | `wp_usermeta` | Per-user display settings, dismissed notices |

### When to Use Custom Tables

Use `$wpdb` custom tables when:
- Data has its own schema distinct from posts (e.g., click logs, analytics events)
- You need efficient queries that `wp_postmeta`'s EAV structure can't handle
- Data volume is large (thousands+ rows)

Use versioned schema with `dbDelta()`:
```php
function myplugin_create_tables() {
    global $wpdb;
    $table = $wpdb->prefix . 'myplugin_logs';
    $charset_collate = $wpdb->get_charset_collate();

    $sql = "CREATE TABLE $table (
        id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        event varchar(100) NOT NULL,
        data longtext,
        created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        KEY event (event),
        KEY created_at (created_at)
    ) $charset_collate;";

    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    dbDelta( $sql );

    update_option( 'myplugin_db_version', '1.0' );
}
```

### Option Naming Convention

All options use a consistent `{plugin_slug}_` prefix:
```php
get_option( 'myplugin_settings' );
get_option( 'myplugin_db_version' );
get_option( 'myplugin_telemetry_enabled' );
get_transient( 'myplugin_cache_key' );
```

---

## 6. Uninstall Cleanup

Every plugin MUST have a comprehensive `uninstall.php`:

```php
<?php
// Exit if not called by WordPress uninstall process.
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
    exit;
}

// Options.
delete_option( 'myplugin_settings' );
delete_option( 'myplugin_db_version' );
delete_option( 'myplugin_telemetry_enabled' );
delete_option( 'myplugin_dismissed_notices' );

// Transients.
delete_transient( 'myplugin_cache' );
delete_transient( 'myplugin_telemetry_buffer' );

// Custom tables.
global $wpdb;
$wpdb->query( "DROP TABLE IF EXISTS {$wpdb->prefix}myplugin_logs" );

// Cron events.
wp_clear_scheduled_hook( 'myplugin_telemetry_cron' );
wp_clear_scheduled_hook( 'myplugin_cleanup_cron' );

// User meta.
delete_metadata( 'user', 0, 'myplugin_dismissed_notice', '', true );
```

**Deactivation vs. uninstall:**
- **Deactivation hook:** Clear crons and transients. Do NOT delete user data or settings.
- **Uninstall:** Remove everything. The user has explicitly chosen to delete the plugin.

**Multisite:** If the plugin supports multisite, `uninstall.php` should iterate per-site to clean up site-specific data.

---

## 7. New Plugin Bootstrap Checklist

### Phase 1: Foundation
- [ ] Monorepo structure: `free/`, `pro/`, `site/`, `docs/`, `scripts/`
- [ ] `CLAUDE.md` with project context, version, run commands
- [ ] `.gitignore`, `composer.json`, `phpcs.xml`, `LICENSE`
- [ ] `README.md`, `CHANGELOG.md`
- [ ] Shared standards docs in `docs/shared-standards/` (copy from canonical source)
- [ ] `uninstall.php` (even if minimal initially)

### Phase 2: Core Plugin (Free)
- [ ] Complete plugin header (Name, URI, Description, Version, Author, License, Text Domain, Domain Path)
- [ ] Text domain loaded via `load_plugin_textdomain()`
- [ ] Activation/deactivation hooks
- [ ] Version constant + version tracking in `wp_options`
- [ ] Settings page (if applicable)
- [ ] `readme.txt` for wp.org

### Phase 3: Pro Plugin
- [ ] Pro extends free (does not duplicate/fork)
- [ ] License key validation
- [ ] Pro-only features gated behind license check
- [ ] Telemetry defaults to on (opt-out) with settings toggle

### Phase 4: Quality
- [ ] PHPCS + WPCS linting passes
- [ ] Unit tests (PHPUnit + WP test suite)
- [ ] CI pipeline (GitHub Actions)
- [ ] i18n: all strings wrapped, `.pot` file generated

### Phase 5: Telemetry & Observability
- [ ] Opt-in consent UI (free) / opt-out toggle (pro)
- [ ] Telemetry service with NoOp provider
- [ ] WP-Cron batching (`blocking => false`)
- [ ] Phone-home API endpoint on your infrastructure
- [ ] Opt-in error reporting (consent-gated)
- [ ] Auto-disable in local/development environments

### Phase 6: Marketing/Docs Site
- [ ] Deploy to Coolify
- [ ] Analytics: all 3 providers + abstraction layer per [Analytics Playbook](./ANALYTICS_PLAYBOOK.md)
- [ ] GlitchTip error tracking
- [ ] Uptime Kuma monitoring
- [ ] Contact form with [Spam Protection Pattern](./SPAM_PROTECTION_PATTERN.md)
- [ ] Service launchpad in site admin

### Phase 7: Hygiene
- [ ] All integrations degrade gracefully when config is missing
- [ ] Version numbers consistent across all files (plugin header, readme.txt, CHANGELOG, constant)
- [ ] Update portfolio decision matrix in [Infra Guide](./SHARED_INFRA_DECISION_GUIDE.md)

---

## Cross-Plugin Decision Matrix

Track which features and infrastructure apply across your plugin portfolio:

### Plugin Features
| Plugin | Settings Page | Custom Tables | WP-Cron | Telemetry | Error Reporting | i18n | Uninstall Cleanup |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| *(plugin-name)* | | | | | | | |

### Companion Sites
| Plugin | Marketing Site | Docs Site | Analytics (3 providers) | GlitchTip | Contact Form | Spam Protection |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|
| *(plugin-name)* | | | | | | |

**Legend:** Yes, No, Planned, N/A
