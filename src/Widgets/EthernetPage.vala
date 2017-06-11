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
    public class EthernetPage : DevicePage {
        private Gtk.Revealer top_revealer;
        private Gtk.Revealer bottom_revealer;
        private Gtk.Box bottom_box;

        construct {
            bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            bottom_box.pack_start (new SettingsButton.from_device (device), false, false, 0);

            bottom_revealer = new Gtk.Revealer ();
            bottom_revealer.valign = Gtk.Align.END;
            bottom_revealer.vexpand = true;
            bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            bottom_revealer.add (bottom_box);

            var info_box = new InfoBox (device);
            info_box.halign = Gtk.Align.CENTER;

            top_revealer = new Gtk.Revealer ();
            top_revealer.valign = Gtk.Align.START;
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (info_box);

            add (top_revealer);
            add (bottom_revealer);

            update ();
        }

        public EthernetPage (Device device) {
            Object (device: device);
        }

        protected override void control_switch_activated () {
            base.control_switch_activated ();

            bool active = control_switch.active;
            bottom_revealer.reveal_child = active;
            top_revealer.reveal_child = active;
        }
    }
}