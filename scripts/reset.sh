#!/bin/bash

set -o errexit -o nounset -o pipefail

build_image() {
  local password
  password="$(openssl rand -base64 32)"
  PKR_VAR_password_hash="$(openssl passwd -6 -- "${password}")"
  export PKR_VAR_password_hash

  export PKR_VAR_ssh_private_key_file=.ssh/id
  (
    trap 'rm --force "${PKR_VAR_ssh_private_key_file}"' EXIT
    ssh-keygen -N '' -f "${PKR_VAR_ssh_private_key_file}" -t ed25519

    packer init .
    packer build -on-error=ask .
  )

  local output_folder
  output_folder="$(query_last_build_manifest '.custom_data.output_folder')"
  (
    umask u=rw,go=
    printf '%s' "${password}" >"${output_folder}/password.txt"
  )
}

query_last_build_manifest() {
  jq \
    '. as $root | .builds[] | select(.packer_run_uuid == $root.last_run_uuid)' \
    packer-manifest.json \
    | jq --raw-output "$1"
}

run_vm() {
  local iso_version output_file share_name
  iso_version="$(query_last_build_manifest '.custom_data.iso_version')"
  output_file="$(query_last_build_manifest '.files[0].name')"
  share_name="$(query_last_build_manifest '.custom_data.share_name')"

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
  build_image
  run_vm
  virt-manager &
}

main "$@"
