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

namespace Network.Widgets {
	public class WiFiEntry : Gtk.ListBoxRow {
	    public NM.AccessPoint? ap;	    
		public string ssid;
		
		private string bssid;
		private uint strength;

		private Gtk.Label title;

		public WiFiEntry.from_access_point (NM.AccessPoint? point) {
		    ap = point;
			this.ssid = NM.Utils.ssid_to_utf8 (ap.get_ssid ());
			this.bssid = ap.get_bssid ();
			this.strength = ap.get_strength ();

			// For debugging purposes
			print ("SSID: %s, STRENGTH: %u\n", ssid, strength);

			var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

			title = new Gtk.Label (ssid);
			title.halign = Gtk.Align.START;
			title.use_markup = true;

			title.get_style_context ().add_class ("h3");

			hbox.add (title);
			this.add (hbox);
			this.show_all (); 		
		}

		public void set_point_connected (bool connected) {
			if (connected)
	 			title.label = title.get_label () + SUFFIX + "(" + Utils.state_to_string (NM.DeviceState.ACTIVATED) + ")";
	 		else
				title.label = ssid;
		}
	}
}
