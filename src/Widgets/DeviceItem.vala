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
        public Switchboard.SettingsPage.StatusType status_type {
            set {
                switch (value) {
                    case ERROR:
                        status_image.icon_name = "emblem-error";
                        break;
                    case OFFLINE:
                        status_image.icon_name = "emblem-disabled";
                        break;
                    case SUCCESS:
                        status_image.icon_name = "emblem-enabled";
                        break;
                    case WARNING:
                        status_image.icon_name = "emblem-warning";
                        break;
                    case NONE:
                        status_image.clear ();
                        break;
                }
            }
        }

        public NM.Device? device { get; construct; default = null; }
        public Widgets.Page? page { get; set; default = null; }
        public string title { get; set; default = ""; }
        public string subtitle { get; set; default = ""; }
        public Icon icon { get; set; default = new ThemedIcon ("network-wired"); }
        public Utils.ItemType item_type { get; set; default = Utils.ItemType.INVALID; }

        private Gtk.Image status_image;

        public DeviceItem.from_page (Widgets.Page page, string icon_name = "network-wired") {
            Object (
                device: page.device,
                icon: new ThemedIcon (icon_name),
                item_type: Utils.ItemType.DEVICE,
                page: page
            );

            page.bind_property ("title", this, "title", SYNC_CREATE);
            page.bind_property ("icon", this, "icon", SYNC_CREATE);
            page.bind_property ("status-type", this, "status-type", SYNC_CREATE);
            page.bind_property ("status", this, "subtitle", SYNC_CREATE);
        }

        construct {
            var row_image = new Gtk.Image.from_gicon (icon) {
                icon_size = LARGE
            };

            var row_title = new Gtk.Label (title) {
                ellipsize = Pango.EllipsizeMode.END,
                halign = Gtk.Align.START,
                valign = Gtk.Align.START
            };
            row_title.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            var row_description = new Gtk.Label (subtitle) {
                use_markup = true,
                ellipsize = Pango.EllipsizeMode.END,
                halign = Gtk.Align.START,
                valign = Gtk.Align.START
            };
            row_description.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

            status_image = new Gtk.Image () {
                halign = Gtk.Align.END,
                valign = Gtk.Align.END
            };

            var overlay = new Gtk.Overlay () {
                child = row_image
            };
            overlay.add_overlay (status_image);

            var row_grid = new Gtk.Grid ();
            row_grid.attach (overlay, 0, 0, 1, 2);
            row_grid.attach (row_title, 1, 0, 1, 1);
            row_grid.attach (row_description, 1, 1);

            child = row_grid;

            bind_property ("title", row_title, "label");
            bind_property ("subtitle", row_description, "label");
            bind_property ("icon", row_image, "gicon");
        }
    }
}
