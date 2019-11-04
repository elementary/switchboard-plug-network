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

    public NM.AccessPoint ap { get { return _tmp_ap; } }
    NM.AccessPoint _tmp_ap;

    private static Gtk.SizeGroup button_sizegroup;

    private Gtk.Button connect_button;
    private Gtk.Image image;
    private Gtk.Image status_image;
    private Gtk.Label ssid_label;
    private Gtk.Label status_label;

    public WifiMenuItem (NM.AccessPoint ap) {
        image = new Gtk.Image ();
        image.margin_start = image.margin_end = 3;
        image.pixel_size = 32;

        status_image = new Gtk.Image ();
        status_image.halign = Gtk.Align.END;
        status_image.valign = Gtk.Align.END;
        status_image.pixel_size = 16;

        var overlay = new Gtk.Overlay ();
        overlay.add (image);
        overlay.add_overlay (status_image);

        ssid_label = new Gtk.Label (null);
        ssid_label.ellipsize = Pango.EllipsizeMode.END;
        ssid_label.hexpand = true;
        ssid_label.xalign = 0;

        status_label = new Gtk.Label (null);
        status_label.use_markup = true;
        status_label.xalign = 0;

        connect_button = new Gtk.Button.with_label (_("Connect"));
        connect_button.valign = Gtk.Align.CENTER;

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (ssid_label, 1, 0);
        grid.attach (status_label, 1, 1);
        grid.attach (connect_button, 3, 0, 1, 2);

        button_sizegroup.add_widget (connect_button);

        _ap = new Gee.LinkedList<NM.AccessPoint> ();

        /* Adding the access point triggers update */
        add_ap (ap);

        add (grid);

        notify["state"].connect (update);
        notify["active"].connect (update);

        connect_button.clicked.connect (() => {
            user_action ();
        });

        update ();
    }

    static construct {
        button_sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
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
        string state_string = "";

        image.icon_name = "network-wireless-signal-" + strength_to_string (strength);
        status_image.icon_name = "";

        var flags = ap.get_wpa_flags ();
        is_secured = false;
        if (NM.@80211ApSecurityFlags.GROUP_WEP40 in flags) {
            is_secured = true;
            state_string = _("40/64-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.GROUP_WEP104 in flags) {
            is_secured = true;
            state_string = _("104/128-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_PSK in flags) {
            is_secured = true;
            state_string = _("WPA encrypted");
        } else if (flags != NM.@80211ApSecurityFlags.NONE || ap.get_rsn_flags () != NM.@80211ApSecurityFlags.NONE) {
            is_secured = true;
            state_string = _("Encrypted");
        } else {
            status_image.icon_name = "security-low";
            state_string = _("Unsecured");
        }

        switch (state) {
            case State.FAILED_WIFI:
                state_string = _("This wireless network could not be connected to.");
                status_image.icon_name = "dialog-error";
                break;
            case State.CONNECTED_WIFI:
                connect_button.label = _("Disconnect");
                connect_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                break;
        }

        status_label.label = "<span font_size='small'>%s</span>".printf (state_string);
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
