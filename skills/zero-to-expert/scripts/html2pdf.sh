#!/usr/bin/env bash
# Prints an HTML course to PDF with a headless Chromium browser (Chrome, Chromium, Edge or Brave).
# macOS / Linux version of html2pdf.ps1: throw-away profile, bounded wait, profile removed at the end.
# Usage: bash html2pdf.sh course.html "/path/to/My course.pdf" [timeout_seconds]
# Set BROWSER_BIN to force a browser. Not tested on this kit's reference machine (Windows); report issues.
set -uo pipefail
html="${1:?usage: html2pdf.sh course.html output.pdf [timeout_seconds]}"
pdf="${2:?usage: html2pdf.sh course.html output.pdf [timeout_seconds]}"
timeout_s="${3:-180}"
[ -f "$html" ] || { echo "HTML not found: $html" >&2; exit 1; }
html_abs="$(cd "$(dirname "$html")" && pwd)/$(basename "$html")"
pdf_dir="$(cd "$(dirname "$pdf")" 2>/dev/null && pwd)" || { echo "Output folder does not exist: $(dirname "$pdf")" >&2; exit 1; }
pdf_abs="$pdf_dir/$(basename "$pdf")"

browser="${BROWSER_BIN:-}"
if [ -z "$browser" ]; then
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
    if [ -x "$c" ]; then browser="$c"; break; fi
  done
fi
if [ -z "$browser" ]; then
  for n in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge microsoft-edge-stable brave-browser; do
    if command -v "$n" >/dev/null 2>&1; then browser="$(command -v "$n")"; break; fi
  done
fi
[ -n "$browser" ] || { echo "No Chromium-based browser found. Open the HTML in a browser and use Print > Save as PDF." >&2; exit 2; }

prof="$(mktemp -d "${TMPDIR:-/tmp}/html2pdf-XXXXXX")"
log="$prof.log"
cleanup() { pkill -f "$prof" 2>/dev/null || true; rm -rf "$prof"; rm -f "$log"; }
trap cleanup EXIT
rm -f "$pdf_abs"
extra=""
[ "$(id -u)" = "0" ] && extra="--no-sandbox"
url="file://$(printf '%s' "$html_abs" | sed 's/%/%25/g; s/ /%20/g; s/#/%23/g')"
start=$(date +%s)
# $extra is intentionally unquoted: empty means no argument.
"$browser" $extra --headless=new --disable-gpu --no-first-run --no-default-browser-check --disable-extensions \
  --disable-sync --no-pdf-header-footer --generate-pdf-document-outline --virtual-time-budget=8000 \
  --enable-logging=stderr --log-level=0 --user-data-dir="$prof" --print-to-pdf="$pdf_abs" "$url" >/dev/null 2>"$log" &
pid=$!
waited=0
while kill -0 "$pid" 2>/dev/null; do
  sleep 1; waited=$((waited + 1))
  if [ "$waited" -ge "$timeout_s" ]; then kill "$pid" 2>/dev/null; echo "Timed out after ${timeout_s}s" >&2; exit 3; fi
done
[ -s "$pdf_abs" ] || { echo "The browser exited but no PDF was written: $pdf_abs" >&2; exit 4; }
links=$(LC_ALL=C grep -a -o '/URI *([^)]*)' "$pdf_abs" | sort -u | wc -l | tr -d ' ')
pages=$(LC_ALL=C grep -a -c '/Type */Page[^s]' "$pdf_abs" || true)
size=$(( $(wc -c < "$pdf_abs") / 1024 ))
echo "OK  $pdf_abs | pages: ${pages:-?} | external links: $links | size: ${size} KB | $(basename "$browser") $(( $(date +%s) - start )) s"
grep -E 'CONSOLE.*source: file:|Uncaught' "$log" | sed -E 's/^\[[^]]*\] *//; s/, source: .*$//; s/^/console: /' || true
