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

            ignored_list = new Gtk.ListBox ();
            ignored_list.vexpand = true;
            ignored_list.selection_mode = Gtk.SelectionMode.SINGLE;
            ignored_list.activate_on_single_click = false;

            var frame = new Gtk.Frame (null);
            frame.add (ignored_list);

            var control_row = new Gtk.ListBoxRow ();
            control_row.selectable = false;

            var ign_label = new Gtk.Label ("<b>" + _("Ignored hosts") + "</b>");
            ign_label.use_markup = true;
            ign_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            var ign_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            ign_box.pack_start (ign_label, false, false, 0);

            var entry = new Gtk.Entry ();
            entry.placeholder_text = _("Exception to add (separate with commas to add multiple)");

            var add_btn = new Gtk.Button.with_label (_("Add Exception"));
            add_btn.sensitive = false;
            add_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
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

            var box_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            box_btn.margin_top = 12;
            box_btn.pack_end (add_btn, false, false, 0);
            box_btn.pack_end (entry, true, true, 0);

            control_row.add (ign_box);
            ignored_list.add (control_row);

            list_exceptions ();

            this.add (frame);
            this.add (box_btn);
            this.show_all ();
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
                var e_label = new Gtk.Label (e);
                e_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

                var remove_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                remove_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

                remove_btn.clicked.connect (() => {
                    remove_exception (e);
                });

                var e_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                e_box.margin_end = e_box.margin_start = 6;
                e_box.pack_start (e_label, false, true, 0);
                e_box.pack_end (remove_btn, false, false, 0);

                row.add (e_box);
                ignored_list.add (row);
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
            this.show_all ();
        }
    }
}
