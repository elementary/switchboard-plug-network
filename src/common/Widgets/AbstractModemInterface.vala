// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

public abstract class Network.AbstractModemInterface : Network.WidgetNMInterface {
    public override void update_name (int count) {
        var name = device.get_description ();
        if (count > 1) {
            display_title = _("Mobile Broadband: %s").printf (name);
        } else {
            display_title = _("Mobile Broadband");
        }

        if (device is NM.DeviceModem) {
            var capabilities = (device as NM.DeviceModem).get_current_capabilities ();
            if (NM.DeviceModemCapabilities.POTS in capabilities) {
                display_title = _("Modem");
            }
        }
    }

    public override void update () {
        base.update ();

        switch (device.state) {
            case NM.DeviceState.UNKNOWN:
            case NM.DeviceState.UNMANAGED:
            case NM.DeviceState.UNAVAILABLE:
            case NM.DeviceState.FAILED:
                state = State.FAILED_MOBILE;
                control_switch.sensitive = false;
                control_switch.active = false;
                break;    
            case NM.DeviceState.DISCONNECTED:
            case NM.DeviceState.DEACTIVATING:
                state = State.DISCONNECTED;
                control_switch.sensitive = true;
                control_switch.active = false;
                break;
            case NM.DeviceState.PREPARE:
            case NM.DeviceState.CONFIG:
            case NM.DeviceState.NEED_AUTH:
            case NM.DeviceState.IP_CONFIG:
            case NM.DeviceState.IP_CHECK:
            case NM.DeviceState.SECONDARIES:
                state = State.CONNECTING_MOBILE;
                control_switch.sensitive = true;
                control_switch.active = true;
                break;
            case NM.DeviceState.ACTIVATED:
                state = State.CONNECTED_MOBILE;
                control_switch.sensitive = true;
                control_switch.active = true;
                break;
        }
    }
}
