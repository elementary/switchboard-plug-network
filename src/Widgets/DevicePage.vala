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

namespace Network {
    public class DevicePage : Gtk.Box {
        public NM.Device device;
        public bool connected;
        public Gtk.Button enable_btn;
        private Gtk.Button details_btn;
        private const string UNKNOWNED = "Unknowned";
        private NM.DHCP4Config dhcp4;

        private Gtk.Label status;
        private Gtk.Label ipaddress;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label broadcast;
        private Gtk.Label sent;
        private Gtk.Label received;

        public DevicePage.from_device (NM.Device _device) {
            device = _device;
            device.state_changed.connect (update_label_status);

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

            status = new Gtk.Label ("");
            status.use_markup = true;  
            status.set_alignment (0, 0);         

            var activity = new Gtk.Label ("Activity:");
            activity.halign = Gtk.Align.START;

            ipaddress = new Gtk.Label ("");
            ipaddress.selectable = true;
            
            mask = new Gtk.Label ("");
            mask.selectable = true;

            /* Is that should be a gateway? */
            router = new Gtk.Label ("");
            router.selectable = true;
            
            broadcast = new Gtk.Label ("");
            broadcast.selectable = true;

            ipaddress.halign = Gtk.Align.START;
            mask.halign = Gtk.Align.START;
            broadcast.halign = Gtk.Align.START;
            router.halign = Gtk.Align.START;

            sent = new Gtk.Label (" ");
            sent.halign = Gtk.Align.START;

            received = new Gtk.Label (" ");
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

            update_label_status ();

            this.add (hbox);            
            this.add (get_properites_box ());

            this.show_all ();
        }

        public void update_label_status () {
            switch (device.get_state ()) {
            	case NM.DeviceState.ACTIVATED:
            		status.label = "Status: <span color='#22c302'>%s</span>".printf (Utils.state_to_string (device.get_state ()));	
            		break;
            	case NM.DeviceState.DISCONNECTED:
            		status.label = "Status: <span color='#e51a1a'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		break;
            	default:
            		if (Utils.state_to_string (device.get_state ()) == "Unknown")
            			status.label = "Status: <span color='#858585'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		else	
            			status.label = "Status: <span color='#857d00'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		break;
            }

            ipaddress.label = "IP Address: %s".printf (dhcp4.get_one_option ("ip_address") ?? UNKNOWNED);
            mask.label = "Subnet mask: %s".printf (dhcp4.get_one_option ("subnet_mask") ?? UNKNOWNED);
            router.label = "Router: %s".printf (dhcp4.get_one_option ("routers") ?? UNKNOWNED);
            broadcast.label = "Broadcast: %s".printf (dhcp4.get_one_option ("broadcast_address") ?? UNKNOWNED);
            sent.label = "Sent: %s".printf (get_activity_information (device.get_iface ())[0]) ?? UNKNOWNED;
            received.label = "Received: %s".printf (get_activity_information (device.get_iface ())[1]) ?? UNKNOWNED;
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

            if (device.get_state () != NM.DeviceState.ACTIVATED)
                switch_button_state (true);
            else    
                switch_button_state (false);

            action_box.add (details_btn);
            action_box.add (enable_btn);

            return action_box;
        }

        private Gtk.Box get_properites_box () {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.expand = true;
            box.margin_left = 20;
            box.spacing = 5;

            Utils.get_permission ().notify["allowed"].connect (() => {
                if (Utils.get_permission ().allowed)
                    box.sensitive = true;
                else
                    box.sensitive = false;
            });

            /*** Kill those silly hardcoded strings ***/
            var ipbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            ipbox.margin_top = 15;
            ipbox.add (new Gtk.Label ("IP Address:    "));
            var ipentry = new Gtk.Entry ();
            ipbox.add (ipentry);
            box.add (ipbox);

            var maskbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            maskbox.add (new Gtk.Label ("Subent mask:"));      
            var maskentry = new Gtk.Entry ();
            maskbox.add (maskentry);
            box.add (maskbox);            

            var routbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            routbox.add (new Gtk.Label ("Router:           "));      
            var routentry = new Gtk.Entry ();
            routbox.add (routentry);
            box.add (routbox);            

            var dnsbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            dnsbox.add (new Gtk.Label ("DNS:               "));      
            var dnsentry = new Gtk.Entry ();
            dnsbox.add (dnsentry);
            dnsbox.add (new Gtk.Label ("(Separate by commas)"));
            box.add (dnsbox); 

            var save_btn = new Gtk.Button.with_label ("      Save      ");
            save_btn.get_style_context ().add_class ("suggested-action");
            var savebox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            savebox.pack_start (save_btn, false, false, 167);  
            box.add (savebox);

            box.sensitive = false;
            
            save_btn.clicked.connect (() => {
                var setting_ip4_config = new NM.SettingIP4Config ();
                string[] dns_array = dnsentry.get_text ().split (",");
                foreach (var dns in dns_array) {
            	}

                print ("TODO\n");
                // TODO
            });

            return box;
        } 

        public void buttons_available (bool available) {
        	enable_btn.sensitive = available;
        	details_btn.sensitive = available;

        }

        public void switch_button_state (bool show_enable) {
            var style = enable_btn.get_style_context ();
            if (show_enable) {
                style.remove_class ("destructive-action");
                enable_btn.label = "Enable";
                style.add_class ("suggested-action");
            } else {
                style.remove_class ("suggested-action");
                enable_btn.label = "Disable";
                style.add_class ("destructive-action");
            }
        }

        /*** Main method to get all information about the interface ***/
        private string[] get_activity_information (string iface) {
            string received_bytes = UNKNOWNED, transfered_bytes = UNKNOWNED;

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
