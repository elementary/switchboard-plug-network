// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-plug-networking)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace Network.Widgets {  
    public class InfoBox : Gtk.Box {
        public signal void update_sidebar (DeviceItem item);
        public signal void info_changed ();
        private NM.Device device;
        private DeviceItem? owner;

        private string ipaddress_l = (_("IP Address:") + SUFFIX);
        private string mask_l = (_("Subnet mask:") + SUFFIX);
        private string router_l = (_("Router:") + SUFFIX);
        private string broadcast_l = (_("Broadcast:") + SUFFIX);
        private string sent_l = (_("Sent:") + SUFFIX);
        private string received_l = (_("Received:") + SUFFIX);

        private Gtk.Label ipaddress;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label broadcast;
        private Gtk.Label sent;
        private Gtk.Label received;

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

            ipaddress = new Gtk.Label ("");
            ipaddress.selectable = true;

            mask = new Gtk.Label ("");
            mask.selectable = true;

            router = new Gtk.Label ("");
            router.selectable = true;

            broadcast = new Gtk.Label ("");
            broadcast.selectable = true;

            var ipaddress_head = new Gtk.Label (ipaddress_l);
            var mask_head = new Gtk.Label (mask_l);
            var broadcast_head = new Gtk.Label (broadcast_l);
            var router_head = new Gtk.Label (router_l);

            fix_halign (Gtk.Align.START, ipaddress, mask, broadcast,
                        router, ipaddress_head, mask_head,
                        broadcast_head, router_head);

            fix_first_col (ipaddress_head, mask_head,
                           broadcast_head, router_head);

            info_grid.attach (ipaddress_head, 0, 0);
            info_grid.attach_next_to (ipaddress, ipaddress_head, Gtk.PositionType.RIGHT);

            info_grid.attach_next_to (mask_head, ipaddress_head, Gtk.PositionType.BOTTOM);
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
            sent.label = sent_bytes ?? _("Unknown");
            received.label = received_bytes ?? _("Unknown");
        }

        public void update_status () {
            // Refresh DHCP4 info
            var dhcp4 = device.get_dhcp4_config ();
            if (dhcp4 != null) {
                ipaddress.label =  (dhcp4.get_one_option ("ip_address") ?? _("Unknown"));
                mask.label =  (dhcp4.get_one_option ("subnet_mask") ?? _("Unknown"));
                router.label =  (dhcp4.get_one_option ("routers") ?? _("Unknown"));
                broadcast.label =  (dhcp4.get_one_option ("broadcast_address") ?? _("Unknown"));
            } else {
                ipaddress.label = _("Unknown");
                mask.label =  _("Unknown");
                router.label = _("Unknown");
                broadcast.label = _("Unknown");
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
