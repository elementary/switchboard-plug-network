/*-
 * Copyright (c) 2015-2019 elementary LLC.
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
 */

public class Network.VPNMenuItem : Gtk.ListBoxRow {
    public signal void activate_vpn ();
    public signal void deactivate_vpn ();
    public NM.RemoteConnection? connection { get; construct; }

    public Network.State state { get; set; default = Network.State.DISCONNECTED; }

    private static Gtk.SizeGroup size_group;

    private Gtk.Button connect_button;
    private Gtk.Image vpn_state;
    private Gtk.Label state_label;
    private Gtk.Label vpn_label;
    private Gtk.Button vpn_info_button;

    public VPNMenuItem (NM.RemoteConnection _connection) {
        Object (
            connection: _connection
        );
    }

    static construct {
        size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("network-vpn", Gtk.IconSize.DND);

        vpn_state = new Gtk.Image.from_icon_name ("user-offline", Gtk.IconSize.MENU);
        vpn_state.halign = Gtk.Align.END;
        vpn_state.valign = Gtk.Align.END;

        state_label = new Gtk.Label (null);
        state_label.xalign = 0;
        state_label.use_markup = true;

        var overlay = new Gtk.Overlay ();
        overlay.add (image);
        overlay.add_overlay (vpn_state);

        vpn_label = new Gtk.Label (connection.get_id ());
        vpn_label.ellipsize = Pango.EllipsizeMode.END;
        vpn_label.hexpand = true;
        vpn_label.xalign = 0;

        vpn_info_button = new Gtk.Button ();
        vpn_info_button.always_show_image = true;
        vpn_info_button.image = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.MENU);
        vpn_info_button.label = null;
        vpn_info_button.margin_end = 3;
        vpn_info_button.show_all ();
        vpn_info_button.no_show_all = true;
        vpn_info_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        vpn_info_button.clicked.connect (() => {
            var dialog = new Widgets.VPNInfoDialog (state.to_string (), connection);
            dialog.transient_for = (Gtk.Window) get_toplevel ();
            dialog.run ();
            dialog.destroy ();
        });

        var vpn_info_revealer = new Gtk.Revealer ();
        vpn_info_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        vpn_info_revealer.add (vpn_info_button);
        vpn_info_revealer.set_reveal_child (false);

        connect_button = new Gtk.Button ();
        connect_button.valign = Gtk.Align.CENTER;
        connect_button.label = _("Connect");
        connect_button.clicked.connect (() => {
            if (state == State.CONNECTED_VPN) {
                deactivate_vpn ();
            } else {
                activate_vpn ();
            }
        });
        size_group.add_widget (connect_button);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (vpn_label, 1, 0);
        grid.attach (state_label, 1, 1);
        grid.attach (vpn_info_revealer, 2, 0, 1, 2);
        grid.attach (connect_button, 3, 0, 1, 2);

        notify["state"].connect (update);
        connection.changed.connect (update);
        update ();

        var event_box = new Gtk.EventBox ();
        event_box.add (grid);
        event_box.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        event_box.enter_notify_event.connect (event => {
            debug ("Enter");
            vpn_info_revealer.set_reveal_child (true);
            return false;
        });

        event_box.leave_notify_event.connect (event => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }
            debug ("Exit");

            vpn_info_revealer.set_reveal_child (false);
            return false;
        });

        add (event_box);
        show_all ();
    }

    private void update () {
        vpn_label.label = connection.get_id ();

        switch (state) {
            case State.FAILED_VPN:
                vpn_state.icon_name = "user-busy";
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            case State.CONNECTING_VPN:
                vpn_state.icon_name = "user-away";
                connect_button.sensitive = false;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            case State.CONNECTED_VPN:
                vpn_state.icon_name = "user-available";
                connect_button.label = _("Disconnect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            case State.DISCONNECTED:
                vpn_state.icon_name = "user-offline";
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            default:
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                break;
        }

        state_label.label = GLib.Markup.printf_escaped ("<span font_size='small'>%s</span>", state.to_string ());
    }

}
