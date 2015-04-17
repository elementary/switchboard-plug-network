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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

namespace Network {

	public class Widgets.Footer : Gtk.Box {
		public signal void on_switch_mode (bool switched);

		public Footer (NM.Client client) {
			this.margin_top = 12;
			this.margin_bottom = 12;
			this.margin_start = 12;

            var plane_symbolic = new Gtk.Image.from_icon_name ("airplane-mode-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            plane_symbolic.margin_end = 10;

			var airplane_switch = new Gtk.Switch ();
			airplane_switch.halign = Gtk.Align.END;

            this.pack_end (airplane_switch, false, false, 0);
			this.pack_end (plane_symbolic, false, false, 0);

			airplane_switch.notify["active"].connect (() => {
				this.on_switch_mode (airplane_switch.get_active ());
			});		
			
            if (!airplane_switch.get_active () && !client.networking_get_enabled ())
                airplane_switch.activate ();		    					  
		}
	}
}			
