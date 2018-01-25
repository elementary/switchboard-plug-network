/*
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Network.VPNMenuItem : Gtk.ListBoxRow {
    public signal void user_action();
    public NM.RemoteConnection? connection;

    public Network.State state { get; set; default = Network.State.DISCONNECTED; }

    Gtk.RadioButton radio_button;
    Gtk.Spinner spinner;
    Gtk.Image error_img;
    Gtk.Button remove_button;

    public VPNMenuItem (NM.RemoteConnection _connection, VPNMenuItem? previous = null) {
        connection = _connection;

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        main_box.margin_start = main_box.margin_end = 6;
        radio_button = new Gtk.RadioButton(null);
        if (previous != null) radio_button.set_group (previous.get_group ());

        radio_button.button_release_event.connect ( (b, ev) => {
            user_action();
            return false;
        });

        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);
        error_img.set_tooltip_text (_("This Virtual Private Network could not be connected to."));

        spinner = new Gtk.Spinner();
        spinner.visible = false;
        spinner.no_show_all = !spinner.visible;

        remove_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        remove_button.get_style_context ().add_class ("flat");
        remove_button.clicked.connect (() => {
            try {
                connection.delete (null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        main_box.pack_start (radio_button, true, true);
        main_box.pack_start (spinner, false, false);
        main_box.pack_start (error_img, false, false);
        main_box.pack_start (remove_button, false, false);

        notify["state"].connect (update);
        radio_button.notify["active"].connect (update);
        this.add (main_box);
        this.get_style_context ().add_class ("menuitem");

        connection.changed.connect (update);
        update ();
    }

    /**
     * Only used for an item which is not displayed: hacky way to have no radio button selected.
     **/
    public VPNMenuItem.blank () {
        radio_button = new Gtk.RadioButton(null);
    }

    unowned SList get_group () {
        return radio_button.get_group();
    }

    public void set_active (bool active) {
        radio_button.set_active (active);
    }

    private void update () {
        radio_button.label = connection.get_id ();

        switch (state) {
        case State.FAILED_VPN:
            show_item(error_img);
            break;
        case State.CONNECTING_VPN:
            show_item(spinner);
            break;
        default:
            hide_icons ();
            break;
        }
    }

    public void hide_icons (bool show_remove_button = true) {
#if PLUG_NETWORK
        hide_item (error_img);
        hide_item (spinner);

        if (!show_remove_button) {
            hide_item (remove_button);
        }
#endif
    }

    void show_item(Gtk.Widget w) {
        w.visible = true;
        w.no_show_all = !w.visible;
    }

    void hide_item(Gtk.Widget w) {
        w.visible = false;
        w.no_show_all = !w.visible;
        w.hide();
    }
}
