Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.memory = "2048"
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "local.yml"
    ansible.limit = "all,localhost"
  end
  config.vm.provision "shell", inline: "reboot"

  config.vm.synced_folder "share", "/home/vagrant/Downloads"
end
