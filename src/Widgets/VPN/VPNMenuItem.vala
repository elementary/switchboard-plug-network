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
    public NM.RemoteConnection? connection { get; construct; }

    public NM.DeviceState state { get; set; default = NM.DeviceState.DISCONNECTED; }

    private static Gtk.SizeGroup size_group;

    private Gtk.Button connect_button;
    private Gtk.Image vpn_state;
    private Gtk.Label state_label;
    private Gtk.Label vpn_label;

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

        vpn_state = new Gtk.Image.from_icon_name ("user-offline", Gtk.IconSize.MENU) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        state_label = new Gtk.Label (null) {
            xalign = 0,
            use_markup = true
        };

        var overlay = new Gtk.Overlay ();
        overlay.add (image);
        overlay.add_overlay (vpn_state);

        vpn_label = new Gtk.Label (connection.get_id ()) {
            ellipsize = Pango.EllipsizeMode.END,
            hexpand = true,
            xalign = 0
        };

        var vpn_info_button = new Gtk.Button () {
            image = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.MENU),
            margin_end = 3,
            valign = Gtk.Align.CENTER
        };
        vpn_info_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        connect_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            label = _("Connect")
        };

        size_group.add_widget (connect_button);

        var grid = new Gtk.Grid () {
            margin = 6,
            column_spacing = 6
        };
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

        connect_button.clicked.connect (() => activate ());

        vpn_info_button.clicked.connect (() => {
            var vpn_info_dialog = new Widgets.VPNInfoDialog (connection) {
                modal = true,
                secondary_text = Utils.state_to_string (state),
                transient_for = (Gtk.Window) get_toplevel ()
            };

            vpn_info_dialog.present ();
            vpn_info_dialog.response.connect (vpn_info_dialog.destroy);
        });
    }

    private void update () {
        vpn_label.label = connection.get_id ();

        switch (state) {
            case NM.DeviceState.FAILED:
                vpn_state.icon_name = "user-busy";
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            case NM.DeviceState.PREPARE:
                vpn_state.icon_name = "user-away";
                connect_button.sensitive = false;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            case NM.DeviceState.ACTIVATED:
                vpn_state.icon_name = "user-available";
                connect_button.label = _("Disconnect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            case NM.DeviceState.DISCONNECTED:
                vpn_state.icon_name = "user-offline";
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
            default:
                connect_button.label = _("Connect");
                connect_button.sensitive = true;
                connect_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
        }

        state_label.label = GLib.Markup.printf_escaped ("<span font_size='small'>%s</span>", Utils.state_to_string (state));
    }

}
