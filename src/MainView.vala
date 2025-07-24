/*
 * Copyright (c) 2015-2019 elementary, Inc. (https://elementary.io)
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

public class Network.MainView : Gtk.Box {
    protected GLib.List<Widgets.Page>? network_interface;

    public NM.DeviceState state { private set; get; default = NM.DeviceState.PREPARE; }

    private Granite.HeaderLabel devices_header;
    private Granite.HeaderLabel virtual_header;
    private Gtk.ListBox device_list;
    private Gtk.Stack content;
    private NM.Device current_device = null;
    private VPNPage vpn_page;

    construct {
        network_interface = new GLib.List<Widgets.Page> ();

        virtual_header = new Granite.HeaderLabel (_("Virtual"));
        devices_header = new Granite.HeaderLabel (_("Devices"));

        var proxy_page = new Widgets.ProxyPage ();
        var proxy = new Widgets.DeviceItem.from_page (proxy_page) {
            item_type = VIRTUAL
        };

        vpn_page = new VPNPage ();
        var vpn = new Widgets.DeviceItem.from_page (vpn_page) {
            item_type = VIRTUAL
        };

        var headerbar = new Adw.HeaderBar () {
            show_end_title_buttons = false,
            show_title = false
        };

        device_list = new Gtk.ListBox () {
            activate_on_single_click = true,
            selection_mode = SINGLE,
            hexpand = true,
            vexpand = true
        };
        device_list.set_sort_func (sort_func);
        device_list.set_header_func (update_headers);
        device_list.append (proxy);
        device_list.append (vpn);

        var label = new Gtk.Label (_("Airplane Mode"));

        var airplane_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var footer = new Gtk.ActionBar ();
        footer.pack_start (label);
        footer.pack_end (airplane_switch);

        var airplane_mode = new Granite.Placeholder (
            _("Airplane Mode Is Enabled")) {
            description = _("While in Airplane Mode your device's Internet access and any wireless and ethernet connections, will be suspended.\n\n") +
            _("You will be unable to browse the web or use applications that require a network connection or Internet access.\n") +
            _("Applications and other functions that do not require the Internet will be unaffected."),
            icon = new ThemedIcon ("airplane-mode")
        };

        content = new Gtk.Stack () {
            hexpand = true
        };
        content.add_named (airplane_mode, "airplane-mode-info");
        content.add_named (vpn_page, "vpn");
        content.add_named (proxy.page, "proxy");

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = device_list,
            hscrollbar_policy = NEVER
        };

        var toolbarview = new Adw.ToolbarView () {
            content = scrolled_window,
            top_bar_style = FLAT,
            bottom_bar_style = RAISED
        };
        toolbarview.add_top_bar (headerbar);
        toolbarview.add_bottom_bar (footer);

        var sidebar = new Sidebar ();
        sidebar.append (toolbarview);

        var paned = new Gtk.Paned (HORIZONTAL) {
            start_child = sidebar,
            end_child = content,
            resize_start_child = false,
            shrink_start_child = false,
            shrink_end_child = false
        };

        var sss = SettingsSchemaSource.get_default ().lookup ("io.elementary.settings", true);
        if (sss != null && sss.has_key ("sidebar-position")) {
            var settings = new Settings ("io.elementary.settings");
            settings.bind ("sidebar-position", paned, "position", DEFAULT);
        }

        append (paned);

        device_list.row_selected.connect ((row) => {
            row.activate ();
        });

        device_list.row_activated.connect ((row) => {
            var page = ((Widgets.DeviceItem)row).page;
            content.visible_child = page;
        });

        unowned var network_manager = NetworkManager.get_default ();
        unowned var nm_client = network_manager.client;
        nm_client.connection_added.connect (connection_added_cb);
        nm_client.connection_removed.connect (connection_removed_cb);

        nm_client.device_added.connect (device_added_cb);
        nm_client.device_removed.connect (device_removed_cb);

        nm_client.get_devices ().foreach ((device) => device_added_cb (device));
        nm_client.get_connections ().foreach ((connection) => connection_added_cb (connection));

        update_networking_state ();
        nm_client.notify["networking-enabled"].connect (update_networking_state);

        airplane_switch.notify["active"].connect (() => {
            nm_client.dbus_call.begin (
                NM.DBUS_PATH, NM.DBUS_INTERFACE, "Enable",
                new GLib.Variant.tuple ({!airplane_switch.active}),
                null, -1, null,
                (obj, res) => {
                    try {
                        nm_client.dbus_call.end (res);
                    } catch (Error e) {
                        warning (e.message);
                    }
                }
            );
        });

        if (!airplane_switch.active && !nm_client.networking_enabled) {
            airplane_switch.activate ();
        }
    }

    public void push (string location) {
        content.visible_child_name = location;
    }

    private void device_removed_cb (NM.Device device) {
        foreach (var widget_interface in network_interface) {
            if (widget_interface.device == device) {
                network_interface.remove (widget_interface);

                // Implementation call
                remove_interface (widget_interface);
                break;
            }
        }

        update_interfaces_names ();
    }

    private void update_interfaces_names () {
        var count_type = new Gee.HashMap<string, int?> ();
        foreach (var iface in network_interface) {
            var type = iface.get_type ().name ();
            if (count_type.has_key (type)) {
                count_type[type] = count_type[type] + 1;
            } else {
                count_type[type] = 1;
            }
        }

        foreach (var iface in network_interface) {
            var type = iface.get_type ().name ();
            iface.update_name (count_type [type]);
        }
    }

    private void connection_added_cb (NM.RemoteConnection connection) {
        switch (connection.get_connection_type ()) {
            case NM.SettingWireGuard.SETTING_NAME:
            case NM.SettingVpn.SETTING_NAME:
                vpn_page.add_connection (connection);
                break;
            default:
                break;
        }
    }

    private void connection_removed_cb (NM.RemoteConnection connection) {
        switch (connection.get_connection_type ()) {
            case NM.SettingWireGuard.SETTING_NAME:
            case NM.SettingVpn.SETTING_NAME:
                vpn_page.remove_connection (connection);
                break;
            default:
                break;
        }
    }

    private void device_added_cb (NM.Device device) {
        if (device.get_iface ().has_prefix ("vmnet") ||
            device.get_iface ().has_prefix ("lo") ||
            device.get_iface ().has_prefix ("veth")) {
            return;
        }

        Widgets.Page? widget_interface = null;
        Widgets.Page? hotspot_interface = null;

        if (device is NM.DeviceWifi) {
            widget_interface = new Network.WifiInterface (device);
            hotspot_interface = new Network.Widgets.HotspotInterface ((WifiInterface)widget_interface);

            debug ("Wifi interface added");
        } else if (device is NM.DeviceEthernet) {
            widget_interface = new Network.Widgets.EtherInterface (device);
            debug ("Ethernet interface added");
        } else if (device is NM.DeviceModem) {
            widget_interface = new Network.Widgets.ModemInterface (device);
            debug ("Modem interface added");
        } else {
            debug ("Unknown device: %s\n", device.get_device_type ().to_string ());
        }

        if (widget_interface != null) {
            // Implementation call
            network_interface.append (widget_interface);
            add_interface (widget_interface);
            widget_interface.notify["state"].connect (update_state);

        }

        if (hotspot_interface != null) {
            // Implementation call
            network_interface.append (hotspot_interface);
            add_interface (hotspot_interface);
            hotspot_interface.notify["state"].connect (update_state);
        }

        update_interfaces_names ();

        foreach (var inter in network_interface) {
            inter.update ();
        }
    }

    private void update_state () {
        var next_state = NM.DeviceState.DISCONNECTED;
        foreach (var inter in network_interface) {
            if (inter.state != NM.DeviceState.DISCONNECTED) {
                next_state = inter.state;
            }
        }

        state = next_state;
    }

    private void add_interface (Widgets.Page page) {
        if (content.get_page (page) != null) {
            return;
        }

        Widgets.DeviceItem item;
        if (page is Widgets.HotspotInterface) {
            item = new Widgets.DeviceItem.from_page (page) {
                item_type = VIRTUAL
            };


            content.add_named (page, "hotspot");

            return;
        } else if (page.device.get_iface ().has_prefix ("usb")) {
            item = new Widgets.DeviceItem.from_page (page, "drive-removable-media");
        } else {
            item = new Widgets.DeviceItem.from_page (page);
        }

        content.add_named (page, page.device.udi);
        device_list.append (item);
        update_networking_state ();
    }

    private void remove_interface (Widgets.Page widget_interface) {
        if (content.get_visible_child () == widget_interface) {
            var row = device_list.get_selected_row ();
            int index = device_list.get_selected_row ().get_index ();
            remove_iface_from_list (widget_interface);

            if (row != null && row.get_index () >= 0) {
                device_list.get_row_at_index (index).activate ();
            } else {
                device_list.get_row_at_index (0).activate ();
            }
        } else {
            remove_iface_from_list (widget_interface);
        }

        widget_interface.destroy ();
    }

    private void remove_iface_from_list (Widgets.Page iface) {
        unowned var child = device_list.get_first_child ();
        while (child != null) {
            if (child is Widgets.DeviceItem && ((Widgets.DeviceItem) child).page == iface) {
                device_list.remove (child);
                break;
            }

            child = child.get_next_sibling ();
        }
    }

    private void update_networking_state () {
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        if (network_manager.client.networking_get_enabled ()) {
            device_list.sensitive = true;
            unowned var child = device_list.get_first_child ();
            while (child != null) {
                if (child is Widgets.DeviceItem && ((Widgets.DeviceItem) child).page.state == NM.DeviceState.ACTIVATED) {
                    child.activate ();
                    return;
                }
                child = child.get_next_sibling ();
            }
            device_list.get_row_at_index (0).activate ();
        } else {
            device_list.sensitive = false;
            current_device = null;
            device_list.select_row (null);
            content.set_visible_child_name ("airplane-mode-info");
        }
    }

    private int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        if (((Widgets.DeviceItem) row1).item_type == DEVICE) {
            return -1;
        } else if (((Widgets.DeviceItem) row1).item_type == VIRTUAL) {
            return 1;
        } else {
            return 0;
        }
    }

    private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before = null) {
        unowned Widgets.DeviceItem row_item = (Widgets.DeviceItem) row;
        unowned Widgets.DeviceItem? before_item = (Widgets.DeviceItem) before;
        if (row_item.item_type == VIRTUAL) {
            if (before_item != null && before_item.item_type == VIRTUAL) {
                row.set_header (null);
                return;
            }

            if (virtual_header.get_parent () != null) {
                virtual_header.unparent ();
            }

            row.set_header (virtual_header);
        } else if (row_item.item_type == DEVICE) {
            if (before_item != null && before_item.item_type == DEVICE) {
                row.set_header (null);
                return;
            }

            if (devices_header.get_parent () != null) {
                devices_header.unparent ();
            }

            row.set_header (devices_header);
        } else {
            row.set_header (null);
        }
    }

    // Workaround to set styles
    private class Sidebar : Gtk.Box {
        class construct {
            set_css_name ("settingssidebar");
        }

        construct {
            add_css_class (Granite.STYLE_CLASS_SIDEBAR);
        }
    }
}
