#!/bin/bash

set -o errexit -o nounset -o pipefail

build_image() {
  VM_PASSWORD="$(openssl rand -base64 32)"
  export VM_PASSWORD
  PKR_VAR_password_hash="$(openssl passwd -6 -- "${VM_PASSWORD}")"
  export PKR_VAR_password_hash

  export PKR_VAR_ssh_private_key_file=.ssh/id
  (
    trap 'rm --force "${PKR_VAR_ssh_private_key_file}"' EXIT
    ssh-keygen -N '' -f "${PKR_VAR_ssh_private_key_file}" -t ed25519

    packer init .
    packer build .
  )
}

run_vm() {
  local build
  build="$(jq \
    '. as $root | .builds[] | select(.packer_run_uuid == $root.last_run_uuid)' \
    packer-manifest.json)"

  local iso_version output_file output_folder share_name
  iso_version="$(echo "${build}" | jq --raw-output '.custom_data.iso_version')"
  output_file="$(echo "${build}" | jq --raw-output '.files[0].name')"
  output_folder="$(echo "${build}" | jq --raw-output '.custom_data.output_folder')"
  share_name="$(echo "${build}" | jq --raw-output '.custom_data.share_name')"

  local -r memory_in_mib=8192

  virt-install \
    --disk "${output_file}" \
    --filesystem "${PWD}/wormhole,${share_name},driver.type=virtiofs" \
    --import \
    --memory "${memory_in_mib}" \
    --memorybacking access.mode=shared,source.type=memfd \
    --name "$(openssl rand -hex 16)" \
    --noautoconsole \
    --os-variant "ubuntu${iso_version:0:5}" \
    --vcpus 4

  (
    umask u=rw,go=
    printf '%s' "${VM_PASSWORD}" >"${output_folder}/password.txt"
  )
}

main() {
  cd -- "$(dirname -- "$0")/.."

  date
  build_image
  run_vm
  virt-manager &
}

main "$@"
