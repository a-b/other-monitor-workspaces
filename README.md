# Other Monitor Workspaces

`SUPER + CTRL + SHIFT + 1..0` switches the monitor you are *not* focused on to its workspace N, numbered the way that monitor's bar numbers it (`0` is slot 10). Your keyboard focus can stay where it is, or follow to the other monitor.

## Requirements

- Omarchy 4.5 or newer (per-monitor workspaces, `o.workspaces`). On older Omarchy the plugin binds nothing.
- Omarchy's Lua Hyprland config, with `~/.config/hypr/bindings.lua`.

Tested on Omarchy 4.5.0rc1 with Hyprland 0.56.2.

## Install

1. Add the plugin:

   ```bash
   omarchy plugin add https://github.com/a-b/other-monitor-workspaces.git
   ```

   This puts it at `~/.config/omarchy/plugins/a-b.other-monitor-workspaces`. `--enable` is not needed; see below.
2. Run:

   ```bash
   ~/.config/omarchy/plugins/a-b.other-monitor-workspaces/setup
   ```

   This adds a small marked block to the end of `~/.config/hypr/bindings.lua` (a backup is saved next to it) and reloads Hyprland.

Enabling or disabling the plugin in Omarchy has no effect. Omarchy has no way for a plugin to add Hyprland keybindings, and every Omarchy plugin must declare a kind, so the plugin ships an empty service. `setup` and `teardown` are what turn the keys on and off.

## Settings

Change the settings in the block in `~/.config/hypr/bindings.lua`, then run `hyprctl reload`. Running `setup` again never overwrites them.

| Setting | Default | Meaning |
|---|---|---|
| `selectors` | `{ "+1" }` | Which monitor counts as "other". An ordered list of Hyprland monitor selectors, relative to the focused monitor. The first one that resolves to a different, non-mirrored monitor wins; if none does, the keys do nothing. Entries: `"+1"` / `"-1"` for the next / previous monitor, wrapping (what `CTRL + ALT + TAB` uses); `"l"`, `"r"`, `"u"`, `"d"` for the monitor in that direction of the layout; `"desc:<EDID description>"` for one fixed screen. List descriptions with `hyprctl monitors -j \| jq -r '.[].description'`. |
| `keep_focus` | `true` | `true`: keyboard focus, the active window and the pointer stay where they are. `false`: they move to the other monitor, like clicking its bar. With `false`, pressing the keys again targets the monitor you started on, since it is now the "other" one. |
| `mods` | `"SUPER + CTRL + SHIFT"` | The modifier chord in front of `1..0`. |

The default works with any two monitors, whatever their make or connector: you only need other selectors with three or more screens, or to pin one screen.

Examples:

```lua
selectors = { "r", "l", "+1" }, -- the screen to the right, else the left one, else the next one
selectors = { "desc:<external monitor description>", "desc:<built-in panel description>" },
```

With that `desc:` pair, the keys switch the external monitor while you work on any other screen, and the built-in panel while you work on the external one. Replace the placeholders with descriptions from the command above.

## Behaviour by setup

| Monitors | "Other" monitor with the default `{ "+1" }` |
|---|---|
| One | None; the keys do nothing. |
| Two | The one you are not focused on. |
| Three or more | The next one in Hyprland's monitor list. That is detection order, not desk position; use directions or `desc:` entries to control it. |
| Mirrored | A mirror is skipped. |

Tested with two monitors. Three or more monitors, mirrored monitors and `desc:` selectors follow from the code above but are untested; reports are welcome.

## Run from a terminal

```bash
hyprctl dispatch 'focus_other_monitor_workspace(3)'
```

## Conflicts

`vladgabrielboca.monitor-workspaces` binds the same chord to move windows. If you use both, change `mods` here.

## Uninstall

```bash
~/.config/omarchy/plugins/a-b.other-monitor-workspaces/teardown
omarchy plugin remove a-b.other-monitor-workspaces
```

If you remove the plugin without running `teardown` first, the block left in `bindings.lua` is inert: it raises no errors, and the keys are gone after the next reload.

## How it works

Each key calls Omarchy's own `o.workspaces.focus(slot, monitor)`, the same call a bar click makes, so reclaiming and creating workspaces behave exactly as stock.
With `keep_focus`, it then re-focuses the window you were on and moves the pointer back to where it was.
That order matters: focusing warps the pointer, and `hl.dsp.cursor.move` does not refocus the window under it.

## Tests

```bash
bash tests/setup-test.sh
```

Needs `lua`. It runs `setup` and `teardown` against a throwaway home directory.

## License

MIT
