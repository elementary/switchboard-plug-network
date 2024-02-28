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
    public abstract class Page : Switchboard.SettingsPage {
        public NM.DeviceState state { get; protected set; default = NM.DeviceState.DISCONNECTED; }
        public NM.Device? device { get; construct; }

        public bool connection_editor_available { get; private set; default = false; }

        protected InfoBox? info_box;
        protected string uuid = "";
        private bool switch_updating = false;

        construct {
            if (device != null) {
                title = Utils.type_to_string (device.get_device_type ());
            } else if (title == null) {
                title = _("Unknown Device");
            }

            if (activatable) {
                status_switch.notify["active"].connect (control_switch_activated);
            }

            if (device != null) {
                info_box = new InfoBox.from_device (device) {
                    margin_end = 16,
                    vexpand = true
                };
                info_box.info_changed.connect (update);

                get_uuid ();
                device.state_changed.connect_after (() => {
                    get_uuid ();
                });
            }
        }

        public virtual void update () {
            if (info_box != null) {
                string sent_bytes, received_bytes;
                this.get_activity_information (out sent_bytes, out received_bytes);
                info_box.update_activity (sent_bytes, received_bytes);
            }

            update_switch ();
        }

        public virtual void update_name (int count) {
            title = _("Unknown type: %s ").printf (device.get_description ());
        }

        protected virtual void update_switch () {
            if (!activatable) {
                return;
            }
            switch_updating = true;
            switch (device.state) {
                case NM.DeviceState.UNKNOWN:
                case NM.DeviceState.UNMANAGED:
                case NM.DeviceState.UNAVAILABLE:
                case NM.DeviceState.FAILED:
                    status_switch.sensitive = false;
                    status_switch.active = false;
                    break;
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.DEACTIVATING:
                    status_switch.sensitive = true;
                    status_switch.active = false;
                    switch_updating = false;
                    break;
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.SECONDARIES:
                    status_switch.sensitive = false;
                    status_switch.active = true;
                    break;
                case NM.DeviceState.ACTIVATED:
                    status_switch.sensitive = true;
                    status_switch.active = true;
                    switch_updating = false;
                    break;
                default:
                    break;
            }
        }

        protected virtual void control_switch_activated () {
            if (switch_updating) {
                return;
            }

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
                    ) {
                        modal = true,
                        transient_for = (Gtk.Window) get_root ()
                    };
                    message_dialog.show_error_details (e.message);
                    message_dialog.present ();
                    message_dialog.response.connect (message_dialog.destroy);
                }
            } else if (status_switch.active && device.get_state () == NM.DeviceState.DISCONNECTED) {
                var connection = NM.SimpleConnection.new ();
                var remote_array = device.get_available_connections ();
                if (remote_array != null && remote_array.length > 0) {
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

        private void get_uuid () {
            var active_connection = device.get_active_connection ();
            if (active_connection != null) {
                uuid = active_connection.get_uuid ();
            } else {
                var available_connections = device.get_available_connections ();
                if (available_connections.length > 0) {
                    uuid = available_connections[0].get_uuid ();
                } else {
                    uuid = "";
                }
            }
        }

        protected void edit_connections () {
            try {
                var appinfo = AppInfo.create_from_commandline (
                    "nm-connection-editor", null, AppInfoCreateFlags.NONE
                );
                appinfo.launch (null, null);
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }

        protected void open_advanced_settings () {
            try {
                var appinfo = AppInfo.create_from_commandline (
                    "nm-connection-editor --edit=%s".printf (uuid), null, AppInfoCreateFlags.NONE
                );

                appinfo.launch (null, null);
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }
    }
}
