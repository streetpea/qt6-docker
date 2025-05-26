#!/bin/sh -xe
# Script to install Qt 6 in docker container

[ "$AQT_VERSION" ] || AQT_VERSION=aqtinstall
[ "$QT_VERSION" ] || exit 1

[ "$QT_PATH" ] || QT_PATH=/opt/Qt

root_dir=$PWD
[ "$root_dir" != '/' ] || root_dir=""

# Init the package system
apt update

echo
echo '--> Save the original installed packages list'
echo

dpkg --get-selections | cut -f 1 > /tmp/packages_orig.lst

echo
echo '--> Install the required packages to install Qt'
echo

apt install -y wget git libglib2.0-0 software-properties-common
add-apt-repository ppa:deadsnakes
apt update
apt install -y python3.12-dev python3.12-venv
python3.12 -m venv myvenv
ENV PATH="$PWD/venv/bin:$PATH"
wget https://bootstrap.pypa.io/get-pip.py
python3.12 get-pip.py
python3.12 -m pip install --upgrade six urllib3[secure]
python3.12 -m pip install --upgrade "$AQT_VERSION"

echo
echo '--> Download & install the Qt library using aqt'
echo

export arm_string=""
export gcc_string="_64"
if [ "$(uname -m)" = "aarch64" ]
then
  arm_string='_arm64'
  gcc_string='_arm64'
fi
aqt install-qt -O "$QT_PATH" linux${arm_string} desktop "$QT_VERSION" linux_gcc${gcc_string} -m qtwebengine qtpositioning qtwebchannel qtwebsockets qtserialport qtwaylandcompositor 
aqt install-tool -O "$QT_PATH" linux${arm_string} desktop tools_cmake
aqt install-tool -O "$QT_PATH" linux${arm_string} desktop tools_ninja

pip3 freeze | xargs pip3 uninstall -y || true

echo
echo '--> Restore the packages list to the original state'
echo

dpkg --get-selections | cut -f 1 > /tmp/packages_curr.lst
grep -Fxv -f /tmp/packages_orig.lst /tmp/packages_curr.lst | xargs apt remove -y --purge

# Complete the cleaning

apt -qq clean
rm -rf /var/lib/apt/lists/*
