[CCode (cprefix = "NMGtk", gir_namespace = "NMGtk", gir_version = "1.0", lower_case_cprefix = "nmgtk_")]
namespace NMGtk {
   [CCode (cheader_filename = "libnm-gtk/nm-wifi-dialog.h", cname = "nma_wifi_dialog_new")] 
   public Gtk.Dialog new_wifi_dialog (NM.Client client,
                                      NM.RemoteSettings settings,
                                      NM.Connection connection,
                                      NM.Device device,
                                      NM.AccessPoint ap,
                                      bool secrets_only);
}
