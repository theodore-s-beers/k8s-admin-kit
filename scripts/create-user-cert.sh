#! /usr/bin/env bash

set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
	echo 'This script must be run as root (sudo)'
	exit 1
fi

# Configure as needed
ACCOUNT_DIR="$HOME/cluster-accounts"
CA_CERT='/etc/kubernetes/pki/ca.crt'
CA_KEY='/etc/kubernetes/pki/ca.key'

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <username> <group>"
	exit 1
fi

USERNAME="$1"
GROUP="$2"

USER_KEY="$ACCOUNT_DIR/$USERNAME.key"
USER_CSR="$ACCOUNT_DIR/$USERNAME.csr"
USER_CRT="$ACCOUNT_DIR/$USERNAME.crt"

for file in "$USER_KEY" "$USER_CSR" "$USER_CRT"; do
	if [[ -e "$file" ]]; then
		echo "Error: $file already exists"
		exit 1
	fi
done

echo "Generating private key for $USERNAME..."
openssl genrsa -out "$USER_KEY" 2048

echo "Generating CSR for $USERNAME in group $GROUP..."
openssl req -new -key "$USER_KEY" -out "$USER_CSR" -subj "/CN=$USERNAME/O=$GROUP"

echo "Signing certificate for $USERNAME..."
openssl x509 -req -in "$USER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
	-out "$USER_CRT" -days 365 -sha256

OWNER="${SUDO_USER:-root}"
chown "$OWNER:$OWNER" "$USER_KEY" "$USER_CSR" "$USER_CRT"
chmod 600 "$USER_KEY"

echo "Generated and signed certificate for $USERNAME in group $GROUP:"
echo "  Key:  $USER_KEY"
echo "  CSR:  $USER_CSR"
echo "  Cert: $USER_CRT"
