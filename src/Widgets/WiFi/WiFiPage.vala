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
    public class WiFiPage : Gtk.Box {
        public Gtk.Switch control_switch;
        private Gtk.ListBox wifi_list;
        private NM.DeviceWifi? device;
        private WiFiEntry[] entries = {};
        private const string BLACKLISTED = "Free Public WiFi";
        
        /* When access point added insert in on top */
        private bool insert_on_top = true;

        public WiFiPage (NM.DeviceWifi? wifidevice) {
            device = wifidevice;
            
            this.orientation = Gtk.Orientation.VERTICAL;
            this.margin = 30;
            this.spacing = this.margin;

            wifi_list = new Gtk.ListBox ();
            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false; 
            wifi_list.row_activated.connect (on_row_activated);

            var infobox = new InfoBox.from_device (device);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);
            scrolled.vexpand = true;
            scrolled.shadow_type = Gtk.ShadowType.OUT;

            var wifi_img = new Gtk.Image.from_icon_name ("network-wireless", Gtk.IconSize.DIALOG);
            wifi_img.margin_end = 15;

            var control_label = new Gtk.Label (_("Wi-Fi Network"));
            control_label.get_style_context ().add_class ("h2");

            var wireless_label = new Gtk.Label ("<b>" + _("Wireless:") + "</b>");
            wireless_label.use_markup = true;

            control_switch = new Gtk.Switch ();
            control_switch.active = client.wireless_get_enabled ();

            var control_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            control_box.pack_start (wifi_img, false, false, 0);
            control_box.pack_start (control_label, false, false, 0);
            control_box.pack_end (control_switch, false, false, 0);
            control_box.pack_end (wireless_label, false, false, 0);

            var disconnect_btn = new Gtk.Button.with_label (_("Disconnect"));
            disconnect_btn.get_style_context ().add_class ("destructive-action");

            var forget_btn = new Gtk.Button.with_label (_("Forget"));

            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 7);
            button_box.pack_start (Utils.get_advanced_button_from_device (device), false, false, 0);
            button_box.pack_end (disconnect_btn, false, false, 0);
            button_box.pack_end (forget_btn, false, false, 0);

            device.access_point_added.connect (add_access_point);
            device.access_point_removed.connect (remove_access_point);

            this.add (control_box);
            this.add (scrolled);
            this.add (infobox);
            this.add (button_box);
            this.show_all ();   
        }

        public NM.DeviceWifi? get_wifi_device () {
            return device;
        }

        private void on_row_activated (Gtk.ListBoxRow row) {
            if (device != null) {   
                /* Do not activate connection if it is already activated */
                if (device.get_active_access_point () != (row as WiFiEntry).ap) {
                    var setting_wireless = new NM.SettingWireless ();
                    if (setting_wireless.add_seen_bssid ((row as WiFiEntry).ap.get_bssid ())) {
                        var connection = new NM.Connection ();                    
                        connection.add_setting (setting_wireless);      
                                  
                        if ((row as WiFiEntry).is_secured) {
                            var remote_settings = new NM.RemoteSettings (null);
                            remote_settings.add_connection (connection, null);                    
                            var dialog = NMGtk.new_wifi_dialog (client,
                                                           remote_settings,
                                                           connection,
                                                           device,
                                                           (row as WiFiEntry).ap,
                                                           false);      
                            dialog.show_all ();   
                            dialog.run ();                                                
                        } else {                                                                         
                            client.add_and_activate_connection (connection, device, (row as WiFiEntry).ap.get_path (), null);               
                        }                               
                    }
                }
                
                /* Check if we are successfully connected to the requested point */
                if (device.get_active_access_point () == (row as WiFiEntry).ap) {
                    foreach (var entry in entries)
                        entry.set_point_connected (false);                
                    (row as WiFiEntry).set_point_connected (true);
                }    
            }
        }

        public void list_connections () {
            var access_points = device.get_access_points ();
            access_points.@foreach ((access_point) => {    
                insert_on_top = false;    
                add_access_point (access_point);  
                insert_on_top = true;
            });

            wifi_list.show_all ();          
        }
        
        private void add_access_point (Object ap) {
            var row = new WiFiEntry.from_access_point (ap as NM.AccessPoint);
            if (row.ssid != BLACKLISTED) {
                if (insert_on_top)
                    wifi_list.insert (row, 0);
                else    
                    wifi_list.add (row);
                entries += row as WiFiEntry;
            }    
            
            if ((ap as NM.AccessPoint) == device.get_active_access_point ())
                row.set_point_connected (true);              
        }
        
        private void remove_access_point (Object ap_removed) {
            WiFiEntry[] new_entries = {};
            foreach (var entry in entries) {
                if ((entry as WiFiEntry).ap == ap_removed)
                    entry.destroy ();
                else
                    new_entries += entry;    
            }
            
            entries = new_entries;
        }            
    }  
}
