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

    private Gtk.Stack content;
    private NM.Device current_device = null;
    private Switchboard.SettingsSidebar sidebar;
    private VPNPage vpn_page;

    construct {
        network_interface = new GLib.List<Widgets.Page> ();

        var proxy = new Widgets.DeviceItem (_("Proxy"), "preferences-system-network") {
            item_type = VIRTUAL
        };
        proxy.page = new Widgets.ProxyPage (proxy);

        vpn_page = new VPNPage ();
        var vpn = new Widgets.DeviceItem.from_page (vpn_page) {
            item_type = VIRTUAL
        };

        var headerbar = new Adw.HeaderBar () {
            show_end_title_buttons = false,
            show_title = false
        };

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
        // content.add_named (airplane_mode, "airplane-mode-info");
        content.add_child (vpn_page);
        content.add_child (proxy.page);

        sidebar = new Switchboard.SettingsSidebar (content) {
            show_title_buttons = true
        };

        var paned = new Gtk.Paned (HORIZONTAL) {
            start_child = sidebar,
            end_child = content,
            resize_start_child = false,
            shrink_start_child = false,
            shrink_end_child = false
        };

        append (paned);

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

    private void device_removed_cb (NM.Device device) {
        foreach (var widget_interface in network_interface) {
            if (widget_interface.device == device) {
                network_interface.remove (widget_interface);

                content.remove (widget_interface);
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
        if (content.get_page (page) == null) {
            content.add_child (page);
        }

        update_networking_state ();
    }

    private void update_networking_state () {
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        if (network_manager.client.networking_get_enabled ()) {
            sidebar.sensitive = true;
        } else {
            sidebar.sensitive = false;
            current_device = null;
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
}
