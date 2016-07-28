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

        private DeviceItem owner;
        private Gtk.Switch proxy_switch;

        public ProxyPage (DeviceItem _owner) {
            owner = _owner;
            column_spacing = 12;
            row_spacing = 12;
            margin = 24;
            margin_bottom = 12;

            var proxy_icon = new Gtk.Image.from_icon_name ("preferences-system-network", Gtk.IconSize.DIALOG);

            var proxy_header = new Gtk.Label (_("Proxy"));
            proxy_header.halign = Gtk.Align.START;
            proxy_header.hexpand = true;
            proxy_header.get_style_context ().add_class ("h2");

            proxy_switch = new Gtk.Switch ();
            proxy_switch.valign = Gtk.Align.CENTER;

            proxy_switch.notify["active"].connect (() => {
                if (!proxy_switch.active) {
                    proxy_settings.mode = "none";
                }
            });

            var configuration_page = new ConfigurationPage ();
            var exceptions_page = new ExecepionsPage ();

            proxy_switch.bind_property ("active", configuration_page, "sensitive", BindingFlags.SYNC_CREATE);
            proxy_switch.bind_property ("active", exceptions_page, "sensitive", BindingFlags.SYNC_CREATE);

            stack = new Gtk.Stack ();
            stack.add_titled (configuration_page, "configuration", _("Configuration"));
            stack.add_titled (exceptions_page, "exceptions", _("Exceptions"));

            var stackswitcher = new Gtk.StackSwitcher ();
            stackswitcher.halign = Gtk.Align.CENTER;
            stackswitcher.stack = stack;

            proxy_settings.changed.connect (update_mode);
            update_mode ();

            attach (proxy_icon, 0, 0, 1, 1);
            attach (proxy_header, 1, 0, 1, 1);
            attach (proxy_switch, 2, 0, 1, 1);
            attach (stackswitcher, 0, 1, 3, 1);
            attach (stack, 0, 2, 3, 1);

            show_all ();

            stack.visible_child = configuration_page;
        }

        private void update_mode () {
            var mode = Utils.CustomMode.INVALID;
            switch (proxy_settings.mode) {
                case "none":
                    mode = Utils.CustomMode.PROXY_NONE;
                    proxy_switch.active = false;
                    break;
                case "manual":
                    mode = Utils.CustomMode.PROXY_MANUAL;
                    proxy_switch.active = true;
                    break;
                case "auto":
                    mode = Utils.CustomMode.PROXY_AUTO;
                    proxy_switch.active = true;
                    break;
                default:
                    mode = Utils.CustomMode.INVALID;
                    break;
            }

            owner.switch_status (mode);
        }
    }
}
