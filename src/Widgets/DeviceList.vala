// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-plug-networking)
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
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace Network.Widgets {
    public class DeviceList : Gtk.ListBox {
        public signal void show_no_devices (bool show);

        private Gtk.Label virtual_l;
        private Gtk.Label devices_l;
        private DeviceItem proxy;

        private int wireless_item = 0;

        public DeviceList () {
            virtual_l = new Gtk.Label (_("Virtual"));
            virtual_l.get_style_context ().add_class ("h4");
            virtual_l.halign = Gtk.Align.START;

            devices_l = new Gtk.Label (_("Devices"));
            devices_l.get_style_context ().add_class ("h4");
            devices_l.halign = Gtk.Align.START;

            this.selection_mode = Gtk.SelectionMode.SINGLE;
            this.activate_on_single_click = true;  
            this.set_header_func (update_headers);
            this.set_sort_func (sort_items);

            bool show = (get_children ().length () > 0);
            this.show_no_devices (!show);
            this.add_proxy ();
        }

        public void add_device_to_list (WidgetNMInterface iface) {
            DeviceItem item;
            if (!iface.device.get_managed ()) {
                warning ("Unmanaged device, probably something that has just been added.");
            }

            if (iface.device.get_device_type () == NM.DeviceType.WIFI) {
                string title = _("Wireless");
                if (wireless_item > 0) {
                    title = _("Wireless %s".printf (wireless_item.to_string ()));
                }

                item = new DeviceItem.from_interface (iface, "network-wireless", title);
                add_hotspot (iface, wireless_item);
                wireless_item++;
            } else {
                if (iface.device.get_iface ().has_prefix ("usb")) {
                    item = new DeviceItem.from_interface (iface, "drive-removable-media");
                } else {
                    item = new DeviceItem.from_interface (iface);
                }
            }

            add (item);
            show_all ();
        }

        public void remove_device_from_list (NM.Device device) {
            foreach (Gtk.Widget _list_item in get_children ()) {
                var list_item = (DeviceItem)_list_item;
                if (list_item.device == device) {
                    remove_row_from_list (list_item);
                }
            }
        }

        public void remove_row_from_list (DeviceItem item) {
            if (item.device.get_device_type () == NM.DeviceType.WIFI && wireless_item > 0) {
                wireless_item--;
            } 

            this.remove (item);
            show_all ();
        }

        private void add_hotspot (WidgetNMInterface iface, int wireless_item) {
            string title = _("Hotspot");
            if (wireless_item > 0) {
                title = _("Hotspot %s".printf (wireless_item.to_string ()));
            }

            var hotspot = new DeviceItem (title, "", "network-wireless-hotspot");
            hotspot.no_show_all = true;
            iface.device.state_changed.connect ((state) => {
                hotspot.visible = (state != NM.DeviceState.UNAVAILABLE
                        && state != NM.DeviceState.UNMANAGED
                        && state != NM.DeviceState.UNKNOWN);
            });

            hotspot.device = iface.device;
            hotspot.type = Utils.ItemType.VIRTUAL;

            var hotspot_page = new HotspotPage (hotspot, ((WifiInterface)iface));
            hotspot_page.title = title;
            hotspot.page = hotspot_page;

            this.add (hotspot);
        }

        private void add_proxy () {
            proxy = new DeviceItem (_("Proxy"), "", "preferences-system-network");
            proxy.page = new ProxyPage (proxy);
            proxy.type = Utils.ItemType.VIRTUAL;

            this.add (proxy);
        }
        
        public void select_first_item () {
            this.get_row_at_index (0).activate ();
        }  

        private int sort_items (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
            if (((DeviceItem) row1).type == Utils.ItemType.DEVICE) {
                return -1;
            } else if (((DeviceItem) row1).type == Utils.ItemType.VIRTUAL) {
                return 1;
            } else {
                return 0;
            }
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before = null) {
            if (((DeviceItem) row).type == Utils.ItemType.VIRTUAL) {
                if (before != null && ((DeviceItem) before).type == Utils.ItemType.VIRTUAL) {
                    return;
                } 

                remove_headers_for_type (Utils.ItemType.VIRTUAL);
                row.set_header (virtual_l);
            } else if (((DeviceItem) row).type == Utils.ItemType.DEVICE) {
                if (before != null && ((DeviceItem) before).type == Utils.ItemType.DEVICE) {
                    return;
                } 

                remove_headers_for_type (Utils.ItemType.DEVICE);
                row.set_header (devices_l);
            } else {
                row.set_header (null);
            }
        }

        private void remove_headers_for_type (Utils.ItemType type) {
            foreach (Gtk.Widget _item in get_children ()) {
                var item = (DeviceItem)_item;
                if (item.type == type) {
                    item.set_header (null);
                }
            }
        }
    }
}
