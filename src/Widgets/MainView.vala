/*-
 * Copyright (c) 2016-2017 elementary LLC.
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
    public class MainView : Gtk.Box {
        //private NM.Device current_device = null;
        private Gtk.Stack content;
        private Gtk.Box sidebar;
        private Gtk.ScrolledWindow scrolled_window;
       // private WidgetNMInterface page;
        private Widgets.DeviceList device_list;
        private Widgets.InfoFrame no_devices;
        
        construct {
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.width_request = 250;

            content = new Gtk.Stack ();
            content.hexpand = true;

            device_list = new Widgets.DeviceList ();
            device_list.row_selected.connect (on_row_selected);

            var dm = DeviceManager.get_default ();
            dm.client.notify["networking-enabled"].connect (on_networking_state_changed);

            var footer = new Widgets.Footer ();
            footer.hexpand = false;

            var airplane_mode = new Widgets.InfoFrame (_("Airplane Mode Is Enabled"),
                                                    _("While in Airplane Mode your device's Internet access and any wireless and ethernet connections, will be suspended.\n\n") +
_("You will be unable to browse the web or use applications that require a network connection or Internet access.\n") + 
_("Applications and other functions that do not require the Internet will be unaffected."), "airplane-mode");

            no_devices = new Widgets.InfoFrame (_("There is nothing to do"),
                                                    _("There are no available WiFi connections and devices connected to this computer.\n") + 
_("Please connect at least one device to begin configuring the network."), "dialog-information");

            content.add_named (airplane_mode, "airplane-mode-info");
            content.add_named (no_devices, "no-devices-info");

            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.add (device_list);
            scrolled_window.vexpand = true;

            sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            sidebar.pack_start (scrolled_window, true, true);
            sidebar.pack_start (footer, false, false);

            paned.pack1 (sidebar, false, false);
            paned.pack2 (content, true, false);
            paned.set_position (240);

            var main_grid = new Gtk.Grid ();
            main_grid.add (paned);
            main_grid.show_all ();
            add (main_grid);

            foreach (var device in dm.get_devices ()) {
                add_device (device);
            }


            dm.device_added.connect (add_device);
            dm.device_removed.connect (remove_device);

            add_proxy ();

            update_device_count ();
            show_all ();
        }

        private void add_device (Device device) {
            var page = DevicePage.create_for_device (device);
            if (page == null) {
                return;
            }

            var item = device_list.add_device (device);

            page.show_all ();
            item.page = page;

            content.add (page);

            update_device_count ();
        }

        private void remove_device (Device device) {
            var item = device_list.remove_device (device);
            if (item == null) {
                return;
            }

            var page = item.page;
            if (page != null) {
                content.remove (page);
            }

            update_device_count ();
        }

        private void add_proxy () {
            var proxy = new ProxyItem ();
            device_list.add (proxy);
            content.add (proxy.page);            
        }

        private void on_row_selected (Gtk.ListBoxRow? row) {
            if (row == null) {
                return;
            }

            var item = row as Item;
            if (item == null || item.page == null) {
                return;
            }

            content.visible_child = item.page;
        }

        private void update_device_count () {
            uint length = device_list.get_children ().length ();

            bool has_devices = length > 0;
            sidebar.visible = has_devices;
            sidebar.no_show_all = !has_devices;

            if (has_devices) {
                if (device_list.get_selected_row () == null) {
                    device_list.select_first_item ();
                }
            } else {
                content.visible_child = no_devices;
            }           
        }

        private void on_networking_state_changed () {
            var client = DeviceManager.get_default_client ();

            bool enabled = client.networking_get_enabled ();

            device_list.sensitive = enabled;
            if (enabled) {
                device_list.select_first_item ();
            } else {
                content.set_visible_child_name ("airplane-mode-info");
                device_list.select_row (null);
            }
        }
    }
}