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
    public class HotspotDialog : Gtk.Dialog {
        private const string NEW_ID = "0";
        private Gtk.Entry ssid_entry;
        private Gtk.Entry key_entry;
        private Gtk.Label ssid_label;
        private Gtk.Label key_label;
        private Gtk.ComboBoxText conn_combo;
        private Gtk.CheckButton check_btn;
        private Gtk.Button create_btn;

        private HashTable<string, NM.Connection> conn_hash;

        public unowned List<NM.Connection> available { get; construct; }
        public NM.AccessPoint? active { get; construct; }

        public HotspotDialog (NM.AccessPoint? active, List<NM.Connection> available) {
            Object (
                active: active,
                available: available
            );
        }

        construct {
            conn_hash = new HashTable<string, NM.Connection> (str_hash, str_equal);

            string? ssid_str = null;
            if (active != null) {
                ssid_str = NM.Utils.ssid_to_utf8 (active.get_ssid ().get_data ());
            } else {
                ssid_str = _("current");
            }

            var image = new Gtk.Image.from_icon_name ("network-wireless-hotspot", Gtk.IconSize.DIALOG);
            image.valign = Gtk.Align.START;

            var title = new Gtk.Label (_("Wireless Hotspot"));
            title.get_style_context ().add_class ("primary");
            title.xalign = 0;

            var info_label = new Gtk.Label (_("Enabling Wireless Hotspot will disconnect from %s network.").printf (ssid_str) + " " +
            _("You will not be able to connect to a wireless network while Hotspot is active."));
            info_label.xalign = 0;
            info_label.margin_bottom = 12;
            info_label.max_width_chars = 60;
            info_label.selectable = true;
            info_label.wrap = true;

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

            conn_combo = new Gtk.ComboBoxText ();
            conn_combo.append (NEW_ID, _("New…"));

            int i = 1;
            foreach (var connection in available) {
                var setting_wireless = connection.get_setting_wireless ();
                conn_combo.append (i.to_string (), NM.Utils.ssid_to_utf8 (setting_wireless.get_ssid ().get_data ()));
                conn_hash.insert (i.to_string (), connection);
                i++;
            }

            conn_combo.active_id = NEW_ID;
            conn_combo.changed.connect (update);

            var conn_label = new Gtk.Label (_("Connection:"));
            conn_label.halign = Gtk.Align.END;

            var main_grid = new Gtk.Grid ();
            main_grid.column_spacing = 12;
            main_grid.row_spacing = 6;
            main_grid.margin = 10;
            main_grid.margin_top = 0;
            main_grid.attach (image, 0, 0, 1, 6);
            main_grid.attach (title, 1, 0, 2, 1);
            main_grid.attach (info_label, 1, 1, 2, 1);
            main_grid.attach (conn_label, 1, 2, 1, 1);
            main_grid.attach (conn_combo, 2, 2, 1, 1);
            main_grid.attach (ssid_label, 1, 3, 1, 1);
            main_grid.attach (ssid_entry, 2, 3, 1, 1);
            main_grid.attach (key_label, 1, 4, 1, 1);
            main_grid.attach (key_entry, 2, 4, 1, 1);
            main_grid.attach (check_btn, 2, 5, 1, 1);

            get_content_area ().add (main_grid);

            var cancel_btn = new Gtk.Button.with_label (_("Cancel"));

            create_btn = new Gtk.Button.with_label (_("Enable Hotspot"));
            create_btn.get_style_context ().add_class ("suggested-action");

            if (active != null) {
                create_btn.label = _("Switch to Hotspot");
            }

            add_action_widget (cancel_btn, 0);
            add_action_widget (create_btn, 1);

            get_action_area ().margin = 5;

            deletable = false;
            resizable = false;
            window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

            update ();

            show_all ();
        }

        public ByteArray get_ssid () {
            var byte_array = new ByteArray ();
            byte_array.append (ssid_entry.get_text ().data);
            return byte_array;
        }

        public string get_key () {
            return key_entry.get_text ();
        }

        public NM.Connection? get_selected_connection () {
            return conn_hash[conn_combo.get_active_id ()];
        }

        private void update () {
            bool sensitive = (conn_combo.get_active_id () == NEW_ID);
            ssid_label.sensitive = sensitive;
            key_label.sensitive = sensitive;

            ssid_entry.sensitive = sensitive;
            key_entry.sensitive = sensitive;

            check_btn.sensitive = sensitive;

            string? secret = null;
            if (get_selected_connection () != null) {
                var setting_wireless_security = get_selected_connection ().get_setting_wireless_security ();

                string key_mgmt = setting_wireless_security.get_key_mgmt ();
                if (key_mgmt == "none") {
                    secret = setting_wireless_security.get_wep_key (0);
                } else if (key_mgmt == "wpa-psk" ||
                            key_mgmt == "wpa-none") {
                    secret = setting_wireless_security.get_psk ();
                }

                if (secret == null) {
                    var connection = get_selected_connection ();
                    Utils.Hotspot.update_secrets (((NM.RemoteConnection) connection), update);
                }
            }

            if (conn_combo.get_active_id () != NEW_ID) {
                ssid_entry.text = NM.Utils.ssid_to_utf8 (get_selected_connection ().get_setting_wireless ().get_ssid ().get_data ());
                if (secret == null) {
                    secret = "";
                }

                key_entry.text = secret;
            }

            create_btn.sensitive = ((ssid_entry.get_text () != "" && key_entry.get_text ().to_utf8 ().length >= 8) || !sensitive);

            if (key_entry.get_text ().to_utf8 ().length < 8 && key_entry.get_text () != "") {
                key_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-error-symbolic");
            } else {
                key_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "");
            }
        }
    }
}
