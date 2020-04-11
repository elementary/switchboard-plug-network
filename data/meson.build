i18n.merge_file(
    input: 'io.elementary.switchboard.network.appdata.xml.in',
    output: 'io.elementary.switchboard.network.appdata.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(datadir, 'metainfo'),
    install: true
)

if get_option('use_ubuntu_system_service')
    i18n.merge_file(
        input: 'io.elementary.switchboard.network.policy.in',
        output: 'io.elementary.switchboard.network.policy',
        po_dir: join_paths(meson.source_root (), 'po', 'extra'),
        install_dir: join_paths(datadir, 'polkit-1', 'actions'),
        install: true
    )
endif
