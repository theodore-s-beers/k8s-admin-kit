#! /usr/bin/env bash

set -Eeuo pipefail

# Configure as needed
ACCOUNT_DIR="$HOME/cluster-accounts"
CLUSTER_NAME='test-cluster'
SERVER_ADDRESS='https://some.domain:6443'
CA_CERT='/etc/kubernetes/pki/ca.crt'

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo "Usage: $0 <username> [namespace]"
	exit 1
fi

USERNAME="$1"
NAMESPACE="${2:-}"

USER_KEY="$ACCOUNT_DIR/$USERNAME.key"
USER_CRT="$ACCOUNT_DIR/$USERNAME.crt"
OUTPUT_KUBECONFIG="$ACCOUNT_DIR/${USERNAME}-${CLUSTER_NAME}.kubeconfig"

for file in "$USER_KEY" "$USER_CRT" "$CA_CERT"; do
	if [[ ! -f "$file" ]]; then
		echo "Error: Required file $file not found"
		exit 1
	fi
done

# Clear output file if it already exists, to avoid contamination
true >"$OUTPUT_KUBECONFIG"

# Set KUBECONFIG environment to output file
export KUBECONFIG="$OUTPUT_KUBECONFIG"

# Configure cluster
kubectl config set-cluster "$CLUSTER_NAME" \
	--server="$SERVER_ADDRESS" \
	--certificate-authority="$CA_CERT" \
	--embed-certs=true

# Configure user credentials
kubectl config set-credentials "$USERNAME" \
	--client-certificate="$USER_CRT" \
	--client-key="$USER_KEY" \
	--embed-certs=true

# Configure context
kubectl config set-context "$USERNAME@$CLUSTER_NAME" \
	--cluster="$CLUSTER_NAME" \
	--user="$USERNAME"

# Set default namespace if provided
if [[ -n "$NAMESPACE" ]]; then
	kubectl config set-context "$USERNAME@$CLUSTER_NAME" --namespace="$NAMESPACE"
fi

# Set current context
kubectl config use-context "$USERNAME@$CLUSTER_NAME"

chown "$(id -un):$(id -gn)" "$OUTPUT_KUBECONFIG"
chmod 600 "$OUTPUT_KUBECONFIG"

echo "Created kubeconfig: $OUTPUT_KUBECONFIG"
