#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

sudo apt-get update
sudo apt-get --yes install ubuntu-desktop-minimal
sudo apt-get --yes dist-upgrade

sudo sed \
  --expression 's/^XKBLAYOUT=.*/XKBLAYOUT="de,us"/' \
  --expression 's/^XKBVARIANT=.*/XKBVARIANT="neo,"/' \
  --in-place /etc/default/keyboard

sudo rsync --archive --mkpath --verbose provisioning/firefox_policies.json \
  /etc/firefox/policies/policies.json

reboot
