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

 public class WiFiEntry : Gtk.ListBoxRow {
 	private string ssid;
 	private string bssid;
 	private uint strength;

 	private Gtk.Label status;

 	public WiFiEntry.from_access_point (NM.AccessPoint point) {
 		this.ssid = NM.Utils.ssid_to_utf8 (point.get_ssid ());
 		this.bssid = point.get_bssid ();
 		this.strength = point.get_strength ();

 		print ("SSID: %s\n", ssid);
 	}

 	public void setup_row () {
 		var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
 		var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);

 		var title = new Gtk.Label ("<b>%s</b>".printf (ssid));
 		title.get_style_context ().add_class ("h2");
 		status = new Gtk.Label ("");

 		hbox.add (vbox);
 		this.add (hbox);
 	}

 	public void set_point_connected () {
 		status.label = "Connected";
 	}
 }