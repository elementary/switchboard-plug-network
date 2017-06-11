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
    public class DevicePage : Page {
        public Device device { get; construct; }

        public static DevicePage? create_for_device (Device device) {
            switch (device.target.get_device_type ()) {
                case NM.DeviceType.ETHERNET:
                    return new EthernetPage (device);
                default:
                    return new DevicePage (device);
            }
        }

        construct {
            device.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
            device.bind_property ("icon-name", this, "icon-name", BindingFlags.SYNC_CREATE);
            device.target.state_changed.connect (() => update ());

            show_all ();            
        }

        public DevicePage (Device device) {
            Object (device: device);
        }

        protected override void update () {
            device.updating = true;

            var state = device.target.get_state ();
            control_switch.active = state != NM.DeviceState.DISCONNECTED &&
                                    state != NM.DeviceState.DEACTIVATING;

            device.updating = false;
        }

        protected override void control_switch_activated () {
            if (device.updating) {
                return;
            }

            var target = device.target;

            if (control_switch.active) {
                var client = DeviceManager.get_default_client ();
                var connection = device.find_available_connection ();
                if (connection != null) {
                    client.activate_connection_async.begin (connection, target, null, null);
                }
            } else {
                disconnect_device.begin ();
            }
        }

        private async void disconnect_device () {
            try {
                yield device.target.disconnect_async (null);
            } catch (Error e) {
                warning ("Could not disconnect: %s", e.message);
            }            
        }
    }
}