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
    public class WiFiPage : Page {
        public new NM.DeviceWifi device;
        private InfoBox info_box;
        private Gtk.ListBox wifi_list;
        private List<WiFiEntry> entries;
        private const string[] BLACKLISTED = { "Free Public WiFi" };
        
        private WiFiEntry? current_connecting_entry = null;

        /* When access point added insert is on top */
        private bool insert_on_top = true;

        public WiFiPage (NM.DeviceWifi? wifidevice) {
            this.device = wifidevice;
            this.icon_name = "network-wireless";
            this.title = _("Wi-Fi Network");

            entries = new List<WiFiEntry> ();

            wifi_list = new Gtk.ListBox ();
            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false; 
            wifi_list.row_activated.connect (on_row_activated);
            wifi_list.set_sort_func (sort_func);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);
            scrolled.vexpand = true;
            scrolled.shadow_type = Gtk.ShadowType.OUT;

            info_box = new info_box.from_device (device);
            info_box.margin_end = this.INFO_BOX_MARGIN;
            info_box.info_changed.connect (update);

            var disconnect_btn = new Gtk.Button.with_label (_("Disconnect"));
            disconnect_btn.sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
            disconnect_btn.get_style_context ().add_class ("destructive-action");
            disconnect_btn.clicked.connect (() => {
                device.disconnect (null);
            });

            var advanced_btn = Utils.get_advanced_button_from_device (device);
            advanced_btn.sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
            info_box.info_changed.connect (() => {
                bool sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
                disconnect_btn.sensitive = sensitive;
                advanced_btn.sensitive = sensitive;
            });

            var hidden_btn = new Gtk.Button.with_label (_("Connect to Hidden Network…"));
            hidden_btn.clicked.connect (() => {
                var remote_settings = new NM.RemoteSettings (null);
                var hidden_dialog = NMGtk.new_wifi_dialog_for_hidden (client, remote_settings);
                hidden_dialog.run ();
            });

            var end_btn_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            end_btn_box.homogeneous = true;
            end_btn_box.halign = Gtk.Align.END;
            end_btn_box.pack_end (disconnect_btn, true, true, 0);
            end_btn_box.pack_end (advanced_btn, true, true, 0);

            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            button_box.pack_start (hidden_btn, false, false, 0);
            button_box.pack_end (end_btn_box, false, false, 0);

            device.access_point_added.connect (add_access_point);
            device.access_point_removed.connect (remove_access_point);

            update ();

            this.add_switch_title (_("Wireless:"));
            this.add (scrolled);
            this.add (info_box);
            this.add (button_box);
            this.show_all ();   
        }

        private void update () {
            string sent_bytes, received_bytes;
            this.get_activity_information (device.get_iface (), out sent_bytes, out received_bytes);
            info_box.update_activity (sent_bytes, received_bytes);

            control_switch.active = (client.wireless_get_enabled () && device.get_state () == NM.DeviceState.ACTIVATED);
        }

        private void on_row_activated (Gtk.ListBoxRow row) {
            if (device != null) {  
                /* Do not activate connection if it is already activated */
                if (device.get_active_access_point () != (row as WiFiEntry).ap) {
                    var setting_wireless = new NM.SettingWireless ();
                    if (setting_wireless.add_seen_bssid ((row as WiFiEntry).ap.get_bssid ())) {
                        current_connecting_entry = row as WiFiEntry;
                        if ((row as WiFiEntry).is_secured) {
                            var remote_settings = new NM.RemoteSettings (null);

                            var connection = new NM.Connection ();
                            var s_con = new NM.SettingConnection ();
                            s_con.@set (NM.SettingConnection.UUID, NM.Utils.uuid_generate ());
                            connection.add_setting (s_con);

                            var s_wifi = new NM.SettingWireless ();
                            s_wifi.@set (NM.SettingWireless.SSID, (row as WiFiEntry).ap.get_ssid ());
                            connection.add_setting (s_wifi);

                            var s_wsec = new NM.SettingWirelessSecurity ();
                            s_wsec.@set (NM.SettingWirelessSecurity.KEY_MGMT, "wpa-eap");
                            connection.add_setting (s_wsec);

                            var s_8021x = new NM.Setting8021x ();
                            s_8021x.add_eap_method ("ttls");
                            s_8021x.@set (NM.Setting8021x.PHASE2_AUTH, "mschapv2");
                            connection.add_setting (s_8021x);
                                            
                            var dialog = NMGtk.new_wifi_dialog (client,
                                                                remote_settings,
                                                                connection,
                                                                device,
                                                                (row as WiFiEntry).ap,
                                                                false);
                            dialog.run ();
                        } else {
                            (row as WiFiEntry).set_status_point (false, true);
                            client.add_and_activate_connection (new NM.Connection (),
                                                                device,
                                                                (row as WiFiEntry).ap.get_path (),
                                                                finish_connection_callback);
                        }
                    }
                }

                /* Check if we are successfully connected to the requested point */
                if (device.get_active_access_point () == (row as WiFiEntry).ap) {
                    foreach (var entry in entries)
                        entry.set_status_point (false, false);
                    (row as WiFiEntry).set_status_point (true, false);
                }
            }
        }

        private void finish_connection_callback (NM.Client _client,
                                                NM.ActiveConnection connection,
                                                string new_connection_path,
                                                Error error) {
            bool success = false;
            _client.get_active_connections ().@foreach ((c) => {
                if (c == connection)
                    success = true;
            });

            if (success) {
                current_connecting_entry.set_status_point (true, false);
            } else {
                current_connecting_entry.set_status_point (false, false);
            }

            current_connecting_entry = null;
        }

        public void list_connections () {
            var ap_list = new List<NM.AccessPoint> ();
            var access_points = device.get_access_points ();
            access_points.@foreach ((access_point) => {
                ap_list.append (access_point);
                insert_on_top = false;
                add_access_point (access_point);
                insert_on_top = true;
            });

            scan_for_duplicates.begin ();
            wifi_list.show_all ();
        }
        
        private async void scan_for_duplicates () {
            var entries_dup = entries.copy ();
            entries.@foreach ((entry) => {
                var ssid = entry.ap.get_ssid ();

                entries_dup.@foreach ((entry_dup) => {
                    if (entry_dup.ap.get_ssid () == ssid) {
                        this.remove_access_point (entry_dup.ap);
                    }
                });
            });
        }

        private void add_access_point (Object ap) {
            var row = new WiFiEntry.from_access_point (ap as NM.AccessPoint);
            if (!(row.ssid in BLACKLISTED) && row.ap.get_ssid () != null) {
                if (insert_on_top) {
                    wifi_list.insert (row, 0);
                } else {
                    wifi_list.add (row);
                }

                entries.append (row as WiFiEntry);
            }

            if ((ap as NM.AccessPoint) == device.get_active_access_point ())
                row.set_status_point (true, false);
        }
        
        private void remove_access_point (Object ap_removed) {
            var new_entries = new List<WiFiEntry> ();
            foreach (var entry in entries) {
                if ((entry as WiFiEntry).ap == ap_removed) {
                    entry.destroy ();
                } else {
                    new_entries.append (entry);
                }
            }
            
            entries = new_entries.copy ();
        }

        private int sort_func (Gtk.ListBoxRow r1, Gtk.ListBoxRow r2) {
            if (r1 == null || r2 == null) {
                return 0;
            }

            if (((WiFiEntry) r1).strength > ((WiFiEntry) r2).strength) {
                return -1;
            } else if (((WiFiEntry) r1).strength < ((WiFiEntry) r2).strength) {
                return 1;
            } else {
                return 0;
            }
        }        
    }
}