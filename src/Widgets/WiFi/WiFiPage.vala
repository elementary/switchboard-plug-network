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

using Network.Widgets;

namespace Network {
    public class WifiInterface : WidgetNMInterface {
        public new NM.DeviceWifi device;
        private Gtk.ListBox wifi_list;
        private List<WiFiEntry> entries;
        private Gtk.RadioButton dumb_btn;
        private Gtk.RadioButton previous_btn;
        private const string[] BLACKLISTED = { "Free Public WiFi" };
        
        private WiFiEntry? current_connecting_entry = null;

        /* When access point added insert is on top */
        private bool insert_on_top = true;

        public WifiInterface (NM.Client client, NM.RemoteSettings settings, NM.Device device_) {
            this.device = (NM.DeviceWifi) device_;
            this.icon_name = "network-wireless";
            this.title = _("Wi-Fi Network");
            info_box = new InfoBox.from_device (device);
            this.init (device, info_box);

            entries = new List<WiFiEntry> ();
            dumb_btn = new Gtk.RadioButton (null);
            previous_btn = dumb_btn;

            wifi_list = new Gtk.ListBox ();
            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false; 
            wifi_list.row_activated.connect (on_row_activated);
            wifi_list.set_sort_func (sort_func);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);
            scrolled.vexpand = true;
            scrolled.shadow_type = Gtk.ShadowType.OUT;

            var disconnect_btn = new Gtk.Button.with_label (_("Disconnect"));
            disconnect_btn.sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
            disconnect_btn.get_style_context ().add_class ("destructive-action");
            disconnect_btn.clicked.connect (() => {
                device.disconnect (((_device, _error) => {
                    update_points ();
                }));
            });

            var advanced_btn = Utils.get_advanced_button_from_device (device);
            advanced_btn.sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
            info_box.info_changed.connect (() => {
                bool sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
                disconnect_btn.sensitive = sensitive;
                advanced_btn.sensitive = sensitive;
                update_points ();
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

            device.notify["active-access-point"].connect (update_points);
            device.access_point_added.connect (add_access_point);
            device.access_point_removed.connect (remove_access_point);

            update ();
            update_points ();

            this.add_switch_title (_("Wireless:"));
            this.add (scrolled);
            this.add (info_box);
            this.add (button_box);
            this.show_all ();   
        }

        private void on_row_activated (Gtk.ListBoxRow row) {
            if (device != null) {  
                /* Do not activate connection if it is already activated */
                if (device.get_active_access_point () != ((WiFiEntry) row).ap) {
                    var setting_wireless = new NM.SettingWireless ();
                    if (setting_wireless.add_seen_bssid (((WiFiEntry) row).ap.get_bssid ())) {
                        current_connecting_entry = ((WiFiEntry) row);
                        if (((WiFiEntry) row).is_secured) {
                            var remote_settings = new NM.RemoteSettings (null);

                            var connection = new NM.Connection ();
                            var s_con = new NM.SettingConnection ();
                            s_con.@set (NM.SettingConnection.UUID, NM.Utils.uuid_generate ());
                            connection.add_setting (s_con);

                            var s_wifi = new NM.SettingWireless ();
                            s_wifi.@set (NM.SettingWireless.SSID, ((WiFiEntry) row).ap.get_ssid ());
                            connection.add_setting (s_wifi);

                            var s_wsec = new NM.SettingWirelessSecurity ();
                            s_wsec.@set (NM.SettingWirelessSecurity.KEY_MGMT, "wpa-psk");
                            connection.add_setting (s_wsec);

                            var dialog = new NMAWifiDialog (client,
                                                            remote_settings,
                                                            connection,
                                                            device,
                                                            ((WiFiEntry) row).ap,
                                                            false);
                            
                            dialog.response.connect ((response) => {
                                if (response != Gtk.ResponseType.OK) {
                                    return;
                                }

                                NM.Device dialog_device;
                                NM.AccessPoint dialog_ap;
                                var dialog_connection = dialog.get_connection (out dialog_device, out dialog_ap);

                                if (get_connection_available (dialog_connection, dialog_device)) {
                                    client.activate_connection (dialog_connection,
                                                                dialog_device,
                                                                dialog_ap.get_path (),
                                                                null);                                    
                                } else {
                                    client.add_and_activate_connection (dialog_connection,
                                                                        dialog_device,
                                                                        dialog_ap.get_path (),
                                                                        finish_connection_callback);
                                }
                            }); 

                            dialog.run ();  
                            dialog.destroy ();
                        } else {
                            client.add_and_activate_connection (new NM.Connection (),
                                                                device,
                                                                ((WiFiEntry) row).ap.get_path (),
                                                                finish_connection_callback);
                        }                            
                    }
                }

                update_points ();
            }
        }

        private bool get_connection_available (NM.Connection connection, NM.Device _device) {
            bool retval = false;
            _device.get_available_connections ().@foreach ((_connection) => {
                if (_connection == connection) {
                    retval = true;
                } 
            });

            return retval;
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

            current_connecting_entry.set_active (success);
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

            wifi_list.show_all ();
        }
        
        private void add_access_point (Object ap) {
            var row = new WiFiEntry (((NM.AccessPoint) ap), previous_btn);
            previous_btn = row.radio_btn;

            if (!(row.ssid_str in BLACKLISTED) && row.ap.get_ssid () != null) {
                if (insert_on_top) {
                    wifi_list.insert (row, 0);
                } else {
                    wifi_list.add (row);
                }

                row.radio_btn.button_release_event.connect (() => {
                    this.on_row_activated (row);
                    return false;
                });

                entries.append (row);
            }

            update_points ();
        }
        
        private void remove_access_point (Object ap_removed) {
            entries.@foreach ((entry) => {
                if (((WiFiEntry) entry).ap == ap_removed) {
                    entries.remove (entry);
                    entry.destroy ();
                }
            }); 

            update_points ();         
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

        private void update_points () {
            var active_point = device.get_active_access_point ();
            if (active_point == null) {
                dumb_btn.active = true;
                return;
            }

            bool in_progress = false;
            switch (device.get_state ()) {
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.SECONDARIES:
                    in_progress = true;        
                    break;
                default:
                    break;    
            }

            entries.@foreach ((entry) => {
                entry.set_connection_in_progress (false);
                if (entry.ap == active_point) {
                    entry.set_connection_in_progress (in_progress);
                    entry.set_active (true);
                }
            });   
        }                 
    }
}
