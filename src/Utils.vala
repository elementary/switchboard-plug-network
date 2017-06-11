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
    public const string UNKNOWN_STR = (_("Unknown"));

    public class Utils {
        public class Hotspot {
            public delegate void UpdateSecretCallback ();

            public static void activate_hotspot (NM.DeviceWifi wifi_device,
                                                ByteArray ssid,
                                                string key,
                                                NM.Connection? selected) {
                if (selected != null) {
                    client.activate_connection_async.begin (selected, wifi_device, null, null);
                    return;
                }

                var hotspot_c = new NM.SimpleConnection ();

                var setting_connection = new NM.SettingConnection ();
                setting_connection.@set (NM.SettingConnection.TYPE, "802-11-wireless");
                setting_connection.@set (NM.SettingConnection.ID, "Hotspot");
                setting_connection.autoconnect = false;
                hotspot_c.add_setting (setting_connection);

                var setting_wireless = new NM.SettingWireless ();

                string? mode = null;
                var caps = wifi_device.get_capabilities ();
                if ((caps & NM.DeviceWifiCapabilities.AP) != 0) {
                    mode = NM.SettingWireless.MODE_AP;
                } else {
                    mode = NM.SettingWireless.MODE_ADHOC;
                }

                setting_wireless.mode = mode;
                //setting_wireless.security = "802-11-wireless-security";

                hotspot_c.add_setting (setting_wireless);

                var ip4_setting = new NM.SettingIP4Config ();
                ip4_setting.method = "shared";
                hotspot_c.add_setting (ip4_setting);

                setting_wireless.@set (NM.SettingWireless.SSID, ssid);

                var setting_wireless_security = new NM.SettingWirelessSecurity ();

                if (mode == NM.SettingWireless.MODE_AP) {
                    if ((caps & NM.DeviceWifiCapabilities.RSN) != 0) {
                        set_wpa_key (setting_wireless_security, key);
                        setting_wireless_security.add_proto ("rsn");
                        setting_wireless_security.add_pairwise ("ccmp");
                        setting_wireless_security.add_group ("ccmp");
                    } else if ((caps & NM.DeviceWifiCapabilities.WPA) != 0) {
                        set_wpa_key (setting_wireless_security, key);
                        setting_wireless_security.add_proto ("wpa");
                        setting_wireless_security.add_pairwise ("tkip");
                        setting_wireless_security.add_group ("tkip");                       
                    } else {
                        set_wep_key (setting_wireless_security, key);
                    }
                } else {
                    set_wep_key (setting_wireless_security, key);
                }

                hotspot_c.add_setting (setting_wireless_security);
                client.add_and_activate_connection_async.begin (hotspot_c,
                                                    wifi_device,
                                                    null,
                                                    null);
            }

            public static void update_secrets (NM.RemoteConnection connection, UpdateSecretCallback callback) {
                /*connection.get_secrets (connection.get_setting_wireless ().get_security (), ((_connection, secrets, error) => {
                    var setting_wireless = _connection.get_setting_wireless ();
                    try {
                        _connection.update_secrets (setting_wireless.get_security (), secrets);
                    } catch (Error e) {
                        warning ("%s\n", e.message);
                        return;
                    }         

                    callback ();
                }));*/
            }

            public static void deactivate_hotspot (NM.DeviceWifi wifi_device) {
                client.get_active_connections ().@foreach ((active_connection) => {
                    var devices = active_connection.get_devices ();
                    if (devices != null && devices.@get (0) == wifi_device) {
                        client.deactivate_connection (active_connection);
                    }
                });        
            }

            private static void set_wpa_key (NM.SettingWirelessSecurity setting, string key) {
                setting.key_mgmt = "wpa-psk";
                setting.psk = key;
            }

            private static void set_wep_key (NM.SettingWirelessSecurity setting, string key) {
                setting.key_mgmt = "none";
                setting.wep_key0 = key;
                setting.wep_key_type = NM.WepKeyType.PASSPHRASE;
            }

            public static bool get_device_is_hotspot (NM.DeviceWifi wifi_device) {
                /*if (wifi_device.get_active_connection () != null) {
                    var connection = nm_settings.get_connection_by_path (wifi_device.get_active_connection ().get_connection ());
                    if (connection != null) {
                        var ip4_setting = connection.get_setting_ip4_config ();
                        return (ip4_setting != null && ip4_setting.get_method () == "shared");
                    }
                }*/

                return false;
            }

            public static bool get_connection_is_hotspot (NM.Connection connection) {
                var setting_connection = connection.get_setting_connection ();
                if (setting_connection.get_connection_type () != "802-11-wireless") {
                    return false;
                }

                var setting_wireless = connection.get_setting_wireless ();
                if (setting_wireless.get_mode () != "adhoc"
                    && setting_wireless.get_mode () != "ap") {
                    return false;
                }

                /*if (setting_wireless.get_security () != "802-11-wireless-security") {
                    return false;
                }*/

                var ip4_config = connection.get_setting_ip4_config ();
                if (ip4_config.get_method () != "shared") {
                    return false;
                }

                return true;
            }

            private static void finish_connection_cb (NM.Client? cb_client,
                                            NM.ActiveConnection? cb_connection,
                                            string? new_connection_path,
                                            Error? error) {
                if (error != null && error.code != 0) {
                    warning ("%s\n", error.message);
                }        
            }               
        }

        public enum CustomMode {
            PROXY_NONE = 0,
            PROXY_MANUAL,
            PROXY_AUTO,
            HOTSPOT_ENABLED,
            HOTSPOT_DISABLED,
            INVALID
        }

        public enum ItemType {
            DEVICE = 0,
            VIRTUAL,
            INVALID
        }

        public static string state_to_string (NM.DeviceState state) {
            switch (state) {
                case NM.DeviceState.ACTIVATED:
                    return _("Connected");
                case NM.DeviceState.DISCONNECTED:
                    return _("Disconnected");  
                case NM.DeviceState.UNMANAGED:
                    return _("Unmanaged");
                case NM.DeviceState.PREPARE:
                    return _("In preparation");
                case NM.DeviceState.CONFIG:
                    return _("Connecting…");
                case NM.DeviceState.NEED_AUTH:
                    return _("Requires more information");
                case NM.DeviceState.IP_CONFIG:
                    return _("Requesting adresses...");
                case NM.DeviceState.IP_CHECK:
                    return _("Checking connection...");
                case NM.DeviceState.SECONDARIES:
                    return _("Waiting for connection...");
                case NM.DeviceState.DEACTIVATING:
                    return _("Disconnecting...");
                case NM.DeviceState.FAILED:
                    return _("Failed to connect");
                case NM.DeviceState.UNKNOWN:
                default:
                    return UNKNOWN_STR;
            }
        }

        public static string type_to_string (NM.DeviceType type) {
            switch (type) {
                case NM.DeviceType.ETHERNET:
                    return _("Ethernet");
                case NM.DeviceType.WIFI:
                    return _("Wi-Fi");  
                case NM.DeviceType.UNUSED1:
                    return _("Not used");
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
                    return UNKNOWN_STR;
            }
        }
    }
}
