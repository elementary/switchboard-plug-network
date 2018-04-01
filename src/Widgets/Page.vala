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
 *              xapantu
 */

namespace Network.Widgets {
    public class Page : Gtk.Grid {
        public NM.Device? device { get; construct; }
        public string icon_name { get; set; }
        public string title { get; set; }

        protected InfoBox? info_box;
        public Gtk.Switch control_switch;
        public Gtk.Grid control_box;

        private Gtk.Image device_img;
        protected Gtk.Label device_label;

        protected Gtk.Revealer bottom_revealer;
        protected Gtk.Box bottom_box;

        construct {
            margin = 24;
            orientation = Gtk.Orientation.VERTICAL;
            row_spacing = 24;
            if (device != null) {
                title = Utils.type_to_string (device.get_device_type ());
            }

            bottom_revealer = new Gtk.Revealer ();
            bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

            bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            bottom_box.pack_start (new SettingsButton (), false, false, 0);

            bottom_revealer.add (bottom_box);

            device_img = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
            device_img.pixel_size = 48;

            device_label = new Gtk.Label (null);
            device_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
            device_label.get_style_context ().add_class ("h2");
            device_label.hexpand = true;
            device_label.xalign = 0;

            control_switch = new Gtk.Switch ();
            control_switch.valign = Gtk.Align.CENTER;
            update_switch ();

            control_switch.notify["active"].connect (control_switch_activated);

            if (device != null) {
                info_box = new InfoBox.from_device (device);
                info_box.margin_end = 16;
                info_box.vexpand = true;
                info_box.info_changed.connect (update);
            }

            control_box = new Gtk.Grid ();
            control_box.column_spacing = 12;
            control_box.add (device_img);
            control_box.add (device_label);
            control_box.add (control_switch);

            add (control_box);

            bind_property ("title", device_label, "label", GLib.BindingFlags.SYNC_CREATE);
            bind_property ("icon-name", device_img, "icon-name", GLib.BindingFlags.SYNC_CREATE);

            show_all ();
        }

        public virtual void update () {
            if (info_box != null) {
                string sent_bytes, received_bytes;
                get_activity_information (out sent_bytes, out received_bytes);
                info_box.update_activity (sent_bytes, received_bytes);
            }

            update_switch ();

            bottom_revealer.set_reveal_child (control_switch.active);
        }

        protected static void show_dialog (string title, string description, string icon_name, Gtk.ButtonsType type) {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (title, description, icon_name, type);
            message_dialog.run ();
            message_dialog.destroy ();
        }

        protected virtual void update_switch () {
            control_switch.active = device.get_state () != NM.DeviceState.DISCONNECTED && device.get_state () != NM.DeviceState.DEACTIVATING;
        }

        protected virtual void control_switch_activated () {
            if (!control_switch.active && device.get_state () == NM.DeviceState.ACTIVATED) {
                try {
                    device.disconnect (null);
                } catch (Error e) {
                    show_dialog (
                        _("Failed To Disconnect"),
                        _("Could not disconnect: %s.").printf (e.message),
                        "dialog-error",
                        Gtk.ButtonsType.CLOSE
                    );

                    control_switch.active = true;
                }
            } else if (control_switch.active && device.get_state () == NM.DeviceState.DISCONNECTED) {
                var connection = NM.SimpleConnection.new ();
                var remote_array = device.get_available_connections ();
                if (remote_array == null) {
                    show_dialog (
                        _("Failed To Connect"),
                        _("Could not find any available connections for this device to establish connection."),
                        "dialog-error",
                        Gtk.ButtonsType.CLOSE
                    );

                    control_switch.active = false;
                } else {
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
                warning (e.message);
            }
        }
    }
}
