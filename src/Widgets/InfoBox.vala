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

namespace Network.Widgets {
    public class InfoBox : Gtk.Grid {
        public signal void update_sidebar (DeviceItem item);
        public signal void info_changed ();
        public NM.Device device { get; construct; }
        public DeviceItem? owner { get; construct; }

        private Gtk.Label ip4address;
        private Gtk.Label ip6address;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label dns;
        private Gtk.Label sent;
        private Gtk.Label received;

        private Gtk.Label ip6address_head;

        public InfoBox.from_device (NM.Device device) {
            Object (device: device);
        }

        public InfoBox.from_owner (DeviceItem owner) {
            Object (owner: owner, device: owner.device);
        }

        construct {
            column_spacing = 12;
            row_spacing = 6;

            var sent_head = new Gtk.Image.from_icon_name ("go-up-symbolic");
            sent = new Gtk.Label (null);

            var sent_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
                tooltip_text = (_("Sent"))
            };
            sent_box.append (sent_head);
            sent_box.append (sent);

            var received_head = new Gtk.Image.from_icon_name ("go-down-symbolic");
            received = new Gtk.Label (null);

            var received_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
                tooltip_text = (_("Received"))
            };
            received_box.append (received_head);
            received_box.append (received);

            var send_receive_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
                halign = Gtk.Align.CENTER,
                margin_top = 12
            };
            send_receive_box.append (sent_box);
            send_receive_box.append (received_box);

            var ip4address_head = new Gtk.Label (_("IP Address:")) {
                halign = Gtk.Align.END
            };

            ip4address = new Gtk.Label (null) {
                selectable = true,
                xalign = 0
            };

            ip6address_head = new Gtk.Label (_("IPv6 Address:")) {
                halign = Gtk.Align.END
            };

            ip6address = new Gtk.Label (null) {
                selectable = true,
                xalign = 0
            };

            var mask_head = new Gtk.Label (_("Subnet mask:")) {
                halign = Gtk.Align.END
            };

            mask = new Gtk.Label (null) {
                selectable = true,
                xalign = 0
            };

            var router_head = new Gtk.Label (_("Router:")) {
                halign = Gtk.Align.END
            };

            router = new Gtk.Label (null) {
                selectable = true,
                xalign = 0
            };

            var dns_head = new Gtk.Label (_("DNS:")) {
                halign = Gtk.Align.END
            };

            dns = new Gtk.Label (null) {
                selectable = true,
                xalign = 0
            };

            attach (ip4address_head, 0, 0);
            attach_next_to (ip4address, ip4address_head, Gtk.PositionType.RIGHT);

            attach_next_to (ip6address_head, ip4address_head, Gtk.PositionType.BOTTOM);
            attach_next_to (ip6address, ip6address_head, Gtk.PositionType.RIGHT);

            attach_next_to (mask_head, ip6address_head, Gtk.PositionType.BOTTOM);
            attach_next_to (mask, mask_head, Gtk.PositionType.RIGHT);

            attach_next_to (router_head, mask_head, Gtk.PositionType.BOTTOM);
            attach_next_to (router, router_head, Gtk.PositionType.RIGHT);

            attach_next_to (dns_head, router_head, Gtk.PositionType.BOTTOM);
            attach_next_to (dns, dns_head, Gtk.PositionType.RIGHT);

            attach_next_to (send_receive_box, dns_head, Gtk.PositionType.BOTTOM, 4, 1);

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
            ip6address.visible = ip6address_head.visible = (ip6 != null);
            ip6address.label = "";
            if (ip6 != null) {
                int i = 1;
                var addresses = ip6.get_addresses ();
                addresses.foreach ((addr) => {
                    addr.@ref ();
                    string inet_str = addr.get_address () + "/" + addr.get_prefix ().to_string ();
                    ip6address.visible = ip6address_head.visible = (inet_str.strip () != "");
                    ip6address.label += inet_str;
                    if (i < addresses.length) {
                        ip6address.label += "\n";
                    }

                    i++;
                });
            }


            if (owner != null) {
                update_sidebar (owner);
            }
        }
    }
}
