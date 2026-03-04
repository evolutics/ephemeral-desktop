#!/bin/bash

set -o errexit -o nounset -o pipefail

rotate_access() {
  rm --force --recursive access

  VM_PASSWORD="$(openssl rand -base64 32)"
  export VM_PASSWORD
  PKR_VAR_password_hash="$(openssl passwd -6 -- "${VM_PASSWORD}")"
  export PKR_VAR_password_hash

  export PKR_VAR_ssh_private_key_file=access/ssh_id
  trap 'rm --force "${PKR_VAR_ssh_private_key_file}"' EXIT
  ssh-keygen -N '' -f "${PKR_VAR_ssh_private_key_file}" -t ed25519
}

build_image() {
  packer init .
  packer build .
}

run_vm() {
  local custom_data
  custom_data="$(jq \
    '. as $root | .builds[] | select(.packer_run_uuid == $root.last_run_uuid) | .custom_data' \
    packer-manifest.json)"

  local iso_version output_file output_folder share_name
  iso_version="$(echo "${custom_data}" | jq --raw-output '.iso_version')"
  output_file="$(echo "${custom_data}" | jq --raw-output '.output_file')"
  output_folder="$(echo "${custom_data}" | jq --raw-output '.output_folder')"
  share_name="$(echo "${custom_data}" | jq --raw-output '.share_name')"

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
  rotate_access
  build_image
  run_vm
  virt-manager &
}

main "$@"
