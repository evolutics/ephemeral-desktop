#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")/.."

vagrant destroy
vagrant box update
vagrant up
vagrant reload # For updates. Also, somehow required for synced folders to work.
virt-manager &
