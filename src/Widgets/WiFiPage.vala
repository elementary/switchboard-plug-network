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
    public class WiFiPage : Gtk.Box {
        public NM.DeviceWifi wifidevice;
        public bool connected;
        public Gtk.Button enable_btn;
        private Gtk.Label status;

        public WiFiPage (NM.DeviceWifi _wifidevice) {
            wifidevice = _wifidevice;

            var access_points = wifidevice.get_access_points ();
            access_points.@foreach ((access_point) => {
                print (access_point.get_bssid () + "\n");
                foreach (uint val in access_point.get_ssid ().data) {
                    print (val.to_string () + "\n");
                }
            });

            this.show_all ();
        }               
    }  
}
