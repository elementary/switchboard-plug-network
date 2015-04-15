namespace Network.Widgets {
	public class ProxyPage : Gtk.Box {
        public Gtk.Stack stack;
        public signal void update_status_label (string text);

		public ProxyPage () {
			this.orientation = Gtk.Orientation.VERTICAL;
			this.baseline_position = Gtk.BaselinePosition.CENTER;
			//this.spacing = this.margin_start;
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
            if (proxy_settings.mode == "none")
                this.update_status_label (_("Disabled"));
            else if (proxy_settings.mode == "manual")
                this.update_status_label (_("Enabled (manual mode)"));
            else if (proxy_settings.mode == "auto")
                this.update_status_label (_("Enabled (auto mode)"));
        }
	}
}
