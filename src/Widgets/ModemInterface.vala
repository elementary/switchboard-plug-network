/*-
 * Copyright (c) 2017 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

namespace Network.Widgets {
    public class ModemInterface : Network.WidgetNMInterface {
        private Gtk.Revealer top_revealer;

        public ModemInterface (NM.Client client, NM.Device device) {
            this.init (device);

            device.state_changed.connect (update);

            info_box.halign = Gtk.Align.CENTER;

            this.icon_name = "network-cellular";

            top_revealer = new Gtk.Revealer ();
            top_revealer.valign = Gtk.Align.START;
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (info_box);

            var settings_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            settings_box.pack_start (new SettingsButton (), false, false, 0);
            settings_box.pack_start (new SettingsButton.from_device (device), false, false, 0);

            add (top_revealer);
            add (settings_box);
            show_all ();

            update ();
        }

        public override void update_name (int count) {
            if (device is NM.DeviceModem) {
                var capabilities = ((NM.DeviceModem)device).get_current_capabilities ();
                if (count > 1) {
                    var name = device.get_description ();
                    if (NM.DeviceModemCapabilities.POTS in capabilities) {
                        display_title = _("Modem: %s").printf (name);
                    } else {
                        display_title = _("Mobile Broadband: %s").printf (name);
                    }
                } else {
                    if (NM.DeviceModemCapabilities.POTS in capabilities) {
                        display_title = _("Modem");
                    } else {
                        display_title = _("Mobile Broadband");
                    }
                }
            } else {
                base.update_name (count);
            }
        }

        public override void update () {
            top_revealer.set_reveal_child (control_switch.active);
            base.update ();

            switch (device.state) {
                case NM.DeviceState.UNKNOWN:
                case NM.DeviceState.UNMANAGED:
                case NM.DeviceState.UNAVAILABLE:
                case NM.DeviceState.FAILED:
                    state = State.FAILED_MOBILE;
                    control_switch.sensitive = false;
                    control_switch.active = false;
                    break;
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.DEACTIVATING:
                    state = State.DISCONNECTED;
                    control_switch.sensitive = true;
                    control_switch.active = false;
                    break;
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.SECONDARIES:
                    state = State.CONNECTING_MOBILE;
                    control_switch.sensitive = true;
                    control_switch.active = true;
                    break;
                case NM.DeviceState.ACTIVATED:
                    state = State.CONNECTED_MOBILE;
                    control_switch.sensitive = true;
                    control_switch.active = true;
                    break;
            }
        }
    }
}
