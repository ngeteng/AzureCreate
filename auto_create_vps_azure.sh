#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# auto_create_vps_azure.sh
# Description : Script otomatis membuat VPS di Azure sekali jalan dengan spesifikasi minimum
# Prasyarat   :
#   - Azure CLI terpasang dan sudah login (jika belum, skrip akan memanggil 'az login')
#   - SSH client terpasang (ssh-keygen)
# ----------------------------------------------------------------------------

set -eo pipefail

# Default konfigurasi (ubah sesuai kebutuhan)
RG_NAME="autoRG"
LOCATION="eastasia"
VM_NAME="autoVM"
VM_SIZE="Standard_B1s"
# Menggunakan image Ubuntu 22.04 LTS dari Canonical
IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest"
ADMIN_USER="azureuser"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"

# 1. Pastikan SSH key ada, jika tidak ada, buat otomatis
echo "=== Cek SSH key ==="
if [[ ! -f "${SSH_KEY_PATH}" ]]; then
  echo "SSH key tidak ditemukan di ${SSH_KEY_PATH}, membuat baru..."
  ssh-keygen -t rsa -b 2048 -f "${SSH_KEY_PATH%.*}" -N ""
fi

# 2. Pastikan sudah login ke Azure
echo "=== Cek Azure login ==="
if ! az account show &> /dev/null; then
  echo "Anda belum login. Mengarahkan ke browser untuk login..."
  az login
fi

# 3. Buat Resource Group (jika belum ada)
echo "=== Membuat Resource Group: $RG_NAME di $LOCATION ==="
az group create --name "$RG_NAME" --location "$LOCATION"

# 4. Buat VM dengan spesifikasi minimum
echo "=== Membuat VM: $VM_NAME ==="
az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --image "$IMAGE" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --ssh-key-values "$SSH_KEY_PATH" \
  --output table

# 5. Buka port SSH (22)
echo "=== Mengizinkan akses SSH (port 22) ==="
az vm open-port --resource-group "$RG_NAME" --name "$VM_NAME" --port 22 --priority 1000

# 6. Tampilkan alamat IP publik
echo "=== Mendapatkan IP Publik ==="
PUBLIC_IP=$(az vm list-ip-addresses --resource-group "$RG_NAME" --name "$VM_NAME" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
echo "VM '$VM_NAME' berhasil dibuat!"
echo "Anda dapat mengaksesnya melalui SSH dengan perintah:" 
	echo "  ssh $ADMIN_USER@${PUBLIC_IP}"
