Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.memory = "2048"
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.limit = "all,localhost"
  end
  config.vm.provision "shell", inline: "reboot"

  config.vm.synced_folder "wormhole", "/home/vagrant/Desktop/wormhole"
end
