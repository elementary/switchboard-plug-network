/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2015-2024 elementary, Inc. (https://elementary.io)
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class Network.WifiInterface : Network.Widgets.Page {
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
    protected Gtk.Revealer top_revealer;
    protected Gtk.Button? hidden_btn;

    public WifiInterface (NM.Device device) {
        Object (
            activatable: true,
            device: device
        );
    }

    construct {
        icon = new ThemedIcon ("network-wireless");

        placeholder = new Gtk.Stack () {
            visible = true
        };

        wifi_list = new Gtk.ListBox () {
            activate_on_single_click = false,
            selection_mode = SINGLE,
            visible = true
        };
        wifi_list.set_sort_func (sort_func);
        wifi_list.set_placeholder (placeholder);
        wifi_list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        var hotspot_mode_alert = new Granite.Placeholder (_("This device is in Hotspot Mode")) {
            description = _("Turn off the Hotspot Mode to connect to other Access Points.")
        };

        scrolled = new Gtk.ScrolledWindow () {
            child = wifi_list
        };

        list_stack = new Gtk.Stack ();
        list_stack.add_child (hotspot_mode_alert);
        list_stack.add_child (scrolled);
        list_stack.visible_child = scrolled;

        var main_frame = new Gtk.Frame (null) {
            child = list_stack,
            vexpand = true
        };
        main_frame.add_css_class (Granite.STYLE_CLASS_VIEW);

        connected_frame = new Gtk.Frame (null) {
            margin_bottom = 12, // Prevent extra space when this is hidden
        };

        top_revealer = new Gtk.Revealer () {
            child = connected_frame,
            transition_type = SLIDE_DOWN
        };

        var settings_button = add_button (_("Edit Connections…"));
        settings_button.clicked.connect (edit_connections);

        hidden_btn = add_button (_("Connect to Hidden Network…"));
        hidden_btn.clicked.connect (connect_to_hidden);

        wifi_device = (NM.DeviceWifi)device;
        active_wifi_item = null;

        var no_aps_alert = new Granite.Placeholder (_("No Access Points Available")) {
            description = _("There are no wireless access points within range.")
        };

        var wireless_off_alert = new Granite.Placeholder (_("Wireless Is Disabled")) {
            description = _("Enable wireless to discover nearby wireless access points.")
        };

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
        scanning.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var scanning_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            visible = true,
            valign = Gtk.Align.CENTER
        };
        scanning_box.append (scanning);
        scanning_box.append (spinner);

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

        var content_box = new Gtk.Box (VERTICAL, 0);
        content_box.append (top_revealer);
        content_box.append (main_frame);

        child = content_box;

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
            unowned var child = wifi_list.get_first_child ();
            while (child != null) {
                if (child is WifiMenuItem) {
                    var menu_item = (WifiMenuItem) child;
                    if (ap.ssid.compare (menu_item.ssid) == 0) {
                        found = true;
                        menu_item.add_ap (ap);
                        break;
                    }
                }
                child = child.get_next_sibling ();
            }
        }

        /* Sometimes network manager sends a (fake?) AP without a valid ssid. */
        if (!found && ap.ssid != null) {
            var item = new WifiMenuItem (ap);
            item.user_action.connect (wifi_activate_cb);

            wifi_list.append (item);

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
            unowned var child = wifi_list.get_first_child ();
            while (child != null && !found) {
                if (child is WifiMenuItem) {
                    var menu_item = (WifiMenuItem) child;

                    if (active_ap.ssid.compare (menu_item.ssid) == 0) {
                        found = true;
                        menu_item.active = true;
                        active_wifi_item = menu_item;
                        active_wifi_item.state = state;
                    }
                }

                child = child.get_next_sibling ();
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
        unowned var child = wifi_list.get_first_child ();
         while (child != null && found_item == null) {
             if (child is WifiMenuItem) {
                 var menu_item = (WifiMenuItem) child;

                 if (ap.ssid.compare (menu_item.ssid) == 0) {
                     found_item = menu_item;
                 }
             }

             child = child.get_next_sibling ();
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
            old_active.visible = true;

            if (connected_frame != null && connected_frame.get_child () != null) {
                connected_frame.get_child ().destroy ();
            }
        } else if (active_access_point != null && active_wifi_item != old_active) {

            if (old_active != null) {
                old_active.visible = true;

                if (connected_frame != null && connected_frame.get_child () != null) {
                    connected_frame.get_child ().destroy ();
                }
            }

            active_wifi_item.visible = false;

            var top_item = new WifiMenuItem (active_access_point) {
                state = NM.DeviceState.ACTIVATED
            };



            // Create a single item listbox to match styles with main listbox
            var connected_listbox = new Gtk.ListBox () {
                selection_mode = NONE
            };
            connected_listbox.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
            connected_listbox.append (top_item);
            connected_listbox.get_first_child ().focusable = false;

            connected_frame.child = connected_listbox;

            var settings_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                top_item.ssid_label.label,
                top_item.status_label.label,
                top_item.img_strength.icon_name,
                NONE
            ) {
                modal = true,
                transient_for = ((Gtk.Application) Application.get_default ()).active_window
            };

            settings_dialog.add_button (_("Advanced…"), 0);
            settings_dialog.add_button (_("Close"), Gtk.ResponseType.CLOSE);
            settings_dialog.custom_bin.append (info_box);

            top_item.user_action.connect (wifi_activate_cb);
            top_item.settings_request.connect (settings_dialog.present);

            settings_dialog.response.connect ((response) => {
                if (response == 0) {
                    open_advanced_settings ();
                }

                settings_dialog.hide ();
            });
        }
    }

    protected override void update_status () {
        switch (device.state) {
            case ACTIVATED:
                status_type = SUCCESS;
                break;
            case DISCONNECTED:
                status_type = OFFLINE;
                break;
            case FAILED:
                status_type = ERROR;
                break;
            default:
                status_type = WARNING;
                break;
        }

        switch (device.state) {
            case UNAVAILABLE:
                status = _("Disabled");
                break;
            case ACTIVATED:
                status = NM.Utils.ssid_to_utf8 (
                    ((NM.DeviceWifi) device).active_access_point.get_ssid ().get_data ()
                );
                break;
            default:
                status = Utils.state_to_string (device.state);
                break;
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
            try {
                device.disconnect (null);
            } catch (Error e) {
                warning (e.message);
            }
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

        var connection = NM.SimpleConnection.new ();

        if (row.is_secured) {
            var s_con = new NM.SettingConnection () {
                uuid = NM.Utils.uuid_generate ()
            };
            connection.add_setting (s_con);

            if (NM.@80211ApSecurityFlags.KEY_MGMT_SAE in row.ap.get_rsn_flags () ||
                NM.@80211ApSecurityFlags.KEY_MGMT_SAE in row.ap.get_wpa_flags ()) {
                var s_wsec = new NM.SettingWirelessSecurity ();
                s_wsec.key_mgmt = "sae";
                connection.add_setting (s_wsec);
            }

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
                modal = true,
                transient_for = (Gtk.Window) get_root ()
            };
            wifi_dialog.present ();

            wifi_dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.OK) {
                    connect_to_network.begin (wifi_dialog);
                }
                wifi_dialog.destroy ();
            });
        } else {
            if (NM.@80211ApSecurityFlags.KEY_MGMT_OWE in row.ap.get_rsn_flags () ||
                NM.@80211ApSecurityFlags.KEY_MGMT_OWE in row.ap.get_wpa_flags ()) {
                var s_con = new NM.SettingConnection () {
                    uuid = NM.Utils.uuid_generate ()
                };
                connection.add_setting (s_con);
                var s_wsec = new NM.SettingWirelessSecurity () {
                    key_mgmt = "owe"
                };
                connection.add_setting (s_wsec);
                var s_wifi = new NM.SettingWireless () {
                    ssid = row.ap.get_ssid ()
                };
                connection.add_setting (s_wifi);
            }

            client.add_and_activate_connection_async.begin (
                connection,
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
        unowned var network_manager = NetworkManager.get_default ();

        var hidden_dialog = new NMA.WifiDialog.for_other (network_manager.client) {
            deletable = false,
            modal = true,
            transient_for = (Gtk.Window) get_root ()
        };
        hidden_dialog.present ();

        hidden_dialog.response.connect ((response) => {
            if (response == Gtk.ResponseType.OK) {
                connect_to_network.begin (hidden_dialog);
            }
            hidden_dialog.destroy ();
        });
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
