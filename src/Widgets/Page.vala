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
 *              xapantu
 */

namespace Network.Widgets {
    public class Page : Gtk.Grid {
        protected Gtk.Switch control_switch;
        protected Gtk.Grid control_box;

        public string icon_name {
            owned get {
                return header_image.icon_name;
            }

            set {
                header_image.icon_name = value;
            }
        }

        public string title {
            get {
                return header_label.label;
            }

            set {
                header_label.label = value;
            }
        }

        protected Gtk.Image header_image;
        protected Gtk.Label header_label;

        construct {
            margin = 24;
            orientation = Gtk.Orientation.VERTICAL;
            row_spacing = 24;
            
            header_image = new Gtk.Image ();
            header_image.pixel_size = 48;

            header_label = new Gtk.Label (null);
            header_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
            header_label.get_style_context ().add_class ("h2");
            header_label.hexpand = true;
            header_label.xalign = 0;

            control_switch = new Gtk.Switch ();
            control_switch.valign = Gtk.Align.CENTER;
            control_switch.notify["active"].connect (control_switch_activated);

            control_box = new Gtk.Grid ();
            control_box.column_spacing = 12;
            control_box.add (header_image);
            control_box.add (header_label);
            control_box.add (control_switch);

            add (control_box);
            show_all ();            
        }

        protected virtual void update () {

        }

        protected virtual void control_switch_activated () {

        }
    }
}
