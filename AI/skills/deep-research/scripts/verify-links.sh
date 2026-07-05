#!/usr/bin/env bash
#
# verify-links.sh — citation-integrity verifier for the deep-research skill.
#
# This does more than ping URLs. It mechanically enforces the skill's rule 2
# ("you may only cite a page you actually fetched"): every URL cited in the
# report must also appear in the on-disk notes. A cited URL with no note is a
# probable fabrication and is flagged UNSOURCED.
#
# Two URL sets:
#   NOTED  — every URL found in the notes dir (the ground truth of what was
#            fetched and summarized during Phase 2).
#   CITED  — every URL found in the report file, if one is given. Without a
#            report (light mode, answer is inline in chat), CITED falls back to
#            NOTED and the cross-check is reported as skipped.
#
# Liveness runs over CITED in parallel. Classification:
#   2xx/3xx          -> OK
#   403 / 405 / 429  -> BOT-BLOCK (likely live; manual look, do not auto-delete)
#   404 / ERR / other-> BROKEN (fix the URL or remove the claim)
#
# Exit code (gate-friendly): 0 if clean or only bot-block warnings; 1 if any
# BROKEN or UNSOURCED citation; 2 on usage error.
#
# Portable across agents: self-locating, depends only on bash, curl, grep, sort,
# sed, xargs. Override notes dir with RESEARCH_DIR.
#
# Usage:
#   verify-links.sh [--report <file>] [--notes <dir>] [--json] [--concurrency N]
#   verify-links.sh --check-one <url>     # internal worker (used by xargs)

set -uo pipefail

BASE_DIR="${RESEARCH_DIR:-docs/deep-research}" # holds the HTML report(s)
NOTES_DIR="$BASE_DIR/.tmp"                      # holds all interim notes
REPORT=""
EMIT_JSON=0
CONCURRENCY=8
UA="Mozilla/5.0 (compatible; deep-research-linkcheck/1.0)"
TIMEOUT=15

die() {
  echo "verify-links.sh: $1" >&2
  exit 2
}

# --- internal worker: check one URL, print "<code>\t<url>" -------------------
if [ "${1:-}" = "--check-one" ]; then
  url="${2:?}"
  code=$(curl -sS -L -A "$UA" -o /dev/null -w '%{http_code}' \
    --max-time "$TIMEOUT" "$url" 2>/dev/null || echo ERR)
  printf '%s\t%s\n' "$code" "$url"
  exit 0
fi

# --- arg parsing -------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
  --report)
    REPORT="${2:?--report needs a file}"
    shift 2
    ;;
  --notes)
    NOTES_DIR="${2:?--notes needs a dir}"
    shift 2
    ;;
  --json)
    EMIT_JSON=1
    shift
    ;;
  --concurrency)
    CONCURRENCY="${2:?--concurrency needs a number}"
    shift 2
    ;;
  *) die "unknown argument '$1'" ;;
  esac
done

[ -d "$NOTES_DIR" ] || die "notes dir '$NOTES_DIR' not found"

