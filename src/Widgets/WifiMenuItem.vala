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
    public signal void settings_request ();

    public bool is_secured { get; private set; }
    public bool active { get; set; }
    public NM.DeviceState state { get; set; default = NM.DeviceState.DISCONNECTED; }

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

    public Gtk.Image img_strength { get; private set; }
    public Gtk.Label ssid_label { get; private set; }
    public Gtk.Label status_label { get; private set; }

    private static Gtk.SizeGroup button_sizegroup;

    private Gtk.Box button_box;
    private Gtk.Button connect_button;
    private Gtk.Image lock_img;
    private Gtk.Image error_img;
    private Gtk.Revealer settings_button_revealer;
    private Gtk.Spinner spinner;

    static construct {
        button_sizegroup = new Gtk.SizeGroup (HORIZONTAL);
    }

    public WifiMenuItem (NM.AccessPoint ap) {
        img_strength = new Gtk.Image () {
            icon_size = LARGE
        };

        ssid_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        status_label = new Gtk.Label (null) {
            use_markup = true,
            xalign = 0
        };

        lock_img = new Gtk.Image.from_icon_name ("channel-insecure-symbolic");

        /* TODO: investigate this, it has not been tested yet. */
        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic");

        spinner = new Gtk.Spinner ();

        var settings_button = new Gtk.Button.with_label (_("Settings…"));

        connect_button = new Gtk.Button ();

        button_sizegroup.add_widget (connect_button);

        settings_button_revealer = new Gtk.Revealer () {
            child = settings_button,
            overflow = VISIBLE
        };

        button_box = new Gtk.Box (HORIZONTAL, 6) {
            hexpand = true,
            halign = END,
            homogeneous = true,
            valign = CENTER
        };
        button_box.append (settings_button_revealer);
        button_box.append (connect_button);

        var grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            column_spacing = 6
        };
        grid.attach (img_strength, 0, 0, 1, 2);
        grid.attach (ssid_label, 1, 0);
        grid.attach (status_label, 1, 1, 2);
        grid.attach (lock_img, 2, 0);
        grid.attach (error_img, 3, 0, 1, 2);
        grid.attach (spinner, 4, 0, 1, 2);
        grid.attach (button_box, 5, 0, 1, 2);

        _ap = new Gee.LinkedList<NM.AccessPoint> ();

        /* Adding the access point triggers update */
        add_ap (ap);

        child = grid;

        notify["state"].connect (update);
        notify["active"].connect (update);

        connect_button.clicked.connect (() => user_action ());
        settings_button.clicked.connect (() => settings_request ());

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
        unowned string state_string;

        img_strength.icon_name = "network-wireless-signal-" + strength_to_string (strength);

        var flags = ap.get_wpa_flags () | ap.get_rsn_flags ();
        is_secured = false;
        if (NM.@80211ApSecurityFlags.GROUP_WEP40 in flags) {
            is_secured = true;
            state_string = _("40/64-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.GROUP_WEP104 in flags) {
            is_secured = true;
            state_string = _("104/128-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_SAE in flags) {
            is_secured = true;
            state_string = _("WPA3 encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_PSK in flags) {
            is_secured = true;
            state_string = _("WPA encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_OWE in flags) {
            is_secured = true;
            state_string = _("Passwordless encrypted");
        } else if (flags != NM.@80211ApSecurityFlags.NONE) {
            is_secured = true;
            state_string = _("Encrypted");
        } else {
            state_string = _("Unsecured");
        }

        lock_img.visible = !is_secured;

        hide_item (error_img);
        spinner.spinning = false;
        button_box.sensitive = true;
        settings_button_revealer.reveal_child = false;
        connect_button.label = _("Connect");

        switch (state) {
            case NM.DeviceState.FAILED:
                show_item (error_img);
                state_string = _("Could not be connected to");
                break;
            case NM.DeviceState.PREPARE:
                spinner.spinning = true;
                button_box.sensitive = false;
                state_string = _("Connecting");
                break;
            case NM.DeviceState.ACTIVATED:
                settings_button_revealer.reveal_child = true;
                connect_button.label = _("Disconnect");
                break;
        }

        status_label.label = GLib.Markup.printf_escaped ("<span font_size='small'>%s</span>", state_string);
    }

    private void show_item (Gtk.Widget w) {
        w.visible = true;
    }

    private void hide_item (Gtk.Widget w) {
        w.visible = false;
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
