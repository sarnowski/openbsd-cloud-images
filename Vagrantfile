VM_MEMORY=4096
VM_CORES=4

Vagrant.configure('2') do |config|
	config.vagrant.plugins = ["vagrant-vbguest"]

	config.vm.box = 'ubuntu/bionic64'

	config.vm.provider :virtualbox do |vb, override|
		vb.memory = VM_MEMORY
		vb.cpus = VM_CORES
	end

	# MacOS time skew issue mitigation
	config.vm.provider :virtualbox do |virtualbox|
		# set timesync parameters to keep the clocks better in sync
		# sync time every 10 seconds
		virtualbox.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-interval", 10000 ]
		# adjustments if drift > 100 ms
		virtualbox.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-min-adjust", 100 ]
		# sync time on restore
		virtualbox.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-on-restore", 1 ]
		# sync time on start
		virtualbox.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-start", 1 ]
		# at 1 second drift, the time will be set and not "smoothly" adjusted
		virtualbox.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
	end

	# configure ubuntu and install basic dependencies
	config.vm.provision 'shell', privileged: true, path: "scripts/host-setup.sh"
end
