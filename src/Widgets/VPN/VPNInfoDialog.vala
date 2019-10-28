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

public class Network.Widgets.VPNInfoDialog : Gtk.Dialog {
    private NM.RemoteConnection? connection = null;
    private string service_type;

    private Gtk.Label vpn_type;
    private Gtk.Label gateway;
    private Gtk.Label username;

    public string state { get; construct; }

    public VPNInfoDialog (string state) {
        Object (
            deletable: false,
            modal: true,
            resizable: true,
            state: state
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("network-vpn", Gtk.IconSize.DIALOG);
        image.hexpand = true;
        image.halign = Gtk.Align.CENTER;

        var data_grid = new Gtk.Grid ();
        data_grid.expand = true;
        data_grid.halign = Gtk.Align.START;

        var state_label = new Gtk.Label (state);
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

        data_grid.attach (new VPNInfoLabel (_("Status: ")), 0, 0, 1, 1);
        data_grid.attach (state_label, 1, 0, 2, 1);

        data_grid.attach (new VPNInfoLabel (_("VPN Type: ")), 3, 0, 1, 1);
        data_grid.attach (vpn_type, 4, 0, 2, 1);

        data_grid.attach (new VPNInfoLabel (_("Username: ")), 0, 1, 1, 1);
        data_grid.attach (username, 1, 1, 2, 1);

        data_grid.attach (new VPNInfoLabel (_("Gateway: ")), 0, 2, 1, 1);
        data_grid.attach (gateway, 1, 2, 5, 1);

        data_grid.show_all ();


        var grid = new Gtk.Grid ();
        grid.expand = true;
        grid.margin_start = grid.margin_end = 12;
        grid.column_spacing = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;

        grid.add (image);
        grid.add (data_grid);
        grid.show_all ();

        get_content_area ().add (grid);

        add_button (_("_Close"), Gtk.ResponseType.CLOSE);
    }

    public void set_connection (NM.RemoteConnection _connection) {
        connection = _connection;
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
}
