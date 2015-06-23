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
        public signal void row_changed (Gtk.ListBoxRow row);
        public signal void show_no_devices (bool show);
        public signal void wifi_device_detected (NM.DeviceWifi? d);
        
        public NM.Client client;
        public DeviceItem wifi = null;
        public DeviceItem proxy;

        private DeviceItem[] items = {};
        private DeviceItem item;
        private GenericArray<NM.Device> devices;

        private Gtk.Label settings_l;
        private Gtk.Label devices_l;

        public DeviceList (NM.Client _client) {
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            this.activate_on_single_click = true;  
            this.set_header_func (update_headers);

            client = _client;

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
                if (device.get_device_type () == NM.DeviceType.WIFI)
                    this.wifi_device_detected (device as NM.DeviceWifi);
                else    
                    add_device_to_list (device);

                if (items.length == 1)
                    this.show_no_devices (false);
                this.selected_rows_changed ();
                this.show_all ();
            });

            client.device_removed.connect ((device) => {
                foreach (var item in items) {
                    if (item.get_item_device () == device)
                        this.remove_row_from_list (item);
                }

                if (items.length == 0)
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

            if (items.length > 0) {
                this.show_no_devices (false);
            } else {
                this.show_no_devices (true);
            }
        }

        public void init () {
            this.list_devices (devices);
            this.show_all ();
        }

        public DeviceItem[] get_items () {
            return items;
        }

        private void list_devices (GenericArray<NM.Device> devices) {
            for (uint i = 0; i < devices.length; i++) {
                var device = devices.get (i);

                if (device.get_device_type () == NM.DeviceType.WIFI) {
                    this.wifi_device_detected (device as NM.DeviceWifi);
                } else {
                    add_device_to_list (device);
                }
            }
        }

        private void add_device_to_list (NM.Device device) {
            if (device.get_managed ()) {
                if (device.get_iface ().has_prefix ("usb")) {
                    item = new DeviceItem.from_device (device, "drive-removable-media");
                } else {
                    item = new DeviceItem.from_device (device);
                }

                items += item;
                if (items.length -1 == 0) {
                    this.insert (item, items.length - 1);
                } else {
                    this.insert (item, 1);
                }
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
            wifi = new DeviceItem (_("Wi-Fi Network"), "", "network-wireless");  
            items += wifi;
            this.add (wifi);            
        }
  
        public void create_proxy_entry () {
            proxy = new DeviceItem (_("Proxy"), "", "preferences-system-network");
            this.add (proxy);  
        }

        public void select_first_item () {
            var first_row = this.get_row_at_index (0);
            this.select_row (first_row);
        }  

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before = null) {
            if (this.get_row_at_index (0) == row && (row as DeviceItem) != proxy) {
                row.set_header (devices_l);
            } else if (this.get_row_at_index (items.length) == row) {
                row.set_header (settings_l);
            }
        }
    }
}
