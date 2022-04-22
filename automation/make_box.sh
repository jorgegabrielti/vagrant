#!/bin/bash

# STEPS:
- Check distro
- Update system
- Install commun packages
- Install Vbox Guest Additions
- Configure vagrant user
- Configure sudoers.d to vagrant user
- Configure vagrant ssh keys
- Configure sshd_config
- Clear the trash files
- Poweroff the machine
- Export to pack the vm
- Make a box


```bash
vagrant package --base rocky-linux --output rocky-linux.box
vagrant box add --name rockylinux-8.5 --provider virtualbox rocky-linux.box
```