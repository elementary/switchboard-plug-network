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
	public class DeviceItem : Gtk.ListBoxRow {
		public Gtk.Image row_image;
		private Gtk.Image status_image;
		
		private string title;
		private string subtitle;

		private Gtk.Grid row_grid;
		private Gtk.Label row_title;
		private Gtk.Label row_description;
		private NM.Device device;

		public DeviceItem (string _title, string _subtitle, string icon_name = "network-wired") {
			this.title = _title;
			this.subtitle = _subtitle;

			create_ui (icon_name, true); 
		}

		public DeviceItem.from_device (NM.Device _device, string icon_name = "network-wired") {
			device = _device;
		    title = Utils.type_to_string (device.get_device_type ());
	        subtitle = "";

	    	create_ui (icon_name);
	    	switch_status (device.get_state ());            
		}

		private void create_ui (string icon_name, bool custom = false) {
			row_grid = new Gtk.Grid ();
			row_grid.margin = 6;
			row_grid.column_spacing = 6;
			this.add (row_grid);

	        //TODO: If not connected use icon: "preferences-system-network"
			row_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND);
			row_image.pixel_size = 32;
			row_grid.attach (row_image, 0, 0, 1, 2);

			row_title = new Gtk.Label (title);
			row_title.get_style_context ().add_class ("h3");
			row_title.ellipsize = Pango.EllipsizeMode.END;
			row_title.halign = Gtk.Align.START;
			row_title.valign = Gtk.Align.START;
			row_grid.attach (row_title, 1, 0, 1, 1);

			row_description = new Gtk.Label (subtitle);
			row_description.use_markup = true;
			row_description.ellipsize = Pango.EllipsizeMode.END;
			row_description.halign = Gtk.Align.START;
			row_description.valign = Gtk.Align.START;

			if (!custom) {
				var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
				status_image = new Gtk.Image.from_icon_name ("user-available", Gtk.IconSize.MENU);
				hbox.pack_start (status_image, false, false, 0);
				hbox.pack_start (row_description, true, true, 0);
				row_grid.attach (hbox, 1, 1, 1, 1);
			} else {
				row_grid.attach (row_description, 1, 1, 1, 1);
			}
		}

		public NM.Device? get_item_device () {
			return device;
		}

		public void switch_status (NM.DeviceState state) {
	        switch (state) {
	            case NM.DeviceState.ACTIVATED:
	            	status_image.icon_name = "user-available";
	            	break;
	            case NM.DeviceState.DISCONNECTED:
	            	status_image.icon_name = "user-busy";
	            	break;
	            case NM.DeviceState.UNMANAGED:
	            	status_image.icon_name = "user-invisible";
	            	break;
	            default:
	            	if (Utils.state_to_string (device.get_state ()) == "Unknown")
	            		status_image.icon_name = "user-offline";
	            	else	
	            		status_image.icon_name = "user-away";
	            	break;
	        }

	        row_description.label = Utils.state_to_string (state);
		}
	}
}
