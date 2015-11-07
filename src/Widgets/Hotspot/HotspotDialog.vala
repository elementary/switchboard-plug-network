// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-plug-networking)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com
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
        private Gtk.Label dumb;

        private Gtk.Button create_btn;

        private HashTable<string, NM.Connection> conn_hash;
        private unowned List<NM.Connection> available;

        public HotspotDialog (NM.AccessPoint? active, List<NM.Connection> _available) {
            this.available = _available;
            this.deletable = false;
            this.resizable = false;
            this.border_width = 6;

            conn_hash = new HashTable<string, NM.Connection> (str_hash, str_equal);

            var content_area = this.get_content_area ();
            content_area.halign = content_area.valign = Gtk.Align.CENTER;

            var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            vbox.margin_left = vbox.margin_right = 6;

            string? ssid_str = null;
            if (active != null) {
                ssid_str = NM.Utils.ssid_to_utf8 (active.get_ssid ());
            } else {
                ssid_str = _("current");
            }

            var title = new Gtk.Label ("<span weight='bold' size='larger'>" + _("Wireless Hotspot") + "</span>");
            title.use_markup = true;
            title.halign = Gtk.Align.START;

            var image = new Gtk.Image.from_icon_name ("network-wireless-hotspot", Gtk.IconSize.DIALOG);
            image.valign = Gtk.Align.START;
            main_box.add (image);

            var info_label = new Gtk.Label (_("Enabling Wireless Hotspot will disconnect from %s network.").printf (ssid_str) + "\n" +
            _("You will not be able to connect to a wireless network while Hotspot is active."));
            info_label.halign = Gtk.Align.START;
            info_label.margin_top = 6;
            info_label.use_markup = true;

            var grid = new Gtk.Grid ();
            grid.hexpand = true;
            grid.row_spacing = 6;
            grid.column_spacing = 12;
            grid.vexpand_set = true;

            ssid_entry = new Gtk.Entry ();
            ssid_entry.hexpand = true;
            ssid_entry.text = get_ssid_for_hotspot ();

            key_entry = new Gtk.Entry ();
            key_entry.hexpand = true;
            key_entry.visibility = false;
            key_entry.secondary_icon_tooltip_text = _("Password needs to be at least 8 characters long.");

            check_btn = new Gtk.CheckButton.with_label (_("Show Password"));
            check_btn.toggled.connect (() => {
                key_entry.visibility = check_btn.active;
            });

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
                conn_combo.append (i.to_string (), NM.Utils.ssid_to_utf8 (setting_wireless.get_ssid ()));
                conn_hash.insert (i.to_string (), connection);
                i++;
            }

            conn_combo.active_id = NEW_ID;
            conn_combo.changed.connect (update);

            var conn_label = new Gtk.Label (_("Connection:"));
            conn_label.halign = Gtk.Align.END;

            grid.attach (conn_label, 0, 0, 1, 1);
            grid.attach_next_to (conn_combo, conn_label, Gtk.PositionType.RIGHT, 1, 1);

            dumb = new Gtk.Label ("");

            grid.attach_next_to (ssid_label, conn_label, Gtk.PositionType.BOTTOM, 1, 1);
            grid.attach_next_to (ssid_entry, ssid_label, Gtk.PositionType.RIGHT, 1, 1);
            grid.attach_next_to (key_label, ssid_label, Gtk.PositionType.BOTTOM, 1, 1);
            grid.attach_next_to (key_entry, key_label, Gtk.PositionType.RIGHT, 1, 1);
            grid.attach_next_to (dumb, key_label, Gtk.PositionType.BOTTOM, 1, 1);
            grid.attach_next_to (check_btn, dumb, Gtk.PositionType.RIGHT, 1, 1);

            var cancel_btn = new Gtk.Button.with_label (_("Cancel"));
            create_btn = new Gtk.Button.with_label (_("Enable Hotspot"));
            if (active != null) {
                create_btn.label = _("Switch to Hotspot");
            }

            create_btn.get_style_context ().add_class ("suggested-action");

            this.add_action_widget (cancel_btn, 0);
            this.add_action_widget (create_btn, 1);

            vbox.add (title);
            vbox.add (info_label);
            vbox.add (grid);

            update ();

            main_box.add (vbox);
            content_area.add (main_box);
            this.show_all ();
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

        private string get_ssid_for_hotspot () {
            string hostname = "";
            try {
                Process.spawn_command_line_sync ("hostname", out hostname, null, null);
            } catch (SpawnError e) {
                warning ("%s\n", e.message);
            }

            return hostname.strip ().replace ("\n", "");
        }

        private void update () {
            bool sensitive = (conn_combo.get_active_id () == NEW_ID);
            ssid_label.sensitive = sensitive;
            key_label.sensitive = sensitive;

            ssid_entry.sensitive = sensitive;
            key_entry.sensitive = sensitive;

            check_btn.sensitive = sensitive;
            dumb.sensitive = sensitive;

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
                ssid_entry.text = NM.Utils.ssid_to_utf8 (get_selected_connection ().get_setting_wireless ().get_ssid ());
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