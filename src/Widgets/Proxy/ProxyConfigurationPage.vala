/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2015-2024 elementary, Inc. (https://elementary.io)
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class Network.Widgets.ConfigurationPage : Gtk.Box {
    private Gtk.CheckButton auto_radio;
    private Gtk.CheckButton manual_radio;

    construct {
        auto_radio = new Gtk.CheckButton.with_label (_("Automatic proxy configuration"));
        manual_radio = new Gtk.CheckButton.with_label (_("Manual proxy configuration")) {
            group = auto_radio
        };

        var auto_entry = new Gtk.Entry () {
            placeholder_text = _("URL to configuration script")
        };

        var use_all_check = new Gtk.CheckButton.with_label (_("Use this proxy server for all protocols"));

        var http_row = new ProxySettingRow (_("HTTP Proxy"), "org.gnome.system.proxy.http");
        var https_row = new ProxySettingRow (_("HTTPS Proxy"), "org.gnome.system.proxy.https");
        var ftp_row = new ProxySettingRow (_("FTP Proxy"), "org.gnome.system.proxy.ftp");
        var socks_row = new ProxySettingRow (_("Socks Host"), "org.gnome.system.proxy.socks");

        var other_protocols_box = new Gtk.Box (VERTICAL, 6);
        other_protocols_box.append (https_row);
        other_protocols_box.append (ftp_row);
        other_protocols_box.append (socks_row);

        var reset_button = new Gtk.Button.with_label (_("Reset Settings")) {
            halign = START,
            valign = END,
            vexpand = true,
            margin_top = 12
        };
        reset_button.clicked.connect (on_reset_btn_clicked);

        var config_grid = new Gtk.Box (VERTICAL, 12);
        config_grid.append (http_row);
        config_grid.append (use_all_check);
        config_grid.append (other_protocols_box);

        margin_top = 12;
        orientation = VERTICAL;
        spacing = 12;
        append (auto_radio);
        append (auto_entry);
        append (manual_radio);
        append (config_grid);
        append (reset_button);

        auto_radio.bind_property ("active", auto_entry, "sensitive", DEFAULT);
        use_all_check.bind_property ("active", other_protocols_box, "sensitive", INVERT_BOOLEAN);
        manual_radio.bind_property ("active", config_grid, "sensitive", SYNC_CREATE);

        use_all_check.notify["active"].connect (() => {
            if (use_all_check.active) {
                https_row.host = http_row.host;
                https_row.port = http_row.port;
                ftp_row.host = http_row.host;
                ftp_row.port = http_row.port;
                socks_row.host = http_row.host;
                socks_row.port = http_row.port;
            }
        });

        http_row.notify["host"].connect (() => {
            if (use_all_check.active) {
                https_row.host = http_row.host;
                ftp_row.host = http_row.host;
                socks_row.host = http_row.host;
            }
        });

        http_row.notify["port"].connect (() => {
            if (use_all_check.active) {
                https_row.port = http_row.port;
                ftp_row.port = http_row.port;
                socks_row.port = http_row.port;
            }
        });

        if (http_row.host == https_row.host &&
            http_row.host == ftp_row.host &&
            http_row.host == socks_row.host &&
            http_row.port == https_row.port &&
            http_row.port == ftp_row.port &&
            http_row.port == socks_row.port) {
            use_all_check.active = true;
        }

        var proxy_settings = new Settings ("org.gnome.system.proxy");
        proxy_settings.bind ("autoconfig-url", auto_entry, "text", DEFAULT);

        proxy_settings.changed["mode"].connect (() => {
            update_radios (proxy_settings.get_string ("mode"));
        });
        update_radios (proxy_settings.get_string ("mode"));

        auto_radio.toggled.connect (() => {
            if (auto_radio.active) {
                proxy_settings.set_string ("mode", "auto");
            }
        });

        manual_radio.toggled.connect (() => {
            if (manual_radio.active) {
                proxy_settings.set_string ("mode", "manual");
            }
        });
    }

    private void update_radios (string mode) {
        switch (mode) {
            case "auto":
                auto_radio.active = true;
                break;
            case "manual":
                manual_radio.active = true;
                break;
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
            transient_for = ((Gtk.Application) Application.get_default ()).active_window
        };

        var reset_button = (Gtk.Button) reset_dialog.add_button (_("Reset Settings"), Gtk.ResponseType.APPLY);
        reset_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        reset_dialog.present ();

        reset_dialog.response.connect ((response) => {
            if (response == Gtk.ResponseType.APPLY) {

                var settings = new Settings ("org.gnome.system.proxy");

                foreach (var child in settings.list_children ()) {
                    var child_settings = settings.get_child (child);
                    var schema = SettingsSchemaSource.get_default ().lookup (
                        child_settings.schema_id,
                        true
                    );

                    foreach (var key in schema.list_keys ()) {
                        child_settings.reset (key);
                    }
                }

                Network.Plug.proxy_settings.reset ("mode");
                Network.Plug.proxy_settings.reset ("autoconfig-url");
            }

            reset_dialog.destroy ();
        });
    }

    private class ProxySettingRow : Gtk.Grid {
        public string label { get; construct; }
        public string schema_id { get; construct; }
        public string host { get; set; }
        public int port { get; set; }

        public ProxySettingRow (string label, string schema_id) {
            Object (
                label: label,
                schema_id: schema_id
            );
        }

        construct {
            var entry = new Gtk.Entry () {
                placeholder_text = _("proxy.example.com"),
                hexpand = true
            };

            var headerlabel = new Granite.HeaderLabel (label) {
                mnemonic_widget = entry
            };

            var spinbutton = new Gtk.SpinButton.with_range (0, ushort.MAX, 1);

            var port_label = new Gtk.Label (_("Port:")) {
                margin_start = 6,
                mnemonic_widget = spinbutton
            };

            column_spacing = 6;
            attach (headerlabel, 0, 0, 3);
            attach (entry, 0, 1);
            attach (port_label, 1, 1);
            attach (spinbutton, 2, 1);

            var settings = new Settings (schema_id);
            settings.bind ("host", entry, "text", DEFAULT);
            settings.bind ("port", spinbutton , "value", DEFAULT);
            settings.bind ("host", this, "host", DEFAULT);
            settings.bind ("port", this , "port", DEFAULT);
        }
    }
}
