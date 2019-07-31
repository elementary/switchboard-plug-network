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
        public NM.Device? device = null;
        public Gtk.Widget? page = null;

        public string title { get; set; default = ""; }
        public string subtitle { get; set; default = ""; }
        public string icon_name { get; set; default = "network-wired"; }
        public Utils.ItemType item_type { get; set; default = Utils.ItemType.INVALID; }

        private Gtk.Image status_image;

        public DeviceItem (string title, string subtitle, string icon_name = "network-wired") {
            Object (
                title: title,
                subtitle: subtitle,
                icon_name: icon_name
            );
        }

        public DeviceItem.from_interface (Widgets.Page iface, string icon_name = "network-wired", string title = "") {
            Object (
                title: title,
                icon_name: icon_name,
                item_type: Utils.ItemType.DEVICE
            );

            this.page = iface;
            this.device = iface.device;
            iface.bind_property ("title", this, "title");
            iface.bind_property ("icon-name", this, "icon-name", GLib.BindingFlags.SYNC_CREATE);

            switch_status (Utils.CustomMode.INVALID, iface.state);
            iface.notify["state"].connect (() => {
                switch_status (Utils.CustomMode.INVALID, iface.state);
            });
        }

        construct {
            var row_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND);
            row_image.pixel_size = 32;

            var row_title = new Gtk.Label (title);
            row_title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            row_title.ellipsize = Pango.EllipsizeMode.END;
            row_title.halign = Gtk.Align.START;
            row_title.valign = Gtk.Align.START;

            var row_description = new Gtk.Label (subtitle);
            row_description.margin_top = 2;
            row_description.use_markup = true;
            row_description.ellipsize = Pango.EllipsizeMode.END;
            row_description.halign = Gtk.Align.START;
            row_description.valign = Gtk.Align.START;

            status_image = new Gtk.Image.from_icon_name ("user-available", Gtk.IconSize.MENU);
            status_image.halign = status_image.valign = Gtk.Align.END;

            var overlay = new Gtk.Overlay ();
            overlay.width_request = 38;
            overlay.add (row_image);
            overlay.add_overlay (status_image);

            var row_grid = new Gtk.Grid ();
            row_grid.margin = 6;
            row_grid.margin_start = 3;
            row_grid.column_spacing = 3;
            row_grid.attach (overlay, 0, 0, 1, 2);
            row_grid.attach (row_title, 1, 0, 1, 1);
            row_grid.attach (row_description, 1, 1);

            add (row_grid);

            bind_property ("title", row_title, "label");
            bind_property ("subtitle", row_description, "label");
            bind_property ("icon-name", row_image, "icon-name");

            show_all ();
        }

        public void switch_status (Utils.CustomMode custom_mode, Network.State? state = null) {
            if (state != null) {
                switch (state) {
                    case Network.State.CONNECTED_WIFI:
                    case Network.State.CONNECTED_WIFI_WEAK:
                    case Network.State.CONNECTED_WIFI_OK:
                    case Network.State.CONNECTED_WIFI_GOOD:
                    case Network.State.CONNECTED_WIFI_EXCELLENT:
                    case Network.State.CONNECTED_WIRED:
                    case Network.State.CONNECTED_VPN:
                    case Network.State.CONNECTED_MOBILE:
                        status_image.icon_name = "user-available";
                        break;
                    case Network.State.DISCONNECTED:
                        status_image.icon_name = "user-offline";
                        break;
                    case Network.State.FAILED_WIRED:
                    case Network.State.FAILED_WIFI:
                    case Network.State.FAILED_VPN:
                    case Network.State.FAILED_MOBILE:
                        status_image.icon_name = "user-busy";
                        break;
                    default:
                        status_image.icon_name = "user-away";
                        break;
                }

                subtitle = state.to_string ();
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
