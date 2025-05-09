# Kubeadm Setup Guide with Docker on Linux

This guide provides detailed steps to set up a Kubernetes cluster using kubeadm and Docker on Linux servers.

## System Requirements

- Linux servers (Ubuntu 22.04 recommended)
- Minimum 2 CPUs
- 2GB RAM per machine
- Full network connectivity between machines
- Unique hostname, MAC address, and product_uuid

## Step 1: Update System and Configure Prerequisites

Run on all nodes (master and workers):

```bash
# Update the system
sudo apt-get update
sudo apt-get upgrade -y

# Install necessary packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

# Disable swap (required for Kubernetes)
sudo swapoff -a
# Make swap off persistent across reboots
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Create the containerd configuration directory:

sudo mkdir -p /etc/containerd

# Generate a default configuration and modify it:

sudo containerd config default | sudo tee /etc/containerd/config.toml

# Edit the config to use systemd cgroup driver:

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd:

sudo systemctl restart containerd

# Configure network settings for Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

## Step 2: Install Docker CE (v24.0.7)

Run on all nodes:

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CE
sudo apt-get update
sudo apt-get install -y docker-ce=5:24.0.7-1~ubuntu.22.04~jammy docker-ce-cli=5:24.0.7-1~ubuntu.22.04~jammy containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Configure Docker to use systemd
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Create systemd directory for Docker
sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```

## Step 3: Install kubeadm, kubelet, and kubectl (v1.28.5)

Run on all nodes:

```bash
# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components with specific versions
sudo apt-get update
sudo apt-get install -y kubelet=1.28.5-1.1 kubeadm=1.28.5-1.1 kubectl=1.28.5-1.1

# Pin package versions to prevent accidental upgrades
sudo apt-mark hold kubelet kubeadm kubectl
```

## Step 4: Initialize Kubernetes Control Plane (Master Node Only)

Run on the master node:

```bash
# Initialize the control plane
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.28.5

# Set up kubectl config for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin (v3.27.0)

# use this look goods
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# This one could sometime cause calico pods not running
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# OR Install Flannel network plugin
# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Verify all pods are running
kubectl get pods -A

# Generate join command for worker nodes
kubeadm token create --print-join-command
```

## Step 5: Join Worker Nodes

Run the generated join command on worker nodes:

```bash
# This is an example. Use the actual command from the previous step
sudo kubeadm join <master-node-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

## Step 6: Verify Cluster

On the master node:

```bash
# Check node status
kubectl get nodes

# Verify all system pods are running
kubectl get pods -n kube-system
```

## Step 7: Deploy Test Application (Optional)

On the master node:

```bash
# Deploy nginx test deployment
kubectl create deployment nginx --image=nginx:1.25.3
kubectl expose deployment nginx --port=80 --type=NodePort

# Check service details
kubectl get svc nginx
```

## Package Versions Summary

- Docker CE: 24.0.7
- kubelet: 1.28.5
- kubeadm: 1.28.5
- kubectl: 1.28.5
- Calico: 3.27.0 (networking plugin)
- Ubuntu: 22.04 LTS (recommended OS)
- containerd.io: Latest from Docker repo

## Troubleshooting

- Check logs: `sudo journalctl -xeu kubelet`
- Verify Docker status: `sudo systemctl status docker`
- Reset kubeadm (if needed): `sudo kubeadm reset`
- Ensure firewall allows required ports:
  - TCP 6443: Kubernetes API server
  - TCP 2379-2380: etcd
  - TCP 10250: Kubelet API
  - TCP 10251: kube-scheduler
  - TCP 10252: kube-controller-manager
  - TCP 8472: Flannel VXLAN (if using Flannel)

## Some detected issues and their solution:

### Error 1: crictl with containerd

- Error Description:
```bash
# Error with containerd when running crictl pods
crictl pods
WARN[0000] runtime connect using default endpoints: [unix:///var/run/dockershim.sock unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead. 
ERRO[0000] validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/dockershim.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /var/run/dockershim.sock: connect: no such file or directory" 
```

- Solution:

```bash
# 1 Set the default endpoint for crictl:

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Create the containerd configuration directory:

sudo mkdir -p /etc/containerd

# Generate a default configuration and modify it:

sudo containerd config default | sudo tee /etc/containerd/config.toml

# Edit the config to use systemd cgroup driver:

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd:

sudo systemctl restart containerd
```

### On worker node, reset kubeadm to join another cluster

```bash
kubeadm reset

# then join another cluster
```
