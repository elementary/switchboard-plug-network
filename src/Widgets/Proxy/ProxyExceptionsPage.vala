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
    public class ExecepionsPage : Gtk.Box {
        private Gtk.ListBox ignored_list;
        private Gtk.ListBoxRow[] items = {};

        construct {
            margin_top = 10;
            orientation = Gtk.Orientation.VERTICAL;

            ignored_list = new Gtk.ListBox () {
                vexpand = true,
                selection_mode = Gtk.SelectionMode.SINGLE,
                activate_on_single_click = false
            };

            var frame = new Gtk.Frame (null) {
                child = ignored_list
            };

            var control_row = new Gtk.ListBoxRow () {
                selectable = false
            };

            var ign_label = new Gtk.Label (_("Ignored hosts"));
            ign_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            var ign_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            ign_box.append (ign_label);

            var entry = new Gtk.Entry () {
                placeholder_text = _("Exception to add (separate with commas to add multiple)"),
                halign = Gtk.Align.FILL,
                hexpand = true
            };

            var add_btn = new Gtk.Button.with_label (_("Add Exception")) {
                sensitive = false
            };
            add_btn.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            add_btn.clicked.connect (() => {
                add_exception (entry);
            });

            entry.activate.connect (() => {
                add_btn.clicked ();
            });

            entry.changed.connect (() => {
                if (entry.get_text () != "")
                  add_btn.sensitive = true;
                else
                  add_btn.sensitive = false;
            });

            var box_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
                margin_top = 12
            };
            box_btn.append (add_btn);
            box_btn.append (entry);

            control_row.child = ign_box;
            ignored_list.append (control_row);

            list_exceptions ();

            this.append (frame);
            this.append (box_btn);
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
                var row = new Gtk.ListBoxRow ();
                var e_label = new Gtk.Label (e) {
                    hexpand = true,
                    halign = Gtk.Align.END
                };
                e_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

                var remove_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic");
                remove_btn.add_css_class (Granite.STYLE_CLASS_FLAT);

                remove_btn.clicked.connect (() => {
                    remove_exception (e);
                });

                var e_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                    margin_end = 6,
                    margin_start = 6
                };
                e_box.append (e_label);
                e_box.append (remove_btn);

                row.child = e_box;
                ignored_list.append (row);
                items += row;
            }
        }

        private void remove_exception (string exception) {
            string[] new_hosts = {};
            foreach (string host in Network.Plug.proxy_settings.get_strv ("ignore-hosts")) {
                if (host != exception)
                    new_hosts += host;
            }

            Network.Plug.proxy_settings.set_strv ("ignore-hosts", new_hosts);
            update_list ();
        }

        private void update_list () {
            foreach (var item in items)
                ignored_list.remove (item);

            items = {};

            list_exceptions ();
        }
    }
}
