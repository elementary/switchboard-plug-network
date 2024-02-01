project(
    'networking',
    'vala', 'c',
    version: '2.5.0'
)

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

add_project_arguments(
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    language: 'vala'
)

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name() + '-plug')
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

subdir('data')
subdir('src')
subdir('po')

vapigen = find_program('vapigen', required: true)
g_ir_dep = dependency('gobject-introspection-1.0', required: true)
if vapigen.found() and g_ir_dep.found()
    subdir('vapi')
endif
