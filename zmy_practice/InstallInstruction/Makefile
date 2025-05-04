# variables
PLATFORM = $(shell uname -s)

# Install docker ce - Ubuntu
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker run hello-world



# Install Kubectl
ifeq ($(PLATFORM), "x86_64")
# download
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# checksum
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

	@echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# install with root user
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

	kubectl version --client

endif

ifeq ($(PLATFORM), "arm64")
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"

	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256"

	@echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

	kubectl version --client
endif

# miniKube installation

ifeq ($(PLATFORM), "x86_64")
	@echo "Installing miniKube"

	curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

	sudo apt install conntrack

	VERSION="v1.33.0"
	wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
	sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
	rm -f crictl-$VERSION-linux-amd64.tar.gz

	wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.17/cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb
	apt-get install ./cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb

	CNI_PLUGIN_VERSION=v1.7.1
	CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz" # change arch if not on amd64
	CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"

	curl -LO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
	sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
	sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
	rm "$CNI_PLUGIN_TAR"
endif
