/*-
 * Copyright (c) 2015-2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

using Network.Widgets;

namespace Network {
    public class WifiInterface : AbstractWifiInterface {
        protected Gtk.Frame connected_frame;
        protected Gtk.Stack list_stack;
        protected Gtk.ScrolledWindow scrolled;
        protected Gtk.Box hotspot_mode_box;
        protected Gtk.Box? connected_box = null;
        protected Gtk.Revealer top_revealer;
        protected Gtk.Button? disconnect_btn;
        protected Gtk.Button? settings_btn;
        protected Gtk.Button? hidden_btn;
        protected Gtk.ToggleButton info_btn;
        protected Gtk.Popover popover;

        public WifiInterface (NM.Client nm_client, NM.Device device) {
            list_stack = new Gtk.Stack ();

            hotspot_mode_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            hotspot_mode_box.visible = true;
            hotspot_mode_box.valign = Gtk.Align.CENTER;

            var main_frame = new Gtk.Frame (null);
            main_frame.margin_bottom = 24;
            main_frame.margin_top = 12;
            main_frame.vexpand = true;          
            main_frame.override_background_color (0, { 255, 255, 255, 255 });

            var hotspot_mode = construct_placeholder_label (_("This device is in Hotspot Mode"), true);
            var hotspot_mode_desc = construct_placeholder_label (_("Turn off the Hotspot Mode to connect to other Access Points."), false);
            hotspot_mode_box.add (hotspot_mode);
            hotspot_mode_box.add (hotspot_mode_desc);

            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false;
            wifi_list.visible = true;

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);

            list_stack.add (hotspot_mode_box);
            list_stack.add (scrolled);
            list_stack.visible_child = scrolled;

            this.init (device);

            info_box.margin = 12;

            popover = new Gtk.Popover (info_btn);
            popover.position = Gtk.PositionType.BOTTOM;
            popover.add (info_box);
            popover.hide.connect (() => {
                info_btn.active = false;
            });

            connected_frame = new Gtk.Frame (null);
            connected_frame.override_background_color (0, { 255, 255, 255, 255 });

            top_revealer = new Gtk.Revealer ();
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (connected_frame);

            init_wifi_interface (nm_client, device);

            this.icon_name = "network-wireless";
            row_spacing = 0;

            control_box.margin_bottom = 12;

            main_frame.add (list_stack);

            hidden_btn = new Gtk.Button.with_label (_("Connect to Hidden Network…"));
            hidden_btn.clicked.connect (connect_to_hidden);

            bottom_box.pack_start (hidden_btn, false, false, 0);

            this.add (top_revealer);
            this.add (main_frame);
            this.add (bottom_revealer);
            this.show_all ();   

            update ();
        }

        public NM.Client get_nm_client () {
            return client;
        }

        public override void update () {
            bool sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
            if (disconnect_btn != null) {
                disconnect_btn.sensitive = sensitive;
            }

            if (settings_btn != null) {
                settings_btn.sensitive = sensitive;
            }

            if (info_btn != null) {
                info_btn.sensitive = sensitive;
            }

            if (hidden_btn != null) {
                hidden_btn.sensitive = (state != State.WIRED_UNPLUGGED);
            }

            var old_active = active_wifi_item;

            base.update ();

            bool is_hotspot = Utils.Hotspot.get_device_is_hotspot (wifi_device, client);

            top_revealer.set_reveal_child (wifi_device.get_active_access_point () != null && !is_hotspot);

            if (is_hotspot) {
                list_stack.visible_child = hotspot_mode_box;
            } else {
                list_stack.visible_child = scrolled;
            }

            if (wifi_device.get_active_access_point () == null && old_active != null) { 
                old_active.no_show_all = false;
                old_active.visible = true;

                if (connected_frame != null && connected_frame.get_child () != null) {
                    connected_frame.get_child ().destroy ();
                }

                disconnect_btn = settings_btn = null;
            } else if (wifi_device.get_active_access_point () != null && active_wifi_item != old_active) { 

                if (old_active != null) {
                    old_active.no_show_all = false;
                    old_active.visible = true;

                    if (connected_frame != null && connected_frame.get_child () != null) {
                        connected_frame.get_child ().destroy ();
                    }
                }

                connected_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                active_wifi_item.no_show_all = true;
                active_wifi_item.visible = false;

                var top_item = new WifiMenuItem (wifi_device.get_active_access_point (), null);
                top_item.hide_icons ();
                connected_box.add (top_item);

                disconnect_btn = new Gtk.Button.with_label (_("Disconnect"));
                disconnect_btn.sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);
                disconnect_btn.get_style_context ().add_class ("destructive-action");
                disconnect_btn.clicked.connect (() => {
                    try {
                        device.disconnect (null);
                    } catch (Error e) {
                        warning (e.message);
                    }
                });

                settings_btn = new SettingsButton.from_device (wifi_device, _("Settings…"));
                settings_btn.sensitive = (device.get_state () == NM.DeviceState.ACTIVATED);

                info_btn = new Gtk.ToggleButton ();
                info_btn.margin_top = info_btn.margin_bottom = 6;
                info_btn.get_style_context ().add_class ("flat");
                info_btn.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

                popover.relative_to = info_btn;

                info_btn.toggled.connect (() => {
                    popover.visible = info_btn.get_active ();
                });

                var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                button_box.homogeneous = true;
                button_box.margin = 6;
                button_box.pack_end (disconnect_btn, false, false, 0);
                button_box.pack_end (settings_btn, false, false, 0);
                button_box.show_all ();

                connected_box.pack_end (button_box, false, false, 0);
                connected_box.pack_end (info_btn, false, false, 0);
                connected_frame.add (connected_box);

                connected_box.show_all ();
                connected_frame.show_all ();
            }
        }

        protected override void update_switch () {
            control_switch.active = !software_locked;
        }

        protected override void control_switch_activated () {
            var active = control_switch.active;
            if (active == software_locked) {
                rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
                client.wireless_set_enabled (active);
            }
        }

        protected override void wifi_activate_cb (WifiMenuItem row) {
            if (device != null) {  
                /* Do not activate connection if it is already activated */
                if (wifi_device.get_active_access_point () != row.ap) {
                    var connections = client.get_connections ();
                    var device_connections = wifi_device.filter_connections (connections);
                    var ap_connections = row.ap.filter_connections (device_connections);

                    var valid_connection = get_valid_connection (row.ap, ap_connections);
                    if (valid_connection != null) {
                        client.activate_connection_async.begin (valid_connection, wifi_device, row.ap.get_path (), null, null);
                        return;
                    }

                    var setting_wireless = new NM.SettingWireless ();
                    if (setting_wireless.add_seen_bssid (row.ap.get_bssid ())) {
                        if (row.is_secured) {
                            var connection = NM.SimpleConnection.new ();
                            var s_con = new NM.SettingConnection ();
                            s_con.@set (NM.SettingConnection.UUID, NM.Utils.uuid_generate ());
                            connection.add_setting (s_con);

                            var s_wifi = new NM.SettingWireless ();
                            s_wifi.@set (NM.SettingWireless.SSID, row.ap.get_ssid ());
                            connection.add_setting (s_wifi);

                            var s_wsec = new NM.SettingWirelessSecurity ();
                            s_wsec.@set (NM.SettingWireless.SECURITY_KEY_MGMT, "wpa-psk");
                            connection.add_setting (s_wsec);

                            var wifi_dialog = new NMAWifiDialog (client,
                                                            connection,
                                                            wifi_device,
                                                            row.ap,
                                                            false);

                            set_wifi_dialog_cb (wifi_dialog);
                            wifi_dialog.run ();
                            wifi_dialog.destroy ();
                        } else {
                            client.add_and_activate_connection_async.begin (NM.SimpleConnection.new (),
                                                                            wifi_device,
                                                                            row.ap.get_path (),
                                                                            null,
                                                                            (obj, res) => {
                                                                                try {
                                                                                    client.add_and_activate_connection_async.end (res);
                                                                                } catch (Error error) {
                                                                                    warning (error.message);
                                                                                }
                                                                            });
                        }
                    }
                }

                /* Do an update at the next iteration of the main loop, so as every
                 * signal is flushed (for instance signals responsible for radio button
                 * checked) */
                Idle.add(() => { update (); return false; });
            }
        }

        private NM.Connection? get_valid_connection (NM.AccessPoint ap, GenericArray<weak NM.Connection> ap_connections) {
            weak NM.Connection ret = null;

            ap_connections.foreach ((connection) => {
                if (ret == null && ap.connection_valid (connection)) {
                    ret = connection;
                }
            });

            return ret;
        }

        private void connect_to_hidden () {
            var hidden_dialog = new NMAWifiDialog.for_other (client);
            set_wifi_dialog_cb (hidden_dialog);
            hidden_dialog.run ();
            hidden_dialog.destroy ();
        }

        private void set_wifi_dialog_cb (NMAWifiDialog wifi_dialog) {
            wifi_dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.OK) {
                    NM.Connection? fuzzy = null;
                    NM.Device dialog_device;
                    NM.AccessPoint? dialog_ap = null;
                    var dialog_connection = wifi_dialog.get_connection (out dialog_device, out dialog_ap);

                    client.get_connections ().foreach ((possible) => {
                        if (dialog_connection.compare (possible, NM.SettingCompareFlags.FUZZY | NM.SettingCompareFlags.IGNORE_ID)) {
                            fuzzy = possible;
                        }
                    });

                    string? path = null;
                    if (dialog_ap != null) {
                        path = dialog_ap.get_path ();
                    }

                    if (fuzzy != null) {
                        client.activate_connection_async.begin (fuzzy, wifi_device, path, null, null);
                    } else {
                        var connection_setting = dialog_connection.get_setting (typeof (NM.Setting));;

                        string? mode = null;
                        var setting_wireless = (NM.SettingWireless) dialog_connection.get_setting (typeof (NM.SettingWireless));
                        if (setting_wireless != null) {
                            mode = setting_wireless.get_mode ();
                        }

                        if (mode == "adhoc") {
                            if (connection_setting == null) {
                                connection_setting = new NM.SettingConnection ();
                            }

                            dialog_connection.add_setting (connection_setting);
                        }

                        client.add_and_activate_connection_async.begin (dialog_connection,
                                                                        dialog_device,
                                                                        path,
                                                                        null,
                                                                        (obj, res) => {
                                                                            try {
                                                                                client.add_and_activate_connection_async.end (res);
                                                                            } catch (Error error) {
                                                                                warning (error.message);
                                                                            }
                                                                        });
                    }
                }
            });
        }
    }
}
