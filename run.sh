#!/bin/bash

ansible --version

# Install Ansible
if [ $? -ne 0 ]; then
    sudo apt-get update

    if [ $? -eq 0 ]; then
        sudo apt-get install -qqy software-properties-common
        sudo apt-add-repository ppa:ansible/ansible -y
        sudo apt-get update
        sudo apt-get install -qqy ansible
    else
        sudo yum install -y epel-release
        sudo yum install -y ansible

	if [ $? -ne 0 ]; then
	    sudo pip install ansible
        fi

        # allow nginx permission to access localhost docker
        setsebool httpd_can_network_connect on -P
    fi
fi

# Install Remote Roles
if ! sudo ansible-galaxy list | grep -q 'nginx'; then
    sudo ansible-galaxy install -r requirements.yml
    sudo chown -R $USER ~/.ansible
fi

group=docker
cmd="ansible-playbook -i hosts ./playbook.yml"

# If not in 'docker' group, need to switch to 
# group to allow to docker ops as non-root user
if [ $(id -gn) != $group ]; then
  if ! grep -q $group /etc/group; then
    sudo groupadd docker
  fi

  if ! groups | grep -q $group; then
    sudo usermod -aG docker $USER
    exec sg $group "$cmd --extra-vars \"$1\""
    return
  fi
fi

echo $cmd
$cmd --extra-vars "$1"

