#!/usr/bin/env bash
# Fetch a Figma frame through the REST API and turn it into a compact, token-friendly spec.
#   bash .claude/skills/figma-to-code/figma-fetch.sh '<figma url with node-id>' [max-depth]
#   bash .claude/skills/figma-to-code/figma-fetch.sh --from-json nodes.json [max-depth]   (offline / pasted JSON)
# Needs FIGMA_TOKEN in the environment (Figma → Settings → Security → Personal access tokens, scope file_content:read).
# Output in .claude/.kit-state/figma/<node>/: spec.txt (outline), palette.txt (colors/type to map to tokens),
# render.png (2x screenshot), nodes.json (raw).
set -euo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
depth="${2:-10}"

if [ "${1:-}" = "--from-json" ]; then
  raw="$2"; depth="${3:-10}"
  node_id=$(jq -r '.nodes | keys[0]' "$raw")
  out="$root/.claude/.kit-state/figma/${node_id//:/-}"
  mkdir -p "$out"; cp "$raw" "$out/nodes.json"
else
  url="${1:?usage: figma-fetch.sh <figma-url> [max-depth]}"
  : "${FIGMA_TOKEN:?FIGMA_TOKEN is not set (export it in ~/.zshrc and restart the terminal/Claude)}"
  # /design|file|proto/<key>/... ; branch URLs: /design/<key>/branch/<branchKey>/...
  file_key=$(sed -E 's#.*/(design|file|proto|board)/([A-Za-z0-9]+)(/branch/([A-Za-z0-9]+))?.*#\2 \4#' <<<"$url" | awk '{print ($2!="") ? $2 : $1}')
  node_id=$(sed -nE 's#.*[?&]node-id=([0-9]+)(-|:|%3A)([0-9]+).*#\1:\3#p' <<<"$url")
  [ -n "$file_key" ] && [ -n "$node_id" ] || { echo "✗ could not parse file key / node-id from URL (select a frame and 'Copy link to selection')"; exit 1; }
  out="$root/.claude/.kit-state/figma/${node_id//:/-}"
  mkdir -p "$out"
  api() { curl -sS --fail-with-body -H "X-Figma-Token: $FIGMA_TOKEN" "https://api.figma.com/v1/$1"; }
  api "files/$file_key/nodes?ids=$node_id" >"$out/nodes.json" || { echo "✗ API error:"; cat "$out/nodes.json"; exit 1; }
  img=$(api "images/$file_key?ids=$node_id&format=png&scale=2" | jq -r --arg id "$node_id" '.images[$id] // empty')
  [ -n "$img" ] && curl -sS -o "$out/render.png" "$img"
fi

