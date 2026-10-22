# cursor-shader [name]: switch the Ghostty cursor shader profile and reload (no arg: list, * = active)
# Profiles are ~/.config/ghostty/shaders/cursor-<name>.glsl; the config points at the cursor.glsl link.
cursor-shader() {
  local dir=~/.config/ghostty/shaders f n
  if (( ! $# )); then
    for f in $dir/cursor-*.glsl; do
      n=${${f:t:r}#cursor-}
      [[ $(readlink $dir/cursor.glsl) == ${f:t} ]] && print "* $n" || print "  $n"
    done
    return
  fi
  [[ -f $dir/cursor-$1.glsl ]] || { print -u2 "cursor-shader: no profile '$1' (run cursor-shader to list)"; return 1; }
  ln -sfn cursor-$1.glsl $dir/cursor.glsl
  osascript -e 'tell application "Ghostty" to perform action "reload_config" on focused terminal of selected tab of front window' &>/dev/null \
    && print "cursor-shader: $1" \
    || print "cursor-shader: $1 (press Cmd+Shift+, to reload)"
}
