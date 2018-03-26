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
    public class WifiInterface : Network.WidgetNMInterface {
        private RFKillManager rfkill;
        public NM.DeviceWifi? wifi_device;
        private NM.AccessPoint? active_ap;

        private Gtk.ListBox wifi_list;

        private WifiMenuItem? active_wifi_item { get; set; }
        private WifiMenuItem? blank_item = null;
        private Gtk.Stack placeholder;

        private bool locked;
        private bool software_locked;
        private bool hardware_locked;

        uint timeout_scan = 0;

        protected Gtk.Frame connected_frame;
        protected Gtk.Stack list_stack;
        protected Gtk.ScrolledWindow scrolled;
        protected Gtk.Box hotspot_mode_alert;
        protected Gtk.Box? connected_box = null;
        protected Gtk.Revealer top_revealer;
        protected Gtk.Button? disconnect_btn;
        protected Gtk.Button? settings_btn;
        protected Gtk.Button? hidden_btn;
        protected Gtk.ToggleButton info_btn;
        protected Gtk.Popover popover;

        public WifiInterface (NM.Device device) {
            Object (device: device);
        }

        construct {
            icon_name = "network-wireless";
            row_spacing = 0;

            placeholder = new Gtk.Stack ();
            placeholder.visible = true;

            control_box.margin_bottom = 12;

            wifi_list = new Gtk.ListBox ();
            wifi_list.set_sort_func (sort_func);
            wifi_list.set_placeholder (placeholder);

            var hotspot_mode_alert = new Granite.Widgets.AlertView (
                _("This device is in Hotspot Mode"),
                _("Turn off the Hotspot Mode to connect to other Access Points."),
                ""
            );
            hotspot_mode_alert.show_all ();

            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false;
            wifi_list.visible = true;

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);

            list_stack = new Gtk.Stack ();
            list_stack.add (hotspot_mode_alert);
            list_stack.add (scrolled);
            list_stack.visible_child = scrolled;

            var main_frame = new Gtk.Frame (null);
            main_frame.margin_bottom = 24;
            main_frame.margin_top = 12;
            main_frame.vexpand = true;
            main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
            main_frame.add (list_stack);

            info_box.margin = 12;

            popover = new Gtk.Popover (info_btn);
            popover.position = Gtk.PositionType.BOTTOM;
            popover.add (info_box);
            popover.hide.connect (() => {
                info_btn.active = false;
            });

            connected_frame = new Gtk.Frame (null);
            connected_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

            top_revealer = new Gtk.Revealer ();
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (connected_frame);

            hidden_btn = new Gtk.Button.with_label (_("Connect to Hidden Network…"));
            hidden_btn.clicked.connect (connect_to_hidden);

            bottom_box.pack_start (hidden_btn, false, false, 0);

            wifi_device = (NM.DeviceWifi)device;
            blank_item = new WifiMenuItem.blank ();
            active_wifi_item = null;

            var no_aps_alert = new Granite.Widgets.AlertView (
                _("No Access Points Available"),
                _("There are no wireless access points within range."),
                ""
            );
            no_aps_alert.show_all ();

            var wireless_off_alert = new Granite.Widgets.AlertView (
                _("Wireless Is Disabled"),
                _("Enable wireless to discover nearby wireless access points."),
                ""
            );
            wireless_off_alert.show_all ();

            var spinner = new Gtk.Spinner ();
            spinner.visible = true;
            spinner.halign = spinner.valign = Gtk.Align.CENTER;
            spinner.start ();

            var scanning = new Gtk.Label (_("Scanning for Access Points…"));
            scanning.visible = true;
            scanning.wrap = true;
            scanning.wrap_mode = Pango.WrapMode.WORD_CHAR;
            scanning.max_width_chars = 30;
            scanning.justify = Gtk.Justification.CENTER;
            scanning.get_style_context ().add_class ("h2");

            var scanning_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            scanning_box.add (scanning);
            scanning_box.add (spinner);
            scanning_box.visible = true;
            scanning_box.valign = Gtk.Align.CENTER;

            placeholder.add_named (no_aps_alert, "no-aps");
            placeholder.add_named (wireless_off_alert, "wireless-off");
            placeholder.add_named (scanning_box, "scanning");
            placeholder.visible_child_name = "no-aps";

            /* Monitor killswitch status */
            rfkill = new RFKillManager ();
            rfkill.open ();
            rfkill.device_added.connect (update);
            rfkill.device_changed.connect (update);
            rfkill.device_deleted.connect (update);

            wifi_device.notify["active-access-point"].connect (update);
            wifi_device.access_point_added.connect (access_point_added_cb);
            wifi_device.access_point_removed.connect (access_point_removed_cb);
            wifi_device.state_changed.connect (update);

            var aps = wifi_device.get_access_points ();
            if (aps != null && aps.length > 0) {
                aps.foreach(access_point_added_cb);
            }

            this.add (top_revealer);
            this.add (main_frame);
            this.add (bottom_revealer);
            this.show_all ();

            update ();
        }

        public override void update_name (int count) {
            if (count <= 1) {
                display_title = _("Wireless");
            } else {
                display_title = device.get_description ();
            }
        }

        void access_point_added_cb (Object ap_) {
            NM.AccessPoint ap = (NM.AccessPoint)ap_;
            WifiMenuItem? previous_wifi_item = blank_item;

            bool found = false;

            foreach(var w in wifi_list.get_children()) {
                var menu_item = (WifiMenuItem) w;

                if(ap.get_ssid () == menu_item.ssid) {
                    found = true;
                    menu_item.add_ap(ap);
                    break;
                }

                previous_wifi_item = menu_item;
            }

            /* Sometimes network manager sends a (fake?) AP without a valid ssid. */
            if(!found && ap.get_ssid() != null) {
                WifiMenuItem item = new WifiMenuItem(ap, previous_wifi_item);

                previous_wifi_item = item;
                item.set_visible(true);
                item.user_action.connect (wifi_activate_cb);

                wifi_list.add (item);
                wifi_list.show_all ();

                update ();
            }
        }

        void update_active_ap () {
            debug("Update active AP");

            active_ap = wifi_device.get_active_access_point ();

            if (active_wifi_item != null) {
                if(active_wifi_item.state == Network.State.CONNECTING_WIFI) {
                    active_wifi_item.state = Network.State.DISCONNECTED;
                }
                active_wifi_item = null;
            }

            if(active_ap == null) {
                debug("No active AP");
                blank_item.set_active (true);
            } else {
                debug("Active ap: %s", NM.Utils.ssid_to_utf8(active_ap.get_ssid().get_data ()));

                bool found = false;
                foreach(var w in wifi_list.get_children()) {
                    var menu_item = (WifiMenuItem) w;

                    if(active_ap.get_ssid () == menu_item.ssid) {
                        found = true;
                        menu_item.set_active (true);
                        active_wifi_item = menu_item;
                        active_wifi_item.state = state;
                    }
                }

                /* This can happen at start, when the access point list is populated. */
                if (!found) {
                    debug ("Active AP not added");
                }
            }
        }

        void access_point_removed_cb (Object ap_) {
            NM.AccessPoint ap = (NM.AccessPoint)ap_;

            WifiMenuItem found_item = null;

            foreach(var w in wifi_list.get_children()) {
                var menu_item = (WifiMenuItem) w;

                assert(menu_item != null);

                if(ap.get_ssid () == menu_item.ssid) {
                    found_item = menu_item;
                    break;
                }
            }

            if(found_item == null) {
                critical("Couldn't remove an access point which has not been added.");
            } else {
                if(!found_item.remove_ap(ap)) {
                    found_item.destroy ();
                }
            }

            update ();
        }

        Network.State strength_to_state (uint8 strength) {
            if(strength < 30)
                return Network.State.CONNECTED_WIFI_WEAK;
            else if(strength < 55)
                return Network.State.CONNECTED_WIFI_OK;
            else if(strength < 80)
                return Network.State.CONNECTED_WIFI_GOOD;
            else
                return Network.State.CONNECTED_WIFI_EXCELLENT;
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

            if (Utils.get_device_is_hotspot (wifi_device)) {
                state = State.DISCONNECTED;
                return;
            }

            switch (wifi_device.state) {
            case NM.DeviceState.UNKNOWN:
            case NM.DeviceState.UNMANAGED:
            case NM.DeviceState.FAILED:
                state = State.FAILED_WIFI;
                if(active_wifi_item != null) {
                    active_wifi_item.state = state;
                }
                cancel_scan ();
                break;

            case NM.DeviceState.DEACTIVATING:
            case NM.DeviceState.UNAVAILABLE:
                cancel_scan ();
                placeholder.visible_child_name = "wireless-off";
                state = State.DISCONNECTED;
                break;
            case NM.DeviceState.DISCONNECTED:
                set_scan_placeholder ();
                state = State.DISCONNECTED;
                break;

            case NM.DeviceState.PREPARE:
            case NM.DeviceState.CONFIG:
            case NM.DeviceState.NEED_AUTH:
            case NM.DeviceState.IP_CONFIG:
            case NM.DeviceState.IP_CHECK:
            case NM.DeviceState.SECONDARIES:
                set_scan_placeholder ();
                state = State.CONNECTING_WIFI;
                break;

            case NM.DeviceState.ACTIVATED:
                set_scan_placeholder ();

                /* That can happen if active_ap has not been added yet, at startup. */
                if (active_ap != null) {
                    state = strength_to_state(active_ap.get_strength());
                } else {
                    state = State.CONNECTED_WIFI_WEAK;
                }
                break;
            }

            debug("New network state: %s", state.to_string ());

            /* Wifi */
            software_locked = false;
            hardware_locked = false;
            foreach (var device in rfkill.get_devices ()) {
                if (device.device_type != RFKillDeviceType.WLAN)
                    continue;

                if (device.software_lock)
                    software_locked = true;
                if (device.hardware_lock)
                    hardware_locked = true;
            }

            locked = hardware_locked || software_locked;

            update_active_ap ();

            base.update ();

            bool is_hotspot = Utils.get_device_is_hotspot (wifi_device);

            top_revealer.set_reveal_child (wifi_device.get_active_access_point () != null && !is_hotspot);

            if (is_hotspot) {
                list_stack.visible_child = hotspot_mode_alert;
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
                unowned NetworkManager network_manager = NetworkManager.get_default ();
                network_manager.client.wireless_set_enabled (active);
            }
        }

        private void wifi_activate_cb (WifiMenuItem row) {
            if (device != null) {
                /* Do not activate connection if it is already activated */
                if (wifi_device.get_active_access_point () != row.ap) {
                    unowned NetworkManager network_manager = NetworkManager.get_default ();
                    unowned NM.Client client = network_manager.client;
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
                            s_con.uuid = NM.Utils.uuid_generate ();
                            connection.add_setting (s_con);

                            var s_wifi = new NM.SettingWireless ();
                            s_wifi.ssid = row.ap.get_ssid ();
                            connection.add_setting (s_wifi);

                            var s_wsec = new NM.SettingWirelessSecurity ();
                            s_wsec.key_mgmt = "wpa-psk";
                            connection.add_setting (s_wsec);

                            var wifi_dialog = new NMA.WifiDialog (client,
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
            unowned NetworkManager network_manager = NetworkManager.get_default ();

            var hidden_dialog = new NMA.WifiDialog.for_other (network_manager.client);
            hidden_dialog.deletable = false;
            hidden_dialog.transient_for = (Gtk.Window) get_toplevel ();
            hidden_dialog.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

            set_wifi_dialog_cb (hidden_dialog);
            hidden_dialog.run ();
            hidden_dialog.destroy ();
        }

        private void set_wifi_dialog_cb (NMA.WifiDialog wifi_dialog) {
            wifi_dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.OK) {
                    NM.Connection? fuzzy = null;
                    NM.Device dialog_device;
                    NM.AccessPoint? dialog_ap = null;
                    var dialog_connection = wifi_dialog.get_connection (out dialog_device, out dialog_ap);

                    unowned NetworkManager network_manager = NetworkManager.get_default ();
                    unowned NM.Client client = network_manager.client;
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


        void cancel_scan () {
            if (timeout_scan > 0) {
                Source.remove (timeout_scan);
                timeout_scan = 0;
            }
        }

        void set_scan_placeholder () {
            // this state is the previous state (because this method is called before putting the new state)
            if (state == State.DISCONNECTED) {
                placeholder.visible_child_name = "scanning";
                cancel_scan ();
                wifi_device.request_scan_async.begin (null, null);
                timeout_scan = Timeout.add(5000, () => {
                    if (Utils.get_device_is_hotspot (wifi_device)) {
                        return false;
                    }

                    timeout_scan = 0;
                    placeholder.visible_child_name = "no-aps";
                    return false;
                });
            }
        }

        private int sort_func (Gtk.ListBoxRow r1, Gtk.ListBoxRow r2) {
            if (r1 == null || r2 == null) {
                return 0;
            }

            var w1 = (WifiMenuItem)r1;
            var w2 = (WifiMenuItem)r2;

            if (w1.ap.get_strength () > w2.ap.get_strength ()) {
                return -1;
            } else if (w1.ap.get_strength () < w2.ap.get_strength ()) {
                return 1;
            } else {
                return 0;
            }
        }

    }
}
