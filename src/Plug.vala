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
 
namespace Network {

    public NM.DeviceType device_type;
    public static Plug plug;

    public class Plug : Switchboard.Plug {
        private Gtk.Grid main_grid = null;
        private NM.Device current_device = null;

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

                var paned = new Granite.Widgets.ThinPaned ();
                paned.width_request = 250;
                main_grid.add (paned);  

                var content = new Gtk.Stack ();

                var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                var device_list = new Widgets.DeviceList ();

                var footer = new Widgets.Footer (device_list.client);
                footer.hexpand = false;

                var networking_disabled = new Widgets.InfoScreen ("Networking is disabled",
                												  "While the network is disabled you cannot have access to the Internet.
It will not affect your connected devices and settings.", "nm-no-connection");

                var no_devices = new Widgets.InfoScreen ("There is nothing to do",
                                                        "There are no available WiFi connections and devices connected to this computer.
Please connect at least one device to begin configuring the newtork.", "dialog-cancel");

                content.add_named (networking_disabled, "networking-disabled-info");
                content.add_named (no_devices, "no-devices-info");

                var scrolled_window = new Gtk.ScrolledWindow (null, null);
                scrolled_window.add (device_list);
                scrolled_window.vexpand = true;

                sidebar.pack_start (scrolled_window, true, true);
				sidebar.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true);
				sidebar.pack_start (footer, false, false);

				paned.pack1 (sidebar, true, false);
				paned.pack2 (content, true, true);
				paned.set_position (240);

                device_list.client.get_devices ().foreach ((d) => {
                    if (d.get_device_type () == NM.DeviceType.WIFI) {
                        device_list.create_wifi_entry ();
                        var wifi_page = new Widgets.WiFiPage (d as NM.DeviceWifi);
                        content.add_named (wifi_page, "wifi-page");

                        device_list.wifi.activate.connect (() => {
                            if (content.get_visible_child_name () != "wifi-page")
                                content.set_visible_child (wifi_page);

                            current_device = null;    
                        });
                    }
                });

                device_list.row_changed.connect ((device) => {
                	if (device_list.client.networking_get_enabled ()) {
                        if (device != current_device) {
    	                    var page = new DevicePage.from_device (device); 
    	                    content.add_named (page, "device-page");
    	                    content.set_visible_child (page);
    	                    page.enable_btn.clicked.connect (() => {
    	                    	if (page.device.get_state () == NM.DeviceState.ACTIVATED) {
    	                    		page.device.disconnect ((() => {
    	                    			page.switch_button_state (true);
    	                    		}));
    	                    	} else {
    	                    		var connection = new NM.Connection ();
    	                    		var remote_array = page.device.get_available_connections ();
    	                    		connection.path = remote_array.get (0).get_path ();
    	                    		device_list.client.activate_connection (connection, page.device, null, (() => {
    	                    			page.switch_button_state (false);
    	                    		}));
    	                    	}
    	            		});
                        }

                        current_device = device;
                	}

            		paned.show_all ();
                });

				footer.on_switch_mode.connect ((switched) => {
					if (switched) {
                        if (!device_list.client.networking_get_enabled ())
						  device_list.client.networking_set_enabled (true);
						scrolled_window.sensitive = true;
						device_list.select_first_item ();
						/* This does not work when on the first run*/
						content.set_visible_child_name ("device-page");
					} else {
						device_list.client.networking_set_enabled (false);
						scrolled_window.sensitive = false;
						content.set_visible_child_name ("networking-disabled-info");
						device_list.select_row (null);
					}
				});
				
				device_list.select_first_item ();
				footer.on_switch_mode (device_list.client.networking_get_enabled ());
                if (device_list.client.get_devices ().length == 0) {
                    content.set_visible_child (no_devices);
                    sidebar.sensitive = false;
                }

                main_grid.show_all ();
        	}

            return main_grid;
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
    var plug = new Network.Plug ();
    return plug;
}
