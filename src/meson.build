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
    'Widgets/VPN/VPNInfoDialog.vala',
    'Widgets/VPN/VPNMenuItem.vala'
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

libnm_dep = dependency('libnm', version: '>=1.20.6')

args = []
if libnm_dep.version().version_compare('>=1.43.0')
    args += '--define=HAS_NM_1_43'
endif

shared_module(
    meson.project_name(),
    plug_files,
    config_file,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=5.2.3'),
        dependency('gtk+-3.0'),
        libnm_dep,
        dependency('libnma'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    vala_args: args,
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'network')
)
