# -*- mode: ruby -*-
# vi: set ft=ruby :

#the default password for "su root" is simply "vagrant"

#Notes on Domino 12 "One Touch" automated initial setup
#https://help.hcltechsw.com/domino/12.0.0/admin/inst_onetouch_invoking_json_withoutdocker.html
#https://blog.nashcom.de/nashcomblog.nsf/dx/domino-v12-one-touch-setup-for-real-world-deployments.htm?opendocument&comments
#http://blog.nashcom.de/nashcomblog.nsf/dx/complete-domino-v12-server-setup-leveraging-on-touch.htm

## PARAMETERS:

# Root directory for files that will be shared between multiple Vagrant projects
#VAGRANT_SHARED = "~/vagrant_domino_files" # this format did not work on macOS 10.15.7 - access restricted error
VAGRANT_SHARED = "./vagrant_cached_domino_mfa_files" # create a symlink with:  ln -s ~/DropBox/Vagrant/DominoServerMFACachedInstallers-Shibboleth/ ./vagrant_cached_domino_mfa_files 


# The the path for the Notes ID to use for the new VM for the purpose of stand-alone Java application use
# This file will be copied to /local/notesjava/user.id
NOTES_ID = "./dist-id-files/SOME_NOTES_ID_OF_YOURS_THAT_YOU_WANT_INSIDE_THE_VM.id"


# Select Domino Install
# Choose 0 for the base Domino server install only.
# Choose 1 for the base Domino server and fixpack.
# Choose 2 for the base Domino server, fixpack, and interim fix.
# You can verify the installed version with these commands:  /opt/hcl/domino/bin/java -fullversion
# TODO:  Make this an environment variable instead?
DOMINO_INSTALL_SELECTION = 0


# Optional.  The directory for the Domino server installer TARs.  You can update this instead of the _PATH variables below
DOMINO_INSTALLER_PATH = "#{VAGRANT_SHARED}"


# The name of the Domino server installer.  This is expected to match the name of the file on downloads.prominic.net
DOMINO_SERVER_INSTALLER_TAR = "Domino_12.0_Linux_English.tar"


# The local path for the Domino server installer tar.  Download from https://downloads.prominic.net/ND12/Domino_12.0_Linux_English.tar
DOMINO_SERVER_INSTALLER_PATH = "#{DOMINO_INSTALLER_PATH}/#{DOMINO_SERVER_INSTALLER_TAR}"
#puts "Installer Path:  '#{DOMINO_SERVER_INSTALLER_PATH}'"
#if !File.exist?(DOMINO_SERVER_INSTALLER_PATH) 
#    puts "Could not find installer!"
#end


# The name of the fixpack installer.
# Get from downloads.prominic.net, /local/downloads-private/ND11/Domino_1101FP2_Linux.tar
DOMINO_SERVER_FIXPACK_TAR = "Domino_1101FP2_Linux.tar"
# The location of the fixpack installer, if you downloaded it
DOMINO_SERVER_FIXPACK_PATH = "#{DOMINO_INSTALLER_PATH}/#{DOMINO_SERVER_FIXPACK_TAR}"
#puts "Installer Path:  '#{DOMINO_SERVER_FIXPACK_PATH}'"
#if !File.exist?(DOMINO_SERVER_FIXPACK_PATH) 
#    puts "Could not find installer!"
#end

# Not needed for 11.0.1
## The name of the interim fix installer.  Download from:  https://downloads.prominic.net/ND9/901FP10HF266-linux64.tar
#DOMINO_SERVER_HOTFIX_TAR = "901FP10HF266-linux64.tar"
## The location of the interum fix installer, if you downloaded it
#DOMINO_SERVER_HOTFIX_PATH = "#{DOMINO_INSTALLER_PATH}/#{DOMINO_SERVER_HOTFIX_TAR}"
##puts "Installer Path:  '#{DOMINO_SERVER_HOTFIX_PATH}'"
##if !File.exist?(DOMINO_SERVER_HOTFIX_PATH) 
##    puts "Could not find installer!"
##end

# The name of the Java tar file
# NOTE:  if you update the name or version, make sure to update SDKMAN_Setup.sh as well
JAVA_TAR = "jre-8u251-linux-x64.tar.gz"
# The location of the Java tar file
JAVA_TAR_PATH = "#{DOMINO_INSTALLER_PATH}/#{JAVA_TAR}"




