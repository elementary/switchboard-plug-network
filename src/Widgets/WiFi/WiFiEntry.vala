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
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com
 */

namespace Network.Widgets {
    public class WiFiEntry : Gtk.ListBoxRow {
        public NM.AccessPoint? ap;
        public string ssid;
        public bool is_secured = false;
        public uint strength;

        private string bssid;

        private Gtk.Label title;

        public WiFiEntry.from_access_point (NM.AccessPoint? point) {
            ap = point;

            this.ssid = NM.Utils.ssid_to_utf8 (ap.get_ssid ());
            this.bssid = ap.get_bssid ();
            this.strength = ap.get_strength ();

            title = new Gtk.Label (ssid);
            title.halign = Gtk.Align.START;

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            hbox.add (title);

            hbox.pack_end (get_strength_image (), false, false, 7);
            if (ap.get_wpa_flags () != NM.@80211ApSecurityFlags.NONE) {
                is_secured = true;

                var lock_img = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                hbox.pack_end (lock_img, false, false, 0);
            }

            this.add (hbox);
            this.show_all ();
        }

        public void set_status_point (bool connected, bool in_process) {
            if (connected || in_process) {
                string status = Utils.state_to_string (NM.DeviceState.ACTIVATED);
                if (in_process)
                    status = Utils.state_to_string (NM.DeviceState.CONFIG);
                title.label = title.get_label () + SUFFIX + "(" + status + ")";
            } else {
                title.label = ssid;
            }
        }

        private Gtk.Image get_strength_image () {
            var image = new Gtk.Image.from_icon_name ("network-wireless-offline-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            if (strength == 0 || strength <= 25) {
                image.icon_name = "network-wireless-signal-weak-symbolic";
            } else if (strength > 25 && strength <= 50) {
                image.icon_name = "network-wireless-signal-ok-symbolic";
            } else if (strength > 50 && strength <= 75) {
                image.icon_name = "network-wireless-signal-good-symbolic";
            } else if (strength > 75) {
                image.icon_name = "network-wireless-signal-excellent-symbolic";
            }

            return image;
        }
    }
}
