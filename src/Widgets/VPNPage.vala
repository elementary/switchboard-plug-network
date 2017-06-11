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

using Network.Widgets;

namespace Network {
    public class VPNPage : WidgetNMInterface {
        private DeviceItem owner;
        //private NM.VPNConnection? active_connection = null;
        private VPNMenuItem? active_vpn_item = null;

        private Gtk.Frame connected_frame;
        private Gtk.ListBox vpn_list;
        private VPNInfoBox vpn_info_box;
        private VPNMenuItem blank_item;
        private Gtk.ScrolledWindow scrolled;
        private Gtk.Box? connected_box = null;
        private Gtk.Button? disconnect_btn;
        private Gtk.Button? settings_btn;
        private Gtk.ToggleButton? info_btn;
        private Gtk.Revealer top_revealer;
        private Gtk.Popover popover;

        public VPNPage (DeviceItem _owner) {
            owner = _owner;

            this.init (null);
            this.title = _("Virtual Private Network");
            this.icon_name = "network-vpn";

            row_spacing = 0;
            control_box.margin_bottom = 12;

            vpn_info_box = new VPNInfoBox ();
            vpn_info_box.margin = 12;

            popover = new Gtk.Popover (info_btn);
            popover.position = Gtk.PositionType.BOTTOM;
            popover.add (vpn_info_box);
            popover.hide.connect (() => {
                info_btn.active = false;
            });

            connected_frame = new Gtk.Frame (null);
            connected_frame.override_background_color (0, { 255, 255, 255, 255 });

            top_revealer = new Gtk.Revealer ();
            top_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            top_revealer.add (connected_frame);

            var no_connections_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            no_connections_box.visible = true;
            no_connections_box.valign = Gtk.Align.CENTER;

            var no_connections_label = new Gtk.Label (_("No VPN Connections"));
            no_connections_label.valign = Gtk.Align.CENTER;
            no_connections_label.wrap = true;
            no_connections_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            no_connections_label.max_width_chars = 30;
            no_connections_label.justify = Gtk.Justification.CENTER;
            no_connections_label.get_style_context ().add_class ("h2");

            var second_label = new Gtk.Label (_("Add a new VPN connection to begin."));
            second_label.valign = Gtk.Align.CENTER;
            second_label.wrap = true;
            second_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            second_label.max_width_chars = 30;
            second_label.justify = Gtk.Justification.CENTER;

            no_connections_box.add (no_connections_label);
            no_connections_box.add (second_label);
            no_connections_box.show_all ();

            vpn_list = new Gtk.ListBox ();
            vpn_list.activate_on_single_click = false;
            vpn_list.visible = true;
            vpn_list.set_placeholder (no_connections_box);

            var toolbar = new Gtk.Toolbar ();
            toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

            var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
            add_button.tooltip_text = _("Add VPN Connection…");
            add_button.clicked.connect (() => {
                add_button.sensitive = false;
                var command = new Granite.Services.SimpleCommand ("/usr/bin",
                                                    "nm-connection-editor --create --type=vpn");
                command.done.connect ((exit) => {
                    if (exit != 0) {
                        var dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s", _("Failed to run Connection Editor."));
                        dialog.run ();
                        dialog.destroy ();
                    }

                    add_button.sensitive = true;
                });

                command.run ();
            });

            toolbar.add (add_button);

            blank_item = new VPNMenuItem.blank ();

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.expand = true;
            scrolled.add (vpn_list);

            var list_root = new Gtk.Grid ();
            list_root.attach (scrolled, 0, 0, 1, 1);
            list_root.attach (toolbar, 0, 1, 1, 1);

            var main_frame = new Gtk.Frame (null);
            main_frame.margin_bottom = 24;
            main_frame.margin_top = 12;
            main_frame.vexpand = true;
            main_frame.override_background_color (0, { 255, 255, 255, 255 });
            main_frame.add (list_root);

            control_switch.no_show_all = true;
            control_switch.visible = false;

            bottom_revealer.set_reveal_child (true);

            this.add (top_revealer);
            this.add (main_frame);
            this.add (bottom_revealer);
            this.show_all ();

            client.notify["active-connections"].connect (update_active_connection);
            update ();
        }

