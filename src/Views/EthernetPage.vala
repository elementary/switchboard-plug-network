/*-
 * Copyright (c) 2015-2020 elementary, Inc (https://elementary.io)
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
    public class EtherInterface : Network.Widgets.Page {
        private Gtk.Stack widgets_stack;
        private Gtk.Revealer top_revealer;
        private Granite.Placeholder no_cable;

        public EtherInterface (NM.Device device) {
            Object (
                activatable: true,
                device: device,
                icon: new ThemedIcon ("network-wired")
            );
        }

        construct {

            no_cable = new Granite.Placeholder (_("This Wired Network is Unavailable")) {
                description = _("A network cable is not plugged in or may be broken")
            };
            info_box.halign = Gtk.Align.CENTER;

            top_revealer = new Gtk.Revealer () {
                valign = Gtk.Align.START,
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                child = info_box
            };

            widgets_stack = new Gtk.Stack ();
            widgets_stack.add_child (no_cable);
            widgets_stack.add_child (top_revealer);

            child = widgets_stack;

            var settings_button = add_button (_("Advanced Settings…"));
            settings_button.clicked.connect (open_advanced_settings);

            settings_button.sensitive = uuid != "";
            notify["uuid"].connect (() => {
                settings_button.sensitive = uuid != "";
            });

            status_switch.bind_property ("active", top_revealer, "reveal-child", GLib.BindingFlags.SYNC_CREATE);
        }

        public override void update_name (int count) {
            var name = device.get_description ();

            /* At least for docker related interfaces, which can be fairly common */
            if (name.has_prefix ("veth")) {
                title = _("Virtual network: %s").printf (name);
            } else {
                if (count <= 1) {
                    title = _("Wired");
                } else {
                    title = name;
                }
            }
        }

        public override void update () {
            base.update ();

            state = device.state;

            if (state == NM.DeviceState.UNAVAILABLE) {
                widgets_stack.visible_child = no_cable;
            } else {
                widgets_stack.visible_child = top_revealer;
            }
        }
    }
}
