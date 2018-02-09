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
    public class ProxyPage : Gtk.Grid {
        public Gtk.Stack stack;
        public signal void update_status_label (string mode);

        public DeviceItem owner { get; construct; }
        private Gtk.Switch control_switch;
        private ConfigurationPage configuration_page;
#if ENABLE_SYSTEMWIDE_PROXY
        private Gtk.InfoBar? permission_infobar = null;
        private static Polkit.Permission? polkit_permission = null;
        private UbuntuSystemService system_proxy_service;
        private bool _system_wide_available = false;
        public bool system_wide_available {
            get {
                return _system_wide_available;
            }
            set {
                _system_wide_available = value;
            }
        }
#endif

        public ProxyPage (DeviceItem _owner) {
            Object (owner: _owner);
        }

        construct {
#if ENABLE_SYSTEMWIDE_PROXY
            try {
                system_proxy_service = Bus.get_proxy_sync (BusType.SYSTEM, "com.ubuntu.SystemService", "/");
            } catch (Error e) {
                warning ("Unable to connect to Ubuntu System Service to set system-wide proxy settings: %s", e.message);
            }
#endif

            orientation = Gtk.Orientation.VERTICAL;

            column_spacing = 12;
            row_spacing = 12;
            margin_bottom = 12;

            configuration_page = new ConfigurationPage ();
            var exceptions_page = new ExecepionsPage ();

#if ENABLE_SYSTEMWIDE_PROXY
            configuration_page.changed.connect (on_proxy_settings_changed);
            exceptions_page.changed.connect (on_proxy_settings_changed);
#endif

            stack = new Gtk.Stack ();
            stack.add_titled (configuration_page, "configuration", _("Configuration"));
            stack.add_titled (exceptions_page, "exceptions", _("Exceptions"));

            var stackswitcher = new Gtk.StackSwitcher ();
            stackswitcher.halign = Gtk.Align.CENTER;
            stackswitcher.stack = stack;

            proxy_settings.changed.connect (update_mode);
            update_mode ();

#if ENABLE_SYSTEMWIDE_PROXY
            configuration_page.notify["manual-mode"].connect (() => {
                update_infobar_visibility ();
            });

            var permission = get_permission ();

            if (permission != null) {
                permission.notify["allowed"].connect (() => {
                    permission_infobar.visible = !permission.allowed;
                    system_wide_available = permission.allowed;
                });

                permission_infobar = new Gtk.InfoBar ();
                permission_infobar.message_type = Gtk.MessageType.INFO;

                var area_infobar = permission_infobar.get_action_area () as Gtk.Container;
                var lock_button = new Gtk.LockButton (permission);
                area_infobar.add (lock_button);

                var content_infobar = permission_infobar.get_content_area () as Gtk.Container;
                var label_infobar = new Gtk.Label (_("Administrator rights are required to set a system-wide proxy"));
                content_infobar.add (label_infobar);
            }

            bind_property ("system-wide-available", configuration_page, "system-wide-available", BindingFlags.SYNC_CREATE);
#endif

            var device_img = new Gtk.Image.from_icon_name ("preferences-system-network", Gtk.IconSize.DIALOG);
            device_img.pixel_size = 48;

            var device_label = new Gtk.Label (_("Proxy"));
            device_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
            device_label.get_style_context ().add_class ("h2");
            device_label.hexpand = true;
            device_label.xalign = 0;

            control_switch = new Gtk.Switch ();
            control_switch.valign = Gtk.Align.CENTER;

            control_switch.bind_property ("active", configuration_page, "sensitive", BindingFlags.SYNC_CREATE);
            control_switch.bind_property ("active", exceptions_page, "sensitive", BindingFlags.SYNC_CREATE);
            control_switch.notify["active"].connect (control_switch_activated);

            var control_box = new Gtk.Grid ();
            control_box.column_spacing = 12;
            control_box.margin_left = control_box.margin_right = 24;
            control_box.margin_top = 24;
            control_box.add (device_img);
            control_box.add (device_label);
            control_box.add (control_switch);

#if ENABLE_SYSTEMWIDE_PROXY
            if (permission_infobar != null) {
                add (permission_infobar);
            }
#endif
            add (control_box);
            add (stackswitcher);
            add (stack);

            show_all ();

            stack.visible_child = configuration_page;

#if ENABLE_SYSTEMWIDE_PROXY
            update_infobar_visibility ();
#endif
        }

#if ENABLE_SYSTEMWIDE_PROXY
        private void on_proxy_settings_changed () {
            if (!system_wide_available) {
                return;
            }

            try {
                if (proxy_settings.mode == "manual") {
                    if (http_settings.host != "" && http_settings.port > 0) {
                        system_proxy_service.set_proxy ("http", "http://%s:%d".printf (http_settings.host, http_settings.port));
                    } else {
                        system_proxy_service.set_proxy ("http", "");
                    }

                    if (https_settings.host != "" && http_settings.port > 0) {
                        system_proxy_service.set_proxy ("https", "https://%s:%d".printf (https_settings.host, https_settings.port));
                    } else {
                        system_proxy_service.set_proxy ("https", "");
                    }

                    if (ftp_settings.host != "" && ftp_settings.port > 0) {
                        system_proxy_service.set_proxy ("ftp", "ftp://%s:%d".printf (ftp_settings.host, ftp_settings.port));
                    } else {
                        system_proxy_service.set_proxy ("ftp", "");
                    }

                    if (socks_settings.host != "" && socks_settings.port > 0) {
                        system_proxy_service.set_proxy ("socks", "socks://%s:%d".printf (socks_settings.host, socks_settings.port));
                    } else {
                        system_proxy_service.set_proxy ("socks", "");
                    }

                    system_proxy_service.set_no_proxy (string.joinv (",", proxy_settings.ignore_hosts));
                } else {
                    system_proxy_service.set_proxy ("http", "");
                    system_proxy_service.set_proxy ("https", "");
                    system_proxy_service.set_proxy ("ftp", "");
                    system_proxy_service.set_proxy ("socks", "");
                    system_proxy_service.set_no_proxy ("");
                }
            } catch (IOError e) {
                warning ("Error while applying systemwide proxy config: %s", e.message);
            }
        }

        private static Polkit.Permission? get_permission () {
            try {
                if (polkit_permission == null) {
                    polkit_permission = new Polkit.Permission.sync ("org.pantheon.switchboard.networking.setproxy",
                                                                    new Polkit.UnixProcess (Posix.getpid ()));

                }

                return polkit_permission;
            } catch (Error e) {
                critical (e.message);
                return null;
            }
        }

        private void update_infobar_visibility () {
            permission_infobar.visible = configuration_page.manual_mode;
        }
#endif

        protected void control_switch_activated () {
            if (!control_switch.active) {
                proxy_settings.mode = "none";
            }

#if ENABLE_SYSTEMWIDE_PROXY
            on_proxy_settings_changed ();
#endif
        }

        private void update_mode () {
            var mode = Utils.CustomMode.INVALID;
            switch (proxy_settings.mode) {
                case "none":
                    mode = Utils.CustomMode.PROXY_NONE;
                    control_switch.active = false;
                    break;
                case "manual":
                    mode = Utils.CustomMode.PROXY_MANUAL;
                    control_switch.active = true;
                    break;
                case "auto":
                    mode = Utils.CustomMode.PROXY_AUTO;
                    control_switch.active = true;
                    break;
                default:
                    mode = Utils.CustomMode.INVALID;
                    break;
            }

            owner.switch_status (mode);
        }
    }
}
