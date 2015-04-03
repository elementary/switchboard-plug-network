
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
	            return "Unknown";
	        case NM.DeviceState.ACTIVATED:
	            return "Connected";
	        case NM.DeviceState.DISCONNECTED:
	            return "Disconnected";  
	        case NM.DeviceState.UNMANAGED:
	            return "Unmanaged";  	            
	        case NM.DeviceState.PREPARE:
	            return "In preparation";  	            	
	        case NM.DeviceState.CONFIG:
	            return "Connecting...";  	            
	        case NM.DeviceState.NEED_AUTH:
	            return "Requires more information";  	            	            	                        	            
	        case NM.DeviceState.IP_CONFIG:
	            return "Requesting adresses...";  	            	            	          
	        case NM.DeviceState.IP_CHECK:
	            return "Checking connection...";  	            	            	          
	        case NM.DeviceState.SECONDARIES:
	            return "Waiting for connection...";  	            	            	          	            	            
	        case NM.DeviceState.DEACTIVATING:
	            return "Is disconnecting";              	            	    
	        case NM.DeviceState.FAILED:
	            return "Failed to connect";  	            	            	    	            
	    }
	    
	    return "Unknown";        
    }
    
    public string type_to_string (NM.DeviceType type) {
	    switch (type) {
	        case NM.DeviceType.UNKNOWN:
	            return "Unknown";
	        case NM.DeviceType.ETHERNET:
	            return "Ethernet";
	        case NM.DeviceType.WIFI:
	            return "WiFi";  
	        case NM.DeviceType.UNUSED1:
	            return "Not used";  	            
	        case NM.DeviceType.UNUSED2:
	            return "Not used";  	            	
	        case NM.DeviceType.BT:
	            return "Bluetooth";  	            
	        case NM.DeviceType.OLPC_MESH:
	            return "OLPC XO";  	            	            	                        	            
	        case NM.DeviceType.WIMAX:
	            return "WiMAX Broadband";  	            	            	          
	        case NM.DeviceType.MODEM:
	            return "Modem";  	            	            	          
	        case NM.DeviceType.INFINIBAND:
	            return "InfiniBand device";  	            	            	          	            	            
	        case NM.DeviceType.BOND:
	            return "Bond master";              	            	    
	        case NM.DeviceType.VLAN:
	            return "VLAN Interface";  	
	        case NM.DeviceType.ADSL:
	            return "ADSL Modem";  	            	            	          
	        case NM.DeviceType.BRIDGE:
	            return "Bridge master";  	            	            	          	            	            
	        //case NM.DeviceType.GENERIC:
	        //    return "Generic device";              	            	    
	       // case NM.DeviceType.TEAM:
	       //     return "Team interface";  		                        	            	    	            
	    }
	    
	    return "Unknown";     
    }        
}
