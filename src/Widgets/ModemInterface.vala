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
    public class ModemInterface : AbstractModemInterface {
        private Gtk.Revealer top_revealer;

        public ModemInterface (NM.Client client, NM.RemoteSettings settings, NM.Device device) {
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

        public override void update () {
            top_revealer.set_reveal_child (control_switch.active);
            base.update ();
        }
    }
}
