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
    public class HotspotDialog : Granite.MessageDialog {
        private Gtk.Entry ssid_entry;
        private Gtk.Entry key_entry;
        private Gtk.Label ssid_label;
        private Gtk.Label key_label;
        private Gtk.ComboBox conn_combo;
        private Gtk.CheckButton check_btn;
        private Gtk.Button create_btn;

        public NM.DeviceWifi device { get; construct; }

        public HotspotDialog (NM.DeviceWifi device) {
            unowned NM.AccessPoint active = device.get_active_access_point ();
            string? ssid_str = null;
            if (active != null) {
                ssid_str = NM.Utils.ssid_to_utf8 (active.get_ssid ().get_data ());
            } else {
                ssid_str = _("current");
            }

            Object (
                device: device,
                image_icon: new ThemedIcon ("network-wireless-hotspot"),
                primary_text: _("Wireless Hotspot"),
                secondary_text: _("Enabling Wireless Hotspot will disconnect from %s network.").printf (ssid_str) + " " +
                    _("You will not be able to connect to a wireless network while Hotspot is active."),
                deletable: false,
                resizable: false,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            ssid_entry = new Gtk.Entry ();
            ssid_entry.hexpand = true;
            ssid_entry.text = GLib.Environment.get_host_name ();

            key_entry = new Gtk.Entry ();
            key_entry.visibility = false;
            key_entry.secondary_icon_tooltip_text = _("Password needs to be at least 8 characters long.");

            check_btn = new Gtk.CheckButton.with_label (_("Show Password"));
            check_btn.bind_property ("active", key_entry, "visibility");

            ssid_entry.changed.connect (update);
            key_entry.changed.connect (update);

            ssid_label = new Gtk.Label (_("Network Name:"));
            ssid_label.halign = Gtk.Align.END;

            key_label = new Gtk.Label (_("Password:"));
            key_label.halign = Gtk.Align.END;

            var list_store = new Gtk.ListStore (2, typeof (string), typeof (NM.Connection));
            conn_combo = new Gtk.ComboBox.with_model (list_store);
            var renderer = new Gtk.CellRendererText ();
            conn_combo.pack_start (renderer, true);
            conn_combo.add_attribute (renderer, "text", 0);

            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, 0, _("New…"), -1);

            int i = 1;
            unowned NetworkManager network_manager = NetworkManager.get_default ();
            var connections = network_manager.client.get_connections ();
            connections.foreach ((connection) => {
                if (Utils.get_connection_is_hotspot (connection)) {
                    var setting_wireless = connection.get_setting_wireless ();
                    var ssid_name = NM.Utils.ssid_to_utf8 (setting_wireless.get_ssid ().get_data ());
                    list_store.append (out iter);
                    list_store.set (iter, 0, ssid_name, 1, connection);
                    i++;
                }
            });

            conn_combo.active = 0;
            conn_combo.changed.connect (update);

            var conn_label = new Gtk.Label (_("Connection:"));
            conn_label.halign = Gtk.Align.END;

            var main_grid = new Gtk.Grid ();
            main_grid.column_spacing = 12;
            main_grid.row_spacing = 6;
            main_grid.attach (conn_label, 1, 2, 1, 1);
            main_grid.attach (conn_combo, 2, 2, 1, 1);
            main_grid.attach (ssid_label, 1, 3, 1, 1);
            main_grid.attach (ssid_entry, 2, 3, 1, 1);
            main_grid.attach (key_label, 1, 4, 1, 1);
            main_grid.attach (key_entry, 2, 4, 1, 1);
            main_grid.attach (check_btn, 2, 5, 1, 1);

            custom_bin.add (main_grid);
            custom_bin.show_all ();

            add_button (_("Cancel"), 0);

            create_btn = (Gtk.Button) add_button (_("Enable Hotspot"), 1);
            create_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

            unowned NM.AccessPoint active = device.get_active_access_point ();
            if (active != null) {
                create_btn.label = _("Switch to Hotspot");
            }

            update ();
        }

        private unowned NM.Connection? get_selected_connection () {
            unowned NM.Connection? connection;
            Gtk.TreeIter iter;
            conn_combo.get_active_iter (out iter);
            conn_combo.model.get (iter, 1, out connection);
            return connection;
        }

        private void update () {
            bool sensitive = (conn_combo.active == 0);
            ssid_label.sensitive = sensitive;
            key_label.sensitive = sensitive;

            ssid_entry.sensitive = sensitive;
            key_entry.sensitive = sensitive;

            check_btn.sensitive = sensitive;

            string? secret = null;
            unowned NM.Connection? selected_connection = get_selected_connection ();
            if (selected_connection != null) {
                unowned NM.SettingWirelessSecurity setting_wireless_security = selected_connection.get_setting_wireless_security ();

                string key_mgmt = setting_wireless_security.get_key_mgmt ();
                if (key_mgmt == "none") {
                    secret = setting_wireless_security.wep_key0;
                } else if (key_mgmt == "wpa-psk" || key_mgmt == "wpa-none") {
                    secret = setting_wireless_security.psk;
                }

                if (secret == null) {
                    Utils.update_secrets (((NM.RemoteConnection) selected_connection), update);
                }
            }

            if (conn_combo.active != 0) {
                ssid_entry.text = NM.Utils.ssid_to_utf8 (selected_connection.get_setting_wireless ().get_ssid ().get_data ());
                if (secret == null) {
                    secret = "";
                }

                key_entry.text = secret;
            }

            bool key_text_over_8 = key_entry.text.length >= 8;
            create_btn.sensitive = ((ssid_entry.get_text () != "" && key_text_over_8 ) || !sensitive);

            if (!key_text_over_8 && key_entry.get_text () != "") {
                key_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-error-symbolic");
            } else {
                key_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            }
        }

        public override void response (int response_id) {
            if (response_id == 1) {
                connect_to_hotspot.begin ();
            } else {
                destroy ();
            }
        }

        private async void connect_to_hotspot () {
            unowned NetworkManager network_manager = NetworkManager.get_default ();
            yield network_manager.activate_hotspot (
                device,
                ssid_entry.text,
                key_entry.text,
                get_selected_connection ()
            );

            destroy ();
        }
    }
}
