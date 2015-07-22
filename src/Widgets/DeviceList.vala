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

namespace Network.Widgets {
    public class DeviceList : Gtk.ListBox {
        public signal void row_changed (Gtk.ListBoxRow row);
        public signal void show_no_devices (bool show);
        public signal void wifi_device_detected (NM.DeviceWifi? d);
        
        public NM.Client client;
        public DeviceItem wifi = null;
        public DeviceItem proxy;

        private List<DeviceItem> items;
        private DeviceItem item;
        private GenericArray<NM.Device> devices;

        private Gtk.Label settings_l;
        private Gtk.Label devices_l;

        public DeviceList (NM.Client _client) {
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            this.activate_on_single_click = true;  
            this.set_header_func (update_headers);

            client = _client;
            items = new List<DeviceItem> ();

            settings_l = new Gtk.Label ("<b>" + _("Virtual") + "</b>");
            settings_l.margin = 7;
            settings_l.get_style_context ().add_class ("category-label");
            settings_l.sensitive = false;
            settings_l.use_markup = true;
            settings_l.halign = Gtk.Align.START;

            devices_l = new Gtk.Label ("<b>" + _("Devices") + "</b>");
            devices_l.margin = 7;
            devices_l.get_style_context ().add_class ("category-label");
            devices_l.sensitive = false;
            devices_l.use_markup = true;
            devices_l.halign = Gtk.Align.START;

            devices = client.get_devices ();
            client.device_added.connect ((device) => {
                add_device_to_list (device);

                if (items.length () == 1)
                    this.show_no_devices (false);
                this.selected_rows_changed ();
                this.show_all ();
            });

            client.device_removed.connect ((device) => {
                foreach (var item in items) {
                    if (item.get_item_device () == device)
                        this.remove_row_from_list (item);
                }

                if (items.length () == 0)
                    this.show_no_devices (true);
            });
        
            this.row_selected.connect ((row) => {
                if (row != null) {
                    if (row == proxy) {
                        proxy.activate ();
                        return;
                    }

                    if (wifi == null || row != wifi) {
                        row_changed (row);
                    } else if (wifi != null && row == wifi) {
                        wifi.activate ();
                    }
                }
            });

            bool show = (items.length () > 0);
            this.show_no_devices (!show);
        }

        public void init () {
            this.list_devices (devices);
            this.show_all ();
        }

        private void list_devices (GenericArray<NM.Device> devices) {
            for (uint i = 0; i < devices.length; i++) {
                var device = devices.get (i);
                add_device_to_list (device);
            }
        }

        private void add_device_to_list (NM.Device device) {
            if (device.get_device_type () == NM.DeviceType.WIFI) {
                this.wifi_device_detected (device as NM.DeviceWifi);
                return;
            }

            if (device.get_managed ()) {
                if (device.get_iface ().has_prefix ("usb")) {
                    item = new DeviceItem.from_device (device, "drive-removable-media");
                } else {
                    item = new DeviceItem.from_device (device);
                }

                items.append (item);
                if (items.length () -1 == 0) {
                    this.insert (item, int.parse ((items.length () - 1).to_string ()));
                } else {
                    this.insert (item, 1);
                }
            }
        }

        public void remove_row_from_list (DeviceItem item) {
            var new_items = new List<DeviceItem> ();
            foreach (var list_item in items) {
                if (list_item != item)
                    new_items.append (item);
            }

            this.remove (item);
            this.select_row (this.get_row_at_index (0));
            items = new_items.copy ();
        }

        public void create_wifi_entry () {
            wifi = new DeviceItem (_("Wireless"), "", "network-wireless");  
            items.append (wifi);
            this.add (wifi);            
        }
  
        public void create_proxy_entry () {
            proxy = new DeviceItem (_("Proxy"), "", "preferences-system-network", true);
            this.add (proxy);  
        }

        public void select_first_item () {
            var first_row = this.get_row_at_index (0);
            this.select_row (first_row);
        }  

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before = null) {
            if (((DeviceItem) row).special && !((DeviceItem) before).special) {
                row.set_header (settings_l);
            } else if (row.get_index () == 0 && !(row as DeviceItem).special) {
                row.set_header (devices_l);
            }
        }
    }
}
