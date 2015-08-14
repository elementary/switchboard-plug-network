// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-network-plug)
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
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com
 */

namespace Network.Widgets {  
    public class InfoBox : Gtk.Box {
        public signal void update_sidebar (DeviceItem item);
        public signal void info_changed ();
        private NM.Device device;
        private DeviceItem? owner;

        private string status_l = (_("Status:") + SUFFIX);
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

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);

            var activity_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
            activity_box.hexpand = true;

            sent = new Gtk.Label (sent_l);
            sent.halign = Gtk.Align.END;

            received = new Gtk.Label (received_l);
            received.halign = Gtk.Align.END;

            activity_box.add (new Gtk.Label ("\n"));
            activity_box.add (sent);
            activity_box.add (received);

            ipaddress = new Gtk.Label (ipaddress_l);
            ipaddress.selectable = true;

            mask = new Gtk.Label (mask_l);
            mask.selectable = true;

            router = new Gtk.Label (router_l);
            router.selectable = true;

            broadcast = new Gtk.Label (broadcast_l);
            broadcast.selectable = true;

            ipaddress.halign = Gtk.Align.START;
            mask.halign = Gtk.Align.START;
            broadcast.halign = Gtk.Align.START;
            router.halign = Gtk.Align.START;

            main_box.add (ipaddress);
            main_box.add (mask);
            main_box.add (router);
            main_box.add (broadcast);
            
            device.state_changed.connect (() => { 
                update_status ();
                info_changed ();
            });

            update_status ();

            this.add (main_box);
            this.pack_end (activity_box, false, true, 0);
            this.show_all ();
        }

        public void update_activity (string sent_bytes, string received_bytes) {
            sent.label = sent_l + sent_bytes ?? UNKNOWN;
            received.label = received_l + received_bytes ?? UNKNOWN;
        }

        public void update_status () {
            // Refresh DHCP4 info
            var dhcp4 = device.get_dhcp4_config ();
            if (dhcp4 != null) {
                ipaddress.label = ipaddress_l + (dhcp4.get_one_option ("ip_address") ?? UNKNOWN);
                mask.label = mask_l + (dhcp4.get_one_option ("subnet_mask") ?? UNKNOWN);
                router.label = router_l + (dhcp4.get_one_option ("routers") ?? UNKNOWN);
                broadcast.label = broadcast_l + (dhcp4.get_one_option ("broadcast_address") ?? UNKNOWN);
            } else {
                ipaddress.label = ipaddress_l + UNKNOWN;
                mask.label = mask_l + UNKNOWN;
                router.label = router_l + UNKNOWN;
                broadcast.label = broadcast_l + UNKNOWN;
            }

            if (owner != null)
                update_sidebar (owner);

            this.show_all ();
        }
    }
}
