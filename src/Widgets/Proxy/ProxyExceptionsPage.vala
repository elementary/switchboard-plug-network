namespace Network.Widgets {
	public class ExecepionsPage : Gtk.Box {
		private Gtk.ListBox ignored_list;
		private Gtk.ListBoxRow[] items = {};

		public ExecepionsPage () {
			this.margin_top = 10;
			this.orientation = Gtk.Orientation.VERTICAL;
			ignored_list = new Gtk.ListBox ();
			ignored_list.vexpand = true;
			ignored_list.selection_mode = Gtk.SelectionMode.SINGLE;
			ignored_list.activate_on_single_click = false; 

			var control_row = new Gtk.ListBoxRow ();
			control_row.selectable = false;

			var ign_label = new Gtk.Label (_("<b>" + _("Ignored hosts") + "</b>"));
			ign_label.use_markup = true;
			ign_label.get_style_context ().add_class ("h4");

			var ign_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			ign_box.pack_start (ign_label, false, false, 0);

			var control_switch = new Gtk.Switch ();
			control_switch.active = client.wireless_get_enabled ();

			var entry = new Gtk.Entry ();
			entry.placeholder_text = _("Exception to add (separate with commas to add multiple)");

			var add_btn = new Gtk.Button.with_label (_("Add exception"));
			add_btn.sensitive = false;
			add_btn.get_style_context ().add_class ("suggested-action");
			add_btn.clicked.connect (() => {
			string[] new_hosts = proxy_settings.ignore_hosts;
				foreach (string host in entry.get_text ().split (",")) {
				    if (host.strip () != "")
				          new_hosts += host.strip ();
				}

				proxy_settings.ignore_hosts = new_hosts;
                entry.text = "";
				update_list ();
			});

            /* On activate add exceptions */
            entry.activate.connect (() => {
                add_btn.clicked ();
            });

			entry.changed.connect (() => {
				if (entry.get_text () != "")
				  add_btn.sensitive = true;
				else
				  add_btn.sensitive = false;    
			});

			var box_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
			box_btn.margin = 11;
			box_btn.pack_end (entry, true, true, 0);
			box_btn.pack_end (add_btn, false, false, 0);

			control_row.add (ign_box);
			ignored_list.add (control_row);

			list_exceptions ();

			this.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
			this.add (ignored_list);
			this.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
			this.add (box_btn);
			this.show_all ();   
		}

		private void list_exceptions () {
			foreach (string e in proxy_settings.ignore_hosts) {
				var row = new Gtk.ListBoxRow ();
				var e_label = new Gtk.Label (e);
				e_label.get_style_context ().add_class ("h3");

				var remove_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
				remove_btn.get_style_context ().add_class ("flat");

				remove_btn.clicked.connect (() => {
				  remove_exception (e);
				});

				var e_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
				e_box.margin_end = 5;
				e_box.pack_start (e_label, false, true, 0);
				e_box.pack_end (remove_btn, false, false, 0);

				row.add (e_box);
				ignored_list.add (row);
				items += row;
			}
		}

		private void remove_exception (string exception) {
			string[]? new_hosts = {};
			foreach (string host in proxy_settings.ignore_hosts) {
			  if (host != exception)
			        new_hosts += host;
			}

			proxy_settings.ignore_hosts = new_hosts;
			update_list ();
		}

		private void update_list () {
			foreach (var item in items)
				ignored_list.remove (item);

			items = {};

			list_exceptions ();
			this.show_all ();
		}
	}
}      
