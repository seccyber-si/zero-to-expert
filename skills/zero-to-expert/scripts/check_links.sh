#!/usr/bin/env bash
# Checks every link of a course before it is shared. Read-only. macOS / Linux version of check_links.ps1.
# Usage: bash check_links.sh course.html     (every href="http..." and bare URLs in td.url cells)
#        bash check_links.sh urls.txt        (one URL per line)
# A .pdf URL answering text/html = probable soft 404. YouTube links go through the oEmbed endpoint.
# Not tested on this kit's reference machine (Windows); report issues.
set -uo pipefail
src="${1:?usage: check_links.sh course.html|urls.txt}"
ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36'
case "$src" in
  *.htm|*.html)
    urls=$( { grep -Eo 'href="https?://[^"]+"' "$src" | sed -E 's/^href="//; s/"$//'
              grep -Eo '<td[^>]*class="[^"]*url[^"]*"[^>]*>[[:space:]]*https?://[^<[:space:]]+' "$src" | sed -E 's/.*>[[:space:]]*//'; } \
            | sed 's/&amp;/\&/g' | grep -v '[][]' | sort -u) ;;
  *) urls=$(grep -E '^https?://' "$src" | sort -u) ;;
esac
total=0; bad=0
while IFS= read -r u; do
  [ -z "$u" ] && continue
  total=$((total + 1)); target="$u"; youtube=0
  if printf '%s' "$u" | grep -Eq '^https?://(www\.|m\.)?(youtube\.com/(watch|shorts|live)|youtu\.be/)'; then
    youtube=1
    enc=$(printf '%s' "$u" | sed 's/%/%25/g; s/&/%26/g; s/?/%3F/g; s/=/%3D/g; s/:/%3A/g; s#/#%2F#g')
    target="https://www.youtube.com/oembed?format=json&url=$enc"
  fi
  r=$(curl -s -o /dev/null -L --max-time 20 --connect-timeout 10 -A "$ua" -H 'Accept-Language: fr-FR,fr;q=0.9,en;q=0.8' -w '%{http_code}|%{content_type}' "$target")
  code="${r%%|*}"; ctype="${r#*|}"; ctype="${ctype%%;*}"
  verdict="OK"
  if ! printf '%s' "$code" | grep -Eq '^[0-9]{3}$' || [ "$code" = "000" ]; then verdict="FAIL (no answer)"
  elif [ "$code" -ge 400 ]; then
    if [ "$youtube" = 1 ] && [ "$code" = 401 ]; then verdict="OK (video exists, embedding disabled)"
    elif [ "$code" = 403 ] || [ "$code" = 429 ]; then verdict="CHECK ($code - the site may block scripts: open it in a browser)"
    else verdict="FAIL ($code)"; fi
  elif printf '%s' "$u" | grep -Eiq '\.pdf($|[?#])' && printf '%s' "$ctype" | grep -qi 'text/html'; then
    verdict="CHECK (pdf link answers html: moved file?)"
  fi
  case "$verdict" in OK*) ;; *) bad=$((bad + 1)) ;; esac
  printf '%3d %s | %s | %s | %s\n' "$total" "$code" "$ctype" "$verdict" "$u"
done <<< "$urls"
echo "--- $total links: $((total - bad)) OK, $bad to fix or check"
