/*-
 * Copyright 2019 elementary, Inc. (https://elementary.io)
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
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

[DBus (name = "com.ubuntu.SystemService")]
public interface UbuntuSystemService : Object {
    [DBus (name = "get_proxy")]
    public abstract string get_proxy (string proxy_type) throws GLib.Error;
    [DBus (name = "set_proxy")]
    public abstract bool set_proxy (string proxy_type, string new_proxy) throws GLib.Error;
    [DBus (name = "set_no_proxy")]
    public abstract bool set_no_proxy (string new_no_proxy) throws GLib.Error;
}

