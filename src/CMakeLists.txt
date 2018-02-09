find_package (PkgConfig)

set (VALA_DEPS gthread-2.0 gtk+-3.0 libnm libnma switchboard-2.0 granite)

if(USE_UBUNTU_SERVICES)
    message (STATUS "Building systemwide proxy support")
    set (VALA_DEPS ${VALA_DEPS} polkit-gobject-1)
endif()

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED ${VALA_DEPS})

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

set (VALA_FLAGS
    --thread
    --define=PLUG_NETWORK
)

set (VALA_FILES
    Plug.vala
    Utils.vala
    Settings/ProxySettings.vala
    Widgets/Page.vala
    Widgets/DeviceList.vala
    Widgets/Device/DeviceItem.vala
    Widgets/Device/DevicePage.vala
    Widgets/WifiInterface.vala
    Widgets/EtherInterface.vala
    Widgets/ModemInterface.vala
    Widgets/HotspotInterface.vala
    Widgets/Proxy/ProxyConfigurationPage.vala
    Widgets/Proxy/ProxyExceptionsPage.vala
    Widgets/Proxy/ProxyPage.vala
    Widgets/InfoBox.vala
    Widgets/SettingsButton.vala
    Widgets/VPNPage.vala
    Widgets/VPNInfoBox.vala
    Widgets/Footer.vala
    Widgets/InfoScreen.vala
    Widgets/Hotspot/HotspotDialog.vala
    common/Utils.vala
    common/Widgets/WifiMenuItem.vala
    common/Widgets/VPNMenuItem.vala
    common/Widgets/AbstractWifiInterface.vala
    common/Widgets/AbstractEtherInterface.vala
    common/Widgets/AbstractHotspotInterface.vala
    common/Widgets/AbstractModemInterface.vala
    common/rfkill.vala
    common/Widgets/NMVisualizer.vala
    common/Widgets/WidgetNMInterface.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
)

if (USE_UBUNTU_SERVICES)
    set (VALA_FLAGS ${VALA_FLAGS}
        --define=ENABLE_SYSTEMWIDE_PROXY
    )

    set (VALA_FILES ${VALA_FILES}
        Settings/SystemServiceProxyBus.vala
    )
endif()

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    ${VALA_FILES}
PACKAGES
    gtk+-3.0
    switchboard-2.0
    granite
    polkit-gobject-1
    posix
OPTIONS
    ${VALA_FLAGS}
CUSTOM_VAPIS
    ../vapi/libnm.vapi
    ../vapi/libnma.vapi
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
