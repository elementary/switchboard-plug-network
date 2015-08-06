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
    public class WifiInterface : AbstractWifiInterface {
        
        public WifiInterface (NM.Client client, NM.RemoteSettings settings, NM.Device device_) {
            info_box = new InfoBox.from_device (device_);
            info_box.no_show_all = true;
            this.init (device_, info_box);
            
            init_wifi_interface (client, settings, device_);

            this.icon_name = "network-wireless";
            this.title = _("Wi-Fi Network");
            
            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false; 
            
            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);
            scrolled.vexpand = true;
            scrolled.shadow_type = Gtk.ShadowType.OUT;

            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

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
                
                update ();
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

            button_box.pack_start (hidden_btn, false, false, 0);
            button_box.pack_end (end_btn_box, false, false, 0);

            update ();

            bottom_box.add (info_box);
            bottom_box.add (button_box);

            this.add_switch_title (_("Wireless:"));
            this.add (scrolled);
            this.add (bottom_revealer);
            this.show_all ();   
        }

        protected override void update_switch () {
            control_switch.active = !software_locked;
        }

        protected override void control_switch_activated () {
            var active = control_switch.active;
            if (active != !software_locked) {
                rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
                nm_client.wireless_set_enabled (active);
            }
        }

        protected override void wifi_activate_cb (WifiMenuItem row) {
            if (device != null) {  
                /* Do not activate connection if it is already activated */
                if (wifi_device.get_active_access_point () != row.ap) {
                    var connections = nm_settings.list_connections ();
                    var device_connections = wifi_device.filter_connections (connections);
                    var ap_connections = row.ap.filter_connections (device_connections);

                    if (ap_connections.length () > 0) {
                        var valid_connection = get_valid_connection (row.ap, ap_connections);
                        if (valid_connection != null) {
                            nm_client.activate_connection (valid_connection, wifi_device, row.ap.get_path (), null);
                            return;
                        }
                    }

                    var setting_wireless = new NM.SettingWireless ();
                    if (setting_wireless.add_seen_bssid (row.ap.get_bssid ())) {
                        if (row.is_secured) {
                            var remote_settings = new NM.RemoteSettings (null);

                            var connection = new NM.Connection ();
                            var s_con = new NM.SettingConnection ();
                            s_con.@set (NM.SettingConnection.UUID, NM.Utils.uuid_generate ());
                            connection.add_setting (s_con);

                            var s_wifi = new NM.SettingWireless ();
                            s_wifi.@set (NM.SettingWireless.SSID, row.ap.get_ssid ());
                            connection.add_setting (s_wifi);

                            var s_wsec = new NM.SettingWirelessSecurity ();
                            s_wsec.@set (NM.SettingWirelessSecurity.KEY_MGMT, "wpa-psk");
                            connection.add_setting (s_wsec);

                            var dialog = new NMAWifiDialog (client,
                                                            remote_settings,
                                                            connection,
                                                            wifi_device,
                                                            row.ap,
                                                            false);
                            
                            dialog.response.connect ((response) => {
                                if (response != Gtk.ResponseType.OK) {
                                    return;
                                }

                                NM.Device dialog_device;
                                NM.AccessPoint dialog_ap;
                                var dialog_connection = dialog.get_connection (out dialog_device, out dialog_ap);
                                  
                                client.add_and_activate_connection (dialog_connection,
                                                                    dialog_device,
                                                                    dialog_ap.get_path (),
                                                                    finish_connection_callback);
                            }); 

                            dialog.run ();  
                            dialog.destroy ();
                        } else {
                            client.add_and_activate_connection (new NM.Connection (),
                                                                wifi_device,
                                                                row.ap.get_path (),
                                                                finish_connection_callback);
                        }                            
                    }
                }

                /* Do an update at the next iteration of the main loop, so as every
                 * signal is flushed (for instance signals responsible for radio button
                 * checked) */
                Idle.add( () => { update (); return false; });
            }
        }

        private NM.Connection? get_valid_connection (NM.AccessPoint ap, SList<weak NM.Connection> ap_connections) {
            foreach (weak NM.Connection connection in ap_connections) {
                if (ap.connection_valid (connection)) {
                    return connection;
                }
            }
            
            return null;
        }

        private void finish_connection_callback (NM.Client _client,
                                                NM.ActiveConnection connection,
                                                string new_connection_path,
                                                Error error) {
            bool success = false;
            _client.get_active_connections ().@foreach ((c) => {
                if (c == connection) {
                    success = true;
                }
            });
        }
    }
}
