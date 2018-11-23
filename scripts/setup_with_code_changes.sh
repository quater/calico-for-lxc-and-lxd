#!/bin/bash

BUILDDIR=/home/vagrant/calico-for-lxc-and-lxd

rm -rf $BUILDDIR
mkdir -p $BUILDDIR

cd $BUILDDIR
git clone https://github.com/quater/cni.git
cd $BUILDDIR/cni
git checkout calico-for-lxc
./build.sh

cd $BUILDDIR
git clone https://github.com/quater/cni-plugin.git
cd $BUILDDIR/cni-plugin
git checkout calico-for-lxc
make build-containerized

sudo cp $BUILDDIR/cni/bin/cnitool /usr/local/bin
sudo cp $BUILDDIR/cni-plugin/dist/* /usr/local/bin
sudo curl -L -o /usr/local/bin/calicoctl https://github.com/projectcalico/calicoctl/releases/download/v1.1.3/calicoctl
sudo chmod +x /usr/local/bin/*

export ETCDIP=$(ip addr show enp0s3 | grep -Po 'inet \K[\d.]+')
# TODO: Only start ETCD if it is not running yet
etcd --name $HOSTNAME --initial-advertise-peer-urls http://$ETCDIP:2380 --listen-peer-urls http://$ETCDIP:2380 --listen-client-urls http://$ETCDIP:2379 --advertise-client-urls http://$ETCDIP:2379 --initial-cluster-token myclustername --initial-cluster ubuntu-xenial=http://$ETCDIP:2380 --initial-cluster-state new &

sudo -E bash -c 'cat > /var/snap/docker/current/config/daemon.json <<"EOF"
{
	"cluster-store":    "etcd://$ETCDIP:2379",
    "log-level":        "error",
    "storage-driver":   "aufs"
}
EOF'

sudo snap restart docker

sudo mkdir -p /etc/calico
sudo mkdir -p /etc/cni/net.d

sudo -E bash -c 'cat > /etc/calico/calicoctl.cfg <<EOF
apiVersion: v1
kind: calicoApiConfig
metadata:
spec:
  datastoreType: "etcdv2"
  etcdEndpoints: "http://$ETCDIP:2379"
EOF'

sudo bash -c 'cat > /etc/calico/ipPool.cfg <<EOF
apiVersion: v1
kind: ipPool
metadata:
  cidr: 10.1.0.0/16
spec:
  nat-outgoing: true
EOF'

sudo -E bash -c 'cat > /etc/cni/net.d/10-frontend-calico.conf <<EOF
{
    "name": "frontend",
    "type": "calico",
    "log_level": "DEBUG",
    "etcd_endpoints": "http://$ETCDIP:2379",
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "ipv4_pools": ["10.1.0.0/16"]
    }
}
EOF'

sudo mkdir -p /var/log/calico
sudo chown root:docker /var/log/calico

sudo mkdir -p /var/run/calico
sudo chown root:docker /var/run/calico

# TODO: Only create pool if it does not exists
sudo calicoctl create -f /etc/calico/ipPool.cfg

echo "Sleep for 5 seconds to ensure the calico-node starts"
sleep 5
sudo calicoctl node run
