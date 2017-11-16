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
    public class DeviceItem : Gtk.ListBoxRow {
        public NM.Device? device = null;
        private NM.RemoteSettings? nm_settings = null;
        public Gtk.Widget? page = null;
        public Utils.ItemType type;

        public Gtk.Label row_description;
        private Gtk.Image row_image;
        private Gtk.Image status_image;

        public string title {
            set {
                row_title.label = value;
            }
        }
        
        private string subtitle;
        private string icon_name;

        private Gtk.Grid row_grid;
        private Gtk.Label row_title;

        public DeviceItem (string _title, string _subtitle, string _icon_name = "network-wired") {
            this.subtitle = _subtitle;
            this.icon_name = _icon_name;
            this.type = Utils.ItemType.INVALID;

            create_ui (icon_name);
            
            this.title = _title;
        }

        public DeviceItem.from_interface (WidgetNMInterface iface,
                                    string _icon_name = "network-wired",
                                    string _title = "") {
            this.page = iface;
            this.device = iface.device;
            this.type = Utils.ItemType.DEVICE;

            this.subtitle = "";
            this.icon_name = _icon_name;

            create_ui (icon_name);
            iface.bind_property ("display-title", this, "title");
            
            switch_status (Utils.CustomMode.INVALID, iface.state);

            nm_settings = new NM.RemoteSettings (null);
            nm_settings.connections_read.connect (() => {
                switch_status (Utils.CustomMode.INVALID, iface.state);
            });

            iface.notify["state"].connect (() => {
                switch_status (Utils.CustomMode.INVALID, iface.state);
            });
        }

        private void create_ui (string icon_name) {
            var overlay = new Gtk.Overlay ();
            overlay.width_request = 38;

            row_grid = new Gtk.Grid ();
            row_grid.margin = 6;
            row_grid.margin_start = 3;
            row_grid.column_spacing = 3;

            row_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND);
            row_image.pixel_size = 32;

            row_title = new Gtk.Label ("");
            row_title.get_style_context ().add_class ("h3");
            row_title.ellipsize = Pango.EllipsizeMode.END;
            row_title.halign = Gtk.Align.START;
            row_title.valign = Gtk.Align.START;

            row_description = new Gtk.Label (subtitle);
            row_description.margin_top = 2;
            row_description.use_markup = true;
            row_description.ellipsize = Pango.EllipsizeMode.END;
            row_description.halign = Gtk.Align.START;
            row_description.valign = Gtk.Align.START;

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            hbox.pack_start (row_description, false, false, 0);

            status_image = new Gtk.Image.from_icon_name ("user-available", Gtk.IconSize.MENU);
            status_image.halign = status_image.valign = Gtk.Align.END;

            overlay.add (row_image);
            overlay.add_overlay (status_image);

            row_grid.attach (overlay, 0, 0, 1, 2);
            row_grid.attach (row_title, 1, 0, 1, 1);
            row_grid.attach (hbox, 1, 1, 1, 1);
            
            this.add (row_grid);
            this.show_all ();
        }

        public NM.Device? get_item_device () {
            return device;
        }

        public string get_item_icon_name () {
            return icon_name;
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

                row_description.label = Common.Utils.network_state_to_string (state);
            } else if (custom_mode != Utils.CustomMode.INVALID) {
                switch (custom_mode) {
                    case Utils.CustomMode.PROXY_NONE:
                        row_description.label = _("Disabled");
                        status_image.icon_name = "user-offline";
                        break;
                    case Utils.CustomMode.PROXY_MANUAL:
                        row_description.label = _("Enabled (manual mode)");
                        status_image.icon_name = "user-available";
                        break;
                    case Utils.CustomMode.PROXY_AUTO:
                        row_description.label = _("Enabled (auto mode)");
                        status_image.icon_name = "user-available";
                        break;
               }
            }

           row_description.label = "<span font_size='small'>" + row_description.label + "</span>";
        }
    }
}
