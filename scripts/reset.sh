#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")/.."

vagrant destroy
vagrant box update
vagrant up
vagrant reload # Somehow required for synced folders to work.
virt-manager
