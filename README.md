# Switchboard Networking Plug
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard-plug-networking.svg)](https://repology.org/metapackage/switchboard-plug-networking)
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-networking/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libgranite-dev
* libnm-dev
* libnma-dev
* libswitchboard-2.0-dev
* policykit-1 (only required for systemwide proxy feature on Ubuntu based distros, see below)
* libpolkit-gobject-1-dev (only required for systemwide proxy feature on Ubuntu based distros, see below)
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install

If you are building on something other than an Ubuntu based distribution, use the following instead to disable the systemwide proxy feature which depends on `ubuntu-system-service`:

    meson build --prefix=/usr -Duse_ubuntu_system_service=false
