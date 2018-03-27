/*-
 * Copyright (c) 2015-2018 elementary LLC.
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

public class Network.WifiMenuItem : Gtk.ListBoxRow {
    private Gee.LinkedList<NM.AccessPoint> _ap;
    public signal void user_action ();
    public GLib.Bytes ssid {
        get {
            return _tmp_ap.get_ssid ();
        }
    }

    public bool is_secured;

    public Network.State state { get; set; default = Network.State.DISCONNECTED; }
    public bool active { get; set; }
    public uint8 strength {
        get {
            uint8 strength = 0;
            foreach (var ap in _ap) {
                strength = uint8.max (strength, ap.get_strength ());
            }
            return strength;
        }
    }

    private bool show_icons = true;

    public NM.AccessPoint ap { get { return _tmp_ap; } }
    NM.AccessPoint _tmp_ap;

    private Gtk.RadioButton radio_button;
    private Gtk.Image img_strength;
    private Gtk.Image lock_img;
    private Gtk.Image error_img;
    private Gtk.Spinner spinner;

    public WifiMenuItem (NM.AccessPoint ap, WifiMenuItem? previous = null) {
        radio_button = new Gtk.RadioButton (null);
        radio_button.hexpand = true;
        if (previous != null) {
            radio_button.set_group (previous.radio_button.get_group ());
        }

        img_strength = new Gtk.Image ();
        img_strength.icon_size = Gtk.IconSize.MENU;

        lock_img = new Gtk.Image.from_icon_name ("channel-insecure-symbolic", Gtk.IconSize.MENU);

        /* TODO: investigate this, it has not been tested yet. */
        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);
        error_img.tooltip_text = _("This wireless network could not be connected to.");

        spinner = new Gtk.Spinner ();
        spinner.start ();
        spinner.visible = false;
        spinner.no_show_all = !spinner.visible;

        var main_grid = new Gtk.Grid ();
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.column_spacing = 6;
        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.add (radio_button);
        main_grid.add (spinner);
        main_grid.add (error_img);
        main_grid.add (lock_img);
        main_grid.add (img_strength);

        _ap = new Gee.LinkedList<NM.AccessPoint> ();

        /* Adding the access point triggers update */
        add_ap (ap);

        get_style_context ().add_class ("menuitem");
        add (main_grid);

        bind_property ("active", radio_button, "active", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL);
        notify["state"].connect (update);
        notify["active"].connect (update);

        radio_button.button_release_event.connect ((b, ev) => {
            user_action ();
            return false;
        });

        update ();
    }

    /**
     * Only used for an item which is not displayed: hacky way to have no radio button selected.
     **/
    public WifiMenuItem.blank () {
        radio_button = new Gtk.RadioButton (null);
    }

    void update_tmp_ap () {
        uint8 strength = 0;
        foreach(var ap in _ap) {
            _tmp_ap = strength > ap.strength ? _tmp_ap : ap;
            strength = uint8.max (strength, ap.strength);
        }
    }

    private void update () {
        radio_button.label = NM.Utils.ssid_to_utf8 (ap.get_ssid ().get_data ());

        if (show_icons) {
            img_strength.icon_name = "network-wireless-signal-" + strength_to_string (strength) + "-symbolic";
            img_strength.show_all ();

            var flags = ap.get_wpa_flags ();
            is_secured = false;
            if (NM.@80211ApSecurityFlags.GROUP_WEP40 in flags) {
                is_secured = true;
                tooltip_text = _("This network uses 40/64-bit WEP encryption");
            } else if (NM.@80211ApSecurityFlags.GROUP_WEP104 in flags) {
                is_secured = true;
                tooltip_text = _("This network uses 104/128-bit WEP encryption");
            } else if (NM.@80211ApSecurityFlags.KEY_MGMT_PSK in flags) {
                is_secured = true;
                tooltip_text = _("This network uses WPA encryption");
            } else if (flags != NM.@80211ApSecurityFlags.NONE || ap.get_rsn_flags () != NM.@80211ApSecurityFlags.NONE) {
                is_secured = true;
                tooltip_text = _("This network uses encryption");
            } else {
                tooltip_text = _("This network is unsecured");
            }

            lock_img.visible = !is_secured;
            lock_img.no_show_all = !lock_img.visible;

            hide_item (error_img);
            hide_item (spinner);
        }

        switch (state) {
            case State.FAILED_WIFI:
                show_item (error_img);
                break;
            case State.CONNECTING_WIFI:
                show_item (spinner);
                if (!radio_button.active) {
                    critical("An access point is being connected but not active.");
                }

                break;
        }
    }

    public void hide_icons () {
        show_icons = false;
        hide_item (error_img);
        hide_item (lock_img);
        hide_item (img_strength);
    }

    private void show_item (Gtk.Widget w) {
        w.visible = true;
        w.no_show_all = !w.visible;
    }

    private void hide_item (Gtk.Widget w) {
        w.visible = false;
        w.no_show_all = !w.visible;
    }

    public void add_ap (NM.AccessPoint ap) {
        _ap.add (ap);
        update_tmp_ap ();
        update ();
    }

    string strength_to_string (uint8 strength) {
        if (strength < 30) {
            return "weak";
        } else if (strength < 55) {
            return "ok";
        } else if (strength < 80) {
            return "good";
        } else {
            return "excellent";
        }
    }

    public bool remove_ap (NM.AccessPoint ap) {
        _ap.remove (ap);
        update_tmp_ap ();
        return !_ap.is_empty;
    }
}

