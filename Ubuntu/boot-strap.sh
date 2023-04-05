#!/bin/bash

### Update system
sudo apt update -y

### Install Ansibleo
sudo apt install -y git ansible sshpass curl

### Ansible - Check installation
ansible --version