JQ_LIB='
def hx: (. * 255 | round) as $n | "0123456789abcdef" as $d | $d[($n/16|floor):($n/16|floor)+1] + $d[($n%16):($n%16)+1];
def color($o): if $o == null then "" else
  "#" + ($o.r|hx) + ($o.g|hx) + ($o.b|hx) + (if (($o.a // 1) < 1) then (" @" + ($o.a*100|round|tostring) + "%") else "" end) end;
def paint: map(select(.visible != false))
  | map(if .type == "SOLID" then color(.color + {a: ((.color.a // 1) * (.opacity // 1))})
        elif .type == "IMAGE" then "image"
        else (.type | ascii_downcase) + "(" + ([.gradientStops[]? | color(.color)] | join("→")) + ")" end)
  | join(", ");
def stylename($styles; $key): (.styles[$key] // null) as $sid | if $sid then ($styles[$sid].name // null) else null end;
def r1: if . == null then 0 else (. * 10 | round) / 10 end;
'

jq -r --argjson maxd "$depth" "$JQ_LIB"'
.nodes | to_entries[0].value as $n | ($n.styles // {}) as $styles |
def line($d):
  (if .visible == false then empty else
    ("  " * $d) + .type + " \"" + .name + "\""
    + (if .absoluteBoundingBox then " " + (.absoluteBoundingBox.width|r1|tostring) + "×" + (.absoluteBoundingBox.height|r1|tostring) else "" end)
    + (if (.layoutMode // "NONE") != "NONE" then
        " | " + (if .layoutMode == "HORIZONTAL" then "row" else "col" end)
        + (if .layoutWrap == "WRAP" then " wrap" else "" end)
        + " gap " + ((.itemSpacing // 0)|tostring)
        + " pad " + ([.paddingTop, .paddingRight, .paddingBottom, .paddingLeft] | map(. // 0 | tostring) | join("/"))
        + " align " + ((.primaryAxisAlignItems // "MIN")|ascii_downcase) + "/" + ((.counterAxisAlignItems // "MIN")|ascii_downcase)
      else "" end)
    + (if .layoutSizingHorizontal then " | size " + (.layoutSizingHorizontal|ascii_downcase) + "×" + (.layoutSizingVertical|ascii_downcase) else "" end)
    + (if ((.fills // []) | map(select(.visible != false)) | length) > 0 and .type != "TEXT" then
        " | bg " + (.fills|paint) + (stylename($styles; "fill") | if . then " {" + . + "}" else "" end) else "" end)
    + (if ((.strokes // []) | length) > 0 then " | border " + ((.strokeWeight // 1)|tostring) + "px " + (.strokes|paint) + (stylename($styles; "stroke") | if . then " {" + . + "}" else "" end) else "" end)
    + (if .rectangleCornerRadii then " | radius " + (.rectangleCornerRadii|map(tostring)|join("/"))
       elif (.cornerRadius // 0) > 0 then " | radius " + (.cornerRadius|tostring) else "" end)
    + (if ((.effects // []) | map(select(.visible != false)) | length) > 0 then
        " | fx " + ([.effects[] | select(.visible != false) | (.type|ascii_downcase) + " " + ((.offset.x // 0)|tostring) + " " + ((.offset.y // 0)|tostring) + " " + ((.radius // 0)|tostring) + " " + ((.spread // 0)|tostring) + " " + color(.color)] | join(", "))
        + (stylename($styles; "effect") | if . then " {" + . + "}" else "" end) else "" end)
    + (if (.opacity // 1) < 1 then " | opacity " + (.opacity|tostring) else "" end)
    + (if .type == "TEXT" then
        " | " + (.style.fontFamily // "?") + " " + ((.style.fontWeight // 400)|tostring) + " "
        + ((.style.fontSize // 0)|tostring) + "/" + ((.style.lineHeightPx // 0)|r1|tostring)
        + (if (.style.letterSpacing // 0) != 0 then " ls " + (.style.letterSpacing|r1|tostring) else "" end)
        + (if .style.textCase then " " + (.style.textCase|ascii_downcase) else "" end)
        + " " + (.fills|paint)
        + (stylename($styles; "text") | if . then " {" + . + "}" else "" end)
        + (stylename($styles; "fill") | if . then " {" + . + "}" else "" end)
        + " \"" + ((.characters // "")[0:80] | gsub("\n"; "⏎")) + "\""
      else "" end)
    + (if .type == "INSTANCE" then
        " → " + ((.componentId as $c | $n.components[$c].name) // "?")
        + (if .componentProperties then " {" + ([.componentProperties | to_entries[] | (.key|split("#")[0]) + "=" + (.value.value|tostring)] | join(", ")) + "}" else "" end)
      else "" end)
    + (if .boundVariables and (.boundVariables|length) > 0 then " [vars: " + (.boundVariables|keys|join(",")) + "]" else "" end),
    (if $d < $maxd and .type != "INSTANCE" then (.children // [])[] | line($d + 1) else empty end)
  end);
$n.document | line(0)
' "$out/nodes.json" >"$out/spec.txt"

jq -r "$JQ_LIB"'
.nodes | to_entries[0].value as $n | ($n.styles // {}) as $styles |
[ $n.document | .. | objects | select(.visible != false) ] as $all |
"## Colors (fills/strokes) — count, value, Figma style",
( [ $all[] | . as $node | ((.fills // []) + (.strokes // []))[] | select(.type == "SOLID" and .visible != false)
    | {c: color(.color + {a: ((.color.a // 1) * (.opacity // 1))}),
       s: ($node | (stylename($styles; "fill") // stylename($styles; "stroke") // stylename($styles; "text") // ""))} ]
  | group_by(.c) | map({c: .[0].c, n: length, s: ([.[].s | select(. != "")] | unique | join(" | "))})
  | sort_by(-.n)[] | "- \(.n)× \(.c)\(if .s != "" then "  {" + .s + "}" else "" end)" ),
"",
"## Typography — count, family weight size/line-height, Figma style",
( [ $all[] | select(.type == "TEXT" and .style != null) | {t: "\(.style.fontFamily) \(.style.fontWeight) \(.style.fontSize)/\(.style.lineHeightPx|r1)", s: (stylename($styles; "text") // "")} ]
  | group_by(.t) | map({t: .[0].t, n: length, s: ([.[].s | select(. != "")] | unique | join(" | "))})
  | sort_by(-.n)[] | "- \(.n)× \(.t)\(if .s != "" then "  {" + .s + "}" else "" end)" ),
"",
"## Spacing values (gap / padding)",
( [ $all[] | select((.layoutMode // "NONE") != "NONE") | .itemSpacing, .paddingTop, .paddingRight, .paddingBottom, .paddingLeft | select(. != null) ]
  | group_by(.) | map("\(.[0])px×\(length)") | join("  ") ),
"",
"## Radii",
( [ $all[] | .cornerRadius | select(. != null and . > 0) ] | group_by(.) | map("\(.[0])px×\(length)") | join("  ") ),
"",
"## Components used (instances)",
( [ $all[] | select(.type == "INSTANCE") | ($n.components[.componentId].name // "?") ] | group_by(.) | map("- \(length)× \(.[0])") | .[] )
' "$out/nodes.json" >"$out/palette.txt"

echo "✓ Figma node $node_id → ${out#"$root"/}/"
echo "  spec.txt ($(wc -l <"$out/spec.txt" | tr -d ' ') lines)  palette.txt  $( [ -f "$out/render.png" ] && echo render.png )  nodes.json"
