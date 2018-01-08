# This a sample CMakeLists.txt for compiling plug for Switchboard
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

option (UBUNTU_BASED_DISTRO "Whether to build in systemwide proxy support, depends on ubuntu-system-service" ON)

# Set the Name of the plug, should be an executable command, lowercase, no spaces 
set (PLUGNAME "pantheon-network")
# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "network")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "Network")
# Set the version for the plug
set (VERSION "0.1.1")

# Set the Name of the plug, should be an executable command, lowercase, no spaces 

# When final switch to: switchboard-plug-network
project (${PLUGNAME} C)

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/switchboard")
set (PKGDATADIR "${DATADIR}/${PLUGCATEGORY}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}-plug")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

add_subdirectory (data)
add_subdirectory (po)
add_subdirectory (src)
