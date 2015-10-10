namespace Network.Widgets {
    public class ProxyPage : Gtk.Box {
        public Gtk.Stack stack;
        public signal void update_status_label (string mode);

        public ProxyPage () {
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

            proxy_settings.changed.connect (() => {
                update_mode ();
            });

            this.add (stackswitcher);
            this.add (stack);
            this.show_all ();
        }

        public void update_mode () {
            this.update_status_label (proxy_settings.mode);
        }
    }
}
