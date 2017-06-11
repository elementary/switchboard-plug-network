/*-
 * Copyright (c) 2015-2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace Network.Widgets {
    public class DeviceList : Gtk.ListBox {
        private Gtk.Label virtual_l;
        private Gtk.Label devices_l;

        construct {
            virtual_l = new Gtk.Label (_("Virtual"));
            virtual_l.get_style_context ().add_class ("h4");
            virtual_l.halign = Gtk.Align.START;

            devices_l = new Gtk.Label (_("Devices"));
            devices_l.get_style_context ().add_class ("h4");
            devices_l.halign = Gtk.Align.START;

            selection_mode = Gtk.SelectionMode.SINGLE;
            activate_on_single_click = true;  
            set_header_func (update_headers);
            set_sort_func (sort_items);

            add_vpn ();
        }

        public DeviceItem add_device (Device device) {
            var item = new DeviceItem (device);
            add (item);
            show_all ();

            return item;
        }

        public DeviceItem? remove_device (Device device) {
            foreach (var row in get_children ()) {
                var item = row as DeviceItem;
                if (item == null || item.device == null) {
                    continue;
                }

                if (item.device.compare (device)) {
                    remove (item);
                    return item;
                }
            }

            return null;
        }

        /*public void add_connection (NM.RemoteConnection connection) {
            switch (connection.get_connection_type ()) {
                case NM.SettingVpn.SETTING_NAME:
                    ((VPNPage)vpn.page).add_connection (connection);
                    break;
                default:
                    break;
            }
        }

        public void remove_connection (NM.RemoteConnection connection) {
            switch (connection.get_connection_type ()) {
                case NM.SettingVpn.SETTING_NAME:
                    ((VPNPage)vpn.page).remove_connection (connection);
                    break;
                default:
                    break;
            }
        }*/

        private void add_vpn () {
            /*vpn = new DeviceItem (_("VPN"), "", "network-vpn");
            vpn.page = new VPNPage (vpn);
            vpn.type = Utils.ItemType.VIRTUAL;

            this.add (vpn);*/
        }

        public void select_first_item () {
            var row = get_row_at_index (0);
            if (row != null) {
                row.activate ();
            }
        }  

        private int sort_items (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
            if (row1 is DeviceItem) {
                return -1;
            } else if (row1 is ProxyItem) {
                return 1;
            }

            return 0;
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before = null) {
            if (row is ProxyItem) {
                if (before != null && before is ProxyItem) {
                    return;
                } 

                //remove_headers_for_type (Utils.ItemType.VIRTUAL);
                row.set_header (virtual_l);
            } else if (row is DeviceItem) {
                if (before != null && before is DeviceItem) {
                    return;
                } 

                //remove_headers_for_type (Utils.ItemType.DEVICE);
                row.set_header (devices_l);
            } else {
                row.set_header (null);
            }
        }

        /*private void remove_headers_for_type (Utils.ItemType type) {
            foreach (Gtk.Widget _item in get_children ()) {
                var item = (DeviceItem)_item;
                if (item.type == type) {
                    item.set_header (null);
                }
            }
        }*/
    }
}
