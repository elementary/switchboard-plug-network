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
    public class ProxySettings : Granite.Services.Settings {
        public string autoconfig_url { get; set; }
        public string[] ignore_hosts { get; set; }
        public string mode { get; set; }

        private static ProxySettings? instance;

        public static ProxySettings get_default () {
            if (instance == null) {
                instance = new ProxySettings ();
            }

            return instance;
        }

        private ProxySettings () {
            base ("org.gnome.system.proxy");
        }

        public void get_state_data (out unowned string description, out unowned string icon) {
            switch (mode) {
                case "none":
                    description = _("Disabled");
                    icon = "user-offline";
                    break;
                case "manual":
                    description = _("Enabled (manual mode)");
                    icon = "user-available";
                    break;
                case "auto":                
                    description = _("Enabled (auto mode)");
                    icon = "user-available";
                    break;
                default:
                    description = _("Unknown");
                    icon = "user-offline";
                    break;
            }
        }

        public string[] get_ignored_hosts () {
            return ignore_hosts;
        }
    }

    public class ProxyFTPSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public ProxyFTPSettings () {
            base ("org.gnome.system.proxy.ftp");
        }
    }

    public class ProxyHTTPSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public ProxyHTTPSettings () {
            base ("org.gnome.system.proxy.http");
        }
    }

    public class ProxyHTTPSSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public ProxyHTTPSSettings () {
            base ("org.gnome.system.proxy.https");
        }
    }

    public class ProxySocksSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public ProxySocksSettings () {
            base ("org.gnome.system.proxy.socks");
        }
    }
}
