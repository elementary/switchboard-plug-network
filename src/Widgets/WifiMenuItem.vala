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
    public signal void user_action ();

    public bool is_secured { get; private set; }
    public bool active { get; set; }
    public Network.State state { get; set; default = Network.State.DISCONNECTED; }

    private NM.AccessPoint _tmp_ap;
    public NM.AccessPoint ap {
        get {
            return _tmp_ap;
        }
    }

    public GLib.Bytes ssid {
        get {
            return _tmp_ap.get_ssid ();
        }
    }

    private Gee.LinkedList<NM.AccessPoint> _ap;
    private uint8 strength {
        get {
            uint8 strength = 0;
            foreach (var ap in _ap) {
                strength = uint8.max (strength, ap.get_strength ());
            }
            return strength;
        }
    }

    private Gtk.Image img_strength;
    private Gtk.Image lock_img;
    private Gtk.Image error_img;
    private Gtk.Label ssid_label;
    private Gtk.Revealer connect_button_revealer;
    private Gtk.Spinner spinner;

    public WifiMenuItem (NM.AccessPoint ap) {
        img_strength = new Gtk.Image ();
        img_strength.icon_size = Gtk.IconSize.DND;

        ssid_label = new Gtk.Label (null);
        ssid_label.ellipsize = Pango.EllipsizeMode.END;
        ssid_label.xalign = 0;

        lock_img = new Gtk.Image.from_icon_name ("channel-insecure-symbolic", Gtk.IconSize.MENU);

        /* TODO: investigate this, it has not been tested yet. */
        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);
        error_img.tooltip_text = _("This wireless network could not be connected to.");

        spinner = new Gtk.Spinner ();

        var connect_button = new Gtk.Button.with_label (_("Connect"));
        connect_button.halign = Gtk.Align.END;
        connect_button.hexpand = true;
        connect_button.valign = Gtk.Align.CENTER;

        connect_button_revealer = new Gtk.Revealer ();
        connect_button_revealer.reveal_child = true;
        connect_button_revealer.add (connect_button);

        var main_grid = new Gtk.Grid ();
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.column_spacing = 6;
        main_grid.margin = 6;
        main_grid.add (img_strength);
        main_grid.add (ssid_label);
        main_grid.add (lock_img);
        main_grid.add (error_img);
        main_grid.add (spinner);
        main_grid.add (connect_button_revealer);

        _ap = new Gee.LinkedList<NM.AccessPoint> ();

        /* Adding the access point triggers update */
        add_ap (ap);

        add (main_grid);

        notify["state"].connect (update);
        notify["active"].connect (update);

        connect_button.clicked.connect (() => {
            user_action ();
        });

        update ();
    }

    void update_tmp_ap () {
        uint8 strength = 0;
        foreach (var ap in _ap) {
            _tmp_ap = strength > ap.strength ? _tmp_ap : ap;
            strength = uint8.max (strength, ap.strength);
        }
    }

    private void update () {
        ssid_label.label = NM.Utils.ssid_to_utf8 (ap.get_ssid ().get_data ());

        img_strength.icon_name = "network-wireless-signal-" + strength_to_string (strength);
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
        spinner.active = false;

        switch (state) {
            case State.FAILED:
                show_item (error_img);
                break;
            case State.CONNECTING:
                spinner.active = true;
                break;
            case State.CONNECTED:
                connect_button_revealer.reveal_child = false;
                break;
        }
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

    private string strength_to_string (uint8 strength) {
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
