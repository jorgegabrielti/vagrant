#!/bin/bash
echo "####################################################################################"
echo "#                             Vagrant provision                                    #"
echo "####################################################################################"
echo "Install Docker Engine"

sudo dnf update -y
sudo dnf check-update
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo docker --version
sudo systemctl enable --now docker
sudo systemctl status docker
sudo usermod -aG docker vagrant
docker run --rm hello-world

