
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