# Auto-detect a report if none was named: the most recently written *.html at
# the workspace top level (reports live there; notes live in .tmp/). Reports
# carry task-relevant names now, so there's no fixed filename to look for —
# newest wins (that's the one the current run just wrote).
if [ -z "$REPORT" ]; then
  # ls -t for newest-first: the portable `find` equivalent needs GNU-only
  # -printf, and report slugs are controlled kebab-case (no odd filenames).
  # shellcheck disable=SC2012
  REPORT=$(ls -t "$BASE_DIR"/*.html 2>/dev/null | head -1 || true)
fi

SELF="$0"

# Recognizable web TLDs for scheme-less hosts. An allowlist (not "any dotted
# token") is what keeps filenames (package.json, clock.sh, README.md), version
# strings (4.8) and code identifiers from being mistaken for citable domains:
# their suffixes (json, sh, md, ts, py, …) are deliberately absent here.
BARE_TLDS='com|org|net|edu|gov|mil|int|io|ai|co|dev|app|info|biz|news|blog|tech|xyz|online|site|wiki|cloud|page|pro|me|tv|fm|gg|ly|so|to|fyi|us|uk|ca|eu|au|nl|jp|cn|de|fr|es|br|in|ru|ch|se|no|fi|dk|pl'

# Trailing chars that may abut a URL in prose/markup but aren't part of it:
# whitespace, quotes, angle brackets, a closing paren and sentence punctuation.
# Stripping the whole set (not just punctuation) keeps a bare host written mid
# sentence ("site.com and") comparable to the same host in an href.
TRAIL_CHARS='[][:space:]"'\''<>).,;:!?]'

# Extract citable URLs from stdin and normalize them for comparison.
#
# Extraction is deliberately asymmetric (arg $1, default 1 = include bare hosts):
#   notes  (1) — full URLs PLUS scheme-less hosts. Crediting everything the
#                agent fetched only makes the rule-2 cross-check more lenient.
#   report (0) — full http(s) URLs only. Report citations are <a href> links;
#                a bare domain in report prose is a mention, not a citation, so
#                manufacturing one would raise false UNSOURCED flags.
extract_urls() {
  local with_bare="${1:-1}" raw
  raw=$(cat)
  {
    printf '%s\n' "$raw" | grep -oE 'https?://[^[:space:]"'"'"'<>)]+'
    [ "$with_bare" -eq 1 ] && extract_bare_hosts "$raw"
  } |
    sed -E 's/&amp;/\&/g; s/'"$TRAIL_CHARS"'+$//; s/#.*$//; s#/$##' |
    grep -iE '^https?://[a-z0-9]' |
    sort -u
}

# Find scheme-less hosts ending in an allowlisted TLD and prefix https://.
# A leading boundary ([^/@…]) avoids re-matching the inside of an http URL or
# the host of an email; a trailing boundary forces the TLD to be the final
# label so "foo.community" can't truncate to "foo.com".
extract_bare_hosts() {
  local boundary_lead='(^|[^/@a-zA-Z0-9_.-])'
  local host='([a-z0-9-]+\.)+('"$BARE_TLDS"')'
  local path_opt="(/[^[:space:]\"'<>)]*)?"
  local boundary_trail='([[:space:]"'"'"'<>).,;:!?]|$)'
  printf '%s\n' "$1" |
    grep -oiE "${boundary_lead}${host}${path_opt}${boundary_trail}" |
    sed -E 's/^[^a-zA-Z0-9]+//; s/'"$TRAIL_CHARS"'+$//; s#^#https://#'
}

# Subagent WIP notes are markdown files in .tmp/; the gathered evidence lives
# there. query.md (the verbatim user prompt) is deliberately excluded: a URL
# the user pasted into the prompt must not satisfy the rule-2 cross-check unless
# a subagent actually fetched it and took notes on it in its own notes file.
noted_urls=$(find "$NOTES_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'query.md' \
  -exec cat {} + 2>/dev/null | extract_urls 1 || true)

cross_check=1
if [ -n "$REPORT" ]; then
  [ -r "$REPORT" ] || die "report '$REPORT' not readable"
  cited_urls=$(extract_urls 0 <"$REPORT")
else
  cross_check=0
  cited_urls="$noted_urls"
fi

[ -n "$cited_urls" ] || {
  echo "No URLs to verify (cited set empty)."
  exit 0
}

# --- rule 2: cited but not noted = unsourced ---------------------------------
unsourced=""
if [ "$cross_check" -eq 1 ]; then
  unsourced=$(comm -23 <(printf '%s\n' "$cited_urls") <(printf '%s\n' "$noted_urls"))
fi

# --- liveness (parallel) -----------------------------------------------------
results=$(printf '%s\n' "$cited_urls" |
  xargs -P "$CONCURRENCY" -I{} "$SELF" --check-one {})

ok=$(echo "$results" | grep -cE '^(2[0-9][0-9]|3[0-9][0-9])	' || true)
botblock=$(echo "$results" | grep -E '^(403|405|429)	' || true)
broken=$(echo "$results" | grep -vE '^(2[0-9][0-9]|3[0-9][0-9]|403|405|429)	' || true)

n_cited=$(printf '%s\n' "$cited_urls" | grep -c . || true)
n_noted=$(printf '%s\n' "$noted_urls" | grep -c . || true)
n_unsourced=$([ -n "$unsourced" ] && echo "$unsourced" | grep -c . || echo 0)
n_botblock=$([ -n "$botblock" ] && echo "$botblock" | grep -c . || echo 0)
n_broken=$([ -n "$broken" ] && echo "$broken" | grep -c . || echo 0)

# --- human report (problems only + counts) -----------------------------------
echo "Citation check — ${n_cited} cited, ${n_noted} noted, ${n_cited} live-checked"
[ "$cross_check" -eq 0 ] &&
  echo "  (no report given — rule-2 cross-check skipped; checked notes URLs)"

while IFS= read -r u; do
  [ -n "$u" ] &&
    echo "  ✗ UNSOURCED       $u  (cited but not in notes — verify or remove)"
done <<<"$unsourced"

while IFS=$'\t' read -r code u; do
  [ -n "$u" ] &&
    echo "  ✗ BROKEN     $code  $u  (fix URL or drop claim)"
done <<<"$broken"

while IFS=$'\t' read -r code u; do
  [ -n "$u" ] &&
    echo "  ⚠ BOT-BLOCK  $code  $u  (likely live; manual check)"
done <<<"$botblock"

echo "  ✓ ${ok} OK"

if [ "$n_unsourced" -gt 0 ] || [ "$n_broken" -gt 0 ]; then
  echo "Result: ${n_unsourced} unsourced, ${n_broken} broken, ${n_botblock} flagged — NEEDS ATTENTION"
  status=1
else
  suffix=""
  [ "$n_botblock" -gt 0 ] && suffix=" (${n_botblock} bot-block warnings)"
  echo "Result: all ${n_cited} citations sourced and live${suffix} — OK"
  status=0
fi

# --- optional machine summary for the methodology footer ---------------------
if [ "$EMIT_JSON" -eq 1 ]; then
  printf '{"cited":%d,"noted":%d,"ok":%d,"unsourced":%d,"broken":%d,"botblock":%d,"cross_check":%s}\n' \
    "$n_cited" "$n_noted" "$ok" "$n_unsourced" "$n_broken" "$n_botblock" \
    "$([ "$cross_check" -eq 1 ] && echo true || echo false)"
fi

exit "$status"
