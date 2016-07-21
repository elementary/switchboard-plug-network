/*-
 * Copyright (c) 2015-2016 elementary LLC.
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
    public class VPNInfoBox : Gtk.Grid {
        private NM.RemoteConnection connection;
        private string service_type;

        private Gtk.Label type;
        private Gtk.Label gateway;
        private Gtk.Label username;
        private Gtk.Label password;

        public VPNInfoBox (NM.RemoteConnection _connection) {
            connection = _connection;

            column_spacing = 12;
            row_spacing = 6;

            var type_head = new Gtk.Label (_("VPN Type:"));
            type_head.halign = Gtk.Align.END;

            var gateway_head = new Gtk.Label (_("Gateway:"));
            gateway_head.halign = Gtk.Align.END;

            var username_head = new Gtk.Label (_("Username:"));
            username_head.halign = Gtk.Align.END;

            var password_head = new Gtk.Label (_("Password:"));
            password_head.halign = Gtk.Align.END;

            type = new Gtk.Label ("");
            type.selectable = true;
            type.xalign = 0;
            type.no_show_all = true;

            gateway = new Gtk.Label ("");
            gateway.selectable = true;
            gateway.xalign = 0;
            gateway.no_show_all = true;

            username = new Gtk.Label ("");
            username.selectable = true;
            username.xalign = 0;
            username.no_show_all = true;

            password = new Gtk.Label ("");
            password.selectable = true;
            password.xalign = 0;
            password_head.no_show_all = true;

            attach (type_head, 0, 0);
            attach_next_to (type, type_head, Gtk.PositionType.RIGHT);

            attach_next_to (gateway_head, type_head, Gtk.PositionType.BOTTOM);
            attach_next_to (gateway, gateway_head, Gtk.PositionType.RIGHT);

            attach_next_to (username_head, gateway_head, Gtk.PositionType.BOTTOM);
            attach_next_to (username, username_head, Gtk.PositionType.RIGHT);

            attach_next_to (password_head, username_head, Gtk.PositionType.BOTTOM);
            attach_next_to (password, password_head, Gtk.PositionType.RIGHT);

            connection.changed.connect (update_status);

            update_status ();
        }

        // From https://github.com/GNOME/gnome-control-center/blob/master/panels/network/net-vpn.c
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

        private string get_key_group_password () {
            if (service_type == "vpnc") {
                return "Xauth password";
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
            service_type = get_service_type ();

            var setting_vpn = connection.get_setting_vpn ();
            type.label = get_service_type ();
            gateway.label = setting_vpn.get_data_item (get_key_gateway ());
            username.label = setting_vpn.get_data_item (get_key_group_username ());
            password.label = setting_vpn.get_data_item (get_key_group_password ());

            type.visible = type.label != "";
            gateway.visible = gateway.label != "";
            username.visible = username.label != "";
            password.visible = password.label != "";
        }
    }
}