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
    public class DevicePage : Network.WidgetNMInterface {

        public DevicePage (NM.Client client, NM.RemoteSettings settings, NM.Device _device) {
            this.init (device);

            bottom_revealer.transition_type = Gtk.RevealerTransitionType.NONE;

            this.icon_name = "network-wired";
            display_title = Utils.type_to_string (device.get_device_type ());

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_end (new SettingsButton.from_device (device), false, false, 0);

            update ();

            bottom_box.pack_start (info_box, true, true);
            bottom_box.pack_end (details_box, false, false);

            pack_start (bottom_revealer, true, true);
            this.show_all ();
        }

        public DevicePage.from_owner (DeviceItem? owner) {
            this.init (owner.get_item_device ());

            this.icon_name = owner.get_item_icon_name ();
            display_title = Utils.type_to_string (device.get_device_type ());

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_start (new SettingsButton.from_device (device), false, false, 0);

            update ();

            this.add (info_box);
            this.pack_end (details_box, false, false, 0);
            this.show_all ();
        }
    }
}
