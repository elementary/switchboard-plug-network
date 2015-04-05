#!/bin/bash
# build and install network plug

dir="$(dirname $0)"
cd "$dir"

INSTALL="1"

case "$1" in
    --only-build|-o) INSTALL="0";;
    *)
esac

deps="cmake libgtk-3-dev libnotify-bin libgranite-dev libswitchboard-2.0-dev libnm-glib-dev libnm-util-dev network-manager-dev"

if ! dpkg -s $deps >/dev/null 2>&1; then
    sudo apt-get install $deps
fi

if [ -d "build/" ]; then
  sudo rm -rf build
fi

mkdir build
cd build

cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make
if [ "$INSTALL" = "1" ]; then
    msg="Successfully builded and installed!"
    sudo make install
    cd ../
    rm -rf build/
else
    msg="Successfully builded!"
    cd ../
fi

echo "$msg"

exit
