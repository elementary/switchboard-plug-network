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

/* Strings */
const string SUFFIX = " ";

namespace Network {
    public class Plug : Switchboard.Plug {
        private MainView? main_view = null;

        public static GLib.Settings proxy_settings;

        public Plug () {
            GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("network", null);
            Object (category: Category.NETWORK,
                    code_name: "io.elementary.switchboard.network",
                    display_name: _("Network"),
                    description: _("Manage network devices and connectivity"),
                    icon: "preferences-system-network",
                    supported_settings: settings);
        }

        static construct {
            proxy_settings = new GLib.Settings ("org.gnome.system.proxy");
        }

        public override Gtk.Widget get_widget () {
            if (main_view == null) {
                main_view = new MainView ();
            }

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
            search_results.set ("%s → %s".printf (display_name, _("Wi-Fi")), "");
            search_results.set ("%s → %s".printf (display_name, _("WLAN")), "");
            search_results.set ("%s → %s".printf (display_name, _("Proxy")), "");
            search_results.set ("%s → %s".printf (display_name, _("Airplane Mode")), "");
            search_results.set ("%s → %s".printf (display_name, _("IP Address")), "");
            search_results.set ("%s → %s".printf (display_name, _("Hotspot")), "");
            search_results.set ("%s → %s".printf (display_name, _("VPN")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Network plug");

    var plug = new Network.Plug ();
    return plug;
}
