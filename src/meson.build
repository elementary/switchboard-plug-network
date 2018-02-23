plug_files = files(
    'Utils.vala',
    'Plug.vala',
    'Widgets/WifiInterface.vala',
    'Widgets/VPNPage.vala',
    'Widgets/VPNInfoBox.vala',
    'Widgets/SettingsButton.vala',
    'Widgets/Page.vala',
    'Widgets/ModemInterface.vala',
    'Widgets/InfoScreen.vala',
    'Widgets/InfoBox.vala',
    'Widgets/HotspotInterface.vala',
    'Widgets/Footer.vala',
    'Widgets/EtherInterface.vala',
    'Widgets/DeviceList.vala',
    'Widgets/Proxy/ProxyPage.vala',
    'Widgets/Proxy/ProxyExceptionsPage.vala',
    'Widgets/Proxy/ProxyConfigurationPage.vala',
    'Widgets/Hotspot/HotspotDialog.vala',
    'Widgets/Device/DevicePage.vala',
    'Widgets/Device/DeviceItem.vala',
    'Settings/ProxySettings.vala',
    'common/Utils.vala',
    'common/rfkill.vala',
    'common/Widgets/WifiMenuItem.vala',
    'common/Widgets/WidgetNMInterface.vala',
    'common/Widgets/VPNMenuItem.vala',
    'common/Widgets/NMVisualizer.vala',
    'common/Widgets/AbstractWifiInterface.vala',
    'common/Widgets/AbstractModemInterface.vala',
    'common/Widgets/AbstractHotspotInterface.vala',
    'common/Widgets/AbstractEtherInterface.vala'
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    plug_files,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libnm'),
        dependency('libnma'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'network')
)
