#!/bin/bash

# Update and upgrade system on first boot
echo "Updating and upgrading system..."
sudo apt update -y && sudo apt upgrade -y

# Set ENV variables
echo "Setting ENV variables..."
read -p "What username do you prefer (default: supernerd): " MYUSR
MYUSR=${MYUSR:-supernerd}
read -p "loadbalancer DNS name (default: load01): " LB01
LB01=${LB01:-load01}
read -p "Loadbalancer private IP (default: 192.168.111.111): " LB01IP
LB01IP=${LB01IP:-192.168.111.111}
read -p "Enter value for CTRL01 (default: master01): " CTRL01
CTRL01=${CTRL01:-master01}
read -p "Enter value for CTRL01IP (default: 192.168.0.201): " CTRL01IP
CTRL01IP=${CTRL01IP:-192.168.0.201}
read -p "Enter value for CTRL02 (default: master02): " CTRL02
CTRL02=${CTRL02:-master02}
read -p "Enter value for CTRL02IP (default: 192.168.0.202): " CTRL02IP
CTRL02IP=${CTRL02IP:-192.168.0.202}
read -p "Enter value for CTRL03 (default: master03): " CTRL03
CTRL03=${CTRL03:-master03}
read -p "Enter value for CTRL03IP (default: 192.168.0.203): " CTRL03IP
CTRL03IP=${CTRL03IP:-192.168.0.203}
read -p "Enter value for NODE01 (default: worker01): " NODE01
NODE01=${NODE01:-worker01}
read -p "Enter value for NODE01IP (default: 192.168.0.101): " NODE01IP
NODE01IP=${NODE01IP:-192.168.0.101}
read -p "Enter value for NODE02 (default: worker02): " NODE02
NODE02=${NODE02:-worker02}
read -p "Enter value for NODE02IP (default: 192.168.0.102): " NODE02IP
NODE02IP=${NODE02IP:-192.168.0.102}
read -p "Enter value for NODE03 (default: worker03): " NODE03
NODE03=${NODE03:-worker03}
read -p "Enter value for NODE03IP (default: 192.168.0.103): " NODE03IP
NODE03IP=${NODE03IP:-192.168.0.103}
read -p "Enter value for Wireguard public key1: " WGPK1
read -p "Enter value for WGIP1 (default: 172.16.16.16/32): " WGIP1
WGIP1=${WGIP1:-172.16.16.16/32}
read -p "Enter value for Wireguard public key2: " WGPK2
read -p "Enter value for WGIP2 (default: 172.16.16.32/32): " WGIP2
WGIP2=${WGIP2:-172.16.16.32/32}
read -p "Enter value for Wireguard public key3: " WGPK3
read -p "Enter value for WGIP3 (default: 172.16.16.48/32): " WGIP3
WGIP3=${WGIP3:-172.16.16.48/32}

cat << EOF | sudo tee /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
KUBECONFIG="/etc/kubernetes/admin.conf"
MYUSR=$MYUSR
LB01=$LB01
LB01IP=$LB01IP
CTRL01=$CTRL01
CTRL01IP=$CTRL01IP
CTRL02=$CTRL02
CTRL02IP=$CTRL02IP
CTRL03=$CTRL03
CTRL03IP=$CTRL03IP
NODE01=$NODE01
NODE01IP=$NODE01IP
NODE02=$NODE02
NODE02IP=$NODE02IP
NODE03=$NODE03
NODE03IP=$NODE03IP
MASTER=$CTRL01
PODNW=10.244.0.0/16
VISUAL=nano
EDITOR=nano
WGPK1=$WGPK1
WGPK2=$WGPK2
WGPK3=$WGPK3
WGIP1=$WGIP1
WGIP2=$WGIP2
WGIP3=$WGIP3
EOF

# Set DNS for hosts
echo "Setting DNS for hosts..."
cat << EOF >> | sudo tee /etc/hosts

# Bet & Yan <3
$LB01IP $LB01 $LB01
$CTRL01IP $CTRL01 $CTRL01
$CTRL02IP $CTRL02 $CTRL02
$CTRL03IP $CTRL03 $CTRL03
$NODE01IP $NODE01 $NODE01
$NODE02IP $NODE02 $NODE02
$NODE03IP $NODE03 $NODE03
EOF

# Add kubernetes repo and install required components
echo "Adding Kubernetes repo..."
sudo apt install -y apt-transport-https ca-certificates curl

curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt update && sudo apt install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl kubernetes-cni

# IP forwarding and other required network settings
echo "Setting up IP forwarding..."
echo br_netfilter | sudo tee -a /etc/modules-load.d/kubernetes.conf
sudo modprobe br_netfilter

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

# Install a supported containerd version
echo "Installing containerd..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt install containerd.io

# Install a supported containerd version
echo "Installing a supported containerd version..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt install containerd.io

# Creating a containerd config file and setting the required configuration flag
echo "Setting up containerd configuration..."
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable containerd
sudo systemctl restart containerd

# Install kgctl on local host for wireguard kilo management
echo "Installing kgctl for Wireguard Kilo management..."
wget https://github.com/squat/kilo/releases/download/0.6.0/kgctl-linux-arm64
chmod +x kgctl-linux-arm64
sudo mv kgctl-linux-arm64 /usr/local/bin/kgctl

# Install Helm
echo "Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
sudo apt-get update
sudo apt-get install helm

# Prepare Flannel for pod installation
echo "Preparing Flannel..."
sudo mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-arm64-v1.2.0.tgz
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-arm64-v1.2.0.tgz

# Create a normal user and give it sudo permissions
read -p "Enter value for MYUSR: " MYUSR
sudo adduser $MYUSR
sudo usermod -aG sudo $MYUSR

# Pull kubeadm images if host is control plane
echo "Pulling kubeadm images..."
sudo kubeadm config images pull

# Initialize cluster with kubeadm if control plane is MASTER
read -p "Enter value for LB01: " LB01
read -p "Enter value for PODNW: " PODNW
echo "Initializing Kubernetes cluster..."
sudo kubeadm init --control-plane-endpoint $LB01 --pod-network-cidr=$PODNW --upload-certs --ignore-preflight-errors NumCPU --v=5

# Switch user then show nodes and pods
echo "Switching user and displaying Kubernetes nodes and pods..."
sudo su $MYUSR -c "kubectl get nodes"
sudo su $MYUSR -c "kubectl get pods --all-namespaces"
