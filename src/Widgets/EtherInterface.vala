/*-
 * Copyright (c) 2015-2016 elementary LLC.
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
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace Network.Widgets {
    public class EtherInterface : Network.WidgetNMInterface {
        private Gtk.Revealer top_revealer;

        public EtherInterface (NM.Device device) {
            Object (
                device: device,
                icon_name: "network-wired"
            );
        }

        construct {
            info_box.halign = Gtk.Align.CENTER;

            top_revealer = new Gtk.Revealer ();
            top_revealer.valign = Gtk.Align.START;
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (info_box);

            action_area.add (new SettingsButton.from_device (device));

            add (top_revealer);
            show_all ();

            status_switch.bind_property ("active", top_revealer, "reveal-child", GLib.BindingFlags.SYNC_CREATE);
            update ();
        }

        public override void update_name (int count) {
            var name = device.get_description ();

            /* At least for docker related interfaces, which can be fairly common */
            if (name.has_prefix ("veth")) {
                display_title = _("Virtual network: %s").printf (name);
            } else {
                if (count <= 1) {
                    display_title = _("Wired");
                } else {
                    display_title = name;
                }
            }
        }

        public override void update () {
            base.update ();

            switch (device.state) {
                case NM.DeviceState.UNKNOWN:
                case NM.DeviceState.UNMANAGED:
                case NM.DeviceState.FAILED:
                    state = State.FAILED_WIRED;
                    break;

                /* physically not connected */
                case NM.DeviceState.UNAVAILABLE:
                    state = State.WIRED_UNPLUGGED;
                    break;

                /* virtually not working */
                case NM.DeviceState.DISCONNECTED:
                    state = State.DISCONNECTED;
                    break;

                case NM.DeviceState.DEACTIVATING:
                    state = State.FAILED_WIRED;
                    break;

                /* configuration */
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.SECONDARIES:
                    state = State.CONNECTING_WIRED;
                    break;

                /* working */
                case NM.DeviceState.ACTIVATED:
                    state = State.CONNECTED_WIRED;
                    break;
            }
        }
    }
}
