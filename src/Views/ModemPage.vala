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
    public class ModemInterface : Network.Widgets.Page {
        private Gtk.Revealer top_revealer;

        public ModemInterface (NM.Device device) {
            Object (
                activatable: true,
                device: device,
                icon_name: "network-cellular"
            );

            device.state_changed.connect (update);

            info_box.halign = Gtk.Align.CENTER;

            top_revealer = new Gtk.Revealer () {
                valign = Gtk.Align.START,
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                child = info_box
            };

            content_area.attach_next_to (top_revealer, null, Gtk.PositionType.BOTTOM);

            action_area.append (new SettingsButton ());
            action_area.append (new SettingsButton.from_device (device));

            update ();
        }

        public override void update_name (int count) {
            if (device is NM.DeviceModem) {
                var capabilities = ((NM.DeviceModem)device).get_current_capabilities ();
                if (count > 1) {
                    var name = device.get_description ();
                    if (NM.DeviceModemCapabilities.POTS in capabilities) {
                        title = _("Modem: %s").printf (name);
                    } else {
                        title = _("Mobile Broadband: %s").printf (name);
                    }
                } else {
                    if (NM.DeviceModemCapabilities.POTS in capabilities) {
                        title = _("Modem");
                    } else {
                        title = _("Mobile Broadband");
                    }
                }
            } else {
                base.update_name (count);
            }
        }

        public override void update () {
            top_revealer.set_reveal_child (status_switch.active);
            base.update ();

            state = device.state;

            switch (device.state) {
                case NM.DeviceState.UNKNOWN:
                case NM.DeviceState.UNMANAGED:
                case NM.DeviceState.UNAVAILABLE:
                case NM.DeviceState.FAILED:
                    status_switch.sensitive = false;
                    status_switch.active = false;
                    break;
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.DEACTIVATING:
                    status_switch.sensitive = true;
                    status_switch.active = false;
                    break;
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.SECONDARIES:
                    status_switch.sensitive = true;
                    status_switch.active = true;
                    break;
                case NM.DeviceState.ACTIVATED:
                    status_switch.sensitive = true;
                    status_switch.active = true;
                    break;
            }
        }
    }
}
