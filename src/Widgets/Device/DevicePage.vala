// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-network-plug)
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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

namespace Network.Widgets {
    public class DevicePage : Page {
        public DeviceItem owner;
        public InfoBox info_box;

        public DevicePage.from_owner (DeviceItem? _owner) {
            this.owner = _owner;
            this.device = owner.get_item_device ();
            this.icon_name = owner.get_item_icon_name ();
            this.title = Utils.type_to_string (device.get_device_type ());
            this.margin_end = 12;

            info_box = new info_box.from_owner (owner);
            info_box.margin_end = this.INFO_BOX_MARGIN;
            info_box.info_changed.connect (update);

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_start (Utils.get_advanced_button_from_device (device), false, false, 0);           

            update ();

            this.add (info_box);
            this.pack_end (details_box, false, false, 0);
            this.show_all ();
        }

        private void update () {
            string sent_bytes, received_bytes;
            this.get_activity_information (device.get_iface (), out sent_bytes, out received_bytes);
            info_box.update_activity (sent_bytes, received_bytes);

            control_switch.active = (device.get_state () == NM.DeviceState.ACTIVATED);
        }
    }
}
