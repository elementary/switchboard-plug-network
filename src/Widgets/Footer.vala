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
    public class Footer : Gtk.ActionBar {
        private Gtk.Switch airplane_switch;

        construct {
            this.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

            var label = new Gtk.Label (_("Airplane Mode"));
            label.get_style_context ().add_class ("h4");
            label.margin_start = 6;

            airplane_switch = new Gtk.Switch ();
            airplane_switch.margin = 12;
            airplane_switch.margin_end = 6;

            var client = DeviceManager.get_default ().client;
            airplane_switch.active = !client.networking_get_enabled ();

            this.pack_start (label);
            this.pack_end (airplane_switch);

            airplane_switch.notify["active"].connect (on_active_changed);
        }

        private void on_active_changed () {
            var client = DeviceManager.get_default ().client;

            try {
                client.networking_set_enabled (!airplane_switch.get_active ());
            } catch (Error e) {
                warning ("Could not set networking state: %s".printf (e.message));
            }
        }
    }
}
