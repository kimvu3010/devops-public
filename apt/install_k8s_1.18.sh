#!/bin/bash
## INSTALL DOCKER
apt-get update -y && apt-get install software-properties-common jq apt-transport-https nano rsync telnet wget curl git htop ca-certificates gnupg nethogs sudo -y
apt-get install -y lvm2 nfs-common

curl -fsSL https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}')/gpg |  gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}') \
  $(lsb_release -cs) stable" |  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y && apt-get install containerd.io docker-ce=5:19.03.15~3-0~debian-$(lsb_release -cs) docker-ce-cli=5:19.03.15~3-0~debian-$(lsb_release -cs) -y
usermod -aG docker $(whoami)

cat >/etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
	  "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl restart docker
systemctl enable docker

## INSTALL DOCKER-COMPOSE
curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.1/contrib/completion/bash/docker-compose \
    -o /etc/bash_completion.d/docker-compose


# INSTALL K8S
swapoff -a
rm /etc/sysctl.d/k8s.conf
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF |  tee /etc/sysctl.d/99-k8s.conf
net.ipv4.conf.all.proxy_arp=1
fs.inotify.max_user_watches = 262144
net.ipv4.ip_forward=1
net.ipv4.ip_nonlocal_bind = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.neigh.default.gc_thresh1 = 80000
net.ipv4.neigh.default.gc_thresh2 = 90000
net.ipv4.neigh.default.gc_thresh3 = 100000

EOF

sysctl --system

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key add -
cat <<EOF |  tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y
apt-get install -y kubelet=1.18.20-00 kubeadm=1.18.20-00 kubectl=1.18.20-00
apt-mark hold kubelet kubeadm kubectl docker-ce docker-ce-cli
systemctl restart kubelet
systemctl enable kubelet && kubelet --version
exit 0