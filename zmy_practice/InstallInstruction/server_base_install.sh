#!/bin/bash

# Ensure the script stops on error
set -e

# Run the Makefile target
echo "------Start installation"
echo "***********Uninstall docker ce if existed"
make uninstall_docker_ce || true

echo "*********Install Docker"
make install_docker_ce

echo "*********Install kubectl"
make install_kubectl

echo "*********Install minikube"
make install_minikube

echo "-------Completed"
