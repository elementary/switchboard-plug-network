// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-network-plug)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com
 */

namespace Network {
    public class Widgets.Footer : Gtk.ActionBar {
        public Footer (NM.Client client) {
            this.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

            var label = new Gtk.Label (_("Airplane Mode"));
            label.get_style_context ().add_class ("h4");
            label.margin_start = 6;

            var airplane_switch = new Gtk.Switch ();
            airplane_switch.margin = 12;
            airplane_switch.margin_end = 6;

            this.pack_start (label);
            this.pack_end (airplane_switch);

            airplane_switch.notify["active"].connect (() => {
                client.networking_set_enabled (!client.networking_get_enabled ());
            });

            if (!airplane_switch.get_active () && !client.networking_get_enabled ()) {
                airplane_switch.activate ();
            }
        }
    }
}
