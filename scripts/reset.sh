#!/bin/bash

set -o errexit -o nounset -o pipefail

rotate_access() {
  rm --force --recursive access

  PKR_VAR_password="$(openssl rand -base64 32)"
  export PKR_VAR_password
  PKR_VAR_password_hash="$(openssl passwd -6 -- "${PKR_VAR_password}")"
  export PKR_VAR_password_hash

  (
    umask u=rwx,go=
    mkdir access
    printf '%s' "${PKR_VAR_password}" >access/password.txt
  )

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

  local iso_version output_file share_name
  iso_version="$(echo "${custom_data}" | jq --raw-output '.iso_version')"
  output_file="$(echo "${custom_data}" | jq --raw-output '.output_file')"
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
