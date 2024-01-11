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
    public class ConfigurationPage : Gtk.Box {
        private Gtk.CheckButton auto_button;
        private Gtk.CheckButton manual_button;

        private Gtk.Entry auto_entry;

        private Gtk.Entry http_entry;
        private Gtk.Entry https_entry;
        private Gtk.Entry ftp_entry;
        private Gtk.Entry socks_entry;

        private Gtk.SpinButton http_spin;
        private Gtk.SpinButton https_spin;
        private Gtk.SpinButton ftp_spin;
        private Gtk.SpinButton socks_spin;

        private Gtk.Button apply_button;

        private GLib.Settings ftp_settings;
        private GLib.Settings http_settings;
        private GLib.Settings https_settings;
        private GLib.Settings socks_settings;

        public ConfigurationPage () {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 12
            );
        }

        construct {
            margin_top = 12;
            halign = Gtk.Align.CENTER;

            ftp_settings = new GLib.Settings ("org.gnome.system.proxy.ftp");
            http_settings = new GLib.Settings ("org.gnome.system.proxy.http");
            https_settings = new GLib.Settings ("org.gnome.system.proxy.https");
            socks_settings = new GLib.Settings ("org.gnome.system.proxy.socks");

            auto_button = new Gtk.CheckButton.with_label (_("Automatic proxy configuration"));
            manual_button = new Gtk.CheckButton.with_label (_("Manual proxy configuration")) {
                group = auto_button
            };

            auto_entry = new Gtk.Entry () {
                placeholder_text = _("URL to configuration script")
            };

            var http_label = new Gtk.Label (_("HTTP Proxy:")) {
                xalign = 1
            };
            http_entry = new Gtk.Entry () {
                placeholder_text = _("proxy.example.com"),
                hexpand = true
            };
            var http_port_label = new Gtk.Label (_("Port:"));
            http_spin = new Gtk.SpinButton.with_range (0, ushort.MAX, 1);

            var use_all_check = new Gtk.CheckButton.with_label (_("Use this proxy server for all protocols"));

            var https_label = new Gtk.Label (_("HTTPS Proxy:")) {
                xalign = 1
            };
            https_entry = new Gtk.Entry () {
                placeholder_text = _("proxy.example.com"),
                hexpand = true
            };
            var https_port_label = new Gtk.Label (_("Port:"));
            https_spin = new Gtk.SpinButton.with_range (0, ushort.MAX, 1);

            var ftp_label = new Gtk.Label (_("FTP Proxy:")) {
                xalign = 1
            };
            ftp_entry = new Gtk.Entry () {
                placeholder_text = _("proxy.example.com")
            };
            var ftp_port_label = new Gtk.Label (_("Port:"));
            ftp_spin = new Gtk.SpinButton.with_range (0, ushort.MAX, 1);
            var socks_label = new Gtk.Label (_("SOCKS Host:")) {
                xalign = 1
            };
            socks_entry = new Gtk.Entry () {
                placeholder_text = _("proxy.example.com")
            };
            var socks_port_label = new Gtk.Label (_("Port:"));
            socks_spin = new Gtk.SpinButton.with_range (0, ushort.MAX, 1);

            var other_protocols_grid = new Gtk.Grid () {
                column_spacing = 6,
                row_spacing = 12
            };
            other_protocols_grid.attach (https_label, 0, 0);
            other_protocols_grid.attach_next_to (https_entry, https_label, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (https_port_label, https_entry, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (https_spin, https_port_label, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (ftp_label, https_label, Gtk.PositionType.BOTTOM);
            other_protocols_grid.attach_next_to (ftp_entry, ftp_label, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (ftp_port_label, ftp_entry, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (ftp_spin, ftp_port_label, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (socks_label, ftp_label, Gtk.PositionType.BOTTOM);
            other_protocols_grid.attach_next_to (socks_entry, socks_label, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (socks_port_label, socks_entry, Gtk.PositionType.RIGHT);
            other_protocols_grid.attach_next_to (socks_spin, socks_port_label, Gtk.PositionType.RIGHT);

            var label_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            label_size_group.add_widget (http_label);
            label_size_group.add_widget (https_label);

            var port_label_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            port_label_size_group.add_widget (http_port_label);
            port_label_size_group.add_widget (https_port_label);

            var entry_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            entry_size_group.add_widget (http_entry);
            entry_size_group.add_widget (https_entry);

            var spin_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            spin_size_group.add_widget (http_spin);
            spin_size_group.add_widget (https_spin);

            apply_button = new Gtk.Button.with_label (_("Apply"));
            apply_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

            var reset_button = new Gtk.Button.with_label (_("Reset all settings"));
            reset_button.clicked.connect (on_reset_btn_clicked);

            var apply_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_top = 12
            };
            apply_box.append (reset_button);
            apply_box.append (apply_button);

            var config_grid = new Gtk.Grid () {
                orientation = Gtk.Orientation.VERTICAL,
                halign = Gtk.Align.CENTER,
                column_spacing = 6,
                row_spacing = 12
            };
            config_grid.attach (http_label, 0, 0, 1, 1);
            config_grid.attach (http_entry, 1, 0, 1, 1);
            config_grid.attach (http_port_label, 2, 0, 1, 1);
            config_grid.attach (http_spin, 3, 0, 1, 1);
            config_grid.attach (use_all_check, 1, 1, 3, 1);
            config_grid.attach (other_protocols_grid, 0, 2, 4, 1);

            append (auto_button);
            append (auto_entry);
            append (manual_button);
            append (config_grid);
            append (apply_box);

            auto_button.bind_property ("active", auto_entry, "sensitive", BindingFlags.DEFAULT);
            use_all_check.bind_property ("active", other_protocols_grid, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
            apply_button.clicked.connect (() => apply_settings ());
            manual_button.bind_property ("active", config_grid, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            use_all_check.notify["active"].connect (() => {
                https_entry.text = http_entry.text;
                https_spin.value = http_spin.value;
                ftp_entry.text = http_entry.text;
                ftp_spin.value = http_spin.value;
                socks_entry.text = http_entry.text;
                socks_spin.value = http_spin.value;
                verify_applicable ();
            });

            auto_entry.notify["text"].connect (() => verify_applicable ());

            http_entry.notify["text"].connect (() => {
                if (use_all_check.active) {
                    https_entry.text = http_entry.text;
                    ftp_entry.text = http_entry.text;
                    socks_entry.text = http_entry.text;
                }

                verify_applicable ();
            });

            http_spin.notify["value"].connect (() => {
                if (use_all_check.active) {
                    https_spin.value = http_spin.value;
                    ftp_spin.value = http_spin.value;
                    socks_spin.value = http_spin.value;
                }
            });

            https_entry.notify["text"].connect (() => verify_applicable ());
            ftp_entry.notify["text"].connect (() => verify_applicable ());
            socks_entry.notify["text"].connect (() => verify_applicable ());

            auto_button.notify["active"].connect (() => verify_applicable ());
            manual_button.notify["active"].connect (() => verify_applicable ());

            auto_entry.text = Network.Plug.proxy_settings.get_string ("autoconfig-url");
            http_entry.text = http_settings.get_string ("host");
            http_spin.value = http_settings.get_int ("port");
            https_entry.text = https_settings.get_string ("host");
            https_spin.value = https_settings.get_int ("port");
            ftp_entry.text = ftp_settings.get_string ("host");
            ftp_spin.value = ftp_settings.get_int ("port");
            socks_entry.text = socks_settings.get_string ("host");
            socks_spin.value = socks_settings.get_int ("port");
            if (http_entry.text == https_entry.text &&
                http_entry.text == ftp_entry.text &&
                http_entry.text == socks_entry.text &&
                http_spin.value == https_spin.value &&
                http_spin.value == ftp_spin.value &&
                http_spin.value == socks_spin.value) {
                use_all_check.active = true;
            }

            if (Network.Plug.proxy_settings.get_string ("mode") == "auto") {
                auto_button.active = true;
            } else {
                manual_button.active = true;
            }

            verify_applicable ();
        }

        private void verify_applicable () {
            if (auto_button.active) {
                apply_button.sensitive = auto_entry.text.strip () != "";
            } else {
                apply_button.sensitive = http_entry.text.strip () != "" ||
                                        https_entry.text.strip () != "" ||
                                        ftp_entry.text.strip () != "" ||
                                        socks_entry.text.strip () != "";
            }
        }

        private void apply_settings () {
            if (auto_button.active) {
                Network.Plug.proxy_settings.set_string ("autoconfig-url", auto_entry.text);
                Network.Plug.proxy_settings.set_string ("mode", "auto");
            } else {
                http_settings.set_string ("host", http_entry.text);
                http_settings.set_int ("port", (int)http_spin.value);

                https_settings.set_string ("host", https_entry.text);
                https_settings.set_int ("port", (int)https_spin.value);

                ftp_settings.set_string ("host", ftp_entry.text);
                ftp_settings.set_int ("port", (int)ftp_spin.value);

                socks_settings.set_string ("host", socks_entry.text);
                socks_settings.set_int ("port", (int)socks_spin.value);

                Network.Plug.proxy_settings.set_string ("mode", "manual");
            }
        }

        private void on_reset_btn_clicked () {
            var reset_dialog = new Granite.MessageDialog (
                _("Are you sure you want to reset all Proxy settings?"),
                _("All host and port settings will be cleared and can not be restored."),
                new ThemedIcon ("dialog-question"),
                Gtk.ButtonsType.CANCEL
            ) {
                modal = true,
                transient_for = (Gtk.Window) get_toplevel ()
            };

            var reset_button = (Gtk.Button) reset_dialog.add_button (_("Reset Settings"), Gtk.ResponseType.APPLY);
            reset_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

            reset_dialog.present ();

            reset_dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.APPLY) {
                    Network.Plug.proxy_settings.set_string ("mode", "none");
                    Network.Plug.proxy_settings.set_string ("autoconfig-url", "");

                    http_settings.set_string ("host", "");
                    http_settings.set_int ("port", 0);

                    https_settings.set_string ("host", "");
                    https_settings.set_int ("port", 0);

                    ftp_settings.set_string ("host", "");
                    ftp_settings.set_int ("port", 0);

                    socks_settings.set_string ("host", "");
                    socks_settings.set_int ("port", 0);
                }

                reset_dialog.destroy ();
            });
        }
    }
}
