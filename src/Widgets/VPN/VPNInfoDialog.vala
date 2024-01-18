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

public class Network.Widgets.VPNInfoDialog : Granite.MessageDialog {
    public NM.RemoteConnection? connection { get; construct; default = null; }

    private string service_type;

    private Gtk.Label vpn_type;
    private Gtk.Label gateway;
    private Gtk.Label username;

    public VPNInfoDialog (NM.RemoteConnection? connection) {
        Object (
            image_icon: new ThemedIcon ("network-vpn"),
            connection: connection
        );
    }

    construct {
        vpn_type = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        username = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        gateway = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        add_button (_("Edit Connection…"), 1);
        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        var box = new Gtk.Box (VERTICAL, 0);
        box.add (new Granite.HeaderLabel (("VPN Type")));
        box.add (vpn_type);
        box.add (new Granite.HeaderLabel (("Username")));
        box.add (username);
        box.add (new Granite.HeaderLabel (("Gateway")));
        box.add (gateway);
        box.show_all ();

        resizable = false;
        custom_bin.add (box);

        connection.changed.connect (update_status);
        update_status ();

        response.connect ((response) => {
            if (response == 1) {
                try {
                    var appinfo = AppInfo.create_from_commandline (
                        "nm-connection-editor --edit=%s".printf (connection.get_uuid ()),
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
                    ) {
                        badge_icon = new ThemedIcon ("dialog-error"),
                        modal = true,
                        transient_for = (Gtk.Window) get_toplevel ()
                    };
                    dialog.show_error_details (error.message);
                    dialog.present ();
                    dialog.response.connect (dialog.destroy);
                }
            }
            destroy ();
        });
    }

    private string get_key_group_username () {
        switch (service_type) {
            case "openvpn":
            case "openconnect":
                return "username";
            case "vpnc":
                return "Xauth username";
            case "pptp":
            case "l2tp":
                return "user";
            case "openswan":
                return "leftxauthusername";
        }

        return "";
    }

    private string get_key_gateway () {
        switch (service_type) {
            case "openvpn":
                return "remote";
            case "vpnc":
                return "IPSec gateway";
            case "pptp":
            case "l2tp":
            case "openconnect":
                return "gateway";
            case "openswan":
                return "right";
        }

        return "";
    }


    private static string get_service_type (NM.SettingVpn vpn_settings) {
        string service_type = vpn_settings.get_service_type ();
        string[] arr = service_type.split (".");
        return arr[arr.length - 1];
    }

    public void update_status () {
        if (connection == null) {
            return;
        }

        primary_text = connection.get_id ();

        switch (connection.get_connection_type ()) {
            case NM.SettingWireGuard.SETTING_NAME:
                service_type = NM.SettingWireGuard.SETTING_NAME;
                vpn_type.label = service_type;

                var wireguard_settings = (NM.SettingWireGuard) connection.get_setting (typeof (NM.SettingWireGuard));
                if (wireguard_settings != null) {
                    if (wireguard_settings.get_peers_len () >= 1) {
                        NM.WireGuardPeer first_peer = wireguard_settings.get_peer (0);
                        gateway.label = first_peer.get_endpoint ();
                        username.label = "";
                    }
                }
                break;
            case NM.SettingVpn.SETTING_NAME:
                var vpn_settings = connection.get_setting_vpn ();

                if (vpn_settings != null) {
                    service_type = get_service_type (vpn_settings);
                    vpn_type.label = service_type;

                    gateway.label = vpn_settings.get_data_item (get_key_gateway ());
                    username.label = vpn_settings.get_data_item (get_key_group_username ());
                }
                break;
        }

        vpn_type.visible = vpn_type.label != "";
        gateway.visible = gateway.label != "";
        username.visible = username.label != "";
    }
}
