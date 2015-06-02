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
        public Gtk.Switch control_switch;
        public InfoBox infobox;

        private Gtk.Label sent;
        private Gtk.Label received;

		private string sent_l = (_("Sent:") + SUFFIX);
		private string received_l = (_("Received:") + SUFFIX);

        public DevicePage.from_owner (DeviceItem? _owner) {           
            owner = _owner;
            device = owner.get_item_device ();

            this.orientation = Gtk.Orientation.VERTICAL;
            this.margin = 30;
            this.spacing = this.margin;

            var allbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            infobox = new InfoBox.from_owner (owner);
            infobox.info_changed.connect (() => {
                update_activity ();
                update_switch_state ();
            });

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

            allbox.add (infobox);
            allbox.add (activitybox);

            var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            details_box.pack_start (Utils.get_advanced_button_from_device (device), false, false, 0);

            activitybox.add (new Gtk.Label ("\n"));
            activitybox.add (sent);
            activitybox.add (received);
            
            update_activity ();
            update_switch_state ();

            this.add (control_box);
            this.add (allbox);
            this.pack_end (details_box, false, false, 0);
            this.show_all ();
        }

        private void update_activity () {         
            string sent_bytes, received_bytes;
            get_activity_information (device.get_iface (), out sent_bytes, out received_bytes);
            sent.label = sent_l + sent_bytes ?? UNKNOWN;
            received.label = received_l + received_bytes ?? UNKNOWN;         
        }

        private void update_switch_state () {
            control_switch.active = device.get_state () == NM.DeviceState.ACTIVATED;
        }

        /* Main method to get all information about the interface */
        private void get_activity_information (string iface, out string received_bytes, out string transfered_bytes) {
            received_bytes = UNKNOWN;
            transfered_bytes = UNKNOWN;

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
        }                 
    }  
}
