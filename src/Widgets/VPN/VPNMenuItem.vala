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
    public signal void connect_clicked ();
    public signal void disconnect_clicked ();
    public NM.RemoteConnection? connection { get; construct; }

    public Network.State state { get; set; default = Network.State.DISCONNECTED; }

    private static Gtk.SizeGroup size_group;

    private Gtk.Button connect_button;
    private Gtk.Image vpn_state;
    private Gtk.Label state_label;
    private Gtk.Label vpn_label;
    private Gtk.MenuButton vpn_info_button;
    private Widgets.VPNInfoDialog vpn_info_popover;

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

        vpn_info_popover = new Widgets.VPNInfoDialog (connection);

        vpn_info_button = new Gtk.MenuButton ();
        vpn_info_button.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        vpn_info_button.margin_end = 3;
        vpn_info_button.popover = vpn_info_popover;
        vpn_info_button.valign = Gtk.Align.CENTER;
        vpn_info_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        connect_button = new Gtk.Button ();
        connect_button.valign = Gtk.Align.CENTER;
        connect_button.label = _("Connect");

        size_group.add_widget (connect_button);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (vpn_label, 1, 0);
        grid.attach (state_label, 1, 1);
        grid.attach (vpn_info_button, 2, 0, 1, 2);
        grid.attach (connect_button, 3, 0, 1, 2);

        add (grid);
        show_all ();

        notify["state"].connect (update);
        connection.changed.connect (update);
        update ();

        connect_button.clicked.connect (() => {
            if (state == State.CONNECTED_VPN) {
                disconnect_clicked ();
            } else {
                connect_clicked ();
            }
        });
    }

    private void update () {
        string state_label_text;
        vpn_label.label = connection.get_id ();

        switch (state) {
            case State.FAILED_VPN:
                state_label_text = _("Failed");
                vpn_state.icon_name = "user-busy";
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                break;
            case State.CONNECTING_VPN:
                state_label_text = _("Connecting");
                vpn_state.icon_name = "user-away";
                connect_button.sensitive = false;
                break;
            case State.CONNECTED_VPN:
                state_label_text = _("Connected");
                vpn_state.icon_name = "user-available";
                connect_button.label = _("Disconnect");
                connect_button.sensitive = true;
                break;
            case State.DISCONNECTED:
                state_label_text = _("Disconnected");
                vpn_state.icon_name = "user-offline";
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                break;
            default:
                state_label_text = _("Unknown");
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                break;
        }

        state_label.label = GLib.Markup.printf_escaped ("<span font_size='small'>%s</span>", state_label_text);
        vpn_info_popover.state_label = state_label_text;
    }

}
