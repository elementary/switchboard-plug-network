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

namespace Network.Widgets {
    public class ProxyPage : Page {
        public Gtk.Stack stack;
        public signal void update_status_label (string mode);

        public DeviceItem owner { get; construct; }

#if USE_UBUNTU_SYSTEM_SERVICE
        private UbuntuSystemService system_proxy_service;

        private bool _systemwide_available = false;
        public bool systemwide_available {
            get {
                return _systemwide_available;
            }
            set {
                _systemwide_available = value;
                configuration_page.systemwide_available = value;
            }
        }
#endif

        private ProxyConfigurationPage configuration_page;

        public ProxyPage (DeviceItem _owner) {
            Object (
                activatable: true,
                title: _("Proxy"),
                icon_name: "preferences-system-network",
                owner: _owner
            );

        }

        construct {
            configuration_page = new ProxyConfigurationPage ();
            var exceptions_page = new ProxyExceptionsPage ();

#if USE_UBUNTU_SYSTEM_SERVICE
            configuration_page.changed.connect (on_proxy_settings_changed);
            exceptions_page.changed.connect (on_proxy_settings_changed);

            try {
                system_proxy_service = Bus.get_proxy_sync (BusType.SYSTEM, "com.ubuntu.SystemService", "/");
            } catch (Error e) {
                warning ("Unable to connect to Ubuntu System Service to set system-wide proxy settings: %s", e.message);
            }
#endif

            status_switch.bind_property ("active", configuration_page, "sensitive", BindingFlags.SYNC_CREATE);
            status_switch.bind_property ("active", exceptions_page, "sensitive", BindingFlags.SYNC_CREATE);

            stack = new Gtk.Stack ();
            stack.add_titled (configuration_page, "configuration", _("Configuration"));
            stack.add_titled (exceptions_page, "exceptions", _("Exceptions"));

            var stackswitcher = new Gtk.StackSwitcher ();
            stackswitcher.homogeneous = true;
            stackswitcher.halign = Gtk.Align.CENTER;
            stackswitcher.stack = stack;

            Network.Plug.proxy_settings.changed.connect (update_mode);
            update_mode ();

            content_area.column_spacing = 12;
            content_area.row_spacing = 12;
            content_area.add (stackswitcher);
            content_area.add (stack);

            show_all ();

            stack.visible_child = configuration_page;
        }

#if USE_UBUNTU_SYSTEM_SERVICE
        private void on_proxy_settings_changed () {
            if (!systemwide_available || system_proxy_service == null) {
                return;
            }

            if (Network.Plug.proxy_settings.get_enum ("mode") == GDesktop.ProxyMode.MANUAL) {
                var http_settings = Network.Plug.http_settings;
                var https_settings = Network.Plug.https_settings;
                var ftp_settings = Network.Plug.ftp_settings;
                var socks_settings = Network.Plug.socks_settings;
                try {
                    var host = http_settings.get_string ("host");
                    var port = http_settings.get_int ("port");
                    if (host != "" && port > 0) {
                        system_proxy_service.set_proxy ("http", "http://%s:%d/".printf (host, port));
                    } else {
                        system_proxy_service.set_proxy ("http", "");
                    }

                    host = https_settings.get_string ("host");
                    port = https_settings.get_int ("port");
                    if (host != "" && port > 0) {
                        system_proxy_service.set_proxy ("https", "https://%s:%d/".printf (host, port));
                    } else {
                        system_proxy_service.set_proxy ("https", "");
                    }

                    host = ftp_settings.get_string ("host");
                    port = ftp_settings.get_int ("port");
                    if (host != null && port > 0) {
                        system_proxy_service.set_proxy ("ftp", "ftp://%s:%d/".printf (host, port));
                    } else {
                        system_proxy_service.set_proxy ("ftp", "");
                    }

                    host = socks_settings.get_string ("host");
                    port = socks_settings.get_int ("port");
                    if (host != null && port > 0) {
                        system_proxy_service.set_proxy ("socks", "socks://%s:%d/".printf (host, port));
                    } else {
                        system_proxy_service.set_proxy ("socks", "");
                    }

                    system_proxy_service.set_no_proxy (string.joinv (",", Network.Plug.proxy_settings.get_strv ("ignore-hosts")));
                } catch (Error e) {
                    warning ("Error applying systemwide proxy settings: %s", e.message);
                }
            } else {
                try {
                    system_proxy_service.set_proxy ("http", "");
                    system_proxy_service.set_proxy ("https", "");
                    system_proxy_service.set_proxy ("ftp", "");
                    system_proxy_service.set_proxy ("socks", "");
                    system_proxy_service.set_no_proxy ("");
                } catch (Error e) {
                    warning ("Error clearing systemwide proy settings: %s", e.message);
                }
            }
        }
#endif

        protected override void control_switch_activated () {
            if (!status_switch.active) {
                Network.Plug.proxy_settings.set_string ("mode", "none");
            }
        }

        protected override void update_switch () {

        }

        private void update_mode () {
            var mode = Utils.CustomMode.INVALID;
            switch (Network.Plug.proxy_settings.get_string ("mode")) {
                case "none":
                    mode = Utils.CustomMode.PROXY_NONE;
                    status_switch.active = false;
                    break;
                case "manual":
                    mode = Utils.CustomMode.PROXY_MANUAL;
                    status_switch.active = true;
                    break;
                case "auto":
                    mode = Utils.CustomMode.PROXY_AUTO;
                    status_switch.active = true;
                    break;
                default:
                    mode = Utils.CustomMode.INVALID;
                    break;
            }

            owner.switch_status (mode);
        }
    }
}
