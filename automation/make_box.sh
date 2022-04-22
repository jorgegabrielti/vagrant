#!/bin/bash

# STEPS:
- Distro detect
```bash
# Test: [OK]
distro_detect () {
  echo -e "\e[40;32;1m[TASK]: distro_detect\e[m\n"
  DISTRO="$(grep -Ei 'PRETTY_NAME' /etc/os-release | cut -d'=' -f2 | tr -d '"'  | cut -d'.' -f1,2)"
  
  case ${DISTRO} in
    "Ubuntu 20.04")
      echo -e "\tDistro: [${DISTRO}]\n"
    ;;
    *)
      echo "Distro: [${DISTRO}] ==> Not supported!"
    ;;
  esac
}

```

- Update system
```bash
dnf install -y epel-release
dnf update -y
```

- Install commun packages
```bash
dnf install -y \
  vim \
  curl \
  wget \
  tmux \
  mtr \
  tcpdump \
  netcat
```

- Install Development Tools
```bash
dnf groupinstall -y 'Development Tools'
```

- Install Vbox Guest Additions
```bash
dnf install -y \
  gcc \
  make \
  perl \
  kernel-devel \
  kernel-headers \
  bzip2 \
  dkms
```

```bash
dnf update -y kernel-*
```

```bash
mount /dev/cdrom /media && cd /media
./VBoxLinuxAdditions.run
```

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