# Domino server silent install configuration file
DOMINO_SERVER_INSTALL_CONFIG = "./dist-support/installer.properties"

# The file which holds the password for the Notes ID.  Be careful not to commit this file to SVN! 
#NOTES_ID_PASSWORD_FILE = "/Users/USERNAME/VagrantDomino.conf"
#NOTES_ID_PASSWORD = File.read(NOTES_ID_PASSWORD_FILE)
# Escape special characters
#NOTES_ID_PASSWORD = NOTES_ID_PASSWORD.gsub(/[&\$\\`"]/, '\\\0')

# Read from input:  Fails with:  "Message: Errno::ENOENT: No such file or directory @ rb_sysopen - up"
#NOTES_ID_PASSWORD = gets
#NOTES_ID_PASSWORD = NOTES_ID_PASSWORD.chomp

# Read the password from the user
#require_relative "user_input.rb"
#NOTES_ID_PASSWORD ||= NotesPassword.new.to_s

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  
  #https://stackoverflow.com/questions/17845637/how-to-change-vagrant-default-machine-name
  config.vm.define "domino-vm"
  config.vm.hostname = "domino-vm.mydomain.com"

  #https://stackoverflow.com/questions/33250304/how-to-automatically-select-bridged-network-interfaces-in-vagrant
  # Specify the interface when creating the public network
  config.vm.network "public_network", bridge: "Intel(R) Dual Band Wireless-AC 8265"

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "centos/7"    #JMH tests show this fails to install guest additions as of June 6, 2021
 
  #https://subscription.packtpub.com/book/virtualization_and_cloud/9781786464910/1/ch01lvl1sec12/enabling-virtualbox-guest-additions-in-vagrant
  
  #this didn't work either....
  #trying this alternate base image, per this article: https://github.com/hashicorp/vagrant/issues/8374
  #there is interesting information in this article about using NFS instead of shared folders: https://seven.centos.org/2017/09/updated-centos-vagrant-images-available-v1708-01/
  #config.vm.box = "geerlingguy/centos7"

  
  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # PROBLEM:  gives a vboxsf error
  #config.vm.synced_folder ".", "/sourcecode"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
     # Display the VirtualBox GUI when booting the machine
     # I have disabled this by default, because the GUI won't load properly until ubuntu-desktop is installed
     #vb.gui = true
  
     # Customize the amount of memory on the VM:
     vb.memory = "4096"
  end
  
  
  
  config.vm.provision "shell", name: "Upgrade Linux so VirtualBox Guest Additions will install", privileged:true, inline: "yum -y upgrade" 
  
  #reboot after upgrade
  #https://superuser.com/questions/1338429/how-do-i-reboot-a-vagrant-guest-from-a-provisioner
  config.vm.provision :shell do |shell|
    shell.privileged = true
    shell.inline = 'echo rebooting'
    shell.reboot = true
  end  
  
  
  ## WORKAROUND for VirtualBox Guest Additions not installing properly - have not tried all of these options yet
  #read this and try to get the Vagrantfile itself to do this
  #https://github.com/hashicorp/vagrant/issues/8374
  #From https://gist.github.com/adaroobi/fea2727be6ae3d9c446767f813146f93
  #
  #https://www.serverlab.ca/tutorials/virtualization/how-to-auto-upgrade-virtualbox-guest-additions-with-vagrant/
  #might be able to get this alternate approach to work in the Vagrantfile:
  #vagrant plugin install vagrant-vbguest
  #vagrant vbguest --do install --no-cleanup
  config.vbguest.auto_update = false
  config.vm.provision "shell", name: "WORKAROUND for VirtualBox Guest Additions.", privileged: true, inline: <<-SHELL
    VBOX_VERSION_ON_HOST_OS=6.1.22     #This should be set to YOUR host OS release of VirtualBox
	
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    #rpm -Uvh http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/d/dkms-2.6.1-1.el7.noarch.rpm
    rpm -Uvh https://download-ib01.fedoraproject.org/pub/epel/7/aarch64/Packages/d/dkms-2.7.1-1.el7.noarch.rpm
	yum -y install wget perl gcc dkms kernel-devel kernel-headers make bzip2

    wget http://download.virtualbox.org/virtualbox/${VBOX_VERSION_ON_HOST_OS}/VBoxGuestAdditions_${VBOX_VERSION_ON_HOST_OS}.iso
	
    mkdir /media/VBoxGuestAdditions
    mount -o loop,ro VBoxGuestAdditions_${VBOX_VERSION_ON_HOST_OS}.iso /media/VBoxGuestAdditions

    sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
	#ugh.. this is still no matching kernel version!
	#https://www.binarytides.com/check-virtualbox-guest-additions-installed-linux-guest/
	#lsmod | grep -i vbox
	#https://www.dev2qa.com/how-to-resolve-virtualbox-guest-additions-kernel-headers-not-found-for-target-kernel-error/
	#https://unix.stackexchange.com/questions/272638/why-cant-i-find-kernel-headers-on-centos-7-when-trying-to-install-virtualbox-gu/505021
	#https://bugs.centos.org/view.php?id=17845
    #yum install “kernel-devel-uname-r == $(uname -r)
	#uname -r; ls /usr/src/kernels/
	
    #rm -f VBoxGuestAdditions_${VBOX_VERSION_ON_HOST_OS}.iso
    #umount /media/VBoxGuestAdditions
    #mdir /media/VBoxGuestAdditions
    unset VBOX_VERSION_ON_HOST_OS
  SHELL

  
  #SYNCED FOLDERS -- depends upon VirtualBox Guest Additions I think
  #https://www.vagrantup.com/docs/synced-folders
  # IMPLEMENT THIS:
  # https://gist.github.com/novalis111/e951a3b7d499ccdcbbb1
  # from here per "novalis111 commented on Oct 2, 2015" post OR cecilemuller commented on Mar 21, 2017:
  # https://github.com/hashicorp/vagrant/issues/936      <<-- this also has really good details on using a Yaml file to better segment operations and settings
  # https://news.ycombinator.com/item?id=15567390
  # https://blog.darwin-it.nl/2019/04/split-your-vagrant-provisioners.html
  if File.exist?(".vagrant/machines/domino-vm/virtualbox/action_provision")
	#
	# Already provisioned, it's now safe to use "config.vm.synced_folder" statements
	# and additional scripts that require the users exist
	#
    config.vm.synced_folder './dist-id-files', '/home/vagrant/dist-id-files', SharedFoldersEnableSymlinksCreate: false
    config.vm.synced_folder './dist',          '/home/vagrant/dist',          SharedFoldersEnableSymlinksCreate: false
    config.vm.synced_folder './dist-src',      '/home/vagrant/dist-src',      SharedFoldersEnableSymlinksCreate: false
    config.vm.synced_folder './dist-build',    '/home/vagrant/dist-build',    SharedFoldersEnableSymlinksCreate: false
    config.vm.synced_folder './dist-built',    '/home/vagrant/dist-built',    SharedFoldersEnableSymlinksCreate: false
  else
	#
	# Not yet provisioned, only run the script that creates the required users
	#
  end

  
  

  # Install some dependencies
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    yum -y install wget
    # For debuggging connections:
    yum -y install telnet
	# To move around easier in a text mode UI:
	yum -y install mc
	# For conveninece of starting Domino and keeping it persistent (without Jedi)
	yum -y install screen
  SHELL

  ## Upload Domino server installer(s)
  # Conditional download
  if File.exist?(DOMINO_SERVER_INSTALLER_PATH)
      # upload from local machine
      config.vm.provision "file",
       # name:"Upload Domino Installer", 
        source: "#{DOMINO_SERVER_INSTALLER_PATH}", 
        destination: "/home/vagrant/#{DOMINO_SERVER_INSTALLER_TAR}"
      #config.vm.provision "file", source: DOMINO_SERVER_INSTALLER_PATH, destination: "/home/vagrant/#{DOMINO_SERVER_INSTALLER_TAR}"
  else
      config.vm.provision "shell",inline: "echo 'Server installer not found at #{DOMINO_SERVER_INSTALLER_PATH}'"
      # download from remote source
      config.vm.provision "shell",
       # name:  "Download Domino installer.",
        inline:  "wget \"https://downloads.prominic.net/ND9/#{DOMINO_SERVER_INSTALLER_TAR}\" --output-document=/home/vagrant/#{DOMINO_SERVER_INSTALLER_TAR} --user downloads@prominic.net --password XXXXXXX --progress=dot:mega",
        privileged: false
  end

  if DOMINO_INSTALL_SELECTION >= 1  # install fixpack
    # Domino server FP copy
    # Conditional download
    if File.exist?(DOMINO_SERVER_FIXPACK_PATH)
        # upload from local machine
        config.vm.provision "file",
         # name:"Upload Domino Installer",
          source: "#{DOMINO_SERVER_FIXPACK_PATH}",
          destination: "/home/vagrant/#{DOMINO_SERVER_FIXPACK_TAR}"
        #config.vm.provision "file", source: DOMINO_SERVER_FIXPACK_PATH, destination: "/home/vagrant/#{DOMINO_SERVER_FIXPACK_TAR}"
    else
        # download from remote source
        # TODO: update this for Domino 11
        config.vm.provision "shell",
         # name:  "Download Domino installer.",
          inline:  "wget \"https://downloads.prominic.net/ND9/#{DOMINO_SERVER_FIXPACK_TAR}\" --output-document=/home/vagrant/#{DOMINO_SERVER_FIXPACK_TAR} --user downloads@prominic.net --password XXXXXXXX --progress=dot:mega",
          privileged: false
    end
  end
  

  if DOMINO_INSTALL_SELECTION >= 2   # install interum fix as well
    # Domino server HF copy
    # Conditional download
    if File.exist?(DOMINO_SERVER_HOTFIX_PATH)
        # upload from local machine
        config.vm.provision "file",
         # name:"Upload Domino Installer",
          source: "#{DOMINO_SERVER_HOTFIX_PATH}",
          destination: "/home/vagrant/#{DOMINO_SERVER_HOTFIX_TAR}"
        #config.vm.provision "file", source: DOMINO_SERVER_HOTFIX_PATH, destination: "/home/vagrant/#{DOMINO_SERVER_HOTFIX_TAR}"
    else
        # download from remote source
        # TODO: update this for Domino 11
        config.vm.provision "shell",
         # name:  "Download Domino installer.",
          inline:  "wget \"https://downloads.prominic.net/ND9/#{DOMINO_SERVER_HOTFIX_TAR}\" --output-document=/home/vagrant/#{DOMINO_SERVER_HOTFIX_TAR} --user downloads@prominic.net --password XXXXXXX --progress=dot:mega",
          privileged: false
    end
  end
 
  
  # Unzip Domino installer files
  config.vm.provision "shell",inline: "tar -xvf /home/vagrant/#{DOMINO_SERVER_INSTALLER_TAR} -C /home/vagrant/", privileged:false
 
  
  # Copy install configuration file
  config.vm.provision "file", source: "#{DOMINO_SERVER_INSTALL_CONFIG}", destination: "/home/vagrant/installer.properties"

  
  # Domino dependencies
  config.vm.provision "shell",privileged:true,inline: "yum -y install perl"

  config.vm.provision "shell", name:"Prepare environment for Domino install.", privileged:true,inline: <<-SHELL
    sudo su
    
	#make a user to run Java applications indepedently of a Domino server actually running
	mkdir -p /local/notesjava
    chown -R vagrant.vagrant /local/notesjava

	
	#make a user for the Domino server to also test code running inside the Domino server
	#note this is NOT necessary if you only want to run standalone Java code
	mkdir -p /local/dominodata
    groupadd domino
    useradd -d /local/dominodata -g domino -G domino domino
    chown -R domino.domino /local/dominodata
    #
    # tune the OS for Domino
    echo "vagrant         soft    nofile          60000"  | sudo tee -a /etc/security/limits.conf
    echo "vagrant         hard    nofile          80000"  | sudo tee -a /etc/security/limits.conf
    echo "domino          soft    nofile          60000"  | sudo tee -a /etc/security/limits.conf
    echo "domino          hard    nofile          80000"  | sudo tee -a /etc/security/limits.conf
    ulimit -n 60000
  SHELL
 
  # Install Domino server in silent mode.  This must run as root
  config.vm.provision "shell", name:"Install Domino server", privileged:true, inline: "sudo su; cd /home/vagrant/linux64; pwd; who; sudo ./install -f /home/vagrant/installer.properties -i silent "
  config.vm.provision "shell",inline: "echo 'Domino Installation complete'; date"

  if DOMINO_INSTALL_SELECTION >= 1  # install fixpack
    # silent install of domino fixpack
    config.vm.provision "shell", name: "Install Domino fixpack", privileged:true,inline: <<-SHELL
       sudo su
       cd /home/vagrant/
       tar xf #{DOMINO_SERVER_FIXPACK_TAR}
       echo "installation_type = 2" >> linux64/domino/script.dat
       NUI_NOTESDIR=/opt/hcl/domino/
       export NUI_NOTESDIR
       cd linux64/domino
       ./install -script ./script.dat
    SHELL
    config.vm.provision "shell",inline: "echo 'domino FP install completed';date"
  end

  if DOMINO_INSTALL_SELECTION >= 2   # install interum fix as well
    # silent install of domino hot fix
    config.vm.provision "shell", name:  "Install interum fix", privileged:true,inline: <<-SHELL
       sudo su
       cd /home/vagrant/
       /bin/rm -rf linux64
       tar xf 901FP10HF266-linux64.tar 
       echo "installation_type = 2" >> linux64/script.dat
       NUI_NOTESDIR=/opt/hcl/domino/
       export NUI_NOTESDIR
       cd linux64
       ./install -script ./script.dat
    SHELL
    config.vm.provision "shell",inline: "echo 'domino HF install completed';date" 
  end


  # Setup environment variable for external Java applications
  config.vm.provision "shell",inline: "echo 'export LD_LIBRARY_PATH=/opt/hcl/domino/notes/latest/linux/' >> ~/.bash_profile", privileged:false
  
  # Use this command to source the profile later
  SOURCE_PROFILE="source /home/vagrant/.bash_profile"

  
  ## Install SVN, for convenience
  config.vm.provision "shell",inline: "sudo yum -y install svn", privileged:true
  
  
  ## Upload compiled JARs
  config.vm.provision "file", source: "dist", destination: "/home/vagrant/dist", run:"always"

  
  ## Upload distribution support files
  config.vm.provision "file", source: "dist-support", destination: "/home/vagrant/dist-support", run:"always"

  
  ## Copy distribution files to /local/notesjava
  config.vm.provision "shell", name: "Copy dist JARs to NotesJava", privileged:true, inline: "cp /home/vagrant/dist/*.jar /local/notesjava/", run:"always"
  
  
  ## Deploy Notes ID
  config.vm.provision "file", source: "#{NOTES_ID}", destination: "/local/notesjava/dist-support-user.id", run:"always"
  
  
  ## Copy templates necessary for standalone Notes Java app 
  config.vm.provision "shell", name: "Copy pernames.ntf template to NotesJava", privileged:true, inline: "sudo cp /local/dominodata/pernames.ntf /local/notesjava/; sudo chown vagrant:vagrant /local/notesjava/pernames.ntf" 

  
  ## Deploy notes.ini to the expected locations
  # 'vagrant' user must have write access for notes.ini
  config.vm.provision "shell", privileged:true, inline: "chown vagrant /home/vagrant/dist-support/notes.ini; chmod 744 /home/vagrant/dist-support/notes.ini" #####, run:"always" 
  # Copy to Domino data directory
  config.vm.provision "shell",inline: "ln -s -f /home/vagrant/dist-support/notes.ini  /local/notesjava/notes.ini"   #####, run:"always"
  # Copy to home directory
  config.vm.provision "shell",inline: "ln -s -f /home/vagrant/dist-support/notes.ini  /home/vagrant/notes.ini"      #####, run:"always"   
  # To Java application directory
  #config.vm.provision "shell",inline: "ln -s -f /home/vagrant/dist-support/notes.ini /home/vagrant/dist/notes.ini" #####, run:"always" 


