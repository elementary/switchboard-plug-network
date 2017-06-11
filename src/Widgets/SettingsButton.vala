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
        public SettingsButton () {
            label = _("Edit Connections…");
            clicked.connect (() => {
                new Granite.Services.SimpleCommand ("/usr/bin",
                                                    "nm-connection-editor").run ();
            });            
        }

        public SettingsButton.from_device (Device device, string title = _("Advanced Settings…")) {
            label = title;

            var target = device.target;
            clicked.connect (() => {
                string uuid = ""; 
                var active_connection = target.get_active_connection ();
                if (active_connection != null) {
                    uuid = target.get_active_connection ().get_uuid ();
                } else {
                    var available_connections = target.get_available_connections ();
                    if (available_connections.length > 0) {
                        uuid = available_connections[0].get_uuid ();
                    }
                }

                new Granite.Services.SimpleCommand ("/usr/bin",
                                                    "nm-connection-editor --edit=%s".printf (uuid)).run ();                    
            });  
        }

        public SettingsButton.from_connection (NM.Connection connection, string title = _("Advanced Settings…")) {
            label = title;
            clicked.connect (() => {
                new Granite.Services.SimpleCommand ("/usr/bin",
                                                    "nm-connection-editor --edit=%s".printf (connection.get_uuid ())).run ();
            });  
        }
    }
}