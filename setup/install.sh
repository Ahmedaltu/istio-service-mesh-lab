#!/bin/bash
# Istio Service Mesh Lab — Full Setup Script
# Tested on Ubuntu 22.04, GCP n2-standard-4, April 2026
# Ahmed Altuwaijari — Aalto University

set -e

echo "=== Step 1: Install dependencies ==="
sudo apt-get update && sudo apt-get install -y curl wget git docker.io
sudo usermod -aG docker $USER
newgrp docker

echo "=== Step 2: Install Kind ==="
curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
sudo install /tmp/kind /usr/local/bin/kind
kind version

echo "=== Step 3: Install kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
kubectl version --client

echo "=== Step 4: Create Kind cluster ==="
kind create cluster --name istio-lab
kubectl get nodes

echo "=== Step 5: Download and install Istio ==="
curl -L https://istio.io/downloadIstio | sh -

# Find the istio directory
ISTIO_DIR=$(ls -d istio-* | head -1)
export PATH=$PWD/$ISTIO_DIR/bin:$PATH
echo "export PATH=$PWD/$ISTIO_DIR/bin:\$PATH" >> ~/.bashrc

istioctl version

echo "=== Step 6: Install Istio with demo profile ==="
# demo profile includes: istiod, ingress gateway, egress gateway
istioctl install --set profile=demo -y

echo "=== Step 7: Verify Istio installation ==="
kubectl get pods -n istio-system

echo "=== Step 8: Enable sidecar injection for default namespace ==="
# This label tells Istio to automatically inject Envoy sidecar into all pods
kubectl label namespace default istio-injection=enabled

echo "=== Step 9: Deploy Bookinfo sample application ==="
# Bookinfo has 4 microservices: productpage, details, reviews (v1/v2/v3), ratings
# Each pod will show 2/2 READY — app container + Envoy sidecar
kubectl apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo.yaml

echo "=== Waiting for pods to be ready ==="
kubectl wait --for=condition=ready pod --all --timeout=120s

echo "=== Step 10: Verify the app is running through the mesh ==="
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" \
  -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

echo "=== Step 11: Apply destination rules ==="
# destination-rule-all.yaml defines subsets for all service versions
# Note: IST0173 warnings for v2-mysql/v2-mysql-vm subsets are expected
# if you have not deployed the MySQL-based ratings variants
kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/destination-rule-all.yaml

echo "=== Step 12: Check proxy status across the mesh ==="
istioctl proxy-status

echo "=== Step 13: Analyze mesh configuration ==="
istioctl analyze

echo ""
echo "=== Setup complete! ==="
echo "Istio service mesh is running with Bookinfo application."
echo "Run traffic management commands from the traffic-management/ directory."
