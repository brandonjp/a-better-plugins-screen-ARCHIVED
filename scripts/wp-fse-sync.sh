#!/usr/bin/env bash
# =============================================================================
# wp-fse-sync — FSE block-theme ⇄ live-site reconciliation (v1.0.1)
# =============================================================================
#
# Single-track sync for WordPress Full-Site-Editing (block) themes. Keeps the
# GIT REPO as the durable source of truth while still letting you edit live in
# the Site Editor, then pull those edits back into the repo and re-assert the
# theme files as the authoritative default (clearing the DB customization layer
# so nothing silently overrides the files).
#
# The invariant this enforces:
#   At rest, the theme FILES (repo == live) are authoritative and the DB
#   customization layer (wp_template / wp_template_part / wp_global_styles)
#   is EMPTY. The DB layer is only ever a temporary working state between a
#   Site-Editor edit and the next `pull`.
#
# WHY this exists: WordPress stores Site-Editor changes as DB posts, NOT in
# theme files, and those DB posts ALWAYS override the theme file. So without a
# reconciliation step the repo silently goes stale. This script is the one and
# only save-back path (we deliberately do NOT use the Create Block Theme plugin,
# which writes to live files but never reaches the repo — a second, lossy path).
#
# -----------------------------------------------------------------------------
# PROJECT-AGNOSTIC: all connection details are resolved from the wp-host-ops
# registry via the host alias. A per-project config supplies only:
#     HOST_ALIAS   — alias registered with wp-host-ops (e.g. "jpf.ngo")
#     THEME_SLUG   — active theme stylesheet/slug (e.g. "jpf-2026")
#     THEME_DIR    — theme dir relative to repo root (e.g. "themes/jpf-2026")
#
# Config lookup order:
#     1. --config <path>
#     2. $FSE_SYNC_CONFIG
#     3. ./.fse-sync.conf, ./scripts/fse-sync.conf  (walking up to git root)
#
# -----------------------------------------------------------------------------
# USAGE
#     wp-fse-sync.sh status [--config PATH]
#         Read-only drift report: which templates/parts/global-styles are
#         currently customized in the live DB (i.e. overriding the files).
#
#     wp-fse-sync.sh pull [--config PATH]
#         Read each live DB customization → write into the repo theme files
#         (parts/<slug>.html, templates/<slug>.html). Global Styles are
#         exported to .fse-pull/global-styles.<slug>.json for review (NOT
#         auto-merged into theme.json — see notes). Shows a git diff stat.
#         Does NOT commit and does NOT touch the live site.
#
#     wp-fse-sync.sh push [--config PATH] [--reset-db] [--yes]
#         rsync the repo theme dir → live, then flush cache. With --reset-db,
#         first DELETE the live DB customizations for this theme so the files
#         become authoritative again (the "files win" step). On a prod host,
#         --reset-db requires --yes.
#
# TYPICAL RECONCILIATION RITUAL
#     wp-fse-sync.sh status                 # see what's drifted
#     wp-fse-sync.sh pull                   # DB customizations → repo files
#     git add -A && git commit -m "..."     # repo is now truth
#     wp-fse-sync.sh push --reset-db        # files → live, clear DB layer
#
# Requires: bash, python3, rsync, ssh; wp-host-ops engine + registered alias.
# =============================================================================

set -euo pipefail

ENGINE="${WP_HOST_ENGINE:-$HOME/.claude/skills/wp-host-ops/scripts/wp-host.sh}"

err()  { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$*"; }
info() { printf '\033[36m• %s\033[0m\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*"; }
die()  { err "$*"; exit 1; }

# --- arg parse --------------------------------------------------------------
CMD="${1:-}"; shift || true
CONFIG=""; RESET_DB=0; ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --reset-db) RESET_DB=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    *) die "unknown option: $1" ;;
  esac
done

[ -f "$ENGINE" ] || die "wp-host-ops engine not found at $ENGINE (set WP_HOST_ENGINE)"

