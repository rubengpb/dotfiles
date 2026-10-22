# zen

Zen Browser **configuration only**. Never copy anything else from the profile here:
logins, cookies, history, sessions, `prefs.js` and every `*.sqlite`/`*.db`/`*lz4` are
personal data or Zen-generated state (`.gitignore` blocks them as a safety net).

| File | Ends up as (symlink) |
|---|---|
| `user.js` | `<profile>/user.js` |
| `chrome/userChrome.css` | `<profile>/chrome/userChrome.css` |
| `chrome/userContent.css` | `<profile>/chrome/userContent.css` |
| `distribution/policies.json` | `<zen install>/distribution/policies.json` (installs Tridactyl) |
| `../.config/tridactyl/` | `~/.config/tridactyl/` (via `stow`, not this script) |

Files are linked one by one, never the whole `chrome/` folder: Zen Mods write
generated CSS into `chrome/` and it must not land in this repo.

## New machine

```sh
# 1. Zen (official tarball installer, no root)
bash <(curl -s https://updates.zen-browser.app/install.sh)
# 2. Open Zen once and close it: creates the profile.
# 3. Tridactyl native messenger (reads tridactylrc; per machine, not in git)
curl -fsSL https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/install.sh -o /tmp/trinative.sh && sh /tmp/trinative.sh
# 4. Config
cd ~/dotfiles && stow . && scripts/zen-link.sh
```

`scripts/zen-link.sh status` shows what is linked. Re-run `zen-link.sh` after every
Zen reinstall: the installer wipes the install folder (and the policy with it).

## Rules

- Machine-specific prefs (HiDPI scale…) go in `about:config` on that machine, not in `user.js`.
- Never run Tridactyl's `:mktridactylrc`, `:setpref`, `:guiset` or `:fixamo`: they
  write into `tridactylrc`, `user.js` or `userChrome.css`, i.e. into this repo.
- Keyboard shortcuts edited in Zen's settings live in the profile
  (`zen-keyboard-shortcuts.json`) and are not versioned; the agreed layer map is in
  `KEYMAP.md`.
