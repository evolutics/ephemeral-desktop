Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 2
    libvirt.memory = 4096
    libvirt.memorybacking :access, :mode => "shared"

    # This makes clipboard work with virt-manager (not so with default VNC).
    libvirt.graphics_type = "spice"
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision "file", source: "firefox_policies.json",
    destination: "/home/vagrant/provisioning/firefox_policies.json"
  config.vm.provision "shell", path: "provision.sh"

  config.vm.synced_folder "wormhole", "/home/vagrant/Desktop/wormhole",
    type: "virtiofs"
end
