namespace Network.Widgets {
	public class ProxyPage : Gtk.Box {
		public ProxyPage () {
			this.orientation = Gtk.Orientation.VERTICAL;
			this.baseline_position = Gtk.BaselinePosition.CENTER;
			//this.spacing = this.margin_start;
			this.margin_top = 20;

			var stackswitcher = new Gtk.StackSwitcher ();
			stackswitcher.halign = Gtk.Align.CENTER;
			var stack = new Gtk.Stack ();
			stack.add_titled (new ConfigurationPage (), "configuration", _("Configuration"));
			stack.add_titled (new ExecepionsPage (), "exceptions", _("Exceptions"));

			stackswitcher.stack = stack;

			this.add (stackswitcher);
			this.add (stack);
			this.show_all ();
		}
	}
}
