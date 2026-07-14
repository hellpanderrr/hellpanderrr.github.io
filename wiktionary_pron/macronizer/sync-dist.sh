#!/usr/bin/env bash
# Rebuild this site's copy of the macronizer engine from the source repo.
#
# The engine's defaults point at a standalone dev server ('/wasm/…', '/macrons.txt').
# On the site it lives under /wiktionary_pron/macronizer/, and the wordlist is
# served gzipped. Those are the only edits — everything else is a verbatim copy,
# so run this after any engine change rather than hand-patching dist/.
#
# Usage: ./sync-dist.sh [path-to-latin-macronizer-repo]
set -euo pipefail

SRC="${1:-F:/projects/macronizer/latin-macronizer-master}"
HERE="$(cd "$(dirname "$0")" && pwd)"
BASE="/wiktionary_pron/macronizer"

[ -d "$SRC/dist" ] || { echo "No dist/ in $SRC — run 'npm run build' there first." >&2; exit 1; }

rm -rf "$HERE/dist"
mkdir -p "$HERE/dist"
# dist/wasm is a duplicate of ./wasm (36 MB) and is never fetched by the page.
(cd "$SRC/dist" && find . -type d -name wasm -prune -o -type f -print0 \
  | tar --null -cf - --files-from=-) | (cd "$HERE/dist" && tar -xf -)

api="$HERE/dist/api/MacronizerAPI.js"
sed -i \
  -e "s#'/wasm/#'$BASE/wasm/#g" \
  -e "s#'/macrons\.txt'#'$BASE/macrons.txt.gz'#g" \
  "$api"

grep -q "$BASE/wasm/rftagger.js" "$api" || { echo "Path rewrite failed in $api" >&2; exit 1; }
grep -q "$BASE/macrons.txt.gz"   "$api" || { echo "Wordlist rewrite failed in $api" >&2; exit 1; }
echo "Synced dist/ from $SRC and rewrote asset paths to $BASE/."
