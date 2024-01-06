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
    public class Widgets.Footer : Gtk.Widget {
        private Gtk.ActionBar main_widget;

        static construct {
            set_layout_manager_type (typeof (Gtk.BinLayout));
        }

        construct {
            hexpand = false;
            add_css_class (Granite.STYLE_CLASS_FLAT);

            var label = new Gtk.Label (_("Airplane Mode")) {
                margin_start = 3
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);


            var airplane_switch = new Gtk.Switch () {
                margin_start = 6,
                margin_top = 6,
                margin_bottom = 6,
                margin_end = 3
            };

            main_widget = new Gtk.ActionBar () {
                hexpand = false
            };
            main_widget.pack_start (label);
            main_widget.pack_end (airplane_switch);
            main_widget.add_css_class (Granite.STYLE_CLASS_FLAT);

            main_widget.set_parent (this);

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

        ~Footer () {
            while (this.get_last_child () != null) {
                this.get_last_child ().unparent ();
            }
        }
    }
}
