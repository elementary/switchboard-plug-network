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

/* Main client instance */
NM.Client client;

/* Proxy settings */
Network.ProxySettings proxy_settings;
Network.ProxyFTPSettings ftp_settings;
Network.ProxyHTTPSettings http_settings;
Network.ProxyHTTPSSettings https_settings;
Network.ProxySocksSettings socks_settings;

/* Strings */
const string SUFFIX = " ";

namespace Network {
    public static Plug plug;

    public class MainBox : Network.Widgets.NMVisualizer {
        private NM.Device current_device = null;
        private Gtk.Stack content;
        private Gtk.ScrolledWindow scrolled_window;
        private WidgetNMInterface page;
        private Widgets.DeviceList device_list;
        private Widgets.Footer footer;   
        private Widgets.InfoScreen no_devices;

        protected override void add_interface (WidgetNMInterface widget_interface) {
            device_list.add_device_to_list (widget_interface);

            select_first ();
            show_all ();
        }

        protected override void remove_interface (WidgetNMInterface widget_interface) {
            device_list.remove_device_from_list (widget_interface.device);
            if (content.get_visible_child () == widget_interface) {
                int index = device_list.get_selected_row ().get_index ();
                if (index >= 0) {
                    device_list.get_row_at_index (index).activate ();
                } else {
                    select_first ();
                }
            }

            content.remove (widget_interface);
            show_all ();
        }

        private void select_first () {
			device_list.select_first_item ();
        }

        protected override void build_ui () {
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.width_request = 250;

            content = new Gtk.Stack ();

            var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            device_list = new Widgets.DeviceList ();

            footer = new Widgets.Footer (client);
            footer.hexpand = false;

            var airplane_mode = new Widgets.InfoScreen (_("Airplane Mode Is Enabled"),
                                                    _("While in Airplane Mode your device's Internet access and any wireless and ethernet connections, will be suspended.\n\n" +
_("You will be unable to browse the web or use applications that require a network connection or Internet access.\n") + 
"Applications and other functions that do not require the Internet will be unaffected."), "airplane-mode");

            no_devices = new Widgets.InfoScreen (_("There is nothing to do"),
                                                    _("There are no available WiFi connections and devices connected to this computer.\n") + 
_("Please connect at least one device to begin configuring the network."), "dialog-cancel");

            content.add_named (airplane_mode, "airplane-mode-info");
            content.add_named (no_devices, "no-devices-info");

            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.add (device_list);
            scrolled_window.vexpand = true;

            sidebar.pack_start (scrolled_window, true, true);
            sidebar.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true);
            sidebar.pack_start (footer, false, false);

            paned.pack1 (sidebar, true, false);
            paned.pack2 (content, true, true);
            paned.set_position (240);

            connect_signals ();

            var main_grid = new Gtk.Grid ();
            main_grid.add (paned);
            main_grid.show_all ();
            add (main_grid);
        }

        /* Main function to connect all the signals */
        private void connect_signals () {
            device_list.row_activated.connect ((row) => {
                if (content.get_children ().find (((Widgets.DeviceItem)row).page) == null) {
                    content.add (((Widgets.DeviceItem) row).page);
                }

                content.visible_child = ((Widgets.DeviceItem)row).page;
            });
            
            device_list.show_no_devices.connect ((show) => {
                if (show) {
                    content.set_visible_child (no_devices);
                    scrolled_window.sensitive = false;
                } else {
                    content.set_visible_child (page);
                    scrolled_window.sensitive = true;
                }
            });

            client.notify["networking-enabled"].connect (() => {
                device_list.sensitive = client.networking_get_enabled ();
                if (client.networking_get_enabled ()) {
                    device_list.select_first_item ();
                } else {
                    content.set_visible_child_name ("airplane-mode-info");
                    current_device = null;
                    device_list.select_row (null);
                }
            });
        }

        /*private void show_error_dialog () {
            var error_dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, " ");
            error_dialog.text = _("Could not enable device: there are no available
connections for this device.");
            error_dialog.deletable = false;
            error_dialog.show_all ();
            error_dialog.response.connect ((response_id) => {
                error_dialog.destroy ();
            }); 
        }*/
    }

    public class Plug : Switchboard.Plug {
        MainBox? main_box = null;
        public Plug () {
            Object (category: Category.NETWORK,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Network"),
                    description: _("Network settings"),
                    icon: "preferences-system-network");
            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_box == null) {
                main_box = new MainBox ();
            }

            return main_box;
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Network plug");
    try {
        NM.Utils.init ();
    } catch (Error e) {
        error ("Could not initialize NetworkManager Utils: %s\n", e.message);
    }

    client = new NM.Client ();
    proxy_settings = new Network.ProxySettings ();
    ftp_settings = new Network.ProxyFTPSettings ();
    http_settings = new Network.ProxyHTTPSettings ();
    https_settings = new Network.ProxyHTTPSSettings ();
    socks_settings = new Network.ProxySocksSettings ();

    var plug = new Network.Plug ();
    return plug;
}
