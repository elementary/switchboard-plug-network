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


        public ProxyPage () {
            Object (
                activatable: true,
                title: _("Proxy"),
                icon: new ThemedIcon ("preferences-system-network")
            );

        }

        construct {
            var configuration_page = new ConfigurationPage ();
            var exceptions_page = new ExecepionsPage ();

            status_switch.bind_property ("active", configuration_page, "sensitive", BindingFlags.SYNC_CREATE);
            status_switch.bind_property ("active", exceptions_page, "sensitive", BindingFlags.SYNC_CREATE);

            stack = new Gtk.Stack ();
            stack.add_titled (configuration_page, "configuration", _("Configuration"));
            stack.add_titled (exceptions_page, "exceptions", _("Exceptions"));

            var stackswitcher = new Gtk.StackSwitcher () {
                halign = Gtk.Align.CENTER,
                stack = stack
            };

            var sizegroup = new Gtk.SizeGroup (HORIZONTAL);
            unowned var switcher_child = stackswitcher.get_first_child ();
            while (switcher_child != null) {
                sizegroup.add_widget (switcher_child);
                switcher_child = switcher_child.get_next_sibling ();
            }

            Network.Plug.proxy_settings.changed.connect (update_mode);
            update_mode ();

            var box = new Gtk.Box (VERTICAL, 12);
            box.append (stackswitcher);
            box.append (stack);

            child = box;

            stack.visible_child = configuration_page;
        }

        protected override void control_switch_activated () {
            if (status_switch.active) {
                Network.Plug.proxy_settings.set_string ("mode", "auto");
            } else {
                Network.Plug.proxy_settings.set_string ("mode", "none");
            }
        }

        protected override void update_switch () {

        }

        private void update_mode () {
            switch (Network.Plug.proxy_settings.get_string ("mode")) {
                case "none":
                    status = _("Disabled");
                    status_switch.active = false;
                    status_type = OFFLINE;
                    break;
                case "manual":
                    status = _("Enabled (manual mode)");
                    status_switch.active = true;
                    status_type = SUCCESS;
                    break;
                case "auto":
                    status = _("Enabled (auto mode)");
                    status_switch.active = true;
                    status_type = SUCCESS;
                    break;
            }
        }
    }
}
