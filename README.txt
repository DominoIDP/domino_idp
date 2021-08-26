# Before starting, download the HCL Domino 12 installer and fixpack installer
# to the vagrant_cached_domino_mfa_files subdirectory, or create symlinks in
# the directory pointing to them

# To start an instance with NO logging (which makes it difficult to see errors):
vagrant up
vagrant ssh

# Wrapper scripts with output written to log file:
./vagrant_up.sh
./vagrant_ssh.sh


View the contents of the dist-support/CommandHelp.text for more details.  This file will also be displayed followed each ./vagrant_up.sh operation for your continued reference.


