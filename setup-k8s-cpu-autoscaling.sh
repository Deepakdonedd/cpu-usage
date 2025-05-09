bin/bash

set -e

echo "[1/8] Updating system and installing dependencies..."
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release docker.io jq

echo "[2/8] Starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[3/8] Installing kubectl..."
curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "[4/8] Installing kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "[5/8] Increasing ulimit for open files..."
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
ulimit -n 65535

echo "[6/8] Creating Kind cluster with extra port and config..."
cat <<EOF | kind create cluster --name cpu-demo --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 30000
EOF

echo "[7/8] Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "[8/8] Deploying Prometheus + metrics server..."
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --set prometheus.service.type=NodePort --set prometheus.service.nodePort=30000

echo "Setup complete!"
echo "Access Prometheus on: http://<EC2-PUBLIC-IP>:30000"
echo "Now deploy your CPU demo and HPA config."
