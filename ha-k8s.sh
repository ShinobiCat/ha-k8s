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

# Apply  kubernetes configuration to MASTER node
RETRY_FILE="/tmp/k8s_retry_point"
RETRY_COUNT_FILE="/tmp/k8s_retry_count"
current_ip=$(hostname -I | awk '{print $1}')

apply_config() {
    config_url=$1
    echo "Applying $config_url..."

    kubectl apply -f $config_url
    if [ $? -ne 0 ]; then
        echo "Failed to apply $config_url."

        # Increment retry count
        if [[ -f $RETRY_COUNT_FILE ]]; then
            retries=$(cat $RETRY_COUNT_FILE)
            retries=$((retries+1))
            echo $retries > $RETRY_COUNT_FILE
        else
            echo 1 > $RETRY_COUNT_FILE
            retries=1
        fi

        # Check if max retries have been reached
        if [[ $retries -ge 3 ]]; then
            echo "Maximum retries reached. Aborting."
            exit 1
        else
            echo "Retrying in 3 minutes..."
            echo "$config_url" > $RETRY_FILE
            sleep 180
            exec $0  # Restart the script
        fi
    else
        # If the command is successful, remove the retry point and reset the retry count
        if [[ -f $RETRY_FILE && $(cat $RETRY_FILE) == $config_url ]]; then
            rm $RETRY_FILE
            rm $RETRY_COUNT_FILE
        fi
    fi
}

# If the validation passes:
if [[ "$(hostname)" == "$CTRL01" && "$CTRL01" == "$MASTER" && "$current_ip" == "$CTRL01IP" ]]; then
    echo "Applying Kubernetes configurations..."

    if [[ ! -f $RETRY_FILE || $(cat $RETRY_FILE) == "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/kubeadm-flannel.yaml" ]]; then
        apply_config "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/kubeadm-flannel.yaml"
    fi

    if [[ ! -f $RETRY_FILE || $(cat $RETRY_FILE) == "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/crds.yaml" ]]; then
        apply_config "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/crds.yaml"
    fi

    if [[ ! -f $RETRY_FILE || $(cat $RETRY_FILE) == "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/kilo-kubeadm-flannel.yaml" ]]; then
        apply_config "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/kilo-kubeadm-flannel.yaml"
    fi

    if [[ ! -f $RETRY_FILE || $(cat $RETRY_FILE) == "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/wg-peers.yaml" ]]; then
        apply_config "https://raw.githubusercontent.com/ShinobiCat/ha-k8s/main/yaml/wg-peers.yaml"
    fi

else
    echo "Validation failed. This host does not match the required criteria, skipping Kubernetes configurations."
fi

# Remove the RETRY_FILE at the end of the script if it exists
if [[ -f $RETRY_FILE ]]; then
    rm $RETRY_FILE
fi

# Progressbar function
print_progress() {
    percent=$1
    chars=$(($percent/2))
    printf "\r["
    for ((i=0; i<$chars; i++)); do
        printf "#"
    done
    for ((i=$chars; i<50; i++)); do
        printf "."
    done
    printf "] $percent%%"
}

echo "Extracting necessary parameters for kubeadm join..."
print_progress 10
sleep 2

TOKEN=$(kubeadm token create)
DISCOVERY_TOKEN_CA_CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
CERTIFICATE_KEY=$(kubeadm init phase upload-certs --upload-certs | tail -1)
print_progress 30

# Node join function and health check
join_node() {
    node_type=$1
    node_name=$2

    if [[ "$node_type" == "control-plane" ]]; then
        echo "\nJoining control plane node: $node_name"
        print_progress 50
        ssh $node_name "kubeadm join --control-plane --token $TOKEN --discovery-token-ca-cert-hash $DISCOVERY_TOKEN_CA_CERT_HASH --certificate-key $CERTIFICATE_KEY"
    elif [[ "$node_type" == "worker" ]]; then
        echo "\nJoining worker node: $node_name"
        print_progress 70
        ssh $node_name "kubeadm join --token $TOKEN --discovery-token-ca-cert-hash $DISCOVERY_TOKEN_CA_CERT_HASH"
    else
        echo "Unknown node type: $node_type"
        exit 1
    fi

    # Check for success of join command
    if [ $? -ne 0 ]; then
        echo "Failed to join node: $node_name. Running kubeadm reset on the node and aborting."
        ssh $node_name "kubeadm reset -f"
        exit 1
    fi

    # Retry-loop to validate if the node has joined successfully and is in Ready state (retries=20  # 15 seconds * 20 = 5 minutes)
    while [[ $retries -gt 0 ]]; do
        NODE_STATUS=$(kubectl get nodes $node_name --no-headers | awk '{print $2}')
        if [[ "$NODE_STATUS" == "Ready" ]]; then
            echo "\nNode $node_name has joined successfully."
            return
        else
            echo "Waiting for node $node_name to become Ready. Retries left: $retries"
            sleep 15
            retries=$((retries-1))
        fi
    done

    echo "Node $node_name hasn't joined successfully within the expected time. Status is $NODE_STATUS. Running kubeadm reset on the node and aborting."
    ssh $node_name "kubeadm reset -f"
    exit 1
}

# Control Plane nodes
for node in $CTRL01 $CTRL02 $CTRL03; do
    join_node "control-plane" $node
done

# Worker nodes
for node in $NODE01 $NODE02 $NODE03; do
    join_node "worker" $node
done

print_progress 100
echo "\nAll nodes have been processed!"
