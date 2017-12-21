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
        private Gtk.Switch control_switch;

        public ProxyPage (DeviceItem _owner) {
            owner = _owner;
            orientation = Gtk.Orientation.VERTICAL;

            column_spacing = 12;
            row_spacing = 12;
            margin_bottom = 12;

            var configuration_page = new ConfigurationPage ();
            var exceptions_page = new ExecepionsPage ();

            stack = new Gtk.Stack ();
            stack.add_titled (configuration_page, "configuration", _("Configuration"));
            stack.add_titled (exceptions_page, "exceptions", _("Exceptions"));

            var stackswitcher = new Gtk.StackSwitcher ();
            stackswitcher.halign = Gtk.Align.CENTER;
            stackswitcher.stack = stack;

            proxy_settings.changed.connect (update_mode);
            update_mode ();

            var permission_infobar = new Gtk.InfoBar ();
            permission_infobar.message_type = Gtk.MessageType.INFO;

            var permission = get_permission ();

            var area_infobar = permission_infobar.get_action_area () as Gtk.Container;
            var lock_button = new Gtk.LockButton (permission);
            area_infobar.add (lock_button);

            var content_infobar = permission_infobar.get_content_area () as Gtk.Container;
            var label_infobar = new Gtk.Label (_("Administrator rights are required to set a system-wide proxy"));
            content_infobar.add (label_infobar);

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
            control_box.add (device_img);
            control_box.add (device_label);
            control_box.add (control_switch);

            add (permission_infobar);
            add (control_box);
            add (stackswitcher);
            add (stack);

            show_all ();

            stack.visible_child = configuration_page;
        }

        private static Polkit.Permission? get_permission () {
            try {
                var permission = new Polkit.Permission.sync ("com.ubuntu.systemservice.setproxy", new Polkit.UnixProcess (Posix.getpid ()));
                return permission;
            } catch (Error e) {
                critical (e.message);
                return null;
            }
        }

        protected void control_switch_activated () {
            if (!control_switch.active) {
                proxy_settings.mode = "none";
            }
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
