Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 4
    libvirt.memory = 8192
    libvirt.memorybacking :access, :mode => "shared"

    # This makes clipboard work with virt-manager (not so with default VNC).
    libvirt.graphics_type = "spice"
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "wormhole", "/home/vagrant/wormhole", type: "virtiofs"

  config.vm.provision "shell", path: "provision.sh"
end
