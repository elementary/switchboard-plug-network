/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 */

// TODO put them inside the class.

public class Network.NetworkManager : GLib.Object {
    private static NetworkManager network_manager;
    public static unowned NetworkManager get_default () {
        if (network_manager == null) {
            network_manager = new NetworkManager ();
        }

        return network_manager;
    }

    /* Main client instance */
    public NM.Client client { get; construct; }

    construct {
        try {
            client = new NM.Client ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    public async void activate_hotspot (NM.DeviceWifi wifi_device, string ssid, string key, NM.Connection? selected) {
        if (selected != null) {
            try {
                yield client.activate_connection_async (selected, wifi_device, null, null);
            } catch (Error error) {
                critical (error.message);
            }

            return;
        }

        var hotspot_c = NM.SimpleConnection.new ();

        var setting_connection = new NM.SettingConnection ();
        setting_connection.type = "802-11-wireless";
        setting_connection.id = "Hotspot";
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

        hotspot_c.add_setting (setting_wireless);

        var ip4_setting = new NM.SettingIP4Config ();
        ip4_setting.method = "shared";
        hotspot_c.add_setting (ip4_setting);

        setting_wireless.ssid = new GLib.Bytes (ssid.data);

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
        try {
            yield client.add_and_activate_connection_async (hotspot_c, wifi_device, null, null);
        } catch (Error error) {
            critical (error.message);
        }
    }

    public async void deactivate_hotspot (NM.DeviceWifi wifi_device) {
        unowned NM.ActiveConnection active_connection = wifi_device.get_active_connection ();
        try {
            client.deactivate_connection (active_connection);
        } catch (Error e) {
            critical (e.message);
        }
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
}
