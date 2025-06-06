# variables
PLATFORM = $(shell uname -m)

install_supports:
	sudo apt-get update
	sudo apt-get install -y apt-transport-https ca-certificates curl gpg

uninstall_docker_ce:
	sudo rm -rf /var/lib/docker
	sudo rm -rf /var/lib/containerd
	sudo rm /etc/apt/sources.list.d/docker.list
	sudo rm /etc/apt/keyrings/docker.asc
	sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

install_docker_ce:
	# Install docker ce - Ubuntu
	# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	echo \
		"deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
		$$(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$$VERSION_CODENAME}") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update

	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	sudo docker run hello-world



# Install Kubectl
install_kubectl:
ifeq ($(PLATFORM), x86_64)
# download
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# checksum
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

	echo "$$(ls)"

	echo "$$(cat kubectl.sha256)  kubectl" | sha256sum --check
# install with root user
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

	kubectl version --client
endif

ifeq ($(PLATFORM), arm64)
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"

	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256"

	echo "$$(cat kubectl.sha256)  kubectl" | sha256sum --check

	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

	kubectl version --client
endif

install_minikube:
# miniKube installation
ifeq ($(PLATFORM), x86_64)
	@echo "Installing miniKube"

	curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

	sudo apt install conntrack

	VERSION=v1.33.0; \
	wget "https://github.com/kubernetes-sigs/cri-tools/releases/download/$$VERSION/crictl-$$VERSION-linux-amd64.tar.gz"; \
	sudo tar zxvf "crictl-$$VERSION-linux-amd64.tar.gz" -C /usr/local/bin; \
	rm -f "crictl-$$VERSION-linux-amd64.tar.gz"

	wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.17/cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb
	apt-get install ./cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb
	rm -f cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb

	CNI_PLUGIN_VERSION=v1.7.1; \
	CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$$CNI_PLUGIN_VERSION.tgz"; \
	CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"; \
	curl -LO "https://github.com/containernetworking/plugins/releases/download/$$CNI_PLUGIN_VERSION/$$CNI_PLUGIN_TAR"; \
	sudo mkdir -p "$$CNI_PLUGIN_INSTALL_DIR"; \
	sudo tar -xf $$CNI_PLUGIN_TAR -C "$$CNI_PLUGIN_INSTALL_DIR"; \
	rm $$CNI_PLUGIN_TAR
endif

install_k8s_tools:
	sudo apt-get install -y docker.io
	sudo mkdir -p -m 755 /etc/apt/keyrings
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y --allow-change-held-packages kubelet kubeadm kubectl
	sudo apt-mark hold kubelet kubeadm kubectl

install_calico_network_plugin:
	kubectl apply -f https://calico-v3-25.netlify.app/archive/v3.25/manifests/calico.yaml

untain_the_master:
# so that it will be available for scheduling workloads
	kubectl taint nodes --all node-role.kubernetes.io/master-


.PHONY: install_supports, uninstall_docker_ce, install_docker_ce, install_kubectl, install_minikube, install_k8s_tools, \
	install_calico_network_plugin, untain_the_master
