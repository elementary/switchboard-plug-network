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
    public class DeviceItem : Item {
        public Device device { get; construct; }

        construct {
            device.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
            device.bind_property ("icon-name", this, "icon-name", BindingFlags.SYNC_CREATE);
            device.target.state_changed.connect (() => update_state ());
        }

        public DeviceItem (Device device) {
            Object (device: device);
        }

        public override void update_state () {
            unowned string description;
            unowned string icon;

            device.get_state_data (out description, out icon);
            set_state_data (description, icon);
        }
    }
}