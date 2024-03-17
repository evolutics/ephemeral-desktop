Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"

  config.vm.provider "libvirt" do |libvirt|
    libvirt.memory = "2048"

    # This makes clipboard work with virt-manager (not so with default VNC).
    libvirt.graphics_type = "spice"
  end

  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.limit = "all,localhost"
  end
  config.vm.provision "shell", inline: "reboot"

  config.vm.synced_folder "wormhole", "/home/vagrant/Desktop/wormhole"
end
