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
    public class Page : Gtk.Box {
        public NM.Device device;
        public InfoBox info_box;
        public Gtk.Switch control_switch;
        public Gtk.Box control_box;
        public signal void show_error ();

        private string _icon_name;
        public string icon_name {
            get {
                return _icon_name;
            }

            set {
                _icon_name = value;
                device_img.icon_name = _icon_name;
            }
        }

        private Gtk.Image device_img;
        protected Gtk.Label device_label;

        protected Gtk.Revealer bottom_revealer;
        protected Gtk.Box bottom_box;

        public Page () {
            this.orientation = Gtk.Orientation.VERTICAL;
            this.margin = 12;
            this.margin_start = 20;
            this.margin_top = this.margin_start;
            this.spacing = 24;
            bottom_revealer = new Gtk.Revealer ();
            bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

            bottom_revealer.add (bottom_box);
        }

        public void init (NM.Device _device, Widgets.InfoBox _info_box) {
            this.device = _device;
            this.info_box = _info_box;
            info_box.margin_end = 16;
            info_box.info_changed.connect (update);
            
            device_img = new Gtk.Image.from_icon_name (_icon_name, Gtk.IconSize.DIALOG);
            device_img.pixel_size = 48;

            device_label = new Gtk.Label (Utils.type_to_string (device.get_device_type ()));
            device_label.get_style_context ().add_class ("h2");

            control_switch = new Gtk.Switch ();
            control_switch.valign = Gtk.Align.CENTER;
            update_switch ();

            control_switch.notify["active"].connect (control_switch_activated);

            control_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            control_box.pack_start (device_img, false, false, 0);
            control_box.pack_start (device_label, false, false, 0);
            control_box.pack_end (control_switch, false, false, 0);

            this.add (control_box);
            this.show_all ();
        }

        public virtual void update () {
            string sent_bytes, received_bytes;
            this.get_activity_information (device.get_iface (), out sent_bytes, out received_bytes);
            info_box.update_activity (sent_bytes, received_bytes);

            update_switch ();

            bottom_revealer.set_reveal_child (control_switch.active);
        }

        public void add_switch_title (string title) {
            var label = new Gtk.Label ("<b>" + title + "</b>");
            label.use_markup = true;
            control_box.pack_end (label, false, false, 0);
        }

        protected virtual void update_switch () {
            control_switch.active = device.get_state () != NM.DeviceState.DISCONNECTED && device.get_state () != NM.DeviceState.DEACTIVATING;
        }

        protected virtual void control_switch_activated () {
            if (!control_switch.active && device.get_state () == NM.DeviceState.ACTIVATED) {
                device.disconnect (null);
            } else if (control_switch.active && device.get_state () == NM.DeviceState.DISCONNECTED) {
                var connection = new NM.Connection ();
                var remote_array = device.get_available_connections ();
                if (remote_array == null) {
                    this.show_error ();
                } else {
                    connection.path = remote_array.get (0).get_path ();
                    client.activate_connection (connection, device, null, null);
                }
            }
        }

        public void get_activity_information (string iface, out string sent_bytes, out string received_bytes) {
            sent_bytes = _("Unknown");
            received_bytes = _("Unknown");

            string tx_bytes_path = "/sys/class/net/" + iface + "/statistics/tx_bytes";
            string rx_bytes_path = "/sys/class/net/" + iface + "/statistics/rx_bytes";

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
                error ("%s\n", e.message);
            }
        }
    }
}
