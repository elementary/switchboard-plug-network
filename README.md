# Switchboard Networking Plug
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard-plug-networking.svg)](https://repology.org/metapackage/switchboard-plug-networking)
[![Translation status](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-networking/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-networking/?utm_source=widget)

## Building and Installation

You'll need the following dependencies:

* cmake
* libgranite-dev
* libnm-glib-dev
* libnm-gtk-dev
* libnm-util-dev
* libswitchboard-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard
