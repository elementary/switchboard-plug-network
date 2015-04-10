find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 libnm-glib switchboard-2.0 granite polkit-gobject-1)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    Plug.vala
    Utils.vala
    Settings/ProxySettings.vala
    Widgets/Device/DeviceList.vala
    Widgets/Device/DeviceItem.vala
    Widgets/Device/DevicePage.vala   
    Widgets/WiFi/WiFiPage.vala
    Widgets/WiFi/WiFiEntry.vala
    Widgets/Proxy/ProxyConfigurationPage.vala
    Widgets/Proxy/ProxyExceptionsPage.vala
    Widgets/Proxy/ProxyPage.vala    
    Widgets/Footer.vala
    Widgets/InfoScreen.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    libnm-glib
    libnm-util
    switchboard-2.0
    granite
    posix
    polkit-gobject-1
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/
    --thread
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})

