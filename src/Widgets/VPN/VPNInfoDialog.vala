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

public class Network.Widgets.VPNInfoDialog : Gtk.Popover {
    public string state_label { get; set; }
    public NM.RemoteConnection? connection { get; construct; default = null; }

    private string service_type;

    private Gtk.Label vpn_type;
    private Gtk.Label gateway;
    private Gtk.Label username;

    public VPNInfoDialog (NM.RemoteConnection? connection) {
        Object (connection: connection);
    }

    construct {
        var state_label = new Gtk.Label ("");
        state_label.selectable = true;
        state_label.xalign = 0;

        vpn_type = new Gtk.Label ("");
        vpn_type.selectable = true;
        vpn_type.xalign = 0;
        vpn_type.no_show_all = true;

        username = new Gtk.Label ("");
        username.selectable = true;
        username.xalign = 0;
        username.no_show_all = true;

        gateway = new Gtk.Label ("");
        gateway.selectable = true;
        gateway.xalign = 0;
        gateway.no_show_all = true;

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.column_spacing = 6;
        grid.row_spacing = 6;

        grid.attach (new VPNInfoLabel (_("Status: ")), 0, 0);
        grid.attach (state_label, 1, 0);

        grid.attach (new VPNInfoLabel (_("VPN Type: ")), 0, 1);
        grid.attach (vpn_type, 1, 1);

        grid.attach (new VPNInfoLabel (_("Username: ")), 0, 2);
        grid.attach (username, 1, 2);

        grid.attach (new VPNInfoLabel (_("Gateway: ")), 0, 3);
        grid.attach (gateway, 1, 3);

        grid.show_all ();

        add (grid);

        bind_property ("state-label", state_label, "label");

        connection.changed.connect (update_status);
        update_status ();
    }

    //  From https://github.com/GNOME/gnome-control-center/blob/master/panels/network/net-vpn.c
    private string get_key_group_username () {
        switch (service_type) {
            case "openvpn":
            case "openconnect":
                return "username";
            case "vpnc":
                return "Xauth username";
            case "pptp":
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
            case "openconnect":
                return "gateway";
            case "openswan":
                return "right";
        }

        return "";
    }


    private string get_service_type () {
        var setting_vpn = connection.get_setting_vpn ();
        string service_type = setting_vpn.get_service_type ();
        string[] arr = service_type.split (".");
        return arr[arr.length - 1];
    }

    public void update_status () {
        if (connection == null) {
            return;
        }

        service_type = get_service_type ();

        var setting_vpn = connection.get_setting_vpn ();
        vpn_type.label = get_service_type ();
        gateway.label = setting_vpn.get_data_item (get_key_gateway ());
        username.label = setting_vpn.get_data_item (get_key_group_username ());

        vpn_type.visible = vpn_type.label != "";
        gateway.visible = gateway.label != "";
        username.visible = username.label != "";
    }

    private class VPNInfoLabel : Gtk.Label {
        public VPNInfoLabel (string label_text) {
            Object (
                halign: Gtk.Align.END,
                justify: Gtk.Justification.RIGHT,
                label: label_text
            );
        }
    }
}
