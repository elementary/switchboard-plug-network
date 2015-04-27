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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

namespace Network.Widgets {
    public class DevicePage : Gtk.Box {
        public NM.Device device;
        public DeviceItem owner;
        private NM.DHCP4Config? dhcp4;        

        public signal void update_sidebar (DeviceItem item);

        public Gtk.Button enable_btn;
        private Gtk.Button details_btn;
        public Gtk.Switch control_switch;

        private string status_l = (_("Status:") + SUFFIX);
		private string ipaddress_l = (_("IP Address:") + SUFFIX);
		private string mask_l = (_("Subnet mask:") + SUFFIX);
		private string router_l = (_("Router:") + SUFFIX);
		private string broadcast_l = (_("Broadcast:") + SUFFIX);
		private string sent_l = (_("Sent:") + SUFFIX);
		private string received_l = (_("Received:") + SUFFIX);

        private Gtk.Label status;
        private Gtk.Label ipaddress;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label broadcast;
        private Gtk.Label sent;
        private Gtk.Label received;

        public DevicePage.from_owner (DeviceItem? _owner) {
            owner = _owner;
            device = owner.get_item_device ();
      
            dhcp4 = device.get_dhcp4_config ();
            
            this.orientation = Gtk.Orientation.VERTICAL;
            this.margin = 30;
            this.spacing = this.margin;

            var allbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            var device_img = new Gtk.Image.from_icon_name (owner.get_item_icon_name (), Gtk.IconSize.DIALOG);
            device_img.margin_end = 15;
            
            var device_label = new Gtk.Label (Utils.type_to_string (device.get_device_type ()));
            device_label.get_style_context ().add_class ("h2");
            
            control_switch = new Gtk.Switch ();

            var control_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            control_box.pack_start (device_img, false, false, 0);
            control_box.pack_start (device_label, false, false, 0);
            control_box.pack_end (control_switch, false, false, 0);     
            
            var activitybox = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
            activitybox.hexpand = true;

            sent = new Gtk.Label (sent_l);
            sent.halign = Gtk.Align.END;

            received = new Gtk.Label (received_l);
            received.halign = Gtk.Align.END;

            allbox.add (get_info_box_from_device ());
            allbox.add (activitybox);

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_start (Utils.get_advanced_button_from_device (device), false, false, 0);

            //activitybox.add (activity);
            activitybox.add (new Gtk.Label ("\n"));
            activitybox.add (sent);
            activitybox.add (received);

            set_switch_state ();

            this.add (control_box);
            this.add (allbox);
            this.pack_end (details_box, false, false, 0);
            this.show_all ();
        }

        public new Gtk.Box get_info_box_from_device (NM.Device? dev = device) {
            var infobox = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
            infobox.hexpand = true;

            status = new Gtk.Label (status_l);
            status.use_markup = true;  
            status.halign = Gtk.Align.START;        

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

            infobox.add (status);
            infobox.add (new Gtk.Label (""));
            infobox.add (ipaddress);
            infobox.add (mask);
            infobox.add (router);
            infobox.add (broadcast);

            update_status ();

            dev.state_changed.connect (() => {
                update_status ();
            });

            return infobox;        
        }

        public void update_status (NM.Device dev = device) {
        	// Refresh status
            switch (dev.get_state ()) {
            	case NM.DeviceState.ACTIVATED:
            		status.label = status_l + "<span color='#22c302'>%s</span>".printf (Utils.state_to_string (dev.get_state ()));	
            		break;
            	case NM.DeviceState.DISCONNECTED:
            		status.label = status_l + "<span color='#e51a1a'>%s</span>".printf (Utils.state_to_string (dev.get_state ()));
            		break;
            	default:
            		if (Utils.state_to_string (device.get_state ()) == "Unknown")
            			status.label = status_l + "<span color='#858585'>%s</span>".printf (Utils.state_to_string (dev.get_state ()));
            		else	
            			status.label = status_l + "<span color='#f1d805'>%s</span>".printf (Utils.state_to_string (dev.get_state ()));
            		break;
            }

            // Refresh DHCP4 info
            dhcp4 = dev.get_dhcp4_config ();
            ipaddress.label = ipaddress_l + (dhcp4.get_one_option ("ip_address") ?? UNKNOWN);
            mask.label = mask_l + (dhcp4.get_one_option ("subnet_mask") ?? UNKNOWN);
            router.label = router_l + (dhcp4.get_one_option ("routers") ?? UNKNOWN);
            broadcast.label = broadcast_l + (dhcp4.get_one_option ("broadcast_address") ?? UNKNOWN);
            sent.label = sent_l + (get_activity_information (device.get_iface ())[0]) ?? UNKNOWN;
            received.label = received_l + (get_activity_information (device.get_iface ())[1]) ?? UNKNOWN;   

            update_sidebar (owner);

            this.show_all ();
        }

        private void set_switch_state () {
            if (device.get_state () != NM.DeviceState.ACTIVATED)
                control_switch.state = false;
            else    
                control_switch.state = true;        
        }

        public void buttons_available (bool available) {
        	enable_btn.sensitive = available;
        	details_btn.sensitive = available;

        }

        /*** Main method to get all information about the interface ***/
        private string[] get_activity_information (string iface) {
            string received_bytes = UNKNOWN, transfered_bytes = UNKNOWN;

    	    try {
    	        string[] spawn_args = { "ifconfig", iface };
    	    	string[] spawn_env = Environ.get ();
    	    	string output;

    	    	Process.spawn_sync ("/",
    	    						spawn_args,
    	    						spawn_env,
    	    						SpawnFlags.SEARCH_PATH,
    	    						null,
    	    						out output,
    	    						null,
    	    						null);

                string[] data = output.split ("\n");
                foreach (string line in data) {
                    if (line.contains ("RX bytes:")) {
                        string[] inf3 = line.split (":");
                        received_bytes = inf3[1].split ("  ")[0].split (" ", 2)[1].replace ("(", "").replace (")", "");
                        transfered_bytes = inf3[2].split (" ", 2)[1].replace ("(", "").replace (")", "");
                    }
                }

    	        } catch (SpawnError e) {
    	        	error (e.message);
    	        }
	        
	        return { received_bytes, transfered_bytes };              
        }                 
    }  
}
