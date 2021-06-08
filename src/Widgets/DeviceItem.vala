/*-
 * Copyright (c) 2015-2019 elementary, Inc. (https://elementary.io)
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
    public class DeviceItem : Gtk.ListBoxRow {
        public NM.Device? device { get; construct; default = null; }
        public Widgets.Page? page { get; set; default = null; }
        public string title { get; set; default = ""; }
        public string subtitle { get; set; default = ""; }
        public string icon_name { get; set; default = "network-wired"; }
        public Utils.ItemType item_type { get; set; default = Utils.ItemType.INVALID; }

        private Gtk.Image status_image;

        public DeviceItem (string title, string icon_name = "network-wired") {
            Object (
                title: title,
                icon_name: icon_name
            );
        }

        public DeviceItem.from_page (Widgets.Page page, string icon_name = "network-wired") {
            Object (
                device: page.device,
                icon_name: icon_name,
                item_type: Utils.ItemType.DEVICE,
                page: page
            );

            page.bind_property ("title", this, "title");
            page.bind_property ("icon-name", this, "icon-name", GLib.BindingFlags.SYNC_CREATE);

            switch_status (Utils.CustomMode.INVALID, page.state);
            page.notify["state"].connect (() => {
                switch_status (Utils.CustomMode.INVALID, page.state);
            });
        }

        construct {
            var row_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND) {
                pixel_size = 32
            };

            var row_title = new Gtk.Label (title) {
                ellipsize = Pango.EllipsizeMode.END,
                halign = Gtk.Align.START,
                valign = Gtk.Align.START
            };
            row_title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var row_description = new Gtk.Label (subtitle) {
                margin_top = 2,
                use_markup = true,
                ellipsize = Pango.EllipsizeMode.END,
                halign = Gtk.Align.START,
                valign = Gtk.Align.START
            };

            status_image = new Gtk.Image.from_icon_name ("user-available", Gtk.IconSize.MENU) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.END
            };

            var overlay = new Gtk.Overlay () {
                width_request = 38
            };
            overlay.add (row_image);
            overlay.add_overlay (status_image);

            var row_grid = new Gtk.Grid () {
                margin = 6,
                margin_start = 3,
                column_spacing = 3
            };
            row_grid.attach (overlay, 0, 0, 1, 2);
            row_grid.attach (row_title, 1, 0, 1, 1);
            row_grid.attach (row_description, 1, 1);

            add (row_grid);

            bind_property ("title", row_title, "label");
            bind_property ("subtitle", row_description, "label");
            bind_property ("icon-name", row_image, "icon-name");

            show_all ();
        }

        public void switch_status (Utils.CustomMode custom_mode, NM.DeviceState? state = null) {
            if (state != null) {
                switch (state) {
                    case NM.DeviceState.ACTIVATED:
                        status_image.icon_name = "user-available";
                        break;
                    case NM.DeviceState.DISCONNECTED:
                        status_image.icon_name = "user-offline";
                        break;
                    case NM.DeviceState.FAILED:
                        status_image.icon_name = "user-busy";
                        break;
                    default:
                        status_image.icon_name = "user-away";
                        break;
                }

                if (device is NM.DeviceWifi && state == NM.DeviceState.UNAVAILABLE) {
                    subtitle = _("Disabled");
                } else {
                    subtitle = Utils.state_to_string (state);
                }
            } else if (custom_mode != Utils.CustomMode.INVALID) {
                switch (custom_mode) {
                    case Utils.CustomMode.PROXY_NONE:
                        subtitle = _("Disabled");
                        status_image.icon_name = "user-offline";
                        break;
                    case Utils.CustomMode.PROXY_MANUAL:
                        subtitle = _("Enabled (manual mode)");
                        status_image.icon_name = "user-available";
                        break;
                    case Utils.CustomMode.PROXY_AUTO:
                        subtitle = _("Enabled (auto mode)");
                        status_image.icon_name = "user-available";
                        break;
               }
            }

           subtitle = "<span font_size='small'>" + subtitle + "</span>";
        }
    }
}
