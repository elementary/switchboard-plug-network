# Networking Settings
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard-plug-networking.svg)](https://repology.org/metapackage/switchboard-plug-networking)
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-networking/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libgranite-7-dev
* libnm-dev
* libnma-dev
* libswitchboard-3-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
