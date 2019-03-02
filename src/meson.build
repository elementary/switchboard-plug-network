plug_files = files(
    'Utils.vala',
    'rfkill.vala',
    'Plug.vala',
    'NetworkManager.vala',
    'Widgets/WifiInterface.vala',
    'Widgets/SettingsButton.vala',
    'Widgets/Page.vala',
    'Widgets/ModemInterface.vala',
    'Widgets/InfoBox.vala',
    'Widgets/HotspotInterface.vala',
    'Widgets/Footer.vala',
    'Widgets/EtherInterface.vala',
    'Widgets/DeviceList.vala',
    'Widgets/DeviceItem.vala',
    'Widgets/WifiMenuItem.vala',
    'Widgets/WidgetNMInterface.vala',
    'Widgets/NMVisualizer.vala',
    'Widgets/Proxy/ProxyPage.vala',
    'Widgets/Proxy/ProxyExceptionsPage.vala',
    'Widgets/Proxy/ProxyConfigurationPage.vala',
    'Widgets/VPN/VPNPage.vala',
    'Widgets/VPN/VPNInfoBox.vala',
    'Widgets/VPN/VPNMenuItem.vala',
    'Widgets/Hotspot/HotspotDialog.vala',
    'Settings/ProxySettings.vala'
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    plug_files,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=5.2.3'),
        dependency('gtk+-3.0'),
        dependency('libnm'),
        dependency('libnma'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'network')
)
