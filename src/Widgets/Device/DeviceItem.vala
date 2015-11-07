// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-plug-networking)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace Network.Widgets {
    public class DeviceItem : Gtk.ListBoxRow {
        public NM.Device? device = null;
        private NM.RemoteSettings? nm_settings = null;
        public Gtk.Box? page = null;
        public Utils.ItemType type;

        public Gtk.Label row_description;
        private Gtk.Image row_image;
        private Gtk.Image status_image;

        public string title;
        private string subtitle;
        private string icon_name;

        private Gtk.Grid row_grid;
        private Gtk.Label row_title;

        public DeviceItem (string _title, string _subtitle, string _icon_name = "network-wired") {
            this.title = _title;
            this.subtitle = _subtitle;
            this.icon_name = _icon_name;
            this.type = Utils.ItemType.INVALID;

            create_ui (icon_name);
        }

        public DeviceItem.from_interface (WidgetNMInterface iface,
                                    string _icon_name = "network-wired",
                                    string _title = "") {
            this.page = iface;
            this.device = iface.device;
            this.type = Utils.ItemType.DEVICE;
            
            if (_title != "") {
                this.title = _title;
            } else {
                this.title = Utils.type_to_string (device.get_device_type ());
            }
           
            this.subtitle = "";
            this.icon_name = _icon_name;

            create_ui (icon_name);
            switch_status (Utils.CustomMode.INVALID, device.get_state ());

            nm_settings = new NM.RemoteSettings (null);
            nm_settings.connections_read.connect (() => {
                switch_status (Utils.CustomMode.INVALID, device.get_state ());
            });

            device.state_changed.connect (() => {
                switch_status (Utils.CustomMode.INVALID, device.get_state ());
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

            row_title = new Gtk.Label (title);
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

        public void switch_status (Utils.CustomMode custom_mode, NM.DeviceState? state = null) {
            if (state != null) {
                if (device != null
                    && nm_settings != null
                    && device is NM.DeviceWifi
                    && Utils.Hotspot.get_device_is_hotspot ((NM.DeviceWifi)device, nm_settings)) {
                    state = NM.DeviceState.DISCONNECTED;
                }

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
                    case NM.DeviceState.UNMANAGED:
                        status_image.icon_name = "user-invisible";
                        break;
                    default:
                        if (Utils.state_to_string (device.get_state ()) == "Unknown") {
                            status_image.icon_name = "user-offline";
                        } else {
                            status_image.icon_name = "user-away";
                        }

                        break;
                }

                row_description.label = Utils.state_to_string (state);
            }

            if (custom_mode != Utils.CustomMode.INVALID) {
                switch (custom_mode) {
                    case Utils.CustomMode.PROXY_NONE:
                    case Utils.CustomMode.HOTSPOT_DISABLED:
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
                    case Utils.CustomMode.HOTSPOT_ENABLED:
                        row_description.label = _("Enabled");
                        status_image.icon_name = "user-available";
                        break;
               }
           }

           row_description.label = "<span font_size='small'>" + row_description.label + "</span>";
        }
    }
}
