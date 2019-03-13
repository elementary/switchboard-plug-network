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
    public class HotspotInterface : Network.WidgetNMInterface {
        public WifiInterface root_iface { get; construct; }
        private Gtk.Stack hotspot_stack;
        private Gtk.Button hotspot_settings_btn;
        private Gtk.Box hinfo_box;
        private Gtk.Label warning_label;
        private Gtk.Label ssid_label;
        private Gtk.Label key_label;
        private bool switch_updating = false;

        public HotspotInterface (WifiInterface root_iface) {
            Object (
                activatable: true,
                root_iface: root_iface,
                device: root_iface.device,
                icon_name: "network-wireless-hotspot"
            );
        }

        construct {
            hotspot_stack = new Gtk.Stack ();
            hotspot_stack.transition_type = Gtk.StackTransitionType.UNDER_UP;

            warning_label = new Gtk.Label (_("Turning on the Hotspot Mode will disconnect from any connected wireless networks."));
            warning_label.halign = Gtk.Align.CENTER;
            warning_label.wrap = true;

            hotspot_settings_btn = new SettingsButton.from_device (device, _("Hotspot Settings…"));

            hinfo_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            ssid_label = new Gtk.Label (null);
            ssid_label.halign = Gtk.Align.START;

            key_label = new Gtk.Label (null);
            key_label.halign = Gtk.Align.START;

            hinfo_box.add (ssid_label);
            hinfo_box.add (key_label);

            hotspot_stack.add_named (warning_label, "warning_label");
            hotspot_stack.add_named (hinfo_box, "hinfo_box");

            action_area.add (hotspot_settings_btn);

            device.state_changed.connect (update);

            update ();

            content_area.add (hotspot_stack);

            show_all ();
        }

        public override void update_name (int count) {
            if (count <= 1) {
                title = _("Hotspot");
            }
            else {
                title = _("Hotspot %s").printf (device.get_description ());
            }
        }

        protected override void update () {
            var root_iface_is_hotsport = Utils.get_device_is_hotspot (root_iface.wifi_device);
            if (hotspot_settings_btn != null) {
                hotspot_settings_btn.sensitive = root_iface_is_hotsport;
            }

            update_hotspot_info ();
            update_switch ();

            if (root_iface_is_hotsport) {
                state = State.CONNECTED_WIFI;
            } else {
                state = State.DISCONNECTED;
            }
        }

        protected override void update_switch () {
            switch_updating = true;
            status_switch.active = state == Network.State.CONNECTED_WIFI;
            switch_updating = false;
        }

        protected override void control_switch_activated () {
            if (switch_updating) {
                switch_updating = false;
                return;
            }

            var wifi_device = (NM.DeviceWifi)device;
            if (!status_switch.active && Utils.get_device_is_hotspot (wifi_device)) {
                unowned NetworkManager network_manager = NetworkManager.get_default ();
                network_manager.deactivate_hotspot.begin (wifi_device);
            } else {
                var hotspot_dialog = new HotspotDialog (wifi_device);
                hotspot_dialog.response.connect ((response) => {
                    if (response != 1) {
                        switch_updating = true;
                        status_switch.active = false;
                    }
                });

                hotspot_dialog.show_all ();
            }
        }

        private void update_hotspot_info () {
            var wifi_device = (NM.DeviceWifi)device;
            bool hotspot_mode = Utils.get_device_is_hotspot (wifi_device);

            var mode = Utils.CustomMode.HOTSPOT_DISABLED;

            if (hotspot_mode) {
                mode = Utils.CustomMode.HOTSPOT_ENABLED;
            }

            if (hotspot_mode) {
                hotspot_stack.set_visible_child (hinfo_box);
            } else {
                hotspot_stack.set_visible_child (warning_label);
            }

            if (hotspot_mode) {
                var connection = wifi_device.get_active_connection ().get_connection ();

                var setting_wireless = connection.get_setting_wireless ();
                ssid_label.label = _("Network Name (SSID): %s").printf (NM.Utils.ssid_to_utf8 (setting_wireless.get_ssid ().get_data ()));

                var setting_wireless_security = connection.get_setting_wireless_security ();

                string key_mgmt = setting_wireless_security.get_key_mgmt ();
                string? secret = null;
                string security = "";
                if (key_mgmt == "none") {
                    secret = setting_wireless_security.get_wep_key (0);
                    security = _("(WEP)");
                } else if (key_mgmt == "wpa-psk" ||
                            key_mgmt == "wpa-none") {
                    security = _("(WPA)");
                    secret = setting_wireless_security.get_psk ();
                }

                if (secret == null) {
                    Utils.update_secrets (connection, update);
                    return;
                }

                key_label.label = _("Password %s: %s").printf (security, secret);
            }
        }
    }
}
