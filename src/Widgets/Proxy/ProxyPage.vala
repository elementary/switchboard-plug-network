namespace Network.Widgets {
    public class ProxyPage : Gtk.Box {
        public Gtk.Stack stack;
        public signal void update_status_label (string mode);

        private DeviceItem owner;

        public ProxyPage (DeviceItem _owner) {
            this.owner = _owner;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.baseline_position = Gtk.BaselinePosition.CENTER;
            this.margin_top = 20;

            var configuration_page = new ConfigurationPage ();
            var exceptions_page = new ExecepionsPage ();

            var stackswitcher = new Gtk.StackSwitcher ();
            stackswitcher.halign = Gtk.Align.CENTER;

            stack = new Gtk.Stack ();
            stack.add_titled (configuration_page, "configuration", _("Configuration"));
            stack.add_titled (exceptions_page, "exceptions", _("Exceptions"));
            stackswitcher.stack = stack;

            proxy_settings.changed.connect (update_mode);

            update_mode ();

            this.add (stackswitcher);
            this.add (stack);
            this.show_all ();

            stack.visible_child = configuration_page;
        }

        public void update_mode () {
            var mode = Utils.CustomMode.INVALID;
            switch (proxy_settings.mode) {
                case "none":
                    mode = Utils.CustomMode.PROXY_NONE;
                    break;
                case "manual":
                    mode = Utils.CustomMode.PROXY_MANUAL;
                    break;
                case "auto":
                    mode = Utils.CustomMode.PROXY_AUTO;
                    break;
                default:
                    mode = Utils.CustomMode.INVALID;
                    break;
            }

            owner.switch_status (mode);
        }
    }
}
