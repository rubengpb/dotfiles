# Zen keymap

One rule: **each modifier belongs to one owner**. A new shortcut goes in its
owner's layer, never in another's; check this file before binding anything.

| Layer | Owner | Examples |
|---|---|---|
| `Super` | GNOME: windows, workspaces, apps | `Super+c` close, `Super+u/i/o/k/l` workspaces |
| `Ctrl+Shift` | GNOME system actions | `s` settings, `h` home, `w` **reboot**, `q` **shutdown**, `b` browser, `Esc` monitor |
| `Ctrl+Alt` | GNOME launchers and arrows | `t`/`a` terminals, `←/→` workspaces |
| `Ctrl` | Browser standard (same in every browser) | `Ctrl+T/W/L/F/R/Tab/Q` |
| `Alt` | **Zen** (custom bindings go here) | `Alt+h/l` spaces, `Alt+n` new space, `Alt+c` compact, `Alt+v/-/g/x` split |
| none | **Tridactyl**, inside web pages | `f`, `/`, `J/K`, `o` |

Mechanics behind it:
- `user.js`: `ui.key.menuAccessKey = 0` and `ui.key.menuAccessKeyFocuses = false`,
  so Alt is never eaten by the hidden menu bar.
- `keymap.json`: Zen shortcut overrides, applied by `scripts/zen-link.sh`.
- `.config/tridactyl/tridactylrc`: in-page keys.

## Conflicts found (2026-10-09)

GNOME grabs these before Zen sees them, so the Zen action is unreachable:

| Keys | GNOME | Zen action lost | Resolution |
|---|---|---|---|
| `Ctrl+Alt+←/→` | switch workspace | switch space | Zen moved to `Alt+h/l` |
| `Ctrl+Shift+W` | **reboot** | close window / DOM devtool | use `Ctrl+Q` or `Super+c` (see below) |
| `Ctrl+Shift+S` | settings | screenshot | Tridactyl / GNOME `Print` |
| `Ctrl+Shift+H` | home folder | history library | `Ctrl+H` (history sidebar) |
| `Ctrl+Shift+B` | browser | bookmarks toolbar | not used (minimal UI) |

Pre-existing GNOME clashes (not browser related, untouched): `Super+o` is both
workspace 3 and rotation lock; `Super+w` is both switcher and space-bar's menu.

⚠️ Muscle memory from other browsers: `Ctrl+Shift+W` / `Ctrl+Shift+Q` reboot / shut
down this machine. Consider moving those two GNOME actions to the `Super` layer.

## Cheat sheet

### The grammar
- **No modifier = Tridactyl, vim style.** A letter is a verb; a prefix is a family:
  `y` copy · `g` go / tab tools · `;` act on a hint · `m` `'` marks.
- **lowercase asks, Uppercase reuses the current page**: `o`/`O`, `t`/`T`, `w`/`W`.
- **Destination by letter**: `o` here · `t` new tab · `w` new window.
- **`Alt` = Zen structure** (spaces, sidebar, split view, tab slots).
- **`Ctrl` = editing and browser standard** (`Ctrl+i` nvim, `Ctrl+d/u` scroll).

### Move inside a page
| Keys | Action |
|---|---|
| `j` `k` `h` `l` | scroll |
| `Ctrl+d` `Ctrl+u` | half page down / up |
| `gg` `G` | top / bottom |
| `/` `?` → `n` `N` | find forward / backward, next / previous |
| `,` `Space` | clear find highlight |
| `m<x>` `'<x>` | set / jump to mark x |
| `H` `L` | back / forward |
| `gn` `gp` | next / previous page of a paginated site |
| `gu` `gU` | parent URL / site root |
| `gi` | first text field |

### Open and search
| Keys | Action |
|---|---|
| `o` `t` `w` + text | open or search here / new tab / new window |
| `O` `T` `W` | same, starting from the current URL (`T` ≈ duplicate, `W` = this page in a new window) |
| `o gh …` | search engine keywords: `g` google, `gh` github, `yt`, `mdn`, `w` wikipedia (default: duckduckgo) |
| `p` `P` | open the copied URL here / new tab |
| `f` `F` | follow link here / background tab |
| `;t` `;w` | follow link in new tab / new window |

