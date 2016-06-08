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
    public class InfoBox : Gtk.Box {
        public signal void update_sidebar (DeviceItem item);
        public signal void info_changed ();
        private NM.Device device;
        private DeviceItem? owner;

        private string ip4address_l = (_("IP Address:") + SUFFIX);
        private string ip6address_l = (_("IPv6 Address:") + SUFFIX);
        private string mask_l = (_("Subnet mask:") + SUFFIX);
        private string router_l = (_("Router:") + SUFFIX);
        private string broadcast_l = (_("Broadcast:") + SUFFIX);
        private string sent_l = (_("Sent:") + SUFFIX);
        private string received_l = (_("Received:") + SUFFIX);

        private Gtk.Label ip4address;
        private Gtk.Label ip6address;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label broadcast;
        private Gtk.Label sent;
        private Gtk.Label received;

        private Gtk.Label ip6address_head;

        public InfoBox.from_device (NM.Device? _device) {
            owner = null;
            device = _device;

            init_box ();
        }

        public InfoBox.from_owner (DeviceItem? _owner) {
            owner = _owner;
            device = owner.get_item_device ();

            init_box ();
        }

        private void init_box () {
            this.orientation = Gtk.Orientation.HORIZONTAL;
            this.spacing = 1;

            var info_grid = new Gtk.Grid ();
            info_grid.column_spacing = 12;
            info_grid.row_spacing = 6;

            var activity_info = new Gtk.Grid ();
            activity_info.expand = true;
            activity_info.column_spacing = 12;
            activity_info.row_spacing = 8;

            var sent_head = new Gtk.Label (sent_l);
            sent_head.margin_start = 6;            
            sent = new Gtk.Label ("");
            sent.halign = Gtk.Align.END;

            var received_head = new Gtk.Label (received_l);
            received_head.margin_start = 8;
            received = new Gtk.Label ("");

            fix_halign (Gtk.Align.END, activity_info, sent_head,
                        sent, received_head, received);

            fix_first_col (sent_head, received_head);

            activity_info.attach (sent_head, 0, 0);
            activity_info.attach_next_to (sent, sent_head, Gtk.PositionType.RIGHT);
            activity_info.attach_next_to (received_head, sent_head, Gtk.PositionType.BOTTOM);
            activity_info.attach_next_to (received, received_head, Gtk.PositionType.RIGHT);

            ip4address = new Gtk.Label ("");
            ip4address.selectable = true;

            ip6address = new Gtk.Label ("");
            ip6address.selectable = true;
            ip6address.no_show_all = true;

            mask = new Gtk.Label ("");
            mask.selectable = true;

            router = new Gtk.Label ("");
            router.selectable = true;

            broadcast = new Gtk.Label ("");
            broadcast.selectable = true;

            var ip4address_head = new Gtk.Label (ip4address_l);

            ip6address_head = new Gtk.Label (ip6address_l);
            ip6address_head.no_show_all = true;
            ip6address_head.valign = Gtk.Align.START;

            var mask_head = new Gtk.Label (mask_l);
            var broadcast_head = new Gtk.Label (broadcast_l);
            var router_head = new Gtk.Label (router_l);

            fix_halign (Gtk.Align.START, ip4address, ip6address, mask, broadcast,
                        router, ip4address_head, ip6address_head, mask_head,
                        broadcast_head, router_head);

            fix_first_col (ip4address_head, ip6address_head, mask_head,
                           broadcast_head, router_head);

            info_grid.attach (ip4address_head, 0, 0);
            info_grid.attach_next_to (ip4address, ip4address_head, Gtk.PositionType.RIGHT);

            info_grid.attach_next_to (ip6address_head, ip4address_head, Gtk.PositionType.BOTTOM);
            info_grid.attach_next_to (ip6address, ip6address_head, Gtk.PositionType.RIGHT);

            info_grid.attach_next_to (mask_head, ip6address_head, Gtk.PositionType.BOTTOM);
            info_grid.attach_next_to (mask, mask_head, Gtk.PositionType.RIGHT);

            info_grid.attach_next_to (router_head, mask_head, Gtk.PositionType.BOTTOM);
            info_grid.attach_next_to (router, router_head, Gtk.PositionType.RIGHT);

            info_grid.attach_next_to (broadcast_head, router_head, Gtk.PositionType.BOTTOM);
            info_grid.attach_next_to (broadcast, broadcast_head, Gtk.PositionType.RIGHT);

            device.state_changed.connect (() => { 
                update_status ();
                info_changed ();
            });

            update_status ();

            this.add (info_grid);
            this.pack_end (activity_info, false, true, 0);
            this.show_all ();
        }

        public void update_activity (string sent_bytes, string received_bytes) {
            sent.label = sent_bytes ?? UNKNOWN_STR;
            received.label = received_bytes ?? UNKNOWN_STR;
        }

        public void update_status () {
            // Refresh DHCP4 info
            var dhcp4 = device.get_dhcp4_config ();
            if (dhcp4 != null) {
                ip4address.label =  (dhcp4.get_one_option ("ip_address") ?? UNKNOWN_STR);
                mask.label =  (dhcp4.get_one_option ("subnet_mask") ?? UNKNOWN_STR);
                router.label =  (dhcp4.get_one_option ("routers") ?? UNKNOWN_STR);
                broadcast.label =  (dhcp4.get_one_option ("broadcast_address") ?? UNKNOWN_STR);
            } else {
                ip4address.label = UNKNOWN_STR;
                mask.label =  UNKNOWN_STR;
                router.label = UNKNOWN_STR;
                broadcast.label = UNKNOWN_STR;
            }

            var ip6 = device.get_ip6_config ();
            ip6address.visible = ip6address_head.visible = (ip6 != null);
            ip6address.label = "";
            if (ip6 != null) {
                int i = 1;
                SList<NM.IP6Address> addresses = ip6.get_addresses ().copy ();
                addresses.@foreach ((addr) => {
                    addr.@ref ();
                    var inet = new InetAddress.from_bytes (addr.get_address (), SocketFamily.IPV6);
                    string inet_str = inet.to_string () + "/" + addr.get_prefix ().to_string ();
                    ip6address.visible = ip6address_head.visible = (inet_str.strip () != "");
                    ip6address.label += inet_str;
                    if (i < addresses.length ()) {
                        ip6address.label += "\n";
                    }

                    i++;
                });         
            }


            if (owner != null) {
                update_sidebar (owner);
            }

            this.show_all ();
        }

        private void fix_first_col (Gtk.Label wid, ...) {
            var list = va_list ();
            do {
                ((Gtk.Misc) wid).xalign = 1;
                wid = list.arg ();
            } while (wid != null);
        }

        private void fix_halign (Gtk.Align val, ...) {
            var list = va_list ();
            while (true) {
                Gtk.Label wid = list.arg ();
                if (wid == null) {
                    break;
                }
                
                wid.halign = val;
            }
        }
    }
}
