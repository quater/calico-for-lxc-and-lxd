# calico-for-lxc-and-lxd

This repository is a rework of the [CuiZhicheng/calico-for-lxc](https://github.com/CuiZhicheng/calico-for-lxc.git) repository in order to facilitate the development of a Calico CNI Plugin that works with LXD by the use of the current (i.e. November 2018) CNI and Calico versions.

## Deployment Scenarios

This repository contains three deployment scenarios.

* 1. LXC Scenario - Not Working - (Codeline as of 29th April 2017 without additional code changes)
* 2. LXC Scenario - Working - (Codeline as of 29th April 2017 with additional code changes)
* 3. LXD Scenario - Working - (Codeline as of 29th April 2017 with additional code changes)

### 1. LXC Scenario - Not Working - (Codeline as of 29th April 2017 without additional code changes)

The `scripts/setup_with_vanilla_code.sh` script builds the CNI and Calico's CNI plugin binaries based on the code line present as of 29th of April 2017. With those binaries it is actually possible to attach a NIC with Calico but it can only attach one NIC to one container. This is due the tuple in the ETCD database missing the container name to make the record unique per container.

#### Usage

```BASH
# Ensure to start from scratch
$ git clone https://github.com/quater/calico-for-lxc-and-lxd.git
$ vagrant destroy -f && vagrant up && vagrant ssh

# Setup test scenario
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts
vagrant@ubuntu-xenial:~$ ./setup_with_vanilla_code.sh

# Create two LXC containers
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts/lxc
vagrant@ubuntu-xenial:~$ ./lxc-create.sh lxc1
vagrant@ubuntu-xenial:~$ ./lxc-create.sh lxc2

# Attach Calico NIC to lxc1 container
vagrant@ubuntu-xenial:~$ ./lxc-attach-calico.sh lxc1 frontend

# Verify that the Calico NIC is attached
vagrant@ubuntu-xenial:~$ sudo lxc-attach -n lxc1 -- ip addr show

# Attach Calico NIC to lxc2 container
vagrant@ubuntu-xenial:~$ ./lxc-attach-calico.sh lxc2 frontend

# Verify that the Calico NIC was not successfully attached
vagrant@ubuntu-xenial:~$ sudo lxc-attach -n lxc2 -- ip addr show
```

### 2. LXC Scenario - Working - (Codeline as of 29th April 2017 with additional code changes)

The `setup_with_code_changes.sh` script builds the CNI and Calico's CNI plugin based on enhancements made by Cui Zhicheng. It basically auto generates the NIC name and introduces the container name into the tuple so that multiple containers can have Calico NICs attached.

The code differences can be looked up at  
https://github.com/quater/cni-plugin/compare/master...quater:calico-for-lxc  
https://github.com/quater/cni/compare/master...quater:calico-for-lxc

#### Usage

```BASH
# Ensure to start from scratch
$ git clone https://github.com/quater/calico-for-lxc-and-lxd.git
$ vagrant destroy -f && vagrant up && vagrant ssh

# Setup test scenario
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts
vagrant@ubuntu-xenial:~$ ./setup_with_code_changes.sh

# Create two LXC containers
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts/lxc
vagrant@ubuntu-xenial:~$ ./lxc-create.sh lxc1
vagrant@ubuntu-xenial:~$ ./lxc-create.sh lxc2

# Attach Calico NIC to container
vagrant@ubuntu-xenial:~$ ./lxc-attach-calico.sh lxc1 frontend
vagrant@ubuntu-xenial:~$ ./lxc-attach-calico.sh lxc2 frontend

# Get the IP address of the Calico NIC and store in variable
vagrant@ubuntu-xenial:~$ LXC1_IP=$(sudo lxc-attach -n lxc1 -- ip addr show | grep calico | grep -Po 'inet \K[\d.]+')
vagrant@ubuntu-xenial:~$ LXC2_IP=$(sudo lxc-attach -n lxc2 -- ip addr show | grep calico | grep -Po 'inet \K[\d.]+')

# Verify that LXC containers can ping each other
vagrant@ubuntu-xenial:~$ sudo lxc-attach -n lxc1 -- ping -c 3 $LXC2_IP
vagrant@ubuntu-xenial:~$ sudo lxc-attach -n lxc2 -- ping -c 3 $LXC1_IP

# Apply Calico profile to deny ICMP packages on ingress
vagrant@ubuntu-xenial:~$ cat << EOF | calicoctl apply -f -
- apiVersion: v1
  kind: profile
  metadata:
    name: frontend
    labels:
      role: frontend
  spec:
    ingress:
    - action: deny
      protocol: icmp
      source:
        selector: role == 'frontend'
EOF

# Verify that LXC containers cannot ping each other anymore. Verifing that Calico is doing its work!
vagrant@ubuntu-xenial:~$ sudo lxc-attach -n lxc1 -- ping -W 1 -c 3 $LXC2_IP
vagrant@ubuntu-xenial:~$ sudo lxc-attach -n lxc2 -- ping -W 1 -c 3 $LXC1_IP

# Detach Calico NICs
vagrant@ubuntu-xenial:~$ ./lxc-detach-calico.sh lxc1 frontend
vagrant@ubuntu-xenial:~$ ./lxc-detach-calico.sh lxc2 frontend

# Destroy LXC containers
vagrant@ubuntu-xenial:~$ ./lxc-delete.sh lxc1
vagrant@ubuntu-xenial:~$ ./lxc-delete.sh lxc2
```

### 3. LXD Scenario - Working - (Codeline as of 29th April 2017 with additional code changes)

The `setup_with_code_changes.sh` script builds the CNI and Calico's CNI plugin based on enhancements made by Cui Zhicheng. It basically auto generates the NIC name and introduces the container name into the tuple so that multiple containers can have Calico NICs attached.

The code differences can be looked up at  
https://github.com/quater/cni-plugin/compare/master...quater:calico-for-lxc  
https://github.com/quater/cni/compare/master...quater:calico-for-lxc

#### Usage

```BASH
# Ensure to start from scratch
$ git clone https://github.com/quater/calico-for-lxc-and-lxd.git
$ vagrant destroy -f && vagrant up && vagrant ssh

# Setup test scenario
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts
vagrant@ubuntu-xenial:~$ ./setup_with_code_changes.sh

# Initialize LXD - Newer versions of LXD can actually be configured automatically but this version does not.
# Simply use all default settings.
vagrant@ubuntu-xenial:~$ sudo lxd init

# Create new LXD profile without any NIC
vagrant@ubuntu-xenial:~$ sudo lxc profile create calico

# Create two LXD containers
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts/lxd
vagrant@ubuntu-xenial:~$ ./lxd-create.sh lxd1 calico
vagrant@ubuntu-xenial:~$ ./lxd-create.sh lxd2 calico

# Attach Calico NIC to containers
vagrant@ubuntu-xenial:~$ ./lxd-attach-calico.sh lxd1 frontend
vagrant@ubuntu-xenial:~$ ./lxd-attach-calico.sh lxd2 frontend

# Get the IP address of the Calico NIC and store in variable
vagrant@ubuntu-xenial:~$ LXD1_IP=$(sudo lxc exec lxd1 -- ip addr | grep -A 3 calico | grep -Po 'inet \K[\d.]+')
vagrant@ubuntu-xenial:~$ LXD2_IP=$(sudo lxc exec lxd2 -- ip addr | grep -A 3 calico | grep -Po 'inet \K[\d.]+')

# Verify that LXC containers can ping each other
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd1 -- ping -c 3 $LXD2_IP
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd2 -- ping -c 3 $LXD1_IP

# Apply Calico profile to deny ICMP packages on ingress
vagrant@ubuntu-xenial:~$ cat << EOF | calicoctl apply -f -
- apiVersion: v1
  kind: profile
  metadata:
    name: frontend
    labels:
      role: frontend
  spec:
    ingress:
    - action: deny
      protocol: icmp
      source:
        selector: role == 'frontend'
EOF

# Verify that LXC containers cannot ping each other anymore. Verifing that Calico is doing its work!
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd1 -- ping -W 1 -c 3 $LXD2_IP
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd2 -- ping -W 1 -c 3 $LXD1_IP

# Detach Calico NICs
vagrant@ubuntu-xenial:~$ ./lxd-detach-calico.sh lxd1 frontend
vagrant@ubuntu-xenial:~$ ./lxd-detach-calico.sh lxd2 frontend

# Destroy LXC containers
vagrant@ubuntu-xenial:~$ ./lxd-delete.sh lxd1
vagrant@ubuntu-xenial:~$ ./lxd-delete.sh lxd2
```
