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
        public signal void show_no_devices (bool show);

        private Gtk.Label virtual_l;
        private Gtk.Label devices_l;
        private DeviceItem proxy;
        private DeviceItem vpn;

        construct {
            selection_mode = Gtk.SelectionMode.SINGLE;
            activate_on_single_click = true;

            virtual_l = new Gtk.Label (_("Virtual")) {
                halign = Gtk.Align.START
            };
            virtual_l.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            devices_l = new Gtk.Label (_("Devices")) {
                halign = Gtk.Align.START
            };
            devices_l.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            set_header_func (update_headers);
            set_sort_func (sort_items);

            bool show = (get_children ().length () > 0);
            show_no_devices (!show);
            add_proxy ();
            add_vpn ();

            row_selected.connect ((row) => {
                row.activate ();
            });
        }

        public void add_iface_to_list (Widgets.Page page) {
            DeviceItem item;
            if (page is WifiInterface) {
                item = new DeviceItem.from_page (page);
            } else if (page is HotspotInterface) {
                item = new DeviceItem.from_page (page);
                item.item_type = Utils.ItemType.VIRTUAL;
            } else if (page is ModemInterface) {
                item = new DeviceItem.from_page (page);
            } else {
                if (page.device.get_iface ().has_prefix ("usb")) {
                    item = new DeviceItem.from_page (page, "drive-removable-media");
                } else {
                    item = new DeviceItem.from_page (page);
                }
            }

            add (item);
            show_all ();
        }

        public void remove_iface_from_list (Widgets.Page iface) {
            foreach (Gtk.Widget _list_item in get_children ()) {
                var list_item = (DeviceItem)_list_item;
                if (list_item.page == iface) {
                    remove_row_from_list (list_item);
                }
            }
        }

        public void add_connection (NM.RemoteConnection connection) {
            switch (connection.get_connection_type ()) {
                case NM.SETTING_WIREGUARD_SETTING_NAME:
                case NM.SettingVpn.SETTING_NAME:
                    ((VPNPage)vpn.page).add_connection (connection);
                    break;
                default:
                    break;
            }
        }

        public void remove_connection (NM.RemoteConnection connection) {
            switch (connection.get_connection_type ()) {
                case NM.SETTING_WIREGUARD_SETTING_NAME:
                case NM.SettingVpn.SETTING_NAME:
                    ((VPNPage)vpn.page).remove_connection (connection);
                    break;
                default:
                    break;
            }
        }

        public void remove_row_from_list (DeviceItem item) {
            this.remove (item);
            show_all ();
        }

        private void add_proxy () {
            proxy = new DeviceItem (_("Proxy"), "preferences-system-network") {
                item_type = Utils.ItemType.VIRTUAL
            };
            proxy.page = new ProxyPage (proxy);
            this.add (proxy);
        }

        private void add_vpn () {
            vpn = new DeviceItem (_("VPN"), "network-vpn") {
                item_type = Utils.ItemType.VIRTUAL
            };
            vpn.page = new VPNPage (vpn);
            this.add (vpn);
        }

        public void select_first_item () {
            this.get_row_at_index (0).activate ();
        }

        private int sort_items (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
            if (((DeviceItem) row1).item_type == Utils.ItemType.DEVICE) {
                return -1;
            } else if (((DeviceItem) row1).item_type == Utils.ItemType.VIRTUAL) {
                return 1;
            } else {
                return 0;
            }
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before = null) {
            unowned DeviceItem row_item = (DeviceItem) row;
            unowned DeviceItem? before_item = (DeviceItem) before;
            if (row_item.item_type == Utils.ItemType.VIRTUAL) {
                if (before_item != null && before_item.item_type == Utils.ItemType.VIRTUAL) {
                    row.set_header (null);
                    return;
                }

                if (virtual_l.get_parent () != null) {
                    virtual_l.unparent ();
                }

                row.set_header (virtual_l);
            } else if (row_item.item_type == Utils.ItemType.DEVICE) {
                if (before_item != null && before_item.item_type == Utils.ItemType.DEVICE) {
                    row.set_header (null);
                    return;
                }

                if (devices_l.get_parent () != null) {
                    devices_l.unparent ();
                }

                row.set_header (devices_l);
            } else {
                row.set_header (null);
            }
        }
    }
}
