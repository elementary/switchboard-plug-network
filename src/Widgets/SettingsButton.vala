/*-
 * Copyright (c) 2015-2019 elementary, Inc.
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

public class Network.Widgets.SettingsButton : Gtk.Button {
    public string args { get; construct; default = ""; }

    public SettingsButton () {
        Object (
            label: _("Edit Connections…")
        );
    }

    public SettingsButton.from_device (NM.Device device, string title = _("Advanced Settings…")) {
        unowned string uuid = "";
        var active_connection = device.get_active_connection ();

        if (active_connection != null) {
            uuid = active_connection.get_uuid ();
        } else {
            var available_connections = device.get_available_connections ();
            if (available_connections.length > 0) {
                uuid = available_connections[0].get_uuid ();
            }
        }

        check_sensitive (device);

        device.state_changed.connect_after (() => {
            check_sensitive (device);
        });

        Object (
            args: "--edit=%s".printf (uuid),
            label: title
        );
    }

    construct {
        clicked.connect (() => {
            try {
                var appinfo = AppInfo.create_from_commandline (
                    "nm-connection-editor %s".printf (args), null, AppInfoCreateFlags.NONE
                );

                appinfo.launch (null, null);
            } catch (Error e) {
                warning ("%s", e.message);
            }
        });
    }

    private void check_sensitive (NM.Device device) {
        sensitive = device.get_available_connections ().length > 0;
    }
}
