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
    public class EtherInterface : Network.Widgets.Page {
        private Gtk.Stack widgets_stack;

        public EtherInterface (NM.Device device) {
            Object (
                activatable: true,
                device: device,
                icon_name: "network-wired"
            );
        }

        construct {
            widgets_stack = new Gtk.Stack ();
            widgets_stack.visible = true;

            var no_cable = new Granite.Widgets.AlertView (_("Cable unplugged"), _("No cable connected"), "");
            info_box.halign = Gtk.Align.CENTER;

            var top_revealer = new Gtk.Revealer ();
            top_revealer.valign = Gtk.Align.START;
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (info_box);

            widgets_stack.add_named (no_cable, "unplugged");
            widgets_stack.add_named (top_revealer, "plugged");
            content_area.add (widgets_stack);

            action_area.add (new SettingsButton.from_device (device));

            show_all ();

            status_switch.bind_property ("active", top_revealer, "reveal-child", GLib.BindingFlags.SYNC_CREATE);
            update ();
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

            string? old_visible_name = widgets_stack.get_visible_child_name ();
            string new_visible_name = "plugged";
            bool ctrl_switch_sens = true;

            if (state == NM.DeviceState.UNAVAILABLE) {
                new_visible_name = "unplugged";
                ctrl_switch_sens = false;
            }

            status_switch.sensitive = ctrl_switch_sens;

            if (old_visible_name == null || old_visible_name != new_visible_name) {
                widgets_stack.set_visible_child_name (new_visible_name);
            }
        }
    }
}
