plug_files = files(
    'Utils.vala',
    'rfkill.vala',
    'Plug.vala',
    'MainView.vala',
    'NetworkManager.vala',
    'Views/EthernetPage.vala',
    'Views/HotspotPage.vala',
    'Views/ModemPage.vala',
    'Views/ProxyPage.vala',
    'Views/VPNPage.vala',
    'Views/WifiPage.vala',
    'Widgets/SettingsButton.vala',
    'Widgets/Page.vala',
    'Widgets/InfoBox.vala',
    'Widgets/Footer.vala',
    'Widgets/DeviceList.vala',
    'Widgets/DeviceItem.vala',
    'Widgets/WifiMenuItem.vala',
    'Widgets/Proxy/ProxyExceptionsPage.vala',
    'Widgets/Proxy/ProxyConfigurationPage.vala',
    'Widgets/VPN/VPNInfoBox.vala',
    'Widgets/VPN/VPNMenuItem.vala',
    'Widgets/Hotspot/HotspotDialog.vala',
    'Settings/ProxySettings.vala'
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

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
    install_dir : join_paths(switchboard_plugsdir, 'network')
)