#  # Copy the Java tar to prepare for setup
#  config.vm.provision "file", source: "#{JAVA_TAR_PATH}", destination: "/home/vagrant/"
  # Setup Java directory
  config.vm.provision "shell", inline: "mkdir /opt/java/", privileged:true
  config.vm.provision "shell", inline: "chown vagrant /opt/java/", privileged:true



  ## SDKMAN install - do this as late as possible, since it tends to fail after Java updates
  # Install using an external script, to avoid issues with the environment
  config.vm.provision "shell", path: "./dist-support/SDKMAN_Setup.sh", privileged:false

 # Use this command later to include SDKMAN and the installed SDKs in the environment
  SOURCE_SDKMAN = "source '/home/vagrant/.sdkman/bin/sdkman-init.sh'"

#  ## Create fresh names.nsf from template
#  config.vm.provision "shell", privileged:true ,inline: "sudo yum -y install expect"
#  # Copy Java helper applications
#  config.vm.provision "shell",inline: "cp /vagrant/JavaTest/CreateNamesDatabase.jar /home/vagrant"
#  config.vm.provision "shell",inline: "cp /vagrant/JavaTest/Notes.jar /home/vagrant"
#  config.vm.provision "shell",inline: "cp /vagrant/CreateNamesDatabase.exp /home/vagrant", run:"always"
#  # Run CreateNamesDatabase application as vagrant (the Domino user)
#  #config.vm.provision "shell",inline: "sudo su - vagrant -c \"cd /home/vagrant; java -jar CreateNamesDatabase.jar\"", run:"always"
#  #config.vm.provision "shell",inline: "sudo su - vagrant -c \"cd /home/vagrant; yes #{NOTES_ID_PASSWORD} | java -jar CreateNamesDatabase.jar\"", run:"always"
#  config.vm.provision "shell",inline: "sudo su - vagrant -c \"cd /home/vagrant; expect CreateNamesDatabase.exp #{NOTES_ID_PASSWORD}\""
 
