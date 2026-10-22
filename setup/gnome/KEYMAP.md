# GNOME keymap

One rule: **each modifier belongs to one owner**. Every system shortcut starts
with `Super`; `Ctrl` is left to the applications, so GNOME never steals their
keys. Check this file before binding anything system-wide.

| Layer | Owner |
|---|---|
| `Super` | GNOME: windows, workspaces, apps, system |
| `Alt+Tab`, `Alt+Esc`, `Alt+<`, `Alt+º` | GNOME switchers |
| any other `Alt` | applications (Zen's layer: [`zen/KEYMAP.md`](../../zen/KEYMAP.md)) |
| `Ctrl`, `Ctrl+Shift`, `Ctrl+Alt` | applications |

GNOME keeps only three `Ctrl` keys: `Ctrl+Shift+Esc` system monitor,
`Ctrl+Alt+Del` log out, `Ctrl+Alt+F1…F12` text consoles. The old `Alt+F2`,
`Alt+F7`/`F8`, `Alt+space` and the `Print` keys stay as GNOME ships them.

## Shortcuts

### Apps
| Keys | Action |
|---|---|
| `Super+a` | Alacritty (attaches to the running tmux session) |
| `Super+Shift+t` | terminal (Ptyxis) |
| `Super+f` `Super+d` `Super+z` | Firefox / Brave / Zen |
| `Super+g` | home folder |
| `Ctrl+Shift+Esc` | system monitor |

Each press opens a new window.

### Windows
| Keys | Action |
|---|---|
| `Super+x` `Super+r` `Super+h` | close / maximize / minimize |
| `Super+↓` | restore |
| `Super+←/→` | half screen |
| `Super+Shift+arrows` | move to another monitor |
| `Super+t` | tile it on the grid (Tactile) |
| `Super+j` | find a window by name (Switcher) |
| `Alt+Tab` `Alt+<` `Alt+º` | switch window / app / window of the same app |

### Workspaces
| Keys | Action |
|---|---|
| `Super+u/i/o/k` `Super+l` | workspace 1–4 / last |
| `Super+Shift+u/i/o/k/l` | move the window there |
| `Super+Alt+←/→`, `Super+Page_Up/Down` | previous / next (`+Shift`: take the window) |
| `Super+Ctrl+Alt+←/→` | reorder workspaces (space-bar) |

### System
| Keys | Action |
|---|---|
| `Super`, twice | overview, app grid |
| `Super+s` `Super+Shift+s` | quick settings / Settings |
| `Super+v` (or `Super+m`) | notification tray (`Shift+Delete` clears it) |
| `Super+n` | focus the visible notification (`Delete` dismisses, `Enter` opens) |
| `Super+c` (or `Print`) `Super+Shift+c` | screenshot / screen recording |
| `Super+-` | hide / show the top bar |
| `Super+space` `Super+p` | keyboard layout / displays |
| `Super+Shift+'` | lock the screen |
| `Super+1..9` | app N of the dash (`+Ctrl`: new window) |

### Session
| Keys | Action |
|---|---|
| `Super+q` `Super+w` | shut down / reboot |
| `Ctrl+Alt+Del` | log out |
| `Ctrl+Alt+F1…F12` | text console (back to the desktop: the one the session runs on, usually `F2`) |

The session dialogs cancel with `Esc` and confirm themselves after 60 s.

Known clash, left as is: `Super+o` is also rotation lock (the workspace wins).

## Where they live

| Shortcuts | File in `setup/gnome/` |
|---|---|
| windows, workspaces, switchers | `desktop.dconf` (`[wm/keybindings]`) |
| screenshot, app grid, notifications | `shell-keybindings.dconf` |
| launchers (`custom-keybindings`), session, Settings, home | `settings-daemon.dconf` |
| Tactile, Switcher, space-bar; top bar hidden | `extensions.dconf` |

Change them live with `gsettings`, then run `setup/gnome/save.sh`. GNOME grabs a
key when its binding is set: if another binding still holds that key, the grab
fails and is never retried. Free the key first, or set the binding again once
it is free.
