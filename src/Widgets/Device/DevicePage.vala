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
    public class DevicePage : Network.WidgetNMInterface {

        public DevicePage (NM.Client client, NM.RemoteSettings settings, NM.Device device) {
            info_box = new InfoBox.from_device (device);
            this.init (device, info_box);

            bottom_revealer.transition_type = Gtk.RevealerTransitionType.NONE;

            this.icon_name = "network-wired";
            this.title = Utils.type_to_string (device.get_device_type ());

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_end (Utils.get_advanced_button_from_device (device), false, false, 0);

            update ();

            bottom_box.pack_start (info_box, true, true);
            bottom_box.pack_end (details_box, false, false);

            pack_start (bottom_revealer, true, true);
            this.show_all ();
        }

        public DevicePage.from_owner (DeviceItem? owner) {
            info_box = new InfoBox.from_owner (owner);
            this.init (owner.get_item_device (), info_box);

            this.icon_name = owner.get_item_icon_name ();
            this.title = Utils.type_to_string (device.get_device_type ());

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_start (Utils.get_advanced_button_from_device (device), false, false, 0);

            update ();

            this.add (info_box);
            this.pack_end (details_box, false, false, 0);
            this.show_all ();
        }
    }
}
