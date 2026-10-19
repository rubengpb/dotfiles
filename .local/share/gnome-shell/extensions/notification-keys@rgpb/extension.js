import Clutter from 'gi://Clutter';

import {Extension, InjectionManager} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';

export default class NotificationKeysExtension extends Extension {
    enable() {
        this._injections = new InjectionManager();
        const proto = MessageTray.MessageTray.prototype;

        // GNOME creates the banner with can_focus = false, so Super+N focuses
        // its empty container and Delete/Enter never reach the notification.
        this._injections.overrideMethod(proto, '_expandBanner', original => function (autoExpanding) {
            if (!autoExpanding && this._banner)
                this._banner.can_focus = true;
            original.call(this, autoExpanding);
        });

        // GNOME only checks the pointer before hiding the banner; keep it on
        // screen while it holds keyboard focus too.
        this._injections.overrideMethod(proto, '_notificationTimeout', original => function () {
            if (this._notificationFocusGrabber._focused) {
                this._updateNotificationTimeout(1000);
                return;
            }
            original.call(this);
        });

        // The tray (Super+V) already closes the focused message on Delete;
        // Shift+Delete does what its Clear button does. Captured, so the
        // focused message never sees the Delete.
        const dateMenu = Main.panel.statusArea.dateMenu;
        dateMenu.menu.actor.connectObject('captured-event::key', (_actor, event) => {
            if (event.type() !== Clutter.EventType.KEY_PRESS ||
                !(event.get_state() & Clutter.ModifierType.SHIFT_MASK))
                return Clutter.EVENT_PROPAGATE;

            const keysym = event.get_key_symbol();
            if (keysym !== Clutter.KEY_Delete && keysym !== Clutter.KEY_KP_Delete)
                return Clutter.EVENT_PROPAGATE;

            const messageView = dateMenu._messageList._messageView;
            if (messageView.canClear)
                messageView.clear();
            return Clutter.EVENT_STOP;
        }, this);
    }

    disable() {
        Main.panel.statusArea.dateMenu.menu.actor.disconnectObject(this);
        this._injections.clear();
        this._injections = null;
    }
}
