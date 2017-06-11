/*-
 * Copyright (c) 2015-2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace Network.Widgets {
    public class Item : Gtk.ListBoxRow {
        public Gtk.Widget? page { get; set; default = null; }

        private Gtk.Label row_description;
        private Gtk.Image status_image;

        private Gtk.Grid row_grid;
        private Gtk.Image row_image;
        private Gtk.Label row_title;

        public string title {
            set {
                row_title.label = value;
            }
        }
        
        public string subtitle {
            set {
                row_description.label = value;
            }
        }

        public string icon_name {
            set {
                row_image.icon_name = value;
            }
        }

        construct {
            var overlay = new Gtk.Overlay ();
            overlay.width_request = 38;

            row_grid = new Gtk.Grid ();
            row_grid.margin = 6;
            row_grid.margin_start = 3;
            row_grid.column_spacing = 3;

            row_image = new Gtk.Image ();
            row_image.pixel_size = 32;

            row_title = new Gtk.Label ("");
            row_title.get_style_context ().add_class ("h3");
            row_title.ellipsize = Pango.EllipsizeMode.END;
            row_title.halign = Gtk.Align.START;
            row_title.valign = Gtk.Align.START;

            row_description = new Gtk.Label (null);
            row_description.margin_top = 2;
            row_description.use_markup = true;
            row_description.ellipsize = Pango.EllipsizeMode.END;
            row_description.halign = Gtk.Align.START;
            row_description.valign = Gtk.Align.START;

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            hbox.pack_start (row_description, false, false, 0);

            status_image = new Gtk.Image.from_icon_name ("user-available", Gtk.IconSize.MENU);
            status_image.halign = status_image.valign = Gtk.Align.END;

            overlay.add (row_image);
            overlay.add_overlay (status_image);

            row_grid.attach (overlay, 0, 0, 1, 2);
            row_grid.attach (row_title, 1, 0, 1, 1);
            row_grid.attach (hbox, 1, 1, 1, 1);

            update_state ();
            add (row_grid);
            show_all ();
        }

        public void set_state_data (string description, string icon_name) {
            status_image.icon_name = icon_name;
            row_description.label = "<span font_size='small'>%s</span>".printf (description);
        }

        public virtual void update_state () {

        }
    }
}