# --- locate + load config ---------------------------------------------------
find_config() {
  [ -n "$CONFIG" ] && { echo "$CONFIG"; return; }
  [ -n "${FSE_SYNC_CONFIG:-}" ] && { echo "$FSE_SYNC_CONFIG"; return; }
  local d; d="$(pwd)"
  while [ "$d" != "/" ]; do
    for c in "$d/.fse-sync.conf" "$d/scripts/fse-sync.conf"; do
      [ -f "$c" ] && { echo "$c"; return; }
    done
    [ -d "$d/.git" ] && break
    d="$(dirname "$d")"
  done
  return 1
}

CONFIG_PATH="$(find_config)" || die "no config found (.fse-sync.conf / scripts/fse-sync.conf, or --config)"
# shellcheck disable=SC1090
source "$CONFIG_PATH"
: "${HOST_ALIAS:?config must set HOST_ALIAS}"
: "${THEME_SLUG:?config must set THEME_SLUG}"
: "${THEME_DIR:?config must set THEME_DIR}"

REPO_ROOT="$(git -C "$(dirname "$CONFIG_PATH")" rev-parse --show-toplevel 2>/dev/null)" \
  || die "config is not inside a git repo"
LOCAL_THEME="$REPO_ROOT/$THEME_DIR"
[ -d "$LOCAL_THEME" ] || die "theme dir not found: $LOCAL_THEME"

# --- resolve host from registry (the SSH abstraction) -----------------------
REG_JSON="$(bash "$ENGINE" get "$HOST_ALIAS")" || die "alias '$HOST_ALIAS' not in wp-host registry"
read_reg() { printf '%s' "$REG_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$1',''))"; }
SSH_USER="$(read_reg ssh_user)"; SSH_HOST="$(read_reg ssh_host)"
SSH_PORT="$(read_reg ssh_port)"; SSH_KEY="$(read_reg ssh_key)"
WP_PATH="$(read_reg wp_path)";   ENV="$(read_reg env)"
SSH_KEY="${SSH_KEY/#\~/$HOME}"
REMOTE_THEME="$WP_PATH/wp-content/themes/$THEME_SLUG"

# --- remote helpers ---------------------------------------------------------
# NOTE: </dev/null is REQUIRED. The engine shells out to ssh, which reads stdin;
# without it, a remote call inside a `while read` loop eats the loop's input and
# the loop silently stops after the first row. (Learned the hard way.)
wpx() { bash "$ENGINE" run "$HOST_ALIAS" -- "$@" </dev/null; }
shx() { bash "$ENGINE" run "$HOST_ALIAS" --shell -- "$@" </dev/null; }

# Run PHP on the host via a temp eval-file (robust against quoting over SSH).
# $1 = PHP body (no opening tag). Echoes the script's stdout.
remote_eval() {
  local php b64 rf
  php="<?php $1"
  b64="$(printf '%s' "$php" | base64 | tr -d '\n')"
  rf="$WP_PATH/.fse-eval-$$-$RANDOM.php"
  shx "printf '%s' '$b64' | base64 -d > '$rf'"
  local out rc=0
  out="$(wpx eval-file "$rf")" || rc=$?
  shx "rm -f '$rf'" || true
  printf '%s' "$out"
  return $rc
}

