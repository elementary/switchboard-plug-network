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
        public signal void row_changed (NM.Device device, Gtk.ListBoxRow row);
        public signal void show_no_devices (bool show);
        public NM.Client client;
        public DeviceItem wifi = null;

        private int wifi_index;
        private DeviceItem[] items = {};
        private DeviceItem item;

        public DeviceList () {
	        this.selection_mode = Gtk.SelectionMode.SINGLE;
		    this.activate_on_single_click = true;  
            //this.set_header_func (update_headers);
		    
		    client = new NM.Client ();
            var devices = client.get_devices ();

            client.device_added.connect ((device) => {
                add_device_to_list (device);
                if (items.length == 1)
                    this.show_no_devices (false);
                this.selected_rows_changed ();
                this.show_all ();
            });

            client.device_removed.connect ((device) => {
                foreach (var item in items) {
                    if (item.get_item_device () == device) {
                        remove_row_from_list (item);
                    }
                }

                if (items.length == 0)
                    this.show_no_devices (true);
            });
        
            this.row_selected.connect ((row) => {
			    if (row != null) {
                    if (wifi == null || row.get_index () != wifi_index) 
			            row_changed (client.get_devices ().get (row.get_index ()), row);
                    else
                        wifi.activate ();
                }            
		    });

            if (items.length > 0)
                this.show_no_devices (false);
            else
                this.show_no_devices (true);
                
		    this.list_devices (devices);		    
		    this.show_all ();      
        }
      
        public DeviceItem[] get_items () {
            return items;
        }

        private void list_devices (GenericArray<NM.Device> devices) {
            for (uint i = 0; i < devices.length; i++) {
                var device = devices.get (i);     

                add_device_to_list (device); 
            }  
        }

        private void add_device_to_list (NM.Device device) {
            if (device.get_managed ()) {
                if (device.get_iface ().has_prefix ("usb")) {
                    item = new DeviceItem.from_device (device, "phone");
                } else { 
                    item = new DeviceItem.from_device (device);  
                } 

                items += item;
                this.add (item);    
            }
        }

        public void remove_row_from_list (DeviceItem item) {
            DeviceItem[] new_items = {};  
            foreach (var list_item in items) {
                if (list_item != item)
                    new_items += item;    
            }

            this.remove (item);
            this.select_row (this.get_row_at_index (0));
            items = new_items;
        }

        public void create_wifi_entry () {
            wifi = new DeviceItem ("Wireless network", "Wi-Fi", "network-wireless");  
            this.add (wifi); 
            wifi_index = wifi.get_index ();              
        }
        
        public void select_first_item () {
		    var first_row = this.get_row_at_index (0);
		    this.select_row (first_row);
        }  

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow before) {
        }      
    }
}
