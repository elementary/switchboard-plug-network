include (Translations) # Replace plug-name with the correct name of your plug

set (EXTRA_TRANSLATION_FILES)

if (UBUNTU_BASED_DISTRO)
    set (EXTRA_TRANSLATION_FILES ${EXTRA_TRANSLATION_FILES}
        ../data/org.pantheon.switchboard.networking.policy.xml
    )
endif ()

add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    APPDATA_FILES
        ${EXTRA_TRANSLATION_FILES}
)
