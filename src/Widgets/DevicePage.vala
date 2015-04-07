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
        private NM.DHCP4Config dhcp4;        
        public bool connected;

        public signal void update_sidebar (DeviceItem item);

        public Gtk.Button enable_btn;
        private Gtk.Box setup_box;
        private Gtk.Button details_btn;
        private const string UNKNOWN = N_("Unknown");
        private const string SUFFIX = " ";

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

        public DevicePage.from_device (NM.Device _device, DeviceItem _owner) {
            device = _device;
            owner = _owner;
            device.state_changed.connect (update_status);

            dhcp4 = device.get_dhcp4_config ();
            
            this.orientation = Gtk.Orientation.VERTICAL;

            var allbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 150);
            allbox.margin_left = 32;
            allbox.margin_right = allbox.margin_left;
            allbox.margin_top = 48;

            var infobox = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
            infobox.hexpand = true;

            var activitybox = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
            activitybox.hexpand = true;

            allbox.add (infobox);
            allbox.add (activitybox);

            status = new Gtk.Label (status_l);
            status.use_markup = true;  
            status.set_alignment (0, 0);         

            var activity = new Gtk.Label (_("Activity:"));
            activity.halign = Gtk.Align.START;

            ipaddress = new Gtk.Label (ipaddress_l);
            ipaddress.selectable = true;
            
            mask = new Gtk.Label (mask_l);
            mask.selectable = true;

            /* Is that should be a gateway? */
            router = new Gtk.Label (router_l);
            router.selectable = true;
            
            broadcast = new Gtk.Label (broadcast_l);
            broadcast.selectable = true;

            ipaddress.halign = Gtk.Align.START;
            mask.halign = Gtk.Align.START;
            broadcast.halign = Gtk.Align.START;
            router.halign = Gtk.Align.START;

            sent = new Gtk.Label (sent_l);
            sent.halign = Gtk.Align.START;

            received = new Gtk.Label (received_l);
            received.halign = Gtk.Align.START;

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            hbox.margin_top = 20;
            hbox.margin_left = hbox.margin_top;
            hbox.margin_right = margin_left;
            hbox.pack_start (new Gtk.LockButton (Utils.get_permission ()), false, false, 0);

            infobox.add (status);
            infobox.add (new Gtk.Label (""));
            infobox.add (ipaddress);
            infobox.add (mask);
            infobox.add (router);
            infobox.add (broadcast);

            activitybox.add (activity);
            activitybox.add (new Gtk.Label (""));
            activitybox.add (sent);
            activitybox.add (received);

            this.add (allbox);
            this.add (get_action_box ());
            this.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

            this.add (hbox);            
            this.add (get_properites_box ());

			update_status ();
            this.show_all ();
        }

        public void update_status () {

        	// Refresh status
            switch (device.get_state ()) {
            	case NM.DeviceState.ACTIVATED:
            		status.label = status_l + "<span color='#22c302'>%s</span>".printf (Utils.state_to_string (device.get_state ()));	
            		break;
            	case NM.DeviceState.DISCONNECTED:
            		status.label = status_l + "<span color='#e51a1a'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		break;
            	default:
            		if (Utils.state_to_string (device.get_state ()) == "Unknown")
            			status.label = status_l + "<span color='#858585'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		else	
            			status.label = status_l + "<span color='#f1d805'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		break;
            }

            // Refresh DHCP4 info
            dhcp4 = device.get_dhcp4_config ();
            ipaddress.label = ipaddress_l + (dhcp4.get_one_option ("ip_address") ?? UNKNOWN);
            mask.label = mask_l + (dhcp4.get_one_option ("subnet_mask") ?? UNKNOWN);
            router.label = router_l + (dhcp4.get_one_option ("routers") ?? UNKNOWN);
            broadcast.label = broadcast_l + (dhcp4.get_one_option ("broadcast_address") ?? UNKNOWN);
            sent.label = sent_l + (get_activity_information (device.get_iface ())[0]) ?? UNKNOWN;
            received.label = received_l + (get_activity_information (device.get_iface ())[1]) ?? UNKNOWN;

            // Refresh button state
            if (device.get_state () != NM.DeviceState.ACTIVATED)
                switch_button_state (true);
            else    
                switch_button_state (false);            

            update_sidebar (owner);

            this.show_all ();
        }

        private Gtk.ButtonBox get_action_box () {
            var action_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            action_box.margin = 30;
            action_box.layout_style = Gtk.ButtonBoxStyle.EXPAND;
            action_box.hexpand = true;

            enable_btn = new Gtk.Button ();
        
            details_btn = new Gtk.Button.with_label ("Advanced...");
            details_btn.clicked.connect (() => {
                try {
                    Process.spawn_command_line_async ("nm-connection-editor --edit=%s".printf (device.get_active_connection ().get_uuid ()));
                } catch (Error e) {
                    error ("%s\n", e.message);
                }
            });

            action_box.add (details_btn);
            action_box.add (enable_btn);

            return action_box;
        }

        private Gtk.Box get_properites_box () {
            setup_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 40);
            setup_box.vexpand = true;
            setup_box.margin_top = 15;
            setup_box.margin_left = 20;
            setup_box.sensitive = Utils.get_permission ().get_allowed ();

            Utils.get_permission ().notify["allowed"].connect (() => {
                if (Utils.get_permission ().get_allowed ())
                    setup_box.sensitive = true;
                else
                    setup_box.sensitive = false;
            });

            var vbox_label = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            vbox_label.margin_top = 5;
            vbox_label.spacing = 15;

            var vbox_entry = new Gtk.Grid ();
            vbox_entry.row_spacing = 5;
            vbox_entry.column_spacing = 20;
            vbox_entry.column_homogeneous = false;
            vbox_entry.hexpand = false;

            var l1 = new Gtk.Label (ipaddress_l);
            l1.halign = Gtk.Align.START;

            var l2 = new Gtk.Label (mask_l);
            l2.halign = Gtk.Align.START;

            var l3 = new Gtk.Label (router_l);
            l3.halign = Gtk.Align.START;

            // "DNS" do not to be translated
            var l4 = new Gtk.Label ("DNS:");
            l4.halign = Gtk.Align.START;

            var ipentry = new Gtk.Entry ();
            var maskentry = new Gtk.Entry ();
            var routerentry = new Gtk.Entry ();
            var dnsentry = new Gtk.Entry ();

            var save_btn = new Gtk.Button.with_label (_("Save"));
            save_btn.get_style_context ().add_class ("suggested-action");

            vbox_label.add (l1);
            vbox_label.add (l2);
            vbox_label.add (l3);
            vbox_label.add (l4);

            vbox_entry.attach (ipentry, 0, 0, 1, 1);
            vbox_entry.attach (maskentry, 0, 1, 1, 1);
            vbox_entry.attach (routerentry, 0, 2, 1, 1);
            vbox_entry.attach (dnsentry, 0, 3, 1, 1);
            vbox_entry.attach (new Gtk.Label (_("(Separate by commas)")), 1, 3, 1, 1);
            vbox_entry.attach (save_btn, 0, 4, 1, 1);

            setup_box.add (vbox_label);
            setup_box.add (vbox_entry);

            save_btn.clicked.connect (() => {
                var setting_ip4_config = new NM.SettingIP4Config ();
                string[] dns_array = dnsentry.get_text ().split (",");
                foreach (var dns in dns_array) {
            	}

                print ("TODO\n");
                // TODO
            });

            return setup_box;
        } 

        public void buttons_available (bool available) {
        	enable_btn.sensitive = available;
        	details_btn.sensitive = available;

        }

        public void switch_button_state (bool show_enable) {
            var style = enable_btn.get_style_context ();
            if (show_enable) {
                style.remove_class ("destructive-action");
                enable_btn.label = _("Enable");
                style.add_class ("suggested-action");
            } else {
                style.remove_class ("suggested-action");
                enable_btn.label = _("Disable");
                style.add_class ("destructive-action");
            }
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
