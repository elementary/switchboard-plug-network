/*-
 * Copyright (c) 2015-2019 elementary, Inc. (https://elementary.io)
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

namespace Network {
    public class WifiInterface : Network.Widgets.Page {
        private RFKillManager rfkill;
        public NM.DeviceWifi? wifi_device;
        private NM.AccessPoint? active_ap;

        private Gtk.ListBox wifi_list;

        private WifiMenuItem? active_wifi_item { get; set; }
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
            Object (
                activatable: true,
                device: device
            );
        }

        construct {
            icon_name = "network-wireless";
            content_area.row_spacing = 0;

            placeholder = new Gtk.Stack () {
                visible = true
            };

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

            var main_frame = new Gtk.Frame (null) {
                margin_top = 12,
                vexpand = true
            };
            main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
            main_frame.add (list_stack);

            info_box.margin = 12;

            popover = new Gtk.Popover (info_btn) {
                position = Gtk.PositionType.BOTTOM
            };
            popover.add (info_box);
            popover.hide.connect (() => {
                info_btn.active = false;
            });

            connected_frame = new Gtk.Frame (null);
            connected_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

            top_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
            };
            top_revealer.add (connected_frame);

            hidden_btn = new Gtk.Button.with_label (_("Connect to Hidden Network…"));
            hidden_btn.clicked.connect (connect_to_hidden);

            action_area.add (new Network.Widgets.SettingsButton ());
            action_area.add (hidden_btn);

            wifi_device = (NM.DeviceWifi)device;
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

            var spinner = new Gtk.Spinner () {
                visible = true,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };
            spinner.start ();

            var scanning = new Gtk.Label (_("Scanning for Access Points…")) {
                visible = true,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD_CHAR,
                max_width_chars = 30,
                justify = Gtk.Justification.CENTER
            };
            scanning.get_style_context ().add_class ("h2");

            var scanning_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                visible = true,
                valign = Gtk.Align.CENTER
            };
            scanning_box.add (scanning);
            scanning_box.add (spinner);

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
                aps.foreach (access_point_added_cb);
            }

            content_area.add (top_revealer);
            content_area.add (main_frame);
            content_area.show_all ();

            update ();
        }

        public override void update_name (int count) {
            if (count <= 1) {
                title = _("Wireless");
            } else {
                title = device.get_description ();
            }
        }

        void access_point_added_cb (Object ap_) {
            NM.AccessPoint ap = (NM.AccessPoint)ap_;

            bool found = false;

            if (ap.ssid != null) {
                foreach (var w in wifi_list.get_children ()) {
                    var menu_item = (WifiMenuItem) w;

                    if (ap.ssid.compare (menu_item.ssid) == 0) {
                        found = true;
                        menu_item.add_ap (ap);
                        break;
                    }
                }
            }

            /* Sometimes network manager sends a (fake?) AP without a valid ssid. */
            if (!found && ap.ssid != null) {
                WifiMenuItem item = new WifiMenuItem (ap) {
                    visible = true
                };
                item.user_action.connect (wifi_activate_cb);

                wifi_list.add (item);
                wifi_list.show_all ();

                update ();
            }
        }

        void update_active_ap () {
            debug ("Update active AP");

            active_ap = wifi_device.get_active_access_point ();

            if (active_wifi_item != null) {
                if (active_wifi_item.state == NM.DeviceState.PREPARE) {
                    active_wifi_item.state = NM.DeviceState.DISCONNECTED;
                }
                active_wifi_item = null;
            }

            if (active_ap == null) {
                debug ("No active AP");
            } else {
                debug ("Active ap: %s", NM.Utils.ssid_to_utf8 (active_ap.get_ssid ().get_data ()));

                bool found = false;
                foreach (var w in wifi_list.get_children ()) {
                    var menu_item = (WifiMenuItem) w;

                    if (active_ap.ssid.compare (menu_item.ssid) == 0) {
                        found = true;
                        menu_item.active = true;
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

            foreach (var w in wifi_list.get_children ()) {
                var menu_item = (WifiMenuItem) w;

                assert (menu_item != null);

                if (ap.ssid.compare (menu_item.ssid) == 0) {
                    found_item = menu_item;
                    break;
                }
            }

            if (found_item == null) {
                critical ("Couldn't remove an access point which has not been added.");
            } else {
                if (!found_item.remove_ap (ap)) {
                    found_item.destroy ();
                }
            }

            update ();
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
                hidden_btn.sensitive = (state != NM.DeviceState.UNAVAILABLE);
            }

            var old_active = active_wifi_item;

            if (Utils.get_device_is_hotspot (wifi_device)) {
                state = NM.DeviceState.DISCONNECTED;
                return;
            }

            switch (wifi_device.state) {
            case NM.DeviceState.UNKNOWN:
            case NM.DeviceState.UNMANAGED:
            case NM.DeviceState.FAILED:
                if (active_wifi_item != null) {
                    active_wifi_item.state = state;
                }
                cancel_scan ();
                break;

            case NM.DeviceState.DEACTIVATING:
            case NM.DeviceState.UNAVAILABLE:
                cancel_scan ();
                placeholder.visible_child_name = "wireless-off";
                break;
            default:
                set_scan_placeholder ();
                break;
            }

            state = wifi_device.state;

            debug ("New network state: %s", state.to_string ());

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

            unowned NM.AccessPoint active_access_point = wifi_device.active_access_point;
            top_revealer.set_reveal_child (active_access_point != null && !is_hotspot);

            if (is_hotspot) {
                list_stack.visible_child = hotspot_mode_alert;
            } else {
                list_stack.visible_child = scrolled;
            }

            if (active_access_point == null && old_active != null) {
                old_active.no_show_all = false;
                old_active.visible = true;

                if (connected_frame != null && connected_frame.get_child () != null) {
                    connected_frame.get_child ().destroy ();
                }

                disconnect_btn = settings_btn = null;
            } else if (active_access_point != null && active_wifi_item != old_active) {

                if (old_active != null) {
                    old_active.no_show_all = false;
                    old_active.visible = true;

                    if (connected_frame != null && connected_frame.get_child () != null) {
                        connected_frame.get_child ().destroy ();
                    }
                }

                active_wifi_item.no_show_all = true;
                active_wifi_item.visible = false;

                var top_item = new WifiMenuItem (active_access_point) {
                    state = NM.DeviceState.ACTIVATED
                };

                connected_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                connected_box.add (top_item);

                disconnect_btn = new Gtk.Button.with_label (_("Disconnect")) {
                    sensitive = (device.get_state () == NM.DeviceState.ACTIVATED)
                };
                disconnect_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                disconnect_btn.clicked.connect (() => {
                    try {
                        device.disconnect (null);
                    } catch (Error e) {
                        warning (e.message);
                    }
                });

                settings_btn = new Network.Widgets.SettingsButton.from_device (wifi_device, _("Settings…")) {
                    sensitive = (device.get_state () == NM.DeviceState.ACTIVATED)
                };

                info_btn = new Gtk.ToggleButton () {
                    margin_top = info_btn.margin_bottom = 6,
                    image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.SMALL_TOOLBAR)
                };
                info_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

                popover.relative_to = info_btn;

                info_btn.toggled.connect (() => {
                    popover.visible = info_btn.get_active ();
                });

                var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                    homogeneous = true,
                    margin = 6,
                    valign = Gtk.Align.CENTER
                };
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
            status_switch.active = !software_locked;
        }

        protected override void control_switch_activated () {
            var active = status_switch.active;
            if (active == software_locked) {
                rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
                unowned NetworkManager network_manager = NetworkManager.get_default ();
                network_manager.client.wireless_set_enabled (active);
            }
        }

        private void wifi_activate_cb (WifiMenuItem row) {
            if (device == null) {
                return;
            }

            /* Do not activate connection if it is already activated */
            if (wifi_device.get_active_access_point () == row.ap) {
                return;
            }

            unowned NetworkManager network_manager = NetworkManager.get_default ();
            unowned NM.Client client = network_manager.client;

            // See if we already have a connection configured for this AP and try connecting if so
            var connections = client.get_connections ();
            var device_connections = wifi_device.filter_connections (connections);
            var ap_connections = row.ap.filter_connections (device_connections);

            var valid_connection = get_valid_connection (row.ap, ap_connections);
            if (valid_connection != null) {
                client.activate_connection_async.begin (valid_connection, wifi_device, row.ap.get_path (), null, null);
                return;
            }

            if (row.is_secured) {
                var connection = NM.SimpleConnection.new ();
                var s_con = new NM.SettingConnection () {
                    uuid = NM.Utils.uuid_generate ()
                };
                connection.add_setting (s_con);

                var s_wifi = new NM.SettingWireless ();
                s_wifi.ssid = row.ap.get_ssid ();
                connection.add_setting (s_wifi);

                // If the AP is WPA[2]-Enterprise then we need to set up a minimal 802.1x setting before
                // prompting the user to configure the authentication, otherwise, the dialog works out
                // what sort of credentials to prompt for automatically
                if (NM.@80211ApSecurityFlags.KEY_MGMT_802_1X in row.ap.get_rsn_flags () ||
                    NM.@80211ApSecurityFlags.KEY_MGMT_802_1X in row.ap.get_wpa_flags ()) {

                    var s_wsec = new NM.SettingWirelessSecurity () {
                        key_mgmt = "wpa-eap"
                    };
                    connection.add_setting (s_wsec);

                    var s_8021x = new NM.Setting8021x ();
                    s_8021x.add_eap_method ("ttls");
                    s_8021x.phase2_auth = "mschapv2";
                    connection.add_setting (s_8021x);
                }

                // In theory, we could just activate normal WEP/WPA connections without spawning a WifiDialog
                // and NM would create its own dialog, but Mutter's focus stealing prevention often hides it
                // behind switchboard, so we spawn our own
                var wifi_dialog = new NMA.WifiDialog (client, connection, wifi_device, row.ap, false) {
                    deletable = false,
                    transient_for = (Gtk.Window) get_toplevel (),
                    window_position = Gtk.WindowPosition.CENTER_ON_PARENT
                };
                wifi_dialog.response.connect ((response) => {
                    if (response == Gtk.ResponseType.OK) {
                        connect_to_network.begin (wifi_dialog);
                    }
                });

                wifi_dialog.run ();
                wifi_dialog.destroy ();
            } else {
                client.add_and_activate_connection_async.begin (
                    NM.SimpleConnection.new (),
                    wifi_device,
                    row.ap.get_path (),
                    null,
                    (obj, res) => {
                        try {
                            client.add_and_activate_connection_async.end (res);
                        } catch (Error error) {
                            warning (error.message);
                        }
                    }
                );
            }

            /* Do an update at the next iteration of the main loop, so as every
             * signal is flushed (for instance signals responsible for radio button
             * checked) */
            Idle.add (() => { update (); return false; });
        }

        private NM.Connection? get_valid_connection (NM.AccessPoint ap, GenericArray<NM.Connection> ap_connections) {
            for (int i = 0; i < ap_connections.length; i++) {
                weak NM.Connection connection = ap_connections.get (i);
                if (ap.connection_valid (connection)) {
                    return connection;
                }
            }

            return null;
        }

        private void connect_to_hidden () {
            unowned NetworkManager network_manager = NetworkManager.get_default ();

            var hidden_dialog = new NMA.WifiDialog.for_other (network_manager.client) {
                deletable = false,
                transient_for = (Gtk.Window) get_toplevel (),
                window_position = Gtk.WindowPosition.CENTER_ON_PARENT
            };
            hidden_dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.OK) {
                    connect_to_network.begin (hidden_dialog);
                }
            });

            hidden_dialog.run ();
            hidden_dialog.destroy ();
        }

        private async void connect_to_network (NMA.WifiDialog wifi_dialog) {
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
                try {
                    yield client.activate_connection_async (fuzzy, wifi_device, path, null);
                } catch (Error error) {
                    critical (error.message);
                }
            } else {
                string? mode = null;
                unowned NM.SettingWireless setting_wireless = dialog_connection.get_setting_wireless ();
                if (setting_wireless != null) {
                    mode = setting_wireless.get_mode ();
                }

                if (mode == "adhoc") {
                    NM.SettingConnection connection_setting = dialog_connection.get_setting_connection ();
                    if (connection_setting == null) {
                        connection_setting = new NM.SettingConnection ();
                    }

                    dialog_connection.add_setting (connection_setting);
                }

                try {
                    yield client.add_and_activate_connection_async (dialog_connection, dialog_device, path, null);
                } catch (Error error) {
                    critical (error.message);
                }
            }
        }


        void cancel_scan () {
            if (timeout_scan > 0) {
                Source.remove (timeout_scan);
                timeout_scan = 0;
            }
        }

        void set_scan_placeholder () {
            // this state is the previous state (because this method is called before putting the new state)
            if (state == NM.DeviceState.DISCONNECTED) {
                placeholder.visible_child_name = "scanning";
                cancel_scan ();
                wifi_device.request_scan_async.begin (null, null);
                timeout_scan = Timeout.add (5000, () => {
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

            return ((WifiMenuItem) r2).ap.strength - ((WifiMenuItem) r1).ap.strength;
        }

    }
}
