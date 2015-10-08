namespace Network.Widgets {

    public class ConfigurationPage : Gtk.Box {
        private const string DEFAULT_PROXY = "host:port";
        private bool syntax_error = false;

        private Gtk.Entry http;
        private Gtk.Entry https;
        private Gtk.Entry ftp;
        private Gtk.Entry socks;

        private Gtk.Label http_l;
        private Gtk.Label https_l;
        private Gtk.Label ftp_l;
        private Gtk.Label socks_l;

        public ConfigurationPage () {
            this.margin_start = 20;
            this.margin_top = this.margin_start;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.spacing = 10;
            this.margin_end = 55;

            /* This radiobutton contatins the oposite state of proxy_switch
             * for blocking auto_btn and manual_btn correctly. 
             */
            var tmp_btn = new Gtk.RadioButton (null);
            
            var proxy_switch = new Gtk.Switch ();
            proxy_switch.valign = Gtk.Align.CENTER;
            var auto_btn = new Gtk.RadioButton.with_label_from_widget (tmp_btn, _("Automatic proxy configuration"));
            var manual_btn = new Gtk.RadioButton.with_label_from_widget (auto_btn, _("Manual proxy configuration"));

            var auto_entry = new Gtk.Entry ();
            auto_entry.placeholder_text = _("URL to configuration script");
            auto_entry.hexpand = true;
            auto_entry.sensitive = false;

            var auto_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 15);
            auto_box.add (auto_btn);
            auto_box.add (auto_entry);

            var setup_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 40);
            setup_box.vexpand = false;
            setup_box.margin_top = 15;
            setup_box.margin_start = 20;

            var proxy_l = new Gtk.Label (_("Proxy"));
            proxy_l.halign = Gtk.Align.START;
            proxy_l.get_style_context ().add_class ("h2");

            var proxy_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            proxy_box.pack_start (proxy_l, false, false, 0);
            proxy_box.pack_end (proxy_switch, false, false, 0);

            proxy_switch.notify["active"].connect (() => {
                bool state = proxy_switch.get_active ();
                setup_box.sensitive = state;
                if (!state)
                    proxy_settings.mode = "none";
                tmp_btn.active = !state;
                auto_btn.active = state;
                auto_box.sensitive = state;
                manual_btn.sensitive = state;
            });

            var vbox_label = new Gtk.Box (Gtk.Orientation.VERTICAL, 25);
            vbox_label.margin_top = 5;

            http_l = new Gtk.Label (_("HTTP Proxy:"));
            http_l.halign = Gtk.Align.START;

            https_l = new Gtk.Label (_("HTTPS Proxy:")); 
            https_l.halign = Gtk.Align.START;

            ftp_l = new Gtk.Label (_("FTP Proxy:"));
            ftp_l.halign = Gtk.Align.START;

            socks_l = new Gtk.Label (_("SOCKS Host:"));
            socks_l.halign = Gtk.Align.START;

            http = new Gtk.Entry ();
            http.placeholder_text = DEFAULT_PROXY;

            https = new Gtk.Entry ();
            https.placeholder_text = DEFAULT_PROXY;
            https.input_purpose = Gtk.InputPurpose.NUMBER;

            ftp = new Gtk.Entry ();
            ftp.placeholder_text = DEFAULT_PROXY;

            socks = new Gtk.Entry ();
            socks.placeholder_text = DEFAULT_PROXY;

            var apply_btn = new Gtk.Button.with_label (_("Apply"));
            apply_btn.get_style_context ().add_class ("suggested-action");
            
            var reset_btn = new Gtk.Button.with_label (_("Reset all settings"));
            reset_btn.clicked.connect (on_reset_btn_clicked);

            vbox_label.add (http_l);
            vbox_label.add (https_l);
            vbox_label.add (ftp_l);
            vbox_label.add (socks_l);

            var vbox_entry = new Gtk.Grid ();
            vbox_entry.row_spacing = 15;
            vbox_entry.column_spacing = 20;
            vbox_entry.column_homogeneous = false;
            vbox_entry.hexpand = false;
            vbox_entry.attach (http, 0, 0, 1, 1);
            vbox_entry.attach (https, 0, 1, 1, 1);
            vbox_entry.attach (ftp, 0, 2, 1, 1);
            vbox_entry.attach (socks, 0, 3, 1, 1);

            setup_box.add (vbox_label);
            setup_box.add (vbox_entry);

            auto_btn.toggled.connect (() => {
                auto_entry.sensitive = auto_btn.get_active ();
            });

            manual_btn.toggled.connect (() => {
                set_entries_sensitive (manual_btn.get_active ());
            });

            apply_btn.clicked.connect (() => {
                if (auto_btn.get_active ()) {
                    if (auto_entry.get_text () != "") {
                        proxy_settings.autoconfig_url = auto_entry.get_text ();
                        proxy_settings.mode = "auto";
                        set_syntax_error_for_entry (auto_entry, false);
                    } else {
                        set_syntax_error_for_entry (auto_entry, true);
                    }

                } else if (manual_btn.get_active ()) {
                    if (http.get_text () != "") {
                        if (http.get_text ().contains (":")) {
                            http_settings.host = http.get_text ().split (":")[0];
                            http_settings.port = int.parse (http.get_text ().split (":")[1]);
                            set_syntax_error_for_entry (http, false);
                        } else {
                            set_syntax_error_for_entry (http, true);
                        }
                    }

                    if (https.get_text () != "") {
                        if (https.get_text ().contains (":")) {
                            https_settings.host = https.get_text ().split (":")[0];
                            https_settings.port = int.parse (https.get_text ().split (":")[1]);
                            set_syntax_error_for_entry (https, false);
                        } else {
                            set_syntax_error_for_entry (https, true);
                        }
                    }

                    if (ftp.get_text () != "") {
                        if (ftp.get_text ().contains (":")) {
                            ftp_settings.host = ftp.get_text ().split (":")[0];
                            ftp_settings.port = int.parse (ftp.get_text ().split (":")[1]);	
                            set_syntax_error_for_entry (ftp, false);
                        } else {
                            set_syntax_error_for_entry (ftp, true);
                        }
                    }

                    if (socks.get_text () != "") {
                        if (socks.get_text ().contains (":")) {
                            socks_settings.host = socks.get_text ().split (":")[0];
                            socks_settings.port = int.parse (socks.get_text ().split (":")[1]);
                            set_syntax_error_for_entry (socks, false);
                        } else {
                            set_syntax_error_for_entry (socks, true);
                        }
                    }

                    if ((http.get_text () + https.get_text () + ftp.get_text () + socks.get_text () != "") && !syntax_error)
                        proxy_settings.mode = "manual";

                } else if (!proxy_switch.get_active ()) {
                    proxy_settings.mode = "none";
                }
            });

            switch (proxy_settings.mode) {
                case "none":
                    setup_box.sensitive = false;
                    auto_box.sensitive = false;
                    manual_btn.sensitive = false;
                    proxy_switch.active = false;
                    break;
                case "manual":
                    proxy_switch.active = true;
                    auto_box.sensitive = true;
                    manual_btn.sensitive = true;
                    setup_box.sensitive = true;
                    break;
                case "auto":
                    proxy_switch.active = true;
                    auto_box.sensitive = true;
                    manual_btn.sensitive = true;
                    setup_box.sensitive = true;
                    break;
            }

            var apply_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            apply_box.layout_style = Gtk.ButtonBoxStyle.EXPAND;
            apply_box.add (reset_btn);
            apply_box.add (apply_btn);

            vbox_entry.attach (apply_box, 0, 4, 1, 1);

            this.add (proxy_box);
            this.add (auto_box);
            this.add (manual_btn);
            this.add (setup_box);
        }

        private void set_syntax_error_for_entry (Gtk.Entry entry, bool error) {
            if (error) {
                entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error");
                syntax_error = true;
            } else {
                entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "");
                syntax_error = false;
            }
        }

        private void set_entries_sensitive (bool sensitive) {
            http.sensitive = sensitive;
            https.sensitive = sensitive;
            ftp.sensitive = sensitive;
            socks.sensitive = sensitive;

            http_l.sensitive = sensitive;
            https_l.sensitive = sensitive;
            ftp_l.sensitive = sensitive;
            socks_l.sensitive = sensitive;
        }

        private void on_reset_btn_clicked () {
            var reset_dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.NONE, " ");

            reset_dialog.text = _("Do you want to reset all the settings to\ndefault values inluding hosts and ports?");
            reset_dialog.add_button (_("Do not reset"), 0);
            reset_dialog.add_button (_("Reset"), 1);

            reset_dialog.deletable = false;
            reset_dialog.show_all ();
            reset_dialog.response.connect ((response_id) => {
                switch (response_id) {
                    case 0:
                        break;
                    case 1:
                        proxy_settings.mode = "none";
                        proxy_settings.autoconfig_url = "";
                        http_settings.host = "";
                        http_settings.port = 0;
                        https_settings.host = "";
                        https_settings.port = 0;
                        ftp_settings.host = "";
                        ftp_settings.port = 0;   
                        socks_settings.host = "";
                        socks_settings.port = 0;
                        break;
                    }

                reset_dialog.destroy ();
            });
        }
    }
}
