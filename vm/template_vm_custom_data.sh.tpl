#!/bin/bash

# Set the timezone
timedatectl set-timezone "${timezone}"

# Prepare to install packages
apt-get update

# Install CIFS package if needed
apt-get install -y cifs-utils

# Disable SMB 1.0 for security
# See https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux#securing-linux
echo "options cifs disable_legacy_dialects=Y" | tee -a /etc/modprobe.d/local.conf > /dev/null

# Install Azure CLI package
apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y azure-cli

# Update entire system
apt-get upgrade -y

# Install useful packages
apt-get install -y jq postgresql-client

# Clean up
apt autoremove -y

# Generate TFE application settings
REPLICATED_CONF=/etc/replicated.conf

cat <<APPSETTINGS > ${app_settings_path}
${application_settings_json}
APPSETTINGS

cat <<REPLICATED > $REPLICATED_CONF
${replicated_conf}
REPLICATED

# Now obtain a few secrets
# Log in to Azure using the VM's managed identity
az login --identity

# Install acme.sh so we can request an SSL certificate for TFE
git clone https://github.com/acmesh-official/acme.sh.git /home/${username}/acme-sh-install
cd /home/${username}/acme-sh-install
./acme.sh --install --home /home/${username}/.acme.sh
chown -R ${username}:${username} /home/${username}/.acme.sh

export AZUREDNS_SUBSCRIPTIONID="${vanity_hostname_dns_zone_subscription_id}"
export AZUREDNS_TENANTID="${azure_tenant_id}"
export AZUREDNS_APPID=$(az keyvault secret show --vault-name ${key_vault_name} --id "${key_vault_uri}secrets/${azure_client_id}" | jq -r '.value')
export AZUREDNS_CLIENTSECRET=$(az keyvault secret show --vault-name ${key_vault_name} --id "${key_vault_uri}secrets/${azure_client_secret}" | jq -r '.value')

cd /home/${username}/.acme.sh
./acme.sh --home /home/${username}/.acme.sh --issue --dns dns_azure -d ${hostname} -d ${vanity_hostname}

# Get the secrets we need to insert in the replicated settings JSON file
ADMIN_UI_PASSWORD=$(az keyvault secret show --vault-name ${key_vault_name} --id "${key_vault_uri}secrets/${replicated_console_password}" | jq -r '.value')

# Replace placeholder values in the replicated settings file with the secrets
sed -i -e "s~PLACEHOLDER_ADMIN_UI_PASSWORD~$ADMIN_UI_PASSWORD~" $REPLICATED_CONF

# Get the secrets we need to insert in the TFE installer settings JSON file
STORAGE_ACCOUNT_KEY=$(az keyvault secret show --vault-name ${key_vault_name} --id "${key_vault_uri}secrets/${azure_account_name}-storage-account-key1" | jq -r '.value')
PG_USER=$(az keyvault secret show --vault-name ${key_vault_name} --id "${key_vault_uri}secrets/${pg_username}" | jq -r '.value')
PG_PASSWORD=$(az keyvault secret show --vault-name ${key_vault_name} --id "${key_vault_uri}secrets/${pg_password}" | jq -r '.value')

# Replace placeholder values in the TFE installer settings file with the secrets
sed -i -e "s~PLACEHOLDER_AZURE_STORAGE_ACCOUNT_KEY~$STORAGE_ACCOUNT_KEY~" ${app_settings_path}
sed -i -e "s~PLACEHOLDER_POSTGRES_USERNAME~$PG_USER~" ${app_settings_path}
sed -i -e "s~PLACEHOLDER_POSTGRES_PASSWORD~$PG_PASSWORD~" ${app_settings_path}

# Finally, download the TFE license file from the Blob Container
az storage blob download --container-name ${azure_container} --name ${license_file_name} --file /home/${username}/${license_file_name} --connection-string "DefaultEndpointsProtocol=https;AccountName=${azure_account_name};AccountKey=$STORAGE_ACCOUNT_KEY;EndpointSuffix=core.windows.net"

# Prepare to run the TFE installer, need a couple of things first
# Download the TFE install script
curl -o /home/${username}/install_ptfe.sh https://install.terraform.io/ptfe/stable
# We need to pass the private IP of the VM to the installer, so let's grab it
# We also need the public IP but we're getting that from Terraform
PRIV_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

# Now run the TFE installer
bash /home/${username}/install_ptfe.sh no-proxy private-address="$PRIV_IP" public-address="${public_ip}"

# Attach an Azure Files volume to store TFE snapshots in a redundant manner
mkdir -p "${snapshots_path}"
smbPath="//${azure_files_endpoint}/${azure_files_share}"
uid=$(id -u replicated)
gid=$(id -g replicated)

mkdir -p "/etc/smbcredentials"

smbCredentialFile="/etc/smbcredentials/${azure_account_name}.cred"
echo "username=${azure_account_name}" | sudo tee $smbCredentialFile > /dev/null
echo "password=$STORAGE_ACCOUNT_KEY" | sudo tee -a $smbCredentialFile > /dev/null
chown root:root $smbCredentialFile
chmod 600 $smbCredentialFile

echo "$smbPath ${snapshots_path} cifs nofail,vers=3.0,credentials=$smbCredentialFile,uid=$uid,gid=$gid,dir_mode=0755,file_mode=0644,serverino" | tee -a /etc/fstab > /dev/null

mount -a

echo "This file appears in /home/${username} to tell you when the VM custom data script is done running. It does NOT mean that the script ran without issues!" | tee -a /home/${username}/finished
