#!/bin/bash

## see: https://www.youtube.com/watch?v=-OOnGK-XeVY

DOMAIN=${DOMAIN:=educanube.com}
USERNAME=${USERNAME:=jcperezamin}
PASSWORD=${PASSWORD:openshift}


yum install -y epel-release

yum install -y git wget zile nano net-tools
yum install -y docker
yum install -y python-cryptography pyOpenSSL.x86_64

## WORKAROUND as per https://github.com/openshift/openshift-ansible/issues/3111
## TODO: yum install ansible
yum install -y "@Development Tools" python2-pip openssl-devel python-devel
pip install -Iv ansible==2.3.0.0

mkdir -p ~/workspace && cd ~/workspace
git clone http://github.com/openshift/openshift-ansible
git clone http://github.com/jcperezamin/installcentos

cat <<EOD > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 console console.${DOMAIN}
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOD

cat /dev/zero | ssh-keygen -t rsa -q -N ""
ssh-copy-id root@console.${DOMAIN}

######################################################################################
## THIS IS HIGHLY INSECURE AND ONLY ACCEPTABLE IN DEVELOPMENT
echo 'INSECURE_REGISTRY="--insecure-registry 172.30.0.0/16"' >> /etc/sysconfig/docker
######################################################################################


#################################################################################
## THIS IS HIGHLY INSECURE AND ONLY ACCEPTABLE IN DEVELOPMENT
#echo 'INSECURE_REGISTRY="--insecure-registry"' >> /etc/sysconfig/docker
#################################################################################

########################################################################################################
#See: http://blog.hashbangbash.com/2014/11/docker-devicemapper-fix-for-device-or-resource-busy-ebusy/
cp -p /usr/lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service.ORIGINAL
## NO, IT DOES NOT WORK:: sed 's/MountFlags=slave/MountFlags=private/' -i /usr/lib/systemd/system/docker.service
########################################################################################################


systemctl restart docker
systemctl enable docker

cd ~/workspace
cat installcentos/inventory.erb | sed "s/educanube.com/${DOMAIN}/g" > /tmp/installcentos-inventory.erb
ansible-playbook -i /tmp/installcentos-inventory.erb openshift-ansible/playbooks/byo/config.yml

#################################################################
##            PLEASE CHOOSE BETTER CREDENTIALS
##
## Note: make sure that the username you choose corresponds to
##       an existing username in the system. Also, make sure
##       that such user belongs to group docker, like below:
##
##       $ usermod -a -G docker gshipley
##
htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}
#################################################################
