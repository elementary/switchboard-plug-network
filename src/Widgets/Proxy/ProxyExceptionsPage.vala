/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2015-2024 elementary, Inc. (https://elementary.io)
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class Network.Widgets.ExecepionsPage : Gtk.Box {
    private Gtk.ListBox ignored_list;
    private Gtk.ListBoxRow[] items = {};

    construct {
        ignored_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = SINGLE,
            activate_on_single_click = false
        };

        var frame = new Gtk.Frame (null) {
            child = ignored_list
        };

        var ign_label = new Granite.HeaderLabel (_("Ignored hosts")) {
            mnemonic_widget = ignored_list
        };

        var entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("Exception to add (separate with commas to add multiple)")
        };

        var add_btn = new Gtk.Button.with_label (_("Add Exception")) {
            sensitive = false
        };
        add_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var box_btn = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 12
        };
        box_btn.add (entry);
        box_btn.add (add_btn);

        list_exceptions ();

        orientation = VERTICAL;
        add (ign_label);
        add (frame);
        add (box_btn);

        add_btn.clicked.connect (() => {
            add_exception (entry);
        });

        entry.activate.connect (() => {
            add_btn.clicked ();
        });

        entry.changed.connect (() => {
            add_btn.sensitive = entry.text != "";
        });
    }

    private void add_exception (Gtk.Entry entry) {
        string[] new_hosts = Network.Plug.proxy_settings.get_strv ("ignore-hosts");
        foreach (string host in entry.get_text ().split (",")) {
            if (host.strip () != "") {
                new_hosts += host.strip ();
            }
        }

        Network.Plug.proxy_settings.set_strv ("ignore-hosts", new_hosts);
        entry.text = "";
        update_list ();
    }

    private void list_exceptions () {
        foreach (string e in Network.Plug.proxy_settings.get_strv ("ignore-hosts")) {
            var e_label = new Gtk.Label (e) {
                halign = START,
                hexpand = true
            };

            var remove_btn = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
                tooltip_text = _("Remove exception")
            };
            remove_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            remove_btn.clicked.connect (() => {
                remove_exception (e);
            });

            var e_box = new Gtk.Box (HORIZONTAL, 0) {
                margin_top = 3,
                margin_end = 6,
                margin_bottom = 3,
                margin_start = 6
            };
            e_box.add (e_label);
            e_box.add (remove_btn);

            var row = new Gtk.ListBoxRow () {
                child = e_box
            };

            ignored_list.add (row);
            items += row;
        }
    }

    private void remove_exception (string exception) {
        string[] new_hosts = {};
        foreach (string host in Network.Plug.proxy_settings.get_strv ("ignore-hosts")) {
            if (host != exception) {
                new_hosts += host;
            }
        }

        Network.Plug.proxy_settings.set_strv ("ignore-hosts", new_hosts);
        update_list ();
    }

    private void update_list () {
        foreach (var item in items) {
            ignored_list.remove (item);
        }

        items = {};

        list_exceptions ();
        this.show_all ();
    }
}
