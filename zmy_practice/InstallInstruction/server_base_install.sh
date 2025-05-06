#!/bin/bash

# Ensure the script stops on error
set -e

# Run the Makefile target
echo "------Start installation"
make install_docker_ce

make install_kubecttl

make install_minicube

echo "-------Completed"
