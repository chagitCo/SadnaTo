# shellcheck shell=bash
# Minimal, dependency-free JSON field readers for hook input (stdin JSON from Claude Code).
# Uses jq when available; otherwise a gawk/awk scanner that understands string escapes.
# Only top-level-or-nested *first occurrence* lookups are needed by our hooks.

# json_get_string KEY  < json   -> prints the unescaped string value of the first "KEY": "..."
json_get_string() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$key" 'first(.. | objects | select(has($k)) | .[$k] | select(type=="string")) // empty' 2>/dev/null
    return 0
  fi
  awk -v key="$key" '
    BEGIN { RS = "\001" }
    {
      pat = "\"" key "\"[ \t\r\n]*:[ \t\r\n]*\""
      if (!match($0, pat)) exit 0
      i = RSTART + RLENGTH; n = length($0); out = ""
      while (i <= n) {
        c = substr($0, i, 1)
        if (c == "\\") {
          i++; e = substr($0, i, 1)
          if (e == "n") out = out "\n"
          else if (e == "t") out = out "\t"
          else if (e == "r") out = out "\r"
          else if (e == "b" || e == "f") out = out " "
          else if (e == "u") { out = out "?"; i += 4 }
          else out = out e
        } else if (c == "\"") {
          break
        } else {
          out = out c
        }
        i++
      }
      printf "%s", out
    }'
}

# json_fields KEY... < json -> prints the string values of several keys in ONE pass, separated by
# the ASCII unit separator (\037), so hooks spawn a single process (forks are slow on Windows).
json_fields() {
  if command -v jq >/dev/null 2>&1; then
    local args=() k
    for k in "$@"; do args+=("$k"); done
    jq -rj --args '. as $in | [ $ARGS.positional[] as $k | ($in | first(.. | objects | select(has($k)) | .[$k] | select(type=="string")) // "") ] | join("\u001f")' "${args[@]}" 2>/dev/null
    return 0
  fi
  awk -v keys="$*" '
    function value(key,    pat, i, n, c, e, out) {
      pat = "\"" key "\"[ \t\r\n]*:[ \t\r\n]*\""
      if (!match(doc, pat)) return ""
      i = RSTART + RLENGTH; n = length(doc); out = ""
      while (i <= n) {
        c = substr(doc, i, 1)
        if (c == "\\") {
          i++; e = substr(doc, i, 1)
          if (e == "n") out = out "\n"; else if (e == "t") out = out "\t"
          else if (e == "r") out = out "\r"; else if (e == "b" || e == "f") out = out " "
          else if (e == "u") { out = out "?"; i += 4 } else out = out e
        } else if (c == "\"") break
        else out = out c
        i++
      }
      return out
    }
    BEGIN { RS = "\001" }
    { doc = $0; n = split(keys, k, " ")
      for (j = 1; j <= n; j++) printf "%s%s", (j > 1 ? "\037" : ""), value(k[j]) }'
}

# json_get_bool KEY < json -> prints true|false|"" for the first "KEY": true/false
json_get_bool() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$key" 'first(.. | objects | select(has($k)) | .[$k] | select(type=="boolean")) // empty' 2>/dev/null
    return 0
  fi
  awk -v key="$key" '
    BEGIN { RS = "\001" }
    {
      pat = "\"" key "\"[ \t\r\n]*:[ \t\r\n]*(true|false)"
      if (match($0, pat)) {
        v = substr($0, RSTART, RLENGTH)
        sub(/.*:[ \t\r\n]*/, "", v)
        printf "%s", v
      }
    }'
}

# json_escape STRING -> prints STRING escaped for embedding inside a JSON string
json_escape() {
  printf '%s' "$1" | awk 'BEGIN { RS = "\001" } {
    gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); gsub(/\r/, ""); gsub(/\n/, "\\n"); printf "%s", $0 }'
}
