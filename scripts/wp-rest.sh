#!/usr/bin/env bash
# =============================================================================
# wp-rest — drive a WordPress site over the core REST API from a headless agent
#           (Claude Code web, CI, cron) using an Application Password (v1.0.0)
# =============================================================================
#
# WHY this exists: Claude Code on the web (the cloud sandbox) has no SSH/FTP and
# no secure secret store — but it DOES have outbound HTTPS. The WordPress core
# REST API is just authenticated HTTPS, so it's the one channel an agent can use
# to change a live site without touching the server shell. This wrapper makes
# those calls consistent and keeps the credential out of the transcript.
#
# WHAT it can reach (Tier 1 — core REST surface):
#   posts, pages, media, users, menus & menu-items, FSE block templates &
#   template-parts (block themes), synced patterns (wp_block), and the small
#   allowlist of core settings (/wp/v2/settings).
#
# WHAT it CANNOT reach (Tier 2 — needs WP-CLI/SSH): plugin settings (e.g. a
# custom wp-admin login path), classic-theme PHP templates, code-registered
# block patterns, the DB, server config. For those use the `wp-host-ops` skill
# (SSH + WP-CLI) from a local machine, or a companion plugin that exposes the
# operation over its own authenticated REST endpoint.
#
# -----------------------------------------------------------------------------
# CONFIG — three environment variables (set them in the Claude Code web
# environment, NOT committed to the repo):
#     WP_URL      site base URL, e.g. https://example.com
#     WP_USER     the WordPress username the application password belongs to
#     WP_APP_PW   a WordPress Application Password (Users → Profile →
#                 Application Passwords). Least-privilege role, revocable,
#                 one per site.
#
# SECURITY: the credential is passed to curl via a `--config` stream on stdin,
# so it never appears in argv, `ps`, shell `-x` traces, or the agent transcript.
# Do NOT add `set -x` to this script. Do NOT echo "$WP_APP_PW".
#
# -----------------------------------------------------------------------------
# USAGE
#     wp-rest.sh me                      # verify auth (GET users/me?context=edit)
#     wp-rest.sh get  <path>             # GET   e.g. get '/wp/v2/pages?slug=about'
#     wp-rest.sh post <path> [json|-]    # POST  body from file or stdin (default -)
#     wp-rest.sh put  <path> [json|-]    # PUT   body from file or stdin (default -)
#     wp-rest.sh delete <path>           # DELETE
#     wp-rest.sh version | help
#
#   <path> may be a REST path under /wp-json (e.g. /wp/v2/posts), a full
#   /wp-json/... path, or an absolute URL. WordPress accepts POST for updates,
#   so use `post /wp/v2/posts/<id>` to edit an existing post.
#
# EXAMPLES
#     wp-rest.sh me
#     echo '{"title":"Hello","status":"draft","content":"<p>Hi</p>"}' \
#         | wp-rest.sh post /wp/v2/posts
#     wp-rest.sh get '/wp/v2/pages?slug=home&context=edit'
#     echo '{"content":"<!-- wp:paragraph --><p>Give</p><!-- /wp:paragraph -->"}' \
#         | wp-rest.sh post /wp/v2/pages/42
#
# Requires: bash, curl >= 7.76 (for --fail-with-body). jq or python3 optional
# (pretty-prints JSON when present; raw passthrough otherwise).
# =============================================================================
set -euo pipefail

VERSION="1.0.0"

die() { printf 'wp-rest: %s\n' "$1" >&2; exit 1; }

usage() {
  sed -n '38,57p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in version) printf 'wp-rest %s\n' "$VERSION"; exit 0 ;;
                ""|help|-h|--help) usage; exit 0 ;; esac

: "${WP_URL:?set WP_URL (e.g. https://example.com) in the environment}"
: "${WP_USER:?set WP_USER (the WP username the application password belongs to)}"
: "${WP_APP_PW:?set WP_APP_PW (a WordPress Application Password) in the environment}"

BASE="${WP_URL%/}"
API="$BASE/wp-json"

_pp() {
  if   command -v jq      >/dev/null 2>&1; then jq .
  elif command -v python3 >/dev/null 2>&1; then python3 -m json.tool
  else cat
  fi
}

# _req METHOD PATH [BODY_FILE|-]
_req() {
  local method="$1" path="$2" body="${3:-}"
  local url tmp=""

  case "$path" in
    http*)       url="$path" ;;
    /wp-json/*)  url="$BASE$path" ;;
    /*)          url="$API$path" ;;
    *)           url="$API/$path" ;;
  esac

  # Capture stdin body to a temp file so curl's stdin stays free for --config.
  if [ "$body" = "-" ]; then
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' RETURN
    cat > "$tmp"; body="$tmp"
    [ -s "$body" ] || body=""   # empty stdin → no body
  fi

  local -a args=(--silent --show-error --fail-with-body
                 --request "$method"
                 --header 'Content-Type: application/json'
                 --config -)
  [ -n "$body" ] && args+=(--data-binary @"$body")

  # Auth via --config on stdin → password never enters argv/ps/transcript.
  curl "${args[@]}" "$url" <<EOF | _pp
user = "$WP_USER:$WP_APP_PW"
EOF
}

cmd="${1:-}"; shift || true
case "$cmd" in
  me)     _req GET "/wp/v2/users/me?context=edit" ;;
  get)    [ $# -ge 1 ] || die "usage: get <path>";            _req GET    "$1" ;;
  post)   [ $# -ge 1 ] || die "usage: post <path> [json|-]";  _req POST   "$1" "${2:--}" ;;
  put)    [ $# -ge 1 ] || die "usage: put <path> [json|-]";   _req PUT    "$1" "${2:--}" ;;
  delete) [ $# -ge 1 ] || die "usage: delete <path>";         _req DELETE "$1" ;;
  *)      die "unknown command: '$cmd' (try: wp-rest.sh help)" ;;
esac
