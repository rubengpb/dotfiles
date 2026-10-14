// Zen Browser preferences — shared by every machine.
// Linked into the active profile by scripts/zen-link.sh. Zen reads this file on
// every start and it wins over prefs.js; Zen never writes to it.
// Machine-specific tweaks (e.g. HiDPI scale) go in about:config on that machine,
// not here. Only prefs that differ from Zen's defaults belong here.

// --- Dotfiles plumbing -------------------------------------------------------
// Load chrome/userChrome.css and chrome/userContent.css.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Mozilla Sync must never carry preferences: this file is the single source of truth.
user_pref("services.sync.engine.prefs", false);
user_pref("services.sync.prefs.sync-seen", true);
// Fresh machines skip the onboarding screens.
user_pref("zen.welcome-screen.seen", true);

// --- Calm: no nagging, no suggestions ----------------------------------------
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
// AI tab grouping suggestions.
user_pref("browser.tabs.groups.smart.enabled", false);

// --- Privacy (telemetry, studies and data reporting are already off in Zen) -
// Upgrade every connection to HTTPS; Zen asks before loading plain HTTP.
user_pref("dom.security.https_only_mode", true);
// Passwords, cards and addresses live in a password manager, never in the profile.
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
user_pref("signon.generation.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);
user_pref("extensions.formautofill.addresses.enabled", false);

// --- Keyboard ----------------------------------------------------------------
// A lone Alt press must not focus the menu bar: Alt is the Zen shortcut layer.
user_pref("ui.key.menuAccessKeyFocuses", false);
// Ctrl+Tab cycles tabs by recent use, like Alt+Tab does with windows.
user_pref("browser.ctrlTab.sortByRecentlyUsed", true);

// --- Dark --------------------------------------------------------------------
// Ask websites for their dark theme (0 = dark, 1 = light, 2 = follow browser).
user_pref("layout.css.prefers-color-scheme.content-override", 0);
// Blank page colour while a site loads in dark mode: no white flash.
user_pref("browser.display.background_color.dark", "#1E1D2F");

// --- Zen look: calm, minimal (colours live in chrome/userChrome.css) ---------
// 0 = always dark, 1 = light, 2 = follow the system.
user_pref("zen.view.window.scheme", 0);
// Start in compact mode: sidebar and toolbar hidden until needed.
user_pref("zen.view.compact.enable-at-startup", true);
// Web content edge to edge, no gap or rounded frame around it.
user_pref("zen.theme.content-element-separation", 0);
user_pref("zen.theme.border-radius", 0);
user_pref("zen.watermark.enabled", false);
user_pref("zen.view.show-clear-tabs-button", false);

// --- Alt layer ---------------------------------------------------------------
// Alt+letter is free for Zen shortcuts (KEYMAP.md): no hidden menu bar access
// keys stealing it (Alt+H would open Help).
user_pref("ui.key.menuAccessKey", 0);