### Copy (y = yank)
| Keys | Copies |
|---|---|
| `yy` | page URL |
| `yt` | page title |
| `ym` | page as Markdown `[title](url)` |
| `;y` | a link's URL (hint) |
| `;p` | an element's text (hint) |
| `v` → move → `y` | precise selection in visual mode (`w b e 0 $ o`) |

### Tabs
| Keys | Action |
|---|---|
| `J` `K` | next / previous (down / up the sidebar) |
| `g0` `g$` | first / last |
| `b` | jump to a tab by name (`B`: all windows) |
| `d` `u` | close / undo close |
| `gd` | duplicate (keeps history) |
| `gx` | detach to a new window |
| `<<` `>>` | move up / down |
| `Alt+p` `Alt+m` | pin / mute |
| `Alt+1..9` | tab by position |

### Zen structure (Alt)
| Keys | Action |
|---|---|
| `Alt+h` `Alt+l` | previous / next space |
| `Alt+n` | new space |
| `Alt+c` | compact mode on / off |
| `Alt+s` | peek the sidebar (in compact mode) |
| `Alt+v` `Alt+-` `Alt+g` | split vertical / horizontal / grid |
| `Alt+x` | unsplit |

### Windows (browser standard + GNOME)
| Keys | Action |
|---|---|
| `Ctrl+N` | new window (`Ctrl+Shift+P` private) |
| `Alt+Tab` / `Super` | switch windows / overview |
| `Ctrl+Q` | quit Zen |

### Text fields and escape hatches
| Keys | Action |
|---|---|
| `Esc` | leave insert mode / close the command line |
| `Ctrl+i` (in a field) | edit in nvim, `:wq` sends it back |
| `Shift+Insert` | ignore mode (site gets every key); again to leave |
| `Ctrl+L` | Zen url bar (works where Tridactyl cannot: `about:*`, new tab) |
| `Ctrl+S` | save page (standard again; compact mode moved to `Alt+c`) |
| `:help` / `:tutor` | Tridactyl help / interactive tutorial |

### Keys Tridactyl takes over (normal mode, inside web pages only)
In a text field (insert mode) these keep their usual meaning.

| Keys | Tridactyl | Browser meaning you lose there | Use instead |
|---|---|---|---|
| `Ctrl+f` `Ctrl+b` | page down / up | find, bookmarks sidebar | `/` to find |
| `Ctrl+d` `Ctrl+u` | half page down / up | bookmark page, view source | `A` bookmark, `gf` source |
| `Ctrl+o` `Ctrl+i` | jump back / forward | Zen Glance, page info | — |
| `Ctrl+a` `Ctrl+x` | increment / decrement number in URL | select all, cut | (fine in text fields) |
| `Ctrl+v` | next key goes to the site | paste | (fine in text fields) |
| `Ctrl+e` `Ctrl+y` | scroll lines | — | — |

### Known overlap inside Zen
`Ctrl+Shift+K` is both "close all unpinned tabs" (Zen) and the web console
(devtools). Prefer `F12` for devtools.

## Habits worth building

1. Mouse-free by default: `f` to click, `gi` to type, `Esc` to get out.
2. Find before scrolling: `/word` + `n` beats `j j j j`.
3. `b` (tab by name) instead of hunting with `J/K` once you have 5+ tabs.
4. One space per context (work, personal, study) and `Alt+h/l` between them.
5. Close tabs aggressively (`d`); `u` brings back a mistake.
6. Learn one new key per day from `:help`, add it here when it sticks.
7. New shortcut? Pick its layer from the table above first; never bind on
   `Super`, `Ctrl+Shift` or a GNOME `Ctrl+Alt` key.
8. Sites with their own keyboard shortcuts (Gmail, GitHub): `Shift+Insert`
   instead of fighting them.
