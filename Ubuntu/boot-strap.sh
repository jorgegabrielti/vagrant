#!/bin/bash

### Update system
sudo apt update -y
sudo apt install -y git

### Clone project
git clone https://github.com/jorgegabrielti/sre-rootsetup.git

cd sre-rootsetup
chmod +x src/sre-setup
src/sre-setup