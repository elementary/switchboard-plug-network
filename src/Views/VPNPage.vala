/*-
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

public class Network.VPNPage : Network.Widgets.Page {
    public Network.Widgets.DeviceItem owner { get; construct; }
    private Gee.List<NM.VpnConnection> active_connections;
    private Gee.List<NM.ActiveConnection> active_wireguard_connections;


    private Gtk.ListBox vpn_list;
    private uint timeout_id = 0;
    private VPNMenuItem? sel_row;
    private Granite.Widgets.Toast remove_vpn_toast;

    public VPNPage (Network.Widgets.DeviceItem owner) {
        Object (
            owner: owner,
            title: _("Virtual Private Network"),
            icon_name: "network-vpn"
        );
    }

    construct {
        remove_vpn_toast = new Granite.Widgets.Toast (_("VPN removed"));
        remove_vpn_toast.set_default_action (_("Undo"));

        var placeholder = new Granite.Widgets.AlertView (
            _("No VPN Connections"),
            _("Add a new VPN connection to begin."),
            ""
        );

        placeholder.show_all ();

        vpn_list = new Gtk.ListBox ();
        vpn_list.activate_on_single_click = false;
        vpn_list.visible = true;
        vpn_list.selection_mode = Gtk.SelectionMode.BROWSE;
        vpn_list.set_placeholder (placeholder);
        vpn_list.set_sort_func ((Gtk.ListBoxSortFunc) compare_rows);

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON);
        add_button.tooltip_text = _("Add VPN Connection…");
        add_button.clicked.connect (() => {
            try_connection_editor ("--create --type=vpn");
        });

        var remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.BUTTON);
        remove_button.tooltip_text = _("Forget selected VPN…");
        remove_button.sensitive = false;
        remove_button.clicked.connect (remove_button_cb);

        remove_vpn_toast.default_action.connect (() => {
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
            sel_row.show ();
        });

        var edit_connection_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.BUTTON);
        edit_connection_button.tooltip_text = _("Edit VPN connection…");
        edit_connection_button.sensitive = false;
        edit_connection_button.clicked.connect (() => {
            var selected_row = (VPNMenuItem) vpn_list.get_selected_row ();
            try_connection_editor ("--edit=" + selected_row.connection.get_uuid ());
        });

        actionbar.add (add_button);
        actionbar.add (remove_button);
        actionbar.add (edit_connection_button);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (vpn_list);

        var list_root = new Gtk.Grid ();
        list_root.attach (scrolled, 0, 0, 1, 1);
        list_root.attach (actionbar, 0, 1, 1, 1);

        var frame = new Gtk.Frame (null);
        frame.vexpand = true;
        frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        frame.add (list_root);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add (frame);
        main_overlay.add_overlay (remove_vpn_toast);

        content_area.add (main_overlay);

        show_all ();

        vpn_list.row_activated.connect (row => {
            if (((VPNMenuItem) row).state == NM.DeviceState.ACTIVATED) {
                disconnect_vpn_cb ((VPNMenuItem) row);
            } else {
                connect_vpn_cb ((VPNMenuItem) row);
            }
        });

        vpn_list.row_selected.connect (row => {
            remove_button.sensitive = row != null;
            edit_connection_button.sensitive = row != null;
        });

        active_connections = new Gee.ArrayList<NM.VpnConnection> ();
        active_wireguard_connections = new Gee.ArrayList<NM.ActiveConnection> ();

        update ();
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.notify["active-connections"].connect (update_active_connections);
    }

    protected override void update () {
        update_active_connections ();

        VPNMenuItem? item = null;
        foreach (var ac in active_connections) {
            if (ac != null) {
                switch (ac.get_vpn_state ()) {
                    case NM.VpnConnectionState.UNKNOWN:
                    case NM.VpnConnectionState.DISCONNECTED:
                        state = NM.DeviceState.DISCONNECTED;
                        break;
                    case NM.VpnConnectionState.PREPARE:
                    case NM.VpnConnectionState.NEED_AUTH:
                    case NM.VpnConnectionState.IP_CONFIG_GET:
                    case NM.VpnConnectionState.CONNECT:
                        state = NM.DeviceState.PREPARE;
                        break;
                    case NM.VpnConnectionState.FAILED:
                        state = NM.DeviceState.FAILED;
                        break;
                    case NM.VpnConnectionState.ACTIVATED:
                        state = NM.DeviceState.ACTIVATED;
                        break;
                }

                item = get_item_by_uuid (ac.get_uuid ());
            } else {
                state = NM.DeviceState.DISCONNECTED;
            }

            if (item != null) {
                item.state = state;
            }
        }

        foreach (var ac in active_wireguard_connections) {
            if (ac != null) {
                switch (ac.get_state ()) {
                    case NM.ActiveConnectionState.UNKNOWN:
                    case NM.ActiveConnectionState.DEACTIVATED:
                    case NM.ActiveConnectionState.DEACTIVATING:
                        state = NM.DeviceState.DISCONNECTED;
                        break;
                    case NM.ActiveConnectionState.ACTIVATING:
                        state = NM.DeviceState.PREPARE;
                        break;
                    case NM.ActiveConnectionState.ACTIVATED:
                        state = NM.DeviceState.ACTIVATED;
                        break;
                }

                item = get_item_by_uuid (ac.get_uuid ());
            } else {
                state = NM.DeviceState.DISCONNECTED;
            }

            if (item != null) {
                item.state = state;
            }
        }

        owner.switch_status (Utils.CustomMode.INVALID, state);
        update_switch ();
    }

    protected override void update_switch () {

    }

    protected override void control_switch_activated () {

    }

    public void add_connection (NM.RemoteConnection connection) {
        var item = new VPNMenuItem (connection);

        vpn_list.add (item);
        update ();
        show_all ();
    }

    public void remove_connection (NM.RemoteConnection connection) {
        var item = get_item_by_uuid (connection.get_uuid ());
        item.destroy ();
    }

    private VPNMenuItem? get_item_by_uuid (string uuid) {
        VPNMenuItem? item = null;
        foreach (var child in vpn_list.get_children ()) {
            var _item = (VPNMenuItem)child;
            if (_item.connection != null && _item.connection.get_uuid () == uuid && item == null) {
                item = (VPNMenuItem)child;
            }
        }

        return item;
    }

    private void update_active_connections () {
        active_connections.clear ();
        active_wireguard_connections.clear ();

        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.get_active_connections ().foreach ((ac) => {
            if (ac.get_vpn ()) {
                active_connections.add ((NM.VpnConnection) ac);
                (ac as NM.VpnConnection).vpn_state_changed.connect (update);
            }
            else if (ac.get_connection_type () == NM.SETTING_WIREGUARD_SETTING_NAME) {
                active_wireguard_connections.add ((NM.ActiveConnection) ac);
                (ac as NM.ActiveConnection).state_changed.connect (update);
            }

        });
    }

    private void connect_vpn_cb (VPNMenuItem item) {
        update_active_connections ();
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.activate_connection_async.begin (item.connection, null, null, null, null);
        update ();
    }

    private void disconnect_vpn_cb (VPNMenuItem item) {
        update_active_connections ();
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        foreach (var ac in active_connections) {
            if (ac.get_connection () == item.connection) {
                try {
                    network_manager.client.deactivate_connection (ac);
                } catch (Error e) {
                    warning (e.message);
                }
                update ();
                return;
            }
        }
        foreach (var ac in active_wireguard_connections) {
            if (ac.get_connection () == item.connection) {
                try {
                    network_manager.client.deactivate_connection (ac);
                } catch (Error e) {
                    warning (e.message);
                }
                update ();
                return;
            }
        }
    }

    private void remove_button_cb () {
        sel_row = vpn_list.get_selected_row () as VPNMenuItem;
        if (sel_row != null) {
            if (sel_row.state == NM.DeviceState.ACTIVATED ||
                sel_row.state == NM.DeviceState.PREPARE) {
                var dialog = new Granite.MessageDialog (
                    _("Failed to remove VPN connection"),
                    _("Cannot remove an active VPN connection."),
                    new ThemedIcon ("network-vpn"),
                    Gtk.ButtonsType.CLOSE
                );
                dialog.badge_icon = new ThemedIcon ("dialog-error");
                dialog.transient_for = (Gtk.Window) get_toplevel ();
                dialog.run ();
                dialog.destroy ();
                return;
            } else {
                remove_vpn_toast.send_notification ();
                sel_row.hide ();
                timeout_id = GLib.Timeout.add (3600, () => {
                    timeout_id = 0;
                    delete_connection ();
                    return GLib.Source.REMOVE;
                });
            }
        }
    }

    private void try_connection_editor (string args) {
        try {
            var appinfo = AppInfo.create_from_commandline (
                "nm-connection-editor %s".printf (args),
                null,
                GLib.AppInfoCreateFlags.NONE
            );
            appinfo.launch (null, null);
        } catch (Error error) {
            var dialog = new Granite.MessageDialog (
                _("Failed to run Connection Editor"),
                _("The program \"nm-connection-editor\" may not be installed."),
                new ThemedIcon ("network-vpn"),
                Gtk.ButtonsType.CLOSE
            );
            dialog.badge_icon = new ThemedIcon ("dialog-error");
            dialog.show_error_details (error.message);
            dialog.transient_for = (Gtk.Window) get_toplevel ();
            dialog.run ();
            dialog.destroy ();
        }
    }

    private void delete_connection () {
        var selected_row = vpn_list.get_selected_row () as VPNMenuItem;
        if (selected_row != null && sel_row != null) {
            if (sel_row == selected_row) {
                try {
                    selected_row.connection.delete (null);
                } catch (Error e) {
                    warning (e.message);
                    var dialog = new Granite.MessageDialog (
                        _("Failed to remove VPN connection"),
                        "",
                        new ThemedIcon ("network-vpn"),
                        Gtk.ButtonsType.CLOSE
                    );
                    dialog.badge_icon = new ThemedIcon ("dialog-error");
                    dialog.show_error_details (e.message);
                    dialog.transient_for = (Gtk.Window) get_toplevel ();
                    dialog.run ();
                    dialog.destroy ();
                }
            } else {
                warning ("Row selection changed between operations. Cancelling removal of VPN.");
                GLib.Source.remove (timeout_id);
                timeout_id = 0;
                sel_row.show ();
            }
        }
    }

    [CCode (instance_pos = -1)]
    private int compare_rows (VPNMenuItem row1, VPNMenuItem row2) {
        unowned NM.SettingConnection vpn_menu_item1 = row1.connection.get_setting_connection ();
        unowned NM.SettingConnection vpn_menu_item2 = row2.connection.get_setting_connection ();

        if (vpn_menu_item1 != null && vpn_menu_item2 != null) {
            if (vpn_menu_item1.get_timestamp () > vpn_menu_item2.get_timestamp ()) {
                return -1;
            }
        }

        return 1;
    }
}
