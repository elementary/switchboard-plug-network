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
        
        public NM.Client client;
        public DeviceItem wifi = null;
        public DeviceItem proxy;

        private List<DeviceItem> items;
        private DeviceItem item;

        private Gtk.Label settings_l;
        private Gtk.Label devices_l;

        private int wireless_item = 0;

        public DeviceList (NM.Client _client) {
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            this.activate_on_single_click = true;  
            this.set_header_func (update_headers);

            client = _client;
            items = new List<DeviceItem> ();

            settings_l = new Gtk.Label (_("Virtual"));
            settings_l.margin = 7;
            settings_l.get_style_context ().add_class ("h4");
            settings_l.sensitive = false;
            settings_l.use_markup = true;
            settings_l.halign = Gtk.Align.START;

            devices_l = new Gtk.Label (_("Devices"));
            devices_l.margin = 7;
            devices_l.get_style_context ().add_class ("h4");
            devices_l.sensitive = false;
            devices_l.use_markup = true;
            devices_l.halign = Gtk.Align.START;

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

        public void add_device_to_list (NM.Device device) {
            if (device.get_device_type () == NM.DeviceType.WIFI) {
                string title = _("Wireless");
                if (wireless_item > 0) {
                    title += " " + wireless_item.to_string ();
                }

                item = new DeviceItem.from_device (device, "network-wireless", false, title);  
                wireless_item++;                 
            } else {

                if (!device.get_managed ()) {
                    warning("Unmanaged device? probably something that has just been added…");
                }
                if (device.get_iface ().has_prefix ("usb")) {
                    item = new DeviceItem.from_device (device, "drive-removable-media");
                } else {
                    item = new DeviceItem.from_device (device);
                }
            }

            items.append (item);
            insert (item, (int)(items.length() - 1));
            show_all ();
        }

        public void remove_device_from_list (NM.Device device) {
            foreach (var list_item in items) {
                if(list_item.device == device) {
                    remove_row_from_list (list_item);
                    break;
                }
            }
        }

        public void remove_row_from_list (DeviceItem item) {
            items.remove (item);

            this.remove (item);
            this.select_row (this.get_row_at_index (0));
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
            if (row == proxy) {
                row.set_header (settings_l);
            } else if (row == items.nth_data (0)) {
                row.set_header (devices_l);
            } else {
                row.set_header (null);
            }
        }
    }
}
