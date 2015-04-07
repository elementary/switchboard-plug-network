
namespace Network.Utils {
    public static Polkit.Permission? permission = null;

	public static Polkit.Permission? get_permission () {
			if (permission != null)
				return permission;
			try {
				permission = new Polkit.Permission.sync ("org.freedesktop.NetworkManager.settings.modify.hostname", Polkit.UnixProcess.new (Posix.getpid ()));
				return permission;
			} catch (Error e) {
				critical (e.message);
				return null;
			}
    }    
    
    public string state_to_string (NM.DeviceState state) {
	    switch (state) {
	        case NM.DeviceState.UNKNOWN:
	            return _("Unknown");
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
	    }
	    
	    return _("Unknown");        
    }
    
    public string type_to_string (NM.DeviceType type) {
	    switch (type) {
	        case NM.DeviceType.UNKNOWN:
	            return _("Unknown");
	        case NM.DeviceType.ETHERNET:
	            return _("Ethernet");
	        case NM.DeviceType.WIFI:
	            return _("WiFi");  
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
	        //case NM.DeviceType.GENERIC:
	        //    return "Generic device";              	            	    
	       // case NM.DeviceType.TEAM:
	       //     return "Team interface";  		                        	            	    	            
	    }
	    
	    return _("Unknown");     
    }        
}
