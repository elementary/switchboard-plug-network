/*
 * Copyright (c) 2019 elementary, Inc. (https://elementary.io)
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
 */

public class Network.Widgets.VPNInfoLabel : Gtk.Label {

    public VPNInfoLabel (string label_text) {
        Object (
            halign: Gtk.Align.END,
            justify: Gtk.Justification.RIGHT,
            label: label_text,
            margin: 0,
            selectable: false
        );

        get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
    }
}