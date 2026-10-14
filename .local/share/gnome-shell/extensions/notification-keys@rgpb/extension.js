import {Extension, InjectionManager} from 'resource:///org/gnome/shell/extensions/extension.js';
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
    }

    disable() {
        this._injections.clear();
        this._injections = null;
    }
}
