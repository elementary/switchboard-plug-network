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

namespace Network {
    public class Device : Object {
        public enum ActivityResult {
            NONE,
            SENT,
            RECEIVED,
        }

        public NM.Device target { get; construct; }

        public string icon_name { get; set; }
        public string title { get; set; default = _("Unknown"); }
        public bool updating { get; set; default = false; }
        public bool valid { get; construct; default = false; }

        construct {
            switch (target.get_device_type ()) {
                case NM.DeviceType.ETHERNET:
                    icon_name = "network-wired";
                    valid = true;
                    break;
                case NM.DeviceType.WIFI:
                    icon_name = "network-wireless";
                    valid = true;
                    break;
                default:
                    break;
            }
        }

        public Device (NM.Device target) {
            Object (target: target);
        }

        public bool compare (Device device) {
            return target.get_udi () == device.target.get_udi ();
        }

        public NM.Connection? find_available_connection () {
            var ac = target.get_active_connection ();
            if (ac != null) {
                return ac.get_connection ();
            }

            NM.Connection? connection = null;
            target.get_available_connections ().@foreach ((conn) => {
                if (conn.get_setting_connection () == null) {
                    return;
                }

                connection = conn;
            });

            return connection;
        }

        public unowned string get_type_string () {
            switch (target.get_device_type ()) {
                case NM.DeviceType.ETHERNET:
                    return _("Ethernet");
                case NM.DeviceType.WIFI:
                    return _("Wi-Fi");  
                case NM.DeviceType.UNUSED1:
                case NM.DeviceType.UNUSED2:
                    return _("Not used");
                case NM.DeviceType.BT:
                    return _("Bluetooth");
                case NM.DeviceType.OLPC_MESH:
                    return _("OLPC XO");
                case NM.DeviceType.WIMAX:
                    return _("WiMAX Broadband");
                case NM.DeviceType.MODEM:
                    return _("Modem");
                case NM.DeviceType.INFINIBAND:
                    return _("InfiniBand device");
                case NM.DeviceType.BOND:
                    return _("Bond master");
                case NM.DeviceType.VLAN:
                    return _("VLAN Interface");
                case NM.DeviceType.ADSL:
                    return _("ADSL Modem");
                case NM.DeviceType.BRIDGE:
                    return _("Bridge master");
                case NM.DeviceType.UNKNOWN:
                default:
                    return _("Unknown");
            }
        }

        public void get_state_data (out unowned string description, out unowned string icon) {
            switch (target.get_state ()) {
                case NM.DeviceState.ACTIVATED:
                    description = _("Connected");
                    icon = "user-available";
                    break;
                case NM.DeviceState.DISCONNECTED:
                    description = _("Disconnected");
                    icon = "user-busy";
                    break;
                case NM.DeviceState.UNMANAGED:
                    description = _("Unmanaged");
                    icon = "user-invisible";
                    break;
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.SECONDARIES:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.IP_CHECK:
                    description = _("Connecting…");
                    icon = "user-away";
                    break;
                case NM.DeviceState.NEED_AUTH:
                    description = _("Waiting for authentication");
                    icon = "user-away";
                    break;
                case NM.DeviceState.DEACTIVATING:
                    description = _("Disconnecting...");
                    icon = "user-away";
                    break;
                case NM.DeviceState.FAILED:
                    description = _("Failed to connect");
                    icon = "user-busy";
                    break;
                default:
                    description = _("Unknown");
                    icon = "user-offline";
                    break;
            }
        }

        public ActivityResult get_activity_information (out uint64 sent, out uint64 received) {
            sent = 0;
            received = 0;

            var result = ActivityResult.NONE;

            string iface = target.get_iface ();

            string tx_bytes_path = Path.build_filename ("/sys/class/net", iface, "statistics/tx_bytes");
            string rx_bytes_path = Path.build_filename ("/sys/class/net/", iface, "statistics/rx_bytes");

            string contents;
            try {
                if (FileUtils.test (tx_bytes_path, FileTest.EXISTS)) {
                    FileUtils.get_contents (tx_bytes_path, out contents);
                    sent = uint64.parse (contents);
                    result = ActivityResult.SENT;
                }

                if (FileUtils.test (rx_bytes_path, FileTest.EXISTS)) {
                    FileUtils.get_contents (rx_bytes_path, out contents);
                    received = uint64.parse (contents);
                    result |= ActivityResult.RECEIVED;
                }
            } catch (FileError e) {
                error ("%s\n", e.message);
            }        

            return result;
        }
    }
}