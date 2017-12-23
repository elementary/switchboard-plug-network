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
    public class EtherInterface : AbstractEtherInterface {
        private Gtk.Revealer top_revealer;

        public EtherInterface (NM.Client client, NM.Device device) {
            this.init (device);

            info_box.halign = Gtk.Align.CENTER;

            this.icon_name = "network-wired";

            top_revealer = new Gtk.Revealer ();
            top_revealer.valign = Gtk.Align.START;
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (info_box);

            bottom_box.pack_start (new SettingsButton.from_device (device), false, false, 0);

            add (top_revealer);
            add (bottom_revealer);
            show_all ();
            
            update ();
        }
        
        public override void update () {
            top_revealer.set_reveal_child (control_switch.active);
            base.update ();
        }
    }
}
