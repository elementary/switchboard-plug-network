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

    public class DeviceList : Gtk.ListBox {
        public signal void row_changed (NM.Device device);
        public NM.Client client;
        
        public DeviceList () {
		    this.selection_mode = Gtk.SelectionMode.SINGLE;
		    this.activate_on_single_click = true;  
		    
		    client = new NM.Client ();
            var devices = client.get_devices ();

            client.device_added.connect ((device) => {
                var item = new DeviceItem (device.get_vendor (), device.get_iface ());
                this.add (item);
            });

		    this.row_selected.connect ((row) => {
			    if (row != null)
			        row_changed (client.get_devices ().get (row.get_index ()));
		    });

		    this.list_devices (devices);		    
		    this.show_all ();      
        }
        
        public void list_devices (GenericArray<NM.Device> devices) {
            for (uint i = 0; i < devices.length; i++) {
                var device = devices.get (i);
                var item = new DeviceItem (device.vendor, device.get_iface ());
                this.add (item);
            }          
        }
        
        public void select_first_item () {
		    var first_row = this.get_row_at_index (0);
		    this.select_row (first_row);
        }        
    }
}
