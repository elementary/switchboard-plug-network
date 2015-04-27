
namespace Network.Widgets {
    
    public class InfoBox : Gtk.Box {
        public signal void update_sidebar (DeviceItem item);
        public signal void on_info_changed ();
        private NM.Device device;
        private DeviceItem? owner;
        
        private string status_l = (_("Status:") + SUFFIX);
		private string ipaddress_l = (_("IP Address:") + SUFFIX);
		private string mask_l = (_("Subnet mask:") + SUFFIX);
		private string router_l = (_("Router:") + SUFFIX);
		private string broadcast_l = (_("Broadcast:") + SUFFIX);

        private Gtk.Label status;
        private Gtk.Label ipaddress;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label broadcast;

        public InfoBox.from_device (NM.Device _device) {
            owner = null;
            device = _device;
            
            init_box ();
        }

        public InfoBox.from_owner (DeviceItem _owner) {    
            owner = _owner;
            device = owner.get_item_device ();    
            
            init_box ();
        }
    
        private void init_box () {    
            this.orientation = Gtk.Orientation.VERTICAL;
            this.spacing = 1;   
                       
            status = new Gtk.Label (status_l);
            status.use_markup = true;  
            status.halign = Gtk.Align.START;        

            ipaddress = new Gtk.Label (ipaddress_l);
            ipaddress.selectable = true;
            
            mask = new Gtk.Label (mask_l);
            mask.selectable = true;

            router = new Gtk.Label (router_l);
            router.selectable = true;
            
            broadcast = new Gtk.Label (broadcast_l);
            broadcast.selectable = true;

            ipaddress.halign = Gtk.Align.START;
            mask.halign = Gtk.Align.START;
            broadcast.halign = Gtk.Align.START;
            router.halign = Gtk.Align.START;

            this.add (status);
            this.add (new Gtk.Label (""));
            this.add (ipaddress);
            this.add (mask);
            this.add (router);
            this.add (broadcast);
            
            device.state_changed.connect (() => { 
                update_status ();
                on_info_changed ();
            });  
            
            update_status ();                        
            this.show_all ();        
        }
        
        public void update_status () {
        	// Refresh status
            switch (device.get_state ()) {
            	case NM.DeviceState.ACTIVATED:
            		status.label = status_l + "<span color='#22c302'>%s</span>".printf (Utils.state_to_string (device.get_state ()));	
            		break;
            	case NM.DeviceState.DISCONNECTED:
            		status.label = status_l + "<span color='#e51a1a'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		break;
            	default:
            		if (Utils.state_to_string (device.get_state ()) == "Unknown")
            			status.label = status_l + "<span color='#858585'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		else	
            			status.label = status_l + "<span color='#f1d805'>%s</span>".printf (Utils.state_to_string (device.get_state ()));
            		break;
            }

            // Refresh DHCP4 info
            var dhcp4 = device.get_dhcp4_config ();
            ipaddress.label = ipaddress_l + (dhcp4.get_one_option ("ip_address") ?? UNKNOWN);
            mask.label = mask_l + (dhcp4.get_one_option ("subnet_mask") ?? UNKNOWN);
            router.label = router_l + (dhcp4.get_one_option ("routers") ?? UNKNOWN);
            broadcast.label = broadcast_l + (dhcp4.get_one_option ("broadcast_address") ?? UNKNOWN);

            if (owner != null)
                update_sidebar (owner);

            this.show_all ();
        }           
    }
}
