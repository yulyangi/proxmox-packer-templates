#!/usr/bin/env bash

set -e

# desable interactive shell
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# install a container runtime
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/' /etc/containerd/config.toml
sudo sed -i 's/snapshotter = \"overlayfs\"/snapshotter = \"native\"/' /etc/containerd/config.toml
sudo sed -i 's/systemd_cgroup \= true/systemd_cgroup \= true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# enable packet forvarding
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# add k8s modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# install kubeadm, kubelet, kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# create a cluster
# sudo kubeadm init --control-plane-endpoint=192.168.0.101 --node-name `hostname` --pod-network-cidr=10.244.0.0/16

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/
# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# You can now join any number of control-plane nodes by copying certificate authorities
# and service account keys on each node and then running the following as root:

#   kubeadm join 192.168.0.101:6443 --token <token> \
# 	--discovery-token-ca-cert-hash sha256:<hash> \
# 	--control-plane

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.0.101:6443 --token <token> \
# 	--discovery-token-ca-cert-hash sha256:<hash>
