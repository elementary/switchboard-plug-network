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
    public class Widgets.Footer : Gtk.Box {
        public Footer (NM.Client client) {
            this.margin = 12;

            var label = new Gtk.Label ("<b>" + _("Airplane Mode") + "</b>");
            label.use_markup = true;

            var airplane_switch = new Gtk.Switch ();

            this.pack_start (label, false, false, 0);
            this.pack_end (airplane_switch, false, false, 0);

            airplane_switch.notify["active"].connect (() => {
                client.networking_set_enabled (!client.networking_get_enabled ());
            });

            if (!airplane_switch.get_active () && !client.networking_get_enabled ()) {
                airplane_switch.activate ();
            }
        }
    }
}
