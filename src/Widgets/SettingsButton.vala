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
    public class SettingsButton : Gtk.Button {
        private string? uuid = null;

        construct {
            clicked.connect (() => {
                if (uuid != null) {
                    new Granite.Services.SimpleCommand ("/usr/bin",
                                                        "nm-connection-editor --edit=%s".printf (uuid)).run ();
                } else {
                    new Granite.Services.SimpleCommand ("/usr/bin",
                                                        "nm-connection-editor").run ();
                }
            });  
        }

        public SettingsButton () {
            label = _("Edit Connections…");
        }

        public SettingsButton.from_device (NM.Device device, string title = _("Advanced Settings…")) {
            label = title;
            uuid = device.get_active_connection ().get_uuid ();
        }

        public SettingsButton.from_connection (NM.Connection connection, string title = _("Advanced Settings…")) {
            label = title;
            uuid = connection.get_uuid ();
        }
    }
}