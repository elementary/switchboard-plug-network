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
        public NM.AccessPoint ap;
        public Gtk.RadioButton radio_btn;
        public string ssid_str;
        public bool is_secured = false;
        public uint strength;

        private Gtk.Box hbox;
        private Gtk.Spinner spinner;

        private string bssid;

        public WiFiEntry (NM.AccessPoint point, Gtk.RadioButton? previous_btn = null) {
            ap = point;

            this.ssid_str = NM.Utils.ssid_to_utf8 (ap.get_ssid ());
            this.bssid = ap.get_bssid ();
            this.strength = ap.get_strength ();

            radio_btn = new Gtk.RadioButton.with_label_from_widget (previous_btn, ssid_str);
            radio_btn.halign = Gtk.Align.START;

            hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            hbox.add (radio_btn);

            var strength_image = new Gtk.Image.from_icon_name (get_strength_icon (), Gtk.IconSize.SMALL_TOOLBAR);
            ap.notify["strength"].connect (() => {
               strength_image.icon_name = get_strength_icon ();
            });

            hbox.pack_end (strength_image, false, false, 7);
            if (ap.get_wpa_flags () != NM.@80211ApSecurityFlags.NONE || ap.get_rsn_flags () != NM.@80211ApSecurityFlags.NONE) {
                is_secured = true;

                var lock_img = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                hbox.pack_end (lock_img, false, false, 0);
            }

            spinner = new Gtk.Spinner ();
            spinner.no_show_all = true;
            spinner.start ();
            hbox.pack_end (spinner, false, false, 0);

            set_connection_in_progress (false);

            this.add (hbox);
            this.show_all ();
        }

        public void set_active (bool connected) {
            radio_btn.active = connected;
        }

        public void set_connection_in_progress (bool progress) {
            spinner.visible = progress;
        }

        private string get_strength_icon () {
            if (strength < 30) {
                return "network-wireless-signal-weak-symbolic";
            } else if (strength < 55) {
                return "network-wireless-signal-ok-symbolic";
            } else if (strength < 80) {
                return "network-wireless-signal-good-symbolic";
            } else {
                return "network-wireless-signal-excellent-symbolic";
            }
        }
    }
}
