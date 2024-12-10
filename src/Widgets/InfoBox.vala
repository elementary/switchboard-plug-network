/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2015-2024 elementary, Inc. (https://elementary.io)
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class Network.Widgets.InfoBox : Gtk.Box {
    public signal void update_sidebar (DeviceItem item);
    public signal void info_changed ();
    public NM.Device device { get; construct; }
    public DeviceItem? owner { get; construct; }

    private Gtk.Box ip6address_box;
    private Gtk.Label ip4address;
    private Gtk.Label mask;
    private Gtk.Label router;
    private Gtk.Label dns;
    private Gtk.Label sent;
    private Gtk.Label received;
    private Gtk.Switch reduce_data_switch;
    private Granite.HeaderLabel ip6address_head;
    private NM.RemoteConnection connection;

    public InfoBox.from_device (NM.Device device) {
        Object (device: device);
    }

    construct {
        var sent_image = new Gtk.Image.from_icon_name ("go-up-symbolic") {
            tooltip_text = _("Sent")
        };

        sent = new Gtk.Label (null);

        var received_image = new Gtk.Image.from_icon_name ("go-down-symbolic") {
            tooltip_text = _("Received")
        };

        received = new Gtk.Label (null);

        var send_receive_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = CENTER,
            margin_top = 12
        };
        send_receive_box.append (sent_image);
        send_receive_box.append (sent);
        send_receive_box.append (received_image);
        send_receive_box.append (received);

        var ip4address_head = new Granite.HeaderLabel (_("IP Address"));

        ip4address = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        ip6address_head = new Granite.HeaderLabel (_("IPv6 Addresses"));

        ip6address_box = new Gtk.Box (VERTICAL, 6);

        var mask_head = new Granite.HeaderLabel (_("Subnet Mask"));

        mask = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        var router_head = new Granite.HeaderLabel (_("Router"));

        router = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        var dns_head = new Granite.HeaderLabel (_("DNS"));

        dns = new Gtk.Label (null) {
            selectable = true,
            xalign = 0
        };

        reduce_data_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var reduce_data_header = new Granite.HeaderLabel (_("Reduce background data usage")) {
            hexpand = true,
            mnemonic_widget = reduce_data_switch,
            secondary_text = _("While connected to this network, background tasks like automatic updates will be paused.")
        };

        var reduce_data_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 24
        };
        reduce_data_box.append (reduce_data_header);
        reduce_data_box.append (reduce_data_switch);

        orientation = VERTICAL;
        append (ip4address_head);
        append (ip4address);
        append (ip6address_head);
        append (ip6address_box);
        append (mask_head);
        append (mask);
        append (router_head);
        append (router);
        append (dns_head);
        append (dns);
        append (send_receive_box);
        append (reduce_data_box);

        connection = device.get_active_connection ().connection;
        connection.changed.connect (update_settings);

        device.state_changed.connect (() => {
            update_status ();
            info_changed ();
        });

        update_settings ();
        update_status ();

        reduce_data_switch.notify["active"].connect (() => {
            var setting_connection = connection.get_setting_connection ();
            var metered = setting_connection.metered;

            if (reduce_data_switch.active && metered != YES && metered != GUESS_YES) {
                metered = YES;
            } else if (!reduce_data_switch.active && metered != NO && metered != GUESS_NO) {
                metered = NO;
            }

            setting_connection.set_property (NM.SettingConnection.METERED, metered);

            try {
                connection.commit_changes_async.begin (true, null);
            } catch (Error e) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Failed To Configure Settings"),
                    _("Unable to save changes to the disk"),
                    "network-error",
                    Gtk.ButtonsType.CLOSE
                ) {
                    modal = true,
                    transient_for = (Gtk.Window) get_root ()
                };
                message_dialog.show_error_details (e.message);
                message_dialog.response.connect (message_dialog.destroy);
                message_dialog.present ();
            }
        });
    }

    public void update_activity (string sent_bytes, string received_bytes) {
        sent.label = sent_bytes ?? UNKNOWN_STR;
        received.label = received_bytes ?? UNKNOWN_STR;
    }

    public void update_status () {
        var ipv4 = device.get_ip4_config ();
        if (ipv4 != null) {
            if (ipv4.get_addresses ().length > 0) {
                unowned NM.IPAddress address = ipv4.get_addresses ().get (0);
                ip4address.label = address.get_address ();
                uint32 mask_addr = Posix.htonl ((uint32)0xffffffff << (32 - address.get_prefix ()));
                var source_addr = Posix.InAddr () { s_addr = mask_addr };
                mask.label = (Posix.inet_ntoa (source_addr) ?? UNKNOWN_STR);
            }

            router.label = (ipv4.get_gateway () ?? UNKNOWN_STR);

            dns.label = "";
            if (ipv4.get_nameservers ().length > 0) {
                string [] dns_addr = ipv4.get_nameservers ();
                dns.label = dns_addr[0];
                for (int i=1; i < dns_addr.length; i++) {
                    dns.label = dns.label + ", " + dns_addr[i];
                }
            }
        } else {
            ip4address.label = UNKNOWN_STR;
            mask.label = UNKNOWN_STR;
            router.label = UNKNOWN_STR;
            dns.label = UNKNOWN_STR;
        }

        var ip6 = device.get_ip6_config ();
        ip6address_box.visible = ip6address_head.visible = (ip6 != null);
        if (ip6 != null) {
            while (ip6address_box.get_first_child () != null) {
                ip6address_box.remove (ip6address_box.get_first_child ());
            }

            foreach (unowned var address in ip6.get_addresses ()) {
                var inet_str = address.get_address () + "/" + address.get_prefix ().to_string ();

                var address_label = new Gtk.Label (inet_str) {
                    selectable = true,
                    xalign = 0
                };

                ip6address_box.append (address_label);
            }
        }

        if (owner != null) {
            update_sidebar (owner);
        }
    }

    private void update_settings () {
        var setting_connection = connection.get_setting_connection ();

        reduce_data_switch.active = setting_connection.metered == YES || setting_connection.metered == GUESS_YES;
    }
}
