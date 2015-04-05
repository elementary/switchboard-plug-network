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

public class Network.Widgets.DeviceItem : Gtk.ListBoxRow {
	public Gtk.Image row_image;
	
	private string title;
	private string subtitle;

	private Gtk.Grid row_grid;
	private Gtk.Label row_title;
	private Gtk.Label row_description;

	public DeviceItem (string iface, string devname, string icon_name = "network-wired") {
	    title = iface;
        subtitle = devname;
	            
    	create_ui (icon_name);
	}

	private void create_ui (string icon_name) {
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

		row_grid.attach (row_description, 1, 1, 1, 1);
	}
}
