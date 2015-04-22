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

/* Main client instance */
NM.Client client;

/* Proxy settings */
Network.ProxySettings proxy_settings;
Network.ProxyFTPSettings ftp_settings;
Network.ProxyHTTPSettings http_settings;
Network.ProxyHTTPSSettings https_settings;
Network.ProxySocksSettings socks_settings;

/* Strings */
const string UNKNOWN = N_("Unknown");
const string SUFFIX = " ";

namespace Network {
    public static Plug plug;

    public class Plug : Switchboard.Plug {
        private NM.Device current_device = null;
        private Gtk.Grid main_grid = null;
        private Gtk.Stack content;
        private Gtk.ScrolledWindow scrolled_window;
        private Widgets.DevicePage page;
        private Widgets.DeviceList device_list;
        private Widgets.Footer footer;   
        private Widgets.InfoScreen no_devices;

        public Plug () {
            Object (category: Category.NETWORK,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Network"),
                    description: _("Network settings"),
                    icon: "preferences-system-network");
            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_grid == null) {
                main_grid = new Gtk.Grid ();        	

                var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
                paned.width_request = 250;
                main_grid.add (paned);  

                content = new Gtk.Stack ();

                var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                device_list = new Widgets.DeviceList (client);

                footer = new Widgets.Footer (client);
                footer.hexpand = false;

                var airplane_mode = new Widgets.InfoScreen (_("elementary OS is in Airplane Mode"),
                										_("While in Airplane Mode your device's Internet access and any wireless and ethernet connections, will be suspended.
                										
You will be unable to browse the web or use applications that require a network connection or Internet access.
Applications and other functions that do not require the Internet will be unaffected."), "airplane-mode-symbolic");
                                                                                        // ^^^^^^^^^^^^^^^^^^^^^^^^
                                                                                        /* Use "airplane-mode" icon here */            
                no_devices = new Widgets.InfoScreen (_("There is nothing to do"),
                                                        _("There are no available WiFi connections and devices connected to this computer.
Please connect at least one device to begin configuring the newtork."), "dialog-cancel");

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
                device_list.select_first_item ();
                main_grid.show_all ();
        	}

            return main_grid;
        }


        /* Main function to connect all the signals */
        private void connect_signals () {
            client.get_devices ().@foreach ((d) => {
                if (d.get_device_type () == NM.DeviceType.WIFI) {
                    device_list.create_wifi_entry ();
                    var wifi_page = new Widgets.WiFiPage ();
                    wifi_page.list_connections_from_device (null);
                    content.add_named (wifi_page, "wifi-page");

                    switch_wifi_status (wifi_page);       
                    wifi_page.control_switch.notify["active"].connect (() => {
                        client.wireless_set_enabled (wifi_page.control_switch.get_active ());
                        switch_wifi_status (wifi_page);  
                    });

                    device_list.wifi.activate.connect (() => {
                        if (content.get_visible_child_name () != "wifi-page")
                            content.set_visible_child (wifi_page);

                        current_device = null;    
                    });
                }
            });

            device_list.create_proxy_entry ();
            var proxy_page = new Widgets.ProxyPage ();
            proxy_page.stack.set_visible_child_name ("configuration");

            proxy_page.update_status_label.connect ((mode) => {
                device_list.proxy.switch_status (null, mode);
            });

            proxy_page.update_mode ();

            content.add_named (proxy_page, "proxy-page");
            device_list.proxy.activate.connect (() => {
                if (content.get_visible_child_name () != "proxy-page")
                    content.set_visible_child (proxy_page);

                current_device = null;    
            });

            device_list.row_changed.connect ((row) => {
                if ((row as Widgets.DeviceItem).get_item_device () != current_device) {
                    page = new Widgets.DevicePage.from_owner (row as Widgets.DeviceItem); 
                    content.add (page);
                    content.set_visible_child (page);
                    
                    page.update_sidebar.connect ((item) => {
                        item.switch_status (item.get_item_device ().get_state ());
                    });

                    if (page.device.get_state () == NM.DeviceState.UNMANAGED)
                        show_unmanaged_dialog (row);

                    page.control_switch.notify["active"].connect (() => {
                        if (page.device.get_state () == NM.DeviceState.ACTIVATED) {
                            page.device.disconnect (null);
                        } else {
                            var connection = new NM.Connection ();
                            var remote_array = page.device.get_available_connections ();
                            if (remote_array == null) {
                                show_error_dialog ();
                            } else {
                                connection.path = remote_array.get (0).get_path ();
                                client.activate_connection (connection, page.device, null, null);
                            }
                        }
                    });

                    current_device = (row as Widgets.DeviceItem).get_item_device ();
                }
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

            footer.on_switch_mode.connect ((switched) => {
                if (!switched) {
                    if (!client.networking_get_enabled ())
                        client.networking_set_enabled (true);
                    device_list.select_first_item ();
                    content.set_visible_child (page);
                } else {
                    client.networking_set_enabled (false);
                    content.set_visible_child_name ("airplane-mode-info");
                    current_device = null;
                    device_list.select_row (null);
                }
            });
        }

        private void switch_wifi_status (Widgets.WiFiPage wifi_page) {
            if (wifi_page.control_switch.get_active ())
                device_list.wifi.switch_status (null, "wifi-enabled");
            else    
                device_list.wifi.switch_status (null, "wifi-disabled");            
        }

        private void show_error_dialog () {
            var error_dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, " ");
            error_dialog.text = _("Could not enable device: there are no available
connections for this device.");
            error_dialog.deletable = false;
            error_dialog.show_all ();
            error_dialog.response.connect ((response_id) => {
                error_dialog.destroy ();                    
            }); 
        }

        private void show_unmanaged_dialog (Gtk.ListBoxRow _row) {
            var unmanaged_dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.NONE, " ");

            unmanaged_dialog.text = _("This device is no longer managed and recognizable.
Do you want to remove it from the list?");
            unmanaged_dialog.add_button (_("Do not remove"), 0);
            unmanaged_dialog.add_button (_("Remove"), 1);

            unmanaged_dialog.deletable = false;
            unmanaged_dialog.show_all ();
            unmanaged_dialog.response.connect ((response_id) => {
                switch (response_id) {
                    case 0:
                        break;
                    case 1:
                        device_list.remove_row_from_list (_row as Widgets.DeviceItem);
                        break;
                    } 

                unmanaged_dialog.destroy ();                    
            });          
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
        stdout.printf ("%s\n", e.message);
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
