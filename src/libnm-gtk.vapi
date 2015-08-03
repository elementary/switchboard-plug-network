[CCode (cheader_filename = "nm-wifi-dialog.h")]
class NMAWifiDialog : Gtk.Dialog {
    public NMAWifiDialog (NM.Client client, NM.RemoteSettings settings, NM.Connection connection, NM.Device device, NM.AccessPoint ap, bool secrets_only);
    public NM.Connection get_connection (out NM.Device device, out NM.AccessPoint ap);
}        


[CCode (cprefix = "NMGtk", gir_namespace = "NMGtk", gir_version = "1.0", lower_case_cprefix = "nmgtk_")]
namespace NMGtk {
    [CCode (cheader_filename = "libnm-gtk/nm-wifi-dialog.h", cname = "nma_wifi_dialog_new_for_other")]                                    
    public Gtk.Dialog new_wifi_dialog_for_hidden (NM.Client client, NM.RemoteSettings settings);                                                                           
}
