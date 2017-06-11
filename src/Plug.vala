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

namespace Network {
    public class Plug : Switchboard.Plug {
        private Widgets.MainView main_view;

        construct {
            main_view = new Widgets.MainView ();
        }

        public Plug () {
            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("network", null);

            Object (category: Category.NETWORK,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Network"),
                    description: _("Manage network devices and connectivity"),
                    icon: "preferences-system-network",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            return main_view;
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Ethernet")), "");
            search_results.set ("%s → %s".printf (display_name, _("LAN")), "");
            search_results.set ("%s → %s".printf (display_name, _("Wireless")), "");
            search_results.set ("%s → %s".printf (display_name, _("WiFi")), "");
            search_results.set ("%s → %s".printf (display_name, _("Wlan")), "");
            search_results.set ("%s → %s".printf (display_name, _("Wi-Fi")), "");
            search_results.set ("%s → %s".printf (display_name, _("Proxy")), "");
            search_results.set ("%s → %s".printf (display_name, _("Airplane Mode")), "");
            search_results.set ("%s → %s".printf (display_name, _("IP Address")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Network plug");
    
    /*client = new NM.Client ();
    proxy_settings = new Network.ProxySettings ();
    ftp_settings = new Network.ProxyFTPSettings ();
    http_settings = new Network.ProxyHTTPSettings ();
    https_settings = new Network.ProxyHTTPSSettings ();
    socks_settings = new Network.ProxySocksSettings ();*/

    var plug = new Network.Plug ();
    return plug;
}