# List customizations (TSV: type<TAB>id<TAB>slug) for THEME_SLUG.
list_customizations() {
  remote_eval "
    \$slug='$THEME_SLUG';
    foreach(['wp_template','wp_template_part','wp_global_styles'] as \$t){
      \$q=new WP_Query(['post_type'=>\$t,'post_status'=>'publish','posts_per_page'=>-1,
        'tax_query'=>[['taxonomy'=>'wp_theme','field'=>'name','terms'=>\$slug]]]);
      foreach(\$q->posts as \$p){ echo \$t.\"\t\".\$p->ID.\"\t\".\$p->post_name.\"\n\"; }
    }
  "
}

require_files_authoritative_ok() {
  if [ "$ENV" = "prod" ] && [ "$ASSUME_YES" -ne 1 ]; then
    die "host '$HOST_ALIAS' is PROD. Re-run with --yes to confirm clearing the live DB customization layer."
  fi
}

# ============================================================================
cmd_status() {
  info "Host '$HOST_ALIAS' ($ENV) — theme '$THEME_SLUG'"
  info "Live DB customizations (these override the theme files):"
  local rows; rows="$(list_customizations)"
  if [ -z "$rows" ]; then
    ok "none — theme files are authoritative (no drift)."
    return
  fi
  printf '%s\n' "$rows" | while IFS=$'\t' read -r t id slug; do
    [ -z "$t" ] && continue
    printf '    %-18s #%-10s %s\n' "$t" "$id" "$slug"
  done
  warn "Run 'pull' to fold these into the repo, then 'push --reset-db' to clear them."
}

# ============================================================================
cmd_pull() {
  info "Pulling live customizations for '$THEME_SLUG' into $THEME_DIR/ …"
  local rows; rows="$(list_customizations)"
  [ -z "$rows" ] && { ok "nothing customized in the DB — repo already current."; return; }

  mkdir -p "$REPO_ROOT/.fse-pull"
  local n=0 gs=0
  while IFS=$'\t' read -r t id slug; do
    [ -z "$t" ] && continue
    case "$t" in
      wp_template_part)
        local dest="$LOCAL_THEME/parts/$slug.html"
        mkdir -p "$(dirname "$dest")"
        wpx post get "$id" --field=post_content > "$dest"
        ok "part     → $THEME_DIR/parts/$slug.html"; n=$((n+1)) ;;
      wp_template)
        local dest="$LOCAL_THEME/templates/$slug.html"
        mkdir -p "$(dirname "$dest")"
        wpx post get "$id" --field=post_content > "$dest"
        ok "template → $THEME_DIR/templates/$slug.html"; n=$((n+1)) ;;
      wp_global_styles)
        local dest="$REPO_ROOT/.fse-pull/global-styles.$THEME_SLUG.json"
        wpx post get "$id" --field=post_content > "$dest"
        warn "Global Styles exported → .fse-pull/global-styles.$THEME_SLUG.json"
        warn "  Review and merge its settings/styles into $THEME_DIR/theme.json by hand"
        warn "  (auto-merge is intentionally not done — it is a layered JSON merge)."
        gs=1 ;;
    esac
  done <<< "$rows"

  ok "$n template/part file(s) written.$([ $gs -eq 1 ] && echo ' Global Styles need a manual theme.json merge.')"
  echo
  info "Diff vs repo (review before committing):"
  git -C "$REPO_ROOT" --no-pager diff --stat -- "$THEME_DIR" ".fse-pull" || true
  echo
  warn "Not committed. Review, then: git add -A && git commit, then 'push --reset-db'."
}

# ============================================================================
cmd_push() {
  [ -d "$LOCAL_THEME" ] || die "no local theme at $LOCAL_THEME"
  if [ "$RESET_DB" -eq 1 ]; then
    require_files_authoritative_ok
    info "Clearing live DB customization layer for '$THEME_SLUG' …"
    local rows; rows="$(list_customizations)"
    if [ -n "$rows" ]; then
      while IFS=$'\t' read -r t id slug; do
        [ -z "$id" ] && continue
        remote_eval "wp_delete_post(${id}, true);" >/dev/null
        ok "deleted $t #$id ($slug)"
      done <<< "$rows"
    else
      info "  (nothing to clear)"
    fi
  fi

  info "Deploying $THEME_DIR/ → $HOST_ALIAS:$REMOTE_THEME/ …"
  rsync -az --delete \
    -e "ssh -i '$SSH_KEY' -p '$SSH_PORT'" \
    --exclude='.DS_Store' --exclude='.git' \
    "$LOCAL_THEME/" "$SSH_USER@$SSH_HOST:$REMOTE_THEME/"
  ok "theme files synced to live."

  if wpx cache flush >/dev/null 2>&1; then ok "object cache flushed."; else warn "cache flush skipped (non-fatal)."; fi
  ok "Done. Theme files are authoritative on '$HOST_ALIAS'."
}

# ============================================================================
case "$CMD" in
  status) cmd_status ;;
  pull)   cmd_pull ;;
  push)   cmd_push ;;
  ""|-h|--help|help)
    sed -n '2,72p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) die "unknown command '$CMD' (use: status | pull | push)" ;;
esac
