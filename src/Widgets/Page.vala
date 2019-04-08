/*
 * Copyright 2015-2019 elementary, Inc. (https://elementary.io)
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
 *              xapantu
 */

namespace Network.Widgets {
    public abstract class Page : Granite.SimpleSettingsPage {
        public NM.Device? device { get; construct; }

        protected InfoBox? info_box;

        construct {
            content_area.orientation = Gtk.Orientation.VERTICAL;
            content_area.row_spacing = 24;

            if (device != null) {
                title = Utils.type_to_string (device.get_device_type ());
            } else if (title == null){
                title = _("Unknown Device");
            }

            update_switch ();

            status_switch.notify["active"].connect (control_switch_activated);

            if (device != null) {
                info_box = new InfoBox.from_device (device);
                info_box.margin_end = 16;
                info_box.vexpand = true;
                info_box.info_changed.connect (update);
            }

            show_all ();
        }

        public virtual void update () {
            if (info_box != null) {
                string sent_bytes, received_bytes;
                this.get_activity_information (out sent_bytes, out received_bytes);
                info_box.update_activity (sent_bytes, received_bytes);
            }

            update_switch ();
        }

        protected virtual void update_switch () {
            status_switch.active = device.get_state () != NM.DeviceState.DISCONNECTED && device.get_state () != NM.DeviceState.DEACTIVATING;
        }

        protected virtual void control_switch_activated () {
            if (!status_switch.active && device.get_state () == NM.DeviceState.ACTIVATED) {
                try {
                    device.disconnect (null);
                } catch (Error e) {
                    status_switch.active = true;

                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                        _("Failed To Disconnect"),
                        _("Unable to disconnect from the currently connected network"),
                        "network-error",
                        Gtk.ButtonsType.CLOSE
                    );
                    message_dialog.show_error_details (e.message);
                    message_dialog.run ();
	                message_dialog.destroy ();
                }
            } else if (status_switch.active && device.get_state () == NM.DeviceState.DISCONNECTED) {
                var connection = NM.SimpleConnection.new ();
                var remote_array = device.get_available_connections ();
                if (remote_array != null) {
                    connection.set_path (remote_array.get (0).get_path ());
                    unowned NetworkManager network_manager = NetworkManager.get_default ();
                    network_manager.client.activate_connection_async.begin (connection, device, null, null, null);
                }
            }
        }

        protected void get_activity_information (out string sent_bytes, out string received_bytes) {
            sent_bytes = UNKNOWN_STR;
            received_bytes = UNKNOWN_STR;

            var iface = device.get_ip_iface ();
            if (iface == null)
                return;

            string tx_bytes_path = Path.build_filename (Path.DIR_SEPARATOR_S, "sys", "class", "net", iface, "statistics", "tx_bytes");
            string rx_bytes_path = Path.build_filename (Path.DIR_SEPARATOR_S, "sys", "class", "net", iface, "statistics", "rx_bytes");

            if (!(File.new_for_path (tx_bytes_path).query_exists ()
                && File.new_for_path (rx_bytes_path).query_exists ())) {
                return;
            }

            try {
                string tx_bytes, rx_bytes;

                FileUtils.get_contents (tx_bytes_path, out tx_bytes);
                FileUtils.get_contents (rx_bytes_path, out rx_bytes);

                sent_bytes = format_size (uint64.parse (tx_bytes));
                received_bytes = format_size (uint64.parse (rx_bytes));
            } catch (FileError e) {
                critical (e.message);
            }
        }
    }
}
