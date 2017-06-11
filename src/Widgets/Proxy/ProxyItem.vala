/*-
 * Copyright (c) 2016-2017 elementary LLC.
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
    public class ProxyItem : Item {
        construct {
            title = _("Proxy");
            icon_name = "preferences-system-network";
            page = new ProxyPage ();

            var proxy_settings = ProxySettings.get_default ();
            proxy_settings.changed.connect (() => update_state ());
            update_state ();
        }

        public override void update_state () {
            unowned string description;
            unowned string icon;

            var proxy_settings = ProxySettings.get_default ();
            proxy_settings.get_state_data (out description, out icon);

            set_state_data (description, icon);
        }
    }
}