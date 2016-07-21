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
    public class VPNInterface : AbstractVPNInterface {
        private NM.Client client;
        private VPNInfoBox vpn_info_box;

        public VPNInterface (NM.Client _client, NM.RemoteConnection _connection) {
            client = _client;
            connection = _connection;

            this.init (null);
            this.icon_name = "network-wireless-encrypted";

            vpn_info_box = new VPNInfoBox (connection);
            vpn_info_box.halign = Gtk.Align.CENTER;

            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            button_box.pack_end (new SettingsButton.from_connection (connection), false, false, 0);

            bottom_box.add (button_box);

            this.pack_start (vpn_info_box);
            this.pack_end (bottom_revealer, false, false, 0);
            show_all ();

            update ();
        }

        protected override void update () {
            vpn_info_box.update_status ();

            active_connection = null;
            client.get_active_connections ().foreach ((ac) => {
                if (ac.get_vpn () && ac.get_uuid () == connection.get_uuid ()) {
                    active_connection = (NM.VPNConnection)ac;
                }
            });

            if (active_connection != null) {
                switch (active_connection.get_vpn_state ()) {
                    case NM.VPNConnectionState.UNKNOWN:
                    case NM.VPNConnectionState.DISCONNECTED:
                        state = State.DISCONNECTED;
                        break;
                    case NM.VPNConnectionState.PREPARE:
                    case NM.VPNConnectionState.NEED_AUTH:
                    case NM.VPNConnectionState.IP_CONFIG_GET:
                    case NM.VPNConnectionState.CONNECT:
                        state = State.CONNECTING_VPN;
                        break;
                    case NM.VPNConnectionState.FAILED:
                        state = State.FAILED_VPN;
                        break;
                    case NM.VPNConnectionState.ACTIVATED:
                        state = State.CONNECTED_VPN;
                        break;
                }                
            }

            base.update ();
        }

        protected override void update_switch () {
            control_switch.active = state == State.CONNECTED_VPN;
        }

        protected override void control_switch_activated () {
            if (control_switch.get_active ()) {
                client.activate_connection (connection, null, null, null);
            } else {
                client.deactivate_connection (active_connection);
            }
        }
    }
}