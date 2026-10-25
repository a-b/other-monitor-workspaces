#!/usr/bin/env bash
# Exercises ./setup and ./teardown against a throwaway HOME. Needs lua. Run: bash tests/setup-test.sh
set -euo pipefail

PLUGIN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ID=a-b.other-monitor-workspaces
fail() { echo "FAIL: $*" >&2; exit 1; }

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
export HOME=$home
unset HYPRLAND_INSTANCE_SIGNATURE
bindings=$home/.config/hypr/bindings.lua
installed=$home/.config/omarchy/plugins/$ID
mkdir -p "$(dirname "$bindings")" "$installed"
cp -r "$PLUGIN_DIR/hypr" "$installed/"
printf -- '-- user line\n' >"$bindings"
cp "$bindings" "$home/original.lua"

# Chords the generated bindings.lua registers, one per line, with stub Omarchy globals.
chords() {
  lua -e 'o = { bind_expressions = {}, workspaces = { focus = function() end },
                bind = function(chord) print(chord) end }' "$bindings"
}
blocks() { grep -cxF -- "-- >>> $ID >>>" "$bindings" || true; }

"$PLUGIN_DIR/setup" >/dev/null
[[ $(blocks) == 1 ]] || fail "setup should add exactly one block"
compgen -G "$bindings.bak.*" >/dev/null || fail "setup should back up bindings.lua"
[[ $(chords | wc -l) == 10 ]] || fail "expected 10 binds"
[[ $(chords | head -n1) == "SUPER + CTRL + SHIFT + code:10" ]] || fail "first bind should be slot 1 (code:10)"
[[ $(chords | tail -n1) == "SUPER + CTRL + SHIFT + code:19" ]] || fail "last bind should be slot 10 (code:19)"

sed -i 's/mods = "SUPER + CTRL + SHIFT"/mods = "SUPER + ALT"/' "$bindings"
"$PLUGIN_DIR/setup" | grep -q "Already set up" || fail "second setup should report it is already set up"
[[ $(blocks) == 1 ]] || fail "second setup should not add another block"
[[ $(chords | head -n1) == "SUPER + ALT + code:10" ]] || fail "mods setting should survive setup and change the chord"

rm -rf "$installed"
[[ -z $(chords) ]] || fail "a removed plugin should bind nothing and raise no error"

"$PLUGIN_DIR/teardown" >/dev/null
cmp -s "$bindings" "$home/original.lua" || fail "teardown should restore the original file"
"$PLUGIN_DIR/teardown" | grep -q "Nothing to remove" || fail "second teardown should be a no-op"

printf -- '-- >>> %s >>>\nkeep me\n' "$ID" >>"$bindings"
cp "$bindings" "$home/broken.lua"
if "$PLUGIN_DIR/teardown" >/dev/null 2>&1; then fail "teardown should refuse a block without its end marker"; fi
cmp -s "$bindings" "$home/broken.lua" || fail "a refused teardown must not change the file"

echo PASS
