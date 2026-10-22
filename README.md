# ghostty-little-things

It's the little things that make a terminal nice.

I spend most of the day in [Ghostty](https://ghostty.org) on macOS. None of this is a big deal on its own: a cursor that glides instead of jumping, a font that doesn't get in the way, a terminal that drops down from the top of the screen. Together they make the terminal feel like a place I want to be.

The main thing here is a set of **cursor shaders**. Ghostty lets a GLSL shader draw the cursor, so you can give it motion, glow, a blink with some character, or a nod to old terminals.

Tested on Ghostty 1.3.1, macOS, with a dark theme (Night Owl).

## The cursors

Four profiles. They share the same body and differ only in the constants at the top of each file, so tweaking one is just changing numbers.

| Profile | What it looks like | Nods to |
|---|---|---|
| **glide** | White block that slides between cells (ease-out, 140 ms) with a soft fading blink. | The [r/Ghostty smooth cursor post](https://www.reddit.com/r/Ghostty/comments/1wg4p88/ghostty_smooth_cursor_animation_shader/) that started this. |
| **amber** | Warm `#ffb000` block with a soft bloom and a short glide. Instead of a trail, the cell it just left keeps a ~90 ms afterglow, like phosphor fading. | P3 amber phosphor terminals of the VT era. The one I'm on right now. |
| **vt220** | Green `#33ff66` blinking block. No glide: it snaps, with a 20 ms afterglow. The calmest one. | P1 green phosphor and the DEC VT100/VT220 default block cursor. |
| **cocoa** | Cursor in the text colour, quick 80 ms glide, gentle fade blink, no glow. | The classic Mac caret and its blink rate. |

Things they all do, because small details are the point:

- **Blinking stops after ~5.5 s idle** and the cursor stays solid, like Windows does after 5 s. A cursor blinking forever while you read is distracting.
- **Solid while you type**, and it only starts blinking 0.6 s after the last move.
- **Long jumps teleport.** When a TUI repaints or the screen redraws, the cursor jumps without gliding across the screen.
- **The letter under the block stays readable.** It's redrawn in the background colour on top of the lit block.
- **No glide in from the corner** on the first frame after launch.
- **Nothing is drawn for hollow (unfocused) or lock cursors**, so other splits don't show a cursor.

## Install

1. Copy the shaders into your Ghostty config folder:

   ```sh
   mkdir -p ~/.config/ghostty/shaders
   cp shaders/cursor-*.glsl ~/.config/ghostty/shaders/
   ```

2. Add to `~/.config/ghostty/config`. The shader draws the cursor, so Ghostty's own cursor has to be hidden. These two lines go together.

   ```
   cursor-opacity = 0
   custom-shader = "./shaders/cursor-amber.glsl"
   ```

3. Reload with <kbd>⌘</kbd><kbd>⇧</kbd><kbd>,</kbd>.

To undo, delete those two lines.

### Switching profiles (optional)

[`cursor-shader.zsh`](cursor-shader.zsh) is a tiny zsh function that switches profiles and reloads Ghostty for you. Point the config at a symlink instead of a specific file:

```sh
ln -sfn cursor-amber.glsl ~/.config/ghostty/shaders/cursor.glsl
```

```
custom-shader = "./shaders/cursor.glsl"
```

Then source the function from your `~/.zshrc` and:

```sh
cursor-shader          # list profiles, * marks the active one
cursor-shader vt220    # switch and reload
```

The reload goes through Ghostty's AppleScript support. If that isn't available, it tells you to press <kbd>⌘</kbd><kbd>⇧</kbd><kbd>,</kbd>.

### Make your own

Copy a profile and change the constants at the top: colour, glide duration, glow, afterglow, blink timing. Each one has a comment. Name it `cursor-<name>.glsl` and the switcher picks it up.

### Caveats

- **Dark themes only.** To keep the letter under the block readable, the shader treats bright pixels in the cursor cell as text. On a light theme that guess is wrong. `cocoa` also hardcodes Night Owl's foreground colour (`#d6deeb`), so change `CURSOR_COLOR` to match your theme.
- The shaders animate, so Ghostty keeps redrawing while the window is focused. That costs a little GPU time.

## Where the ideas came from

- **thdxg's [`cursor_glide.glsl`](https://gist.github.com/thdxg/e43956748b9f685492011c2e8754080d)**, shared in the [r/Ghostty post](https://www.reddit.com/r/Ghostty/comments/1wg4p88/ghostty_smooth_cursor_animation_shader/). The glide, the easing and the rectangle maths all come from there. I changed the text mask to work with an opaque background, and added the blink, glow, afterglow and teleport.
- **[sahaj-b/ghostty-cursor-shaders](https://github.com/sahaj-b/ghostty-cursor-shaders)** and **abdallahsoliman00's [cursor-smear](https://github.com/abdallahsoliman00/dotfiles/blob/main/ghostty/shaders/cursor-smear.glsl)**: other takes I came across along the way. Worth a look if you want trails and smears.
- **The first version left a bright white trail as it moved**, which was a bit trippy. So I went looking at how cursors used to look, and found that old terminals didn't need a trail: phosphor just faded. That became the afterglow.
  - **Amber and green phosphor.** Amber was often called easier on the eyes. [cool-retro-term](https://github.com/Swordfish90/cool-retro-term) exists to bring this look back, and its default profile is amber. See also [Monochrome monitor](https://en.wikipedia.org/wiki/Monochrome_monitor) and this [CRT phosphor research PDF](https://ww.labguysworld.com/crt_phosphor_research.pdf) for colours and decay times. I stretched the amber decay well past the real thing so you can actually see it.
  - **The VT220 block.** [VT220](https://en.wikipedia.org/wiki/VT220), and the [DECSCUSR](https://vt100.net/docs/vt510-rm/DECSCUSR) cursor styles. The Windows Terminal team [checked their blink against a video of a real VT220](https://www.theregister.com/2020/09/23/windows_terminal_1_4/).
  - **Blink timing.** Raymond Chen on [the Windows caret blink](https://devblogs.microsoft.com/oldnewthing/20240916-00/?p=110272), Microsoft on [flashing UI and `GetCaretBlinkTime`](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/dnacc/flashing-user-interface-and-the-getcaretblinktime-function), and [Mozilla bug 1518196](https://bugzilla.mozilla.org/show_bug.cgi?id=1518196) on caret blink in Firefox. Plus [a short history of the blinking cursor](https://www.inverse.com/innovation/blinking-cursor-history).

Which old cursor is "best" is a matter of taste. These are the ones I liked.

## The font: JetBrains Mono, 15pt

```
font-family = "JetBrains Mono"
font-size = 15
adjust-cell-height = 1
```

I've tried a lot of fonts (CommitMono, Geist Mono, Fira Code, Cascadia Code, Maple Mono, Monaspace, Nordwand, Cozette, a free Berkeley Mono lookalike) and keep coming back to this one. My verdict: *"Feels right, maybe too right."*

Why it works for me:

- **Tall lowercase letters at a normal width.** It reads big at 15pt without making lines wrap sooner.
- **Rounded-rectangle curves.** `o`, `a` and `d` have slightly straight sides, so lines look even and calm without going boxy.
- **Low contrast, no quirks.** Stroke thickness barely changes, and nothing pulls your eye to the letters instead of the code.
- **Characters you can't confuse.** Dotted zero; `l`, `1` and `I` are all clearly different.
- **Mild ligatures.** `->`, `!=` and `>=` join up, but code still looks like what you typed.

Every font I rejected pulled away from neutral in one direction: too playful, too newspapery, too pointy, too square, too narrow. The flip side of "designed to disappear" is that it can feel bland, so CommitMono gets a day now and then.

Two nice things about using it in Ghostty:

- **Ghostty ships JetBrains Mono built in** (it's the default), so there's nothing to install.
- **Ghostty has Nerd Font icons built in as a fallback**, so prompt and `ls` icons work with the plain font. No patched "Nerd Font" version needed.

`adjust-cell-height = 1` adds one pixel of line spacing.

## Other little things in my config

```
# Hide the mouse pointer while typing
mouse-hide-while-typing = true

# Quick terminal: ⌘` from anywhere drops a terminal down from the top. Game changer.
keybind = global:cmd+grave_accent=toggle_quick_terminal
quick-terminal-position = top
quick-terminal-autohide = true

# Jump between shell prompts in the scrollback
keybind = ctrl+shift+up=jump_to_prompt:-1
keybind = ctrl+shift+down=jump_to_prompt:1

# Shift+Enter inserts a newline (handy in Claude Code and other TUIs)
keybind = shift+enter=text:\n

# Clipboard: copy on select, ask before an app reads it, warn on risky pastes
copy-on-select = true
clipboard-read = ask
clipboard-write = allow
clipboard-paste-protection = true

# macOS looks
theme = Night Owl
macos-titlebar-style = tabs
macos-window-shadow = false
macos-icon = chalkboard
```

The global quick-terminal key needs Accessibility permission for Ghostty (macOS asks the first time).

## License

The glide part of the shader body comes from thdxg's gist, which doesn't state a license, so credit goes to them for that. The profiles, tuning and everything else here are mine: take them, change them, share them.
