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

namespace Network {
    public class ProxySettings : Granite.Services.Settings {
        public string autoconfig_url { get; set; }
        public string[] ignore_hosts { get; set; }
        public string mode { get; set; }

        public static ProxySettings () {
            base ("org.gnome.system.proxy");
        }

        public string[] get_ignored_hosts () {
            return ignore_hosts;
        }
    }

    public class ProxyFTPSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public static ProxyFTPSettings () {
            base ("org.gnome.system.proxy.ftp");
        }
    }

    public class ProxyHTTPSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public static ProxyHTTPSettings () {
            base ("org.gnome.system.proxy.http");
        }
    }

    public class ProxyHTTPSSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public static ProxyHTTPSSettings () {
            base ("org.gnome.system.proxy.https");
        }
    }

    public class ProxySocksSettings : Granite.Services.Settings {
        public string host { get; set; }
        public int port { get; set; }

        public static ProxySocksSettings () {
            base ("org.gnome.system.proxy.socks");
        }
    }
}
