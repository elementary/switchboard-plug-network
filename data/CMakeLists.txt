include(Translations)

if (USE_UBUNTU_SERVICES)
    configure_file_translation(${CMAKE_SOURCE_DIR}/data/org.pantheon.switchboard.networking.policy.xml ${CMAKE_BINARY_DIR}/data/org.pantheon.switchboard.networking.policy ${CMAKE_SOURCE_DIR}/po/)

    install (FILES ${CMAKE_BINARY_DIR}/data/org.pantheon.switchboard.networking.policy DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/polkit-1/actions/)
endif ()
