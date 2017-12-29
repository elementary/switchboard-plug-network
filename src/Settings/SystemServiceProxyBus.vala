/*-
 * Copyright (c) 2017 elementary LLC.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

[DBus (name = "com.ubuntu.SystemService")]
public interface UbuntuSystemService : Object {
    [DBus (name = "get_proxy")]
    public abstract string get_proxy (string proxy_type) throws IOError;
    [DBus (name = "set_proxy")]
    public abstract bool set_proxy (string proxy_type, string new_proxy) throws IOError;
    [DBus (name = "set_no_proxy")]
    public abstract bool set_no_proxy (string new_no_proxy) throws IOError;
}