        protected override void update () {
            update_active_connection ();

            bool sensitive = false;
            VPNMenuItem? item = null;
            /*if (active_connection != null) {
                switch (active_connection.get_vpn_state ()) {
                    case NM.VPNConnectionState.UNKNOWN:
                    case NM.VPNConnectionState.DISCONNECTED:
                        state = State.DISCONNECTED;
                        break;
                    case NM.VPNConnectionState.PREPARE:
                    case NM.VPNConnectionState.IP_CONFIG_GET:
                    case NM.VPNConnectionState.CONNECT:
                        state = State.CONNECTING_VPN;
                        item = get_item_by_uuid (active_connection.get_uuid ());
                        break;
                    case NM.VPNConnectionState.FAILED:
                        state = State.FAILED_VPN;
                        break;
                    case NM.VPNConnectionState.ACTIVATED:
                        state = State.CONNECTED_VPN;
                        item = get_item_by_uuid (active_connection.get_uuid ());
                        sensitive = true;
                        break;
                }
            } else {
                state = State.DISCONNECTED;
            }*/

            if (disconnect_btn != null) {
                disconnect_btn.sensitive = sensitive;
            }

            if (settings_btn != null) {
                settings_btn.sensitive = sensitive;
            }

            if (info_btn != null) {
                info_btn.sensitive = sensitive;
            }

            if (item == null) {
                top_revealer.set_reveal_child (false);
                blank_item.set_active (true);

                if (active_vpn_item != null) {
                    active_vpn_item.no_show_all = false;
                    active_vpn_item.visible = true;
                    active_vpn_item.state = state;

                    if (connected_frame != null && connected_frame.get_child () != null) {
                        connected_frame.get_child ().destroy ();
                    }                        
                }            
            } else {
                top_revealer.set_reveal_child (true);
                if (connected_frame != null && connected_frame.get_child () != null) {
                    connected_frame.get_child ().destroy ();
                }

                connected_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                item.state = state;
                item.no_show_all = true;
                item.visible = false;

                var top_item = new VPNMenuItem (item.connection, null);
                top_item.hide_icons (false);

                connected_box.add (top_item);

                disconnect_btn = new Gtk.Button.with_label (_("Disconnect"));
                disconnect_btn.get_style_context ().add_class ("destructive-action");
                disconnect_btn.clicked.connect (vpn_deactivate_cb);

                settings_btn = new SettingsButton.from_connection (item.connection, _("Settings…"));

                info_btn = new Gtk.ToggleButton ();
                info_btn.margin_top = info_btn.margin_bottom = 6;
                info_btn.get_style_context ().add_class ("flat");
                info_btn.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

                vpn_info_box.set_connection (item.connection);
                vpn_info_box.show_all ();

                popover.relative_to = info_btn;

                info_btn.toggled.connect (() => {
                    popover.visible = popover.sensitive = info_btn.get_active ();
                });

                var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                button_box.homogeneous = true;
                button_box.margin = 6;
                button_box.pack_end (disconnect_btn, false, false, 0);
                button_box.pack_end (settings_btn, false, false, 0);
                button_box.show_all ();

                connected_box.pack_end (button_box, false, false, 0);
                connected_box.pack_end (info_btn, false, false, 0);
                connected_frame.add (connected_box);

                connected_box.show_all ();
                connected_frame.show_all ();
            }

            owner.switch_status (Utils.CustomMode.INVALID, state);
            update_switch ();
        }

        protected override void update_switch () {

        }

        protected override void control_switch_activated () {

        }

        public void add_connection (NM.RemoteConnection connection) {
            var item = new VPNMenuItem (connection, get_previous_menu_item ());
            item.user_action.connect (vpn_activate_cb);

            vpn_list.add (item);
            update ();
            this.show_all ();
        }

        public void remove_connection (NM.RemoteConnection connection) {
            var item = get_item_by_uuid (connection.get_uuid ());
            item.destroy ();
        }

        private VPNMenuItem? get_item_by_uuid (string uuid) {
            VPNMenuItem? item = null;
            foreach (var child in vpn_list.get_children ()) {
                var _item = (VPNMenuItem)child;
                if (_item.connection != null && _item.connection.get_uuid () == uuid && item == null) {
                    item = (VPNMenuItem)child;
                }
            }

            return item;
        }

        private VPNMenuItem? get_previous_menu_item () {
            var children = vpn_list.get_children ();
            if (children.length () == 0) {
                return blank_item;
            }

            return (VPNMenuItem)children.last ().data;
        }

        private void update_active_connection () {
            //active_connection = null;

            client.get_active_connections ().foreach ((ac) => {
                if (ac.get_vpn ()) { //&& active_connection == null) {
                    //active_connection = (NM.VPNConnection)ac;
                    //active_connection.vpn_state_changed.connect (update);
                }
            });
        }

        private void vpn_activate_cb (VPNMenuItem item) {
            active_vpn_item = item;
            foreach (var child in vpn_list.get_children ()) {
                ((VPNMenuItem)child).hide_icons ();
            }

            update ();
            client.activate_connection_async.begin (item.connection, null, null, null);
        }

        private void vpn_deactivate_cb () {
            update_active_connection ();
            /*if (active_connection == null) {
                return;
            }*/

            update ();
            //client.deactivate_connection (active_connection);
        }
    }
}
