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
    private Granite.HeaderLabel ip6address_head;

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

        device.state_changed.connect (() => {
            update_status ();
            info_changed ();
        });

        update_status ();
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
}