#  config.vm.provision "shell", name: "Cleanup names.nsf", inline: "rm -f /local/notesdata/names.nsf", run:"always"
#  # Create names.nsf by passing the password as a sensitive environment variable
#  #config.vm.provision "shell", name: "Create names.nsf", inline: "sudo -E su - vagrant -c \"echo $PASSWORD; whoami;\"", sensitive:true, env: {"PASSWORD" => NOTES_ID_PASSWORD}, run:"always"
#  config.vm.provision "shell", name: "Create names.nsf", inline: "sudo -E su - vagrant -c \"cd dist; java -jar CreateNamesDatabase.jar\"", sensitive:true, env: {"PASSWORD" => NOTES_ID_PASSWORD}, run:"always"

  


  # Configure Domino server in silent mode.  This must run as root
  config.vm.provision "shell", name: "Copy setup.json to dest", privileged:true, inline: "cp /home/vagrant/dist-support/setup.json /local/dominodata; chown domino:domino /local/dominodata/setup.json"   #####, run:"always" 
  config.vm.provision "shell", name: "Configure Domino server", privileged:false, inline: "sudo -E su - domino -c \"cd /local/dominodata; pwd; whoami; /opt/hcl/domino/bin/server -autoconf ./setup.json\""   #####, run:"always" 
  config.vm.provision "shell",                                                   inline: "echo 'Domino automated setup complete'; date"   #####, run:"always" 
  
  config.vm.provision "shell",inline: "cat /local/dominodata/IBM_TECHNICAL_SUPPORT/autoconfigure.log" #####, run:"always"
  
  config.vm.provision "shell", name: "Copy new user ID to NotesJava", privileged:true, inline: "cp /local/dominodata/idp-demo-user.id /local/notesjava/user.id; chown vagrant:vagrant /local/notesjava/user.id" 
  
  config.vm.provision "shell", inline: "mkdir /home/vagrant/dist-id-files", privileged:false
  
  config.vm.provision "shell", name: "Copy IDs to dist-id-files for each access from host if Guest Additions folder sync is working", privileged:true, inline: "cp /local/dominodata/*.id /home/vagrant/dist-id-files; chown vagrant:vagrant /home/vagrant/dist-id-files/*.id", run:"always" 

  # Install/configure java, jetty, and the idp
  config.vm.provision "file", source: "idp_config", destination: "/tmp/idp_config", run:"always"
  config.vm.provision "shell", name: "fix EOL", privileged:true, inline: "find /tmp/idp_config -type f | xargs sed -i -e 's/\r$//'"

  config.vm.provision "shell", name: "install java/jetty", privileged:true, path: "idp_scripts/jetty_install.sh"
  config.vm.provision "shell", name: "install idp", privileged:true, path: "idp_scripts/idp_install.sh"

  config.vm.provision "shell", name: "config idp", privileged:true, path: "idp_scripts/idp_config.sh", run:"always"

  # Allow access to idp through host
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  
  # Output a list of actions the user can run.  Run this last!
  config.vm.provision "shell",inline: "cat /home/vagrant/dist-support/CommandHelp.txt" , run:"always" 
  
end
