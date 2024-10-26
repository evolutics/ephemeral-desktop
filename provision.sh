#!/bin/bash

set -o errexit -o nounset -o pipefail

sudo apt-get update
sudo apt-get --yes install gnome-session gnome-terminal spice-vdagent

sudo snap install firefox

sudo apt-get --yes dist-upgrade
sudo snap refresh

sudo sed \
  --expression 's/^XKBLAYOUT=.*/XKBLAYOUT="de,us"/' \
  --expression 's/^XKBVARIANT=.*/XKBVARIANT="neo,"/' \
  --in-place /etc/default/keyboard

sudo rsync --archive --mkpath --verbose wormhole/firefox_policies.json \
  /etc/firefox/policies/policies.json

reboot
