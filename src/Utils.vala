namespace Network.Utils {
    public enum ItemType {
        DEVICE = 0,
        PROXY,
        INVALID
    }

    public Gtk.Button get_advanced_button_from_device (NM.Device? device, string title = _("Advanced Settings…")) {
        var details_btn = new Gtk.Button.with_label (title);
        details_btn.clicked.connect (() => {
            new Granite.Services.SimpleCommand ("/usr/bin",
                                                "nm-connection-editor --edit=" + device.get_active_connection ().get_uuid ()).run ();
        }); 

        return details_btn;
    }
    
    public string state_to_string (NM.DeviceState state) {
        switch (state) {
            case NM.DeviceState.ACTIVATED:
                return _("Connected");
            case NM.DeviceState.DISCONNECTED:
                return _("Disconnected");  
            case NM.DeviceState.UNMANAGED:
                return _("Unmanaged");
            case NM.DeviceState.PREPARE:
                return _("In preparation");
            case NM.DeviceState.CONFIG:
                return _("Connecting...");
            case NM.DeviceState.NEED_AUTH:
                return _("Requires more information");
            case NM.DeviceState.IP_CONFIG:
                return _("Requesting adresses...");
            case NM.DeviceState.IP_CHECK:
                return _("Checking connection...");
            case NM.DeviceState.SECONDARIES:
                return _("Waiting for connection...");
            case NM.DeviceState.DEACTIVATING:
                return _("Disconnecting...");
            case NM.DeviceState.FAILED:
                return _("Failed to connect");
            case NM.DeviceState.UNKNOWN:
            default:
                return _("Unknown");
        }
    }

    public string type_to_string (NM.DeviceType type) {
        switch (type) {
            case NM.DeviceType.ETHERNET:
                return _("Ethernet");
            case NM.DeviceType.WIFI:
                return _("Wi-Fi");  
            case NM.DeviceType.UNUSED1:
                return _("Not used");
            case NM.DeviceType.UNUSED2:
                return _("Not used");
            case NM.DeviceType.BT:
                return _("Bluetooth");
            case NM.DeviceType.OLPC_MESH:
                return _("OLPC XO");
            case NM.DeviceType.WIMAX:
                return _("WiMAX Broadband");
            case NM.DeviceType.MODEM:
                return _("Modem");
            case NM.DeviceType.INFINIBAND:
                return _("InfiniBand device");
            case NM.DeviceType.BOND:
                return _("Bond master");
            case NM.DeviceType.VLAN:
                return _("VLAN Interface");
            case NM.DeviceType.ADSL:
                return _("ADSL Modem");
            case NM.DeviceType.BRIDGE:
                return _("Bridge master");
            case NM.DeviceType.UNKNOWN:
            default:
                return _("Unknown");
        }
    }
}
