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

namespace Network {
    public class Widgets.Footer : Gtk.ActionBar {
        construct {
            hexpand = false;
            get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

            var label = new Gtk.Label (_("Airplane Mode"));
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            label.margin_start = 6;

            var airplane_switch = new Gtk.Switch ();
            airplane_switch.margin = 12;
            airplane_switch.margin_end = 6;

            this.pack_start (label);
            this.pack_end (airplane_switch);

            unowned NetworkManager network_manager = NetworkManager.get_default ();
            unowned NM.Client client = network_manager.client;
            airplane_switch.notify["active"].connect (() => {
                try {
                    client.networking_set_enabled (!airplane_switch.active);
                } catch (Error e) {
                    warning (e.message);
                }
            });

            if (!airplane_switch.get_active () && !client.networking_get_enabled ()) {
                airplane_switch.activate ();
            }
        }
    }
}
