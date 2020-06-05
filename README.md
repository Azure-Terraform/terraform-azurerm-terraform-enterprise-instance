## What is this?

This repository contains Terraform code to create a TFE application stack.  

**Important**: please read this document before using the module, as it is not written conventionally. Instead, you will find it is composed of several modules that are intended to use semi-independently (with the outputs of some feeding the inputs of others). You can't run all the submodules at the same time when starting from scratch, it will not work.

**Note to external/open source readers**: this is a very opinionated implementation. It obeys to certain LexisNexis standards that you probably don't care about, and doesn't expose a lot of settings that could otherwise be variables in a "normal" module. This module was written for LexisNexis internal use, so it's not very flexible and doesn't give you a lot of choice. For example if you didn't want to use Ubuntu, this is hard-coded here, so you'd have to tweak the code to change that. If you didn't want to use SSL for the database connection, too bad, that's also hard-coded because it's a requirement for us, and we didn't want our teams to have a choice in the matter when setting up TFE.

So while this code may not be as reusable as your typical Terraform module, its value is in showing how to tie various Azure services together to form a TFE stack in Azure. The piece of code you'll probably find most useful is the VM submodule, as that's where all the automation related to setting up TFE takes place, and that's the hardest part to get working. Not much else in the code is ground-breaking in any way.

The code in this repository creates a number of things:

1. An Azure Resource Group to contain all the other resources.
1. An Azure Virtual Network with two subnets, one for TFE, one for an optional instance of HashiCorp Vault. The latter will remain empty and unused unless you use the Terraform code to "append" this instance of Vault to your TFE implementation. The code is available in a separate repository, and includes separate documentation.
1. An Azure Key Vault. This will only store a few small things: the storage account keys, the Postgres database user and password, and a few other secrets. This is NOT used by TFE directly, only to bring up TFE and its database.
1. An Azure Storage Account with a Blob container and a Files endpoint. The Blob container will hold the TFE license file as well as some of the TFE application data. The Files endpoint is a CIFS share that is mounted to the VM. TFE will store its application snapshots there.
1. A PostgreSQL database instance. By default, only TFE will be able to connect to the DB. You can configure the database firewall to allow connections from your workstation if needed. This should be avoided except for troubleshooting, and is done outside of this module (an example is provided farther down).
1. An Azure VM for the TFE application. This VM is assigned a managed identity allowing it to download required secrets from Key Vault.
1. Rules in the network security group attached to our subnet, allowing access to TFE from outside Azure.
1. An SSL certificate for the instance. The VM (not Terraform) generates this certificate through ACME/LetsEncrypt and manages it autonomously, including renewals.

## Intro

Our initial intent was to do a clustered deployment of TFE, however we are not doing that because, as of writing, clustered TFE is in "Controlled Availability" and only available to a limited set of HashiCorp customers. HashiCorp provides its own supported module to set up a TFE cluster, but given that the cluster feature has been pulled out, we couldn't use the module, and therefore had to write our own to support a standalone, non-clustered deployment.

That means TFE will, for now, run in a standalone VM, running in the "Production - External Services" [operational mode](https://www.terraform.io/docs/enterprise/before-installing/index.html#operational-mode-decision).

You can read more on the deployment method [here](https://www.terraform.io/docs/enterprise/before-installing/index.html#deployment-method-decision).

We will revisit the clustered deployment option at a later date and determine if it's possible to migrate the single instance setup to a cluster as originally intended.

The VM runs Ubuntu 18.04 LTS since CentOS 7 is not supported by HashiCorp.

**Important**: once TFE is operational, DO NOT attempt to have TFE manage itself in a workspace. You will break everything. You should manage the TFE instance "manually" (e.g. from your laptop) using the code in this repo, or a purpose-built GitLab CI pipeline. It'll be fine as long as TFE is managed externally.

## Requirements

- You must have the Owner role within the Azure subscription. The reason for that is the code assigns a managed identity to the TFE virtual machine, and that particular bit requires Owner privileges (or at the very least, a custom role with the necessary permissions).
- Terraform 0.12.x. Some level of familiarity with the tool is immensely helpful.
- The TFE license file that HashiCorp sent us
- An existing public DNS zone hosted in Azure. This will be used to create a DNS record for the TFE instance, as well as to create/validate the SSL certificate for said instance.
- You should have an account on GitHub.com with a [personal account token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) set up. When creating the token and going through its permissions, you do not need to give it any permissions whatsoever, as it is only used to access GitHub's public API with authentication, which increases rate limits. The token is not used for anything having to do with your GitHub account or repositories that you own or have access to.
- You will need an Azure Service Principal created in Azure AD. Either create it yourself or (more likely) if you don't have access to do so, request one. This is used only to create TXT records in a specified DNS zone to perform the LetsEncrypt [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge), so it doesn't need extensive permissions. The policy below should be enough:

```json
{ 
  "Name": "DNS TXT Contributor", 
  "Id": "",
    "IsCustom": true, 
  "Description": "Can manage DNS TXT records only.", 
  "Actions": [ 
    "Microsoft.Network/dnsZones/TXT/*", 
    "Microsoft.Network/dnsZones/read", 
    "Microsoft.Authorization/*/read", 
    "Microsoft.ResourceHealth/availabilityStatuses/read", 
    "Microsoft.Resources/deployments/read", 
    "Microsoft.Resources/subscriptions/resourceGroups/read" 
  ],
  "NotActions": [ 
  ],
  "AssignableScopes": [ 
    "/subscriptions/12345678-9abc-def0-1234-567890abcdef" 
  ] 
}
```

**Note**: the Service Principal needs access to the subscription that contains the DNS zone where the TFE **vanity** record will be created. This is probably **not** the same subscription that contains TFE itself, so be mindful of that when setting up the permissions of the Service Principal.

## Setup overview

The setup phase involves a few easy but manual steps despite the fact we're using Terraform. This is due to a chicken-and-egg problem. Certain items must exist before other pieces of this stack can come online, however these items must be stored in Azure Key Vault or an Azure Blob Container prior to setting up TFE, and we avoided writing TF code to handle those items, since they are sensitive and we didn't want them stored in the TF state file.

That means three main steps to the setup process:

1. Use the included TF code to create an Azure Resource Group, Virtual Network, Key Vault instance and Blob Container.
1. Manually store a few items within the Key Vault and the Storage Account.
1. Run TF again to set up the remaining pieces of the TFE stack: the DB and the VM where TFE will run.

The idea here is to keep the various required secrets as safe as possible.

## Detailed setup steps

1. Set up a blank Git repository.
1. Add one or more .tf files to the Git repo, you can name them however you like, but in my example (see the `example` subdirectory of this repo), I used three files named `settings.tf`, `tfe.tf` and `tfe_vars.tf`.
    1. `settings.tf` contains settings specific to Terraform, its providers, and Azure itself, rather than the application.
    1. `tfe.tf` contains the calls to the various bits of code that Terraform will parse.
    1. `tfe_vars.tf` contains variables that are fed to the code in `tfe.tf`.
1. Open your copy of `settings.tf` and copy-paste the contents of `settings.tf` from this repo's `example` directory into your local `settings.tf`.
1. Edit the value of the `subscription_id` variable with the ID of the Azure subscription where you're working. Save and close `settings.tf` for now.
1. In a shell window (PowerShell on Windows or Terminal on Mac), go to the directory containing your work so far, and type `terraform init`. You should see something like this:

```
$ terraform init
Initializing modules...

Initializing the backend...

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

6. Open your copy of `tfe_vars.tf` and copy-paste the contents of `tfe_vars.tf` from this repo's `example` directory into your local `tfe_vars.tf`.
1. Edit the value of the `name_randomness` variable to any number between 0 and 255. The example uses 62, obtained by adding up "tfedev", where "t" is the 20th letter of the alphabet, "f" is the 6th, and so forth.
1. Edit the value of the `key_vault_authorized_users` variable. This is a list of Azure AD users or groups available in our tenant, in GUID format, that will be authorized to use the Azure Key Vault instance that will be created by this code. The list must include at least the person running this Terraform code (presumably that's you). Be careful that the value is expressed as a list/array, even if only one item is in the list, it must therefore be enclosed in square brackets \[\] and values are comma-separated, as shown in the example. 
1. Edit the value of the `key_vault_authorized_subnets` variable as needed. This is a list of subnets in CIDR notation that are authorized to connect to the Azure Key Vault instance we'll be creating. This list must include at least the IP address of the person running this Terraform code (again, presumably that's you). Be careful that the value is expressed as a list/array, even if only one item is in the list, it must therefore be enclosed in square brackets \[\] and values are comma-separated, as shown in the example. 
1. Edit the value of the `storage_account_authorized_subnets` variable as needed. This is a list of subnets in CIDR notation that are authorized to use the Azure Storage Account we'll be creating. This list must include at least the IP address of the person running this Terraform code (presumably that's you). Be careful that the value is expressed a list/array, even if only one item is in the list, it must therefore be enclosed in square brackets \[\] and values are comma-separated, as shown in the example. And unlike the previous variable, due to some weird inconsistency in the Azure API, this does not support CIDR prefixes of length /30, /31 and /32. When using subnets of that size, list the individual IPs and omit the CIDR prefix.
1. Edit the value of the `tfe_authorized_subnets` variable as needed. This is a list of subnets in CIDR notation that are authorized to connect to TFE. Be careful that the value is expressed as a list/array, even if only one item is in the list, it must therefore be enclosed in square brackets \[\] and values are comma-separated, as shown in the example. 
1. Edit the value of the `tfe_admin_authorized_subnets` variable as needed. This is a list of subnets in CIDR notation that are authorized to connect to TFE's administrative ports, which are 22 and 8800. You should restrict those to a minimum, for example the public interface of a particular workstation from which you plan on managing TFE. You won't need to access this interface too often. Be careful that the value is expressed as a list/array, even if only one item is in the list, it must therefore be enclosed in square brackets \[\] and values are comma-separated, as shown in the example. 
1. Save and close `tfe_vars.tf`.
1. Go back to your shell and do another `terraform init` followed by `terraform plan`. Terraform should not detect any changes at this point because we haven't introduced any resources, but this will show you if there are any syntax errors in your code so far.
1. In the directory of examples, open `metadata.tf` and copy-paste its contents into your `tfe.tf`.
1. Edit all the values in accordance to your needs and with respect to the tagging requirements.
1. In the directory of examples, open `resource_group.tf` and copy-paste its contents into your `tfe.tf`.
1. You shouldn't need to edit anything here unless you want to set up TFE in a different region.
1. In the directory of examples, open `vnet.tf` and copy-paste its contents into your `tfe.tf`.
1. Again, you shouldn't need to edit anything here.
1. In the directory of examples, open `key_vault.tf` and copy-paste its contents into your `tfe.tf`.
1. Again, you shouldn't need to edit anything here.
1. In the directory of examples, open `storage_account.tf` and copy-paste its contents into your `tfe.tf`.
1. Again, you shouldn't need to edit anything here. Save your changes to `tfe.tf`.
1. Go back to your shell and do another `terraform init` followed by `terraform plan`. This time, Terraform should detect a number of changes, including the creation of a resource group, a virtual network, a subnet, a network security group with a number of rules, a key vault, a few key vault access policies, a storage account and a storage container. Review the plan output.
1. If the plan output looks like what you expect, run `terraform apply` and type `yes` when prompted. This will take a few minutes but should complete without incident.

**If Terraform returns no errors, you're done with the first phase of the setup. You should now have a functioning instance of Key Vault and a Storage Account in Azure, where we'll be putting some things manually.**

1. Make up the following secrets and write them down in plain text somewhere temporary.
    1. Postgres DB user: this will be the admin user for the database.
    1. Postgres DB password: this goes with the above username. Use your favorite password generator to make a complex password, alphanumerical, mixed case, with some symbols sprinkled on top.
    1. Another complex password, which will be used to access the TFE admin console (https://tfehost.example.com:8800).
    1. A private/public SSH key pair. Click [here](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for instructions to generate this if you don't know how.
1. Using the Azure Portal, or Azure CLI, or Powershell, we'll now store these secrets in the previously-created instance of Azure Key Vault. To accomplish this through the GUI, follow these steps:
    1. Log in to the Azure Portal.
    1. Type "key vaults" in the search field at the top, then click on **Key Vaults** in the search results.
    1. Open the Key Vault that Terraform just created. It should be called `tfe<environment><random_number>`. If you don't see it, you may have to adjust the **Subscription** filter to include the subscription in which you're working.
    1. Select **Secrets** in the navigation bar on the left.
    1. Here you should already see two secrets called `tfe<environment><random_number>-storage-account-keyX`. We'll use these in a subsequent step,
    1. Click the **Generate/Import** button.
    1. Leave **Upload options** set to **Manual**.
    1. In the **Name** field, set a name for the secret. This is an arbitrary name but should describe what the secret is about, e.g. `tfe-<environment>-postgres-admin-user`.
    1. In the **Value** field, paste the value for the secret that you created earlier.
    1. Leave the remaining options (**Content type**, **Set activation date**, **Set expiration date**, **Enabled**) alone.
    1. Click **Create**.
    1. You should be returned to the list of secrets, and the new secret should appear.
    1. Repeat the previous seven steps for each secret that you created earlier, **plus the Azure Service Principal ID and secret** that was mentioned in the requirements section above. If you choose to store the SSH private key here (you don't have to but it's a good idea), you should encode it using base64 first so you don't have to worry about newlines when storing that secret. The private key is not used in this code, but you may find it useful to store it someplace safe so you can always retrieve it to log in to the TFE VM if needed.
    1. You should now have a total of 8 or 9 secrets in your Key Vault's secrets store. 2 were already there when you started, and you added 6 or 7, depending on whether you stored the SSH private key or not (you really should).
1. Next, we need to upload the TFE license file to Azure Blob (an Azure service more or less equivalent to AWS S3).
    1. Back in the Azure Portal, type "Storage accounts" in the search field at the top, then click on **Storage accounts** in the search results.
    1. Open the account that Terraform just created, which should be called `tfe<environment><random_number>` (same as the Key Vault earlier). As before, if you don't see it, you may have to adjust the **Subscription** filter to include the subscription in which you're working.
    1. In the navigation bar on the left, under the **Blob service** section (you may have to scroll down some to find it), click on **Containers**.
    1. You should see a container named `tfe-<environment>`, click on it.
    1. Click the **Upload** button at the top.
    1. In the pane that appears on the right, click on **Select a file**.
    1. Locate the TFE license file on your computer.
    1. Click the blue **Upload** button underneath. The file will now be uploaded and should appear in the center shortly.

**You're done with the second phase of the setup. The third and last phase is to create a Postgres DB instance for TFE, and a VM for TFE itself.**

1. Reopen the `tfe.tf` file you worked on in the first phase earlier.
1. In the directory of examples, open `db.tf` and copy-paste its contents into your `tfe.tf`. There are five variables you must edit here.
    1. `sku_name`: set this to `GP_Gen5_x` where x is 2, 4, 8, 16, 32 or 64. HashiCorp's recommendation ([link](https://www.terraform.io/docs/enterprise/before-installing/reference-architecture/azure.html)) is for a 4- or 8-core instance, I recommend starting with 4 and see how it goes.
    1. `storage_mb`: this is the number of megabytes available to the TFE Postgres DB. The value must be between 5120 and 4194304, and must be divisible by 1024. HashiCorp recommends a minimum of 50 GB, which means a value of 51200 here.
    1. `backup_retention_days`: the Azure Postgres DB service takes automatic daily backups of your data. This sets how many days each backup is kept before it's deleted.
    1. `admin_user`: earlier, you stored an admin username for the Postgres instance in Key Vault. This variable must be set to the **name of the Key Vault secret** containing the username you set, **not the username itself**.
    1. `admin_password`: earlier, you stored an admin password for the Postgres instance in Key Vault. This variable must be set to the **name of the Key Vault secret** containing the password you set, **not the password itself**.
1. In the directory of examples, open `vm.tf` and copy-paste its contents into your `tfe.tf`. There are a number of things you must edit here.
    1. `tfe_hostname`: the fully-qualified domain name you want to assign to TFE.
    1. `tfe_vanity_hostname`: a vanity domain name, for example `tfe_hostname` might be something ugly like `app.tfe.nonprod.us.lnrisk.io`, and this could be `tfe-dev.lnrisk.io`.
    1. `tfe_vanity_hostname_dns_zone_subscription_id`: the subscription ID where resides the DNS zone that will contain the vanity record. This is most likely a subscription ID different from the one where you are setting up TFE. **Your Service Principal must have access to read/write/delete TXT records in this subscription.**
    1. `dns_zone_resource_group`: the name of the resource group that owns the DNS zone where the DNS records for TFE must be created. This is probably not the same resource group as the one you created in an earlier step.
    1. `vm_size`: we've spent considerable time running performance tests against various Azure VM types and came to the conclusion that the [Das v4-series](https://azure.microsoft.com/en-us/updates/new-azure-dav4-series-and-eav4-seriesvirtual-machines-are-now-available/) are best suited for running TFE. Note that Hashicorp recommends [Dv3](https://azure.microsoft.com/en-us/blog/introducing-the-new-dv3-and-ev3-vm-sizes/) VM sizes ([link](https://www.terraform.io/docs/enterprise/before-installing/reference-architecture/azure.html)), but we've proved that they perform worse than Da/Das v4 VMs while costing the same. You should use an instance type of `Standard_D4as_v4` (4 CPU cores, 16 GB RAM) as a minimum, and increase to the next SKU, `Standard_D8as_v4` (8 CPU cores, 32 GB RAM) if needed (probably will be needed for a Prod deployment). Since larger instances cost double, you should do your due diligence and monitor CPU/RAM utilization, and only use a larger instance if monitoring shows it to be a necessity. Just don't use Azure Av2 or Bs instance types here.
    1. `vm_os_disk_size`: this defaults to 128, which should be ample according to HashiCorp, who recommends a minimum of 50 GB. If you change this value, you should make sure it's an integral power of 2 (32, 64, 128, 256, etc.), due to Azure billing considerations (Azure disks are priced by tier, and for example a 50 GB disk is billed at the next tier level, 64 in this case).
    1. `pg_admin_user`: the name of the secret holding the Postgres DB username
    1. `pg_admin_password`: the name of the secret holding the Postgres DB password
    1. `replicated_console_password`: the name of the secret holding the TFE admin UI (port 8800) password
    1. `vm_public_key`: the name of the secret containing the SSH public key to install in the VM's `~/.ssh/authorized_keys` file
    1. `azure_client_id`: the name of the secret containing the Service Principal ID
    1. `azure_client_secret`: the name of the secret containing the secret associated with the Service Principal
    1. `license_file_name`: the name of the license file that you uploaded to the blob container during the second phase of the setup earlier
1. You should be done here, so save your changes to `tfe.tf`.
1. Run `terraform apply` and type `yes` when prompted. This will take a few minutes but should complete without incident.
1. By the time Terraform returns, you should be able to SSH into the VM, or will be able to shortly. You can try the FQDN first, and if it doesn't resolve yet, you can obtain the VM's public IP address through the Azure Portal, or query the Terraform state, for example. There's not much reason to SSH in at this point, unless you're already familiar with the automated steps that happen after the VM starts and you want to watch things "live". Otherwise, skip to the next step.
1. After a few minutes, go to http://tfe_hostname:8800. This is the TFE admin console. If it doesn't work yet, wait a few more minutes and try again. Once that UI is up, it should ask for a password that you created earlier and should have written down. Once you're in, you can go through all the settings and double check that everything is set correctly. One thing you may want to adjust now or later is the snapshot settings, i.e. whether to take daily snapshots automatically, how many to retain, etc. This is not currently configurable through automation.
1. Refer to [this link](https://www.terraform.io/docs/enterprise/install/config.html) for this step. If this is a clean install/new TFE instance, the first thing you need to do is create an admin account. Follow the instructions in the link to do this. You can also follow [these instructions](https://www.terraform.io/docs/enterprise/install/automating-initial-user.html) to set up the first admin user via an API, but this method only works for 60 minutes after TFE starts, for security reasons.
1. You should now be able to log in to TFE at https://tfe_hostname using the admin account you created.
1. Have someone who has access to the vanity DNS zone create a CNAME for the value you specified in the `tfe_vanity_hostname` variable earlier, and point the CNAME to what you set in the `tfe_hostname` variable. If you have access to do this yourself, do so. This step was not included in the Terraform code due to complexities associated with running a single code base against more than one Azure subscription.
1. Make sure https://tfe_vanity_hostname is working and the SSL cert includes the vanity alias.

If you've reached this step and had no issues, you're done and can now start using TFE. Refer to the [official docs](https://www.terraform.io/docs/enterprise/index.html) for all your needs, and [open a support ticket](https://support.hashicorp.com/hc/en-us) with HashiCorp as needed. Their support is great and responsive.

There is one final thing you can do: Terraform keeps data in what it calls a state file. This data contains all the resources that Terraform created via the code you provided. When you run Terraform, it compares the code to the contents of the state file, and tries to apply the differences. If you've been running Terraform by following the above steps, you should now have a file called "terraform.tfstate" in your working directory. The last recommended step in this setup is to move this state file to your Azure Blob container. This requires adding a few lines to your configuration.

1. Look in your `settings.tf`. The first paragraph should look like this:

```
terraform {
  required_version = "~> 0.12.20"

  # backend "azurerm" {
  #   resource_group_name  = "..."
  #   storage_account_name = "..."
  #   container_name       = "..."
  #   key                  = "terraform.tfstate"
  # }

  experiments = [variable_validation]
}
```

2. Uncomment the commented lines (`backend "azurerm" { ... }`).
1. Fill out the dotted values with the names of the objects you created in the first phase of the setup. You need the following names: the resource group, the storage account, and the storage container.
1. Save the file and run `terraform init`. It should detect the new state backend setting, and ask if you want to copy your existing local state file to the remote backend. Say yes, and the rest should happen immediately.
1. Double check that the state file was written to your Azure Blob container by looking for it in the Azure Portal. If it's there, you can then run `terraform plan`. If it returns no changes, that's good.
1. The last thing you can do is move your local `terraform.tfstate*` files (there may be one called `terraform.tfstate.backup` as well) to a different directory and run `terraform init` followed by `terraform plan` again to double check that everything is in order. If yes, you can delete those files from your computer.

When you've done all that, the state file will be maintained securely and redundantly in Azure. All you have to do is be careful not to delete the Blob container or the storage account!

By the way, you can do this at any time after the storage account is created (first phase of the setup steps above), or you could use another storage account/blob from the start, if one is available to you.

## Maintenance/Upgrades

### Application

Application upgrades must be handled within the application, not with Terraform. It's a straightforward, automated process, documented [here](https://www.terraform.io/docs/enterprise/admin/upgrades.html).

### Operating System

As mentioned earlier, the VM is running Ubuntu 18.04. Special care should be taken when installing OS updates. Terraform Enterprise expects a specific version of Docker, which is tied to the version of TFE you're running. Therefore, when patching the OS, you should be careful not to upgrade any Docker packages without first consulting HashiCorp and making sure the Docker upgrade is supported by the current version of TFE, or check if a newer version of TFE is available that supports the newer version of Docker you're aiming to install.

## Logging & Monitoring

Refer to the HashiCorp docs on these topics:

- [Logging](https://www.terraform.io/docs/enterprise/admin/monitoring.html)
- [Monitoring](https://www.terraform.io/docs/enterprise/admin/monitoring.html)

## Snapshots & Disaster Recovery

This code creates an Azure Files endpoint which is then mounted to the VM's file system at `/var/lib/tfe_snapshots`. Azure Files is basically a managed CIFS share. TFE is then configured to write its snapshots to that path. The idea is that if the VM were to be deleted for whatever reason, the combination of 1. PostgreSQL, 2. Azure Blob, 3. a recent snapshot will enable you to return to a functional state. In such an event, you should be able to just run Terraform, and if the VM is missing, a new one will be created and reattach itself to the existing Postgres instance, Azure Blob, and Azure Files mount. Once TFE is back up, you should then be able to restore a snapshot.

To accomplish this, you can follow [these docs](https://www.terraform.io/docs/enterprise/admin/automated-recovery.html).

We could have scripted restoring the latest snapshot automatically, but chose not to for a few reasons, mainly not to force a snapshot restore when a VM fails, in case you want to troubleshoot something after a new VM comes up. Once the VM is back up, you have the freedom of verifying that TFE app components are back online, and then of restoring a snapshot manually. This is a quick operation because our use of TFE's External Services operational mode means that relatively little data lives in the snapshots (relative to Postgres and the Blob container).

The instructions above provide a template of a script to automate a snapshot restore. The simplest way of doing this manually comes in these steps:

1. SSH to the VM
1. Run `replicatedctl snapshot ls` and grab the Snapshot ID (first column of the output) of the snapshot you want to restore.
1. Run `replicatedctl snapshot restore --dismiss-preflight-checks "<snapshot_id>"`.
1. If the TFE admin UI on port 8800 is up, you should be able to see that the snapshot is restoring, and that TFE services are being restarted.

## Troubleshooting

1. If you ever need to connect to the DB directly, you can add the following resource to your TF code (adjust the resource name and start/end IP addresses as needed):

```
resource "azurerm_postgresql_firewall_rule" "johns_workstation" {
  name                = "john-doe-workstation"
  resource_group_name = module.tfe_rg.name
  server_name         = module.tfe_postgres_db.name
  start_ip_address    = "1.2.3.4"
  end_ip_address      = "1.2.3.4"
}
```

It's recommended that you go through the TFE VM to connect to the Postgres DB, rather than connecting to the DB directly, but this will work if you need it, and it's also recommended that you destroy this firewall rule once you're done with whatever you needed to do on the DB. Simply remove/comment that code to delete the firewall rule.

2. Issues with this code are most likely to crop up when the VM comes up and [this script](https://github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance/blob/master/vm/template_vm_custom_data.sh.tpl) runs. Many lines of this script are inter-dependent, and almost every line ultimately affects whether TFE deploys successfully. It's useful to review the contents of the script so you understand what it does, it isn't complicated. If TFE fails to come up for whatever, things to look for include, in no particular order:

- Check that a file called `finished` is present in `~ubuntu`. Read its contents. It only means that the Cloud-Init script ran to completion (instead of exiting prematurely for some reason), but it's possible some of the lines in the script failed.
- `/etc/replicated.conf` and `/etc/tfe_application_settings.json` contain correct values. Because we use `sed` to insert certain secrets in those files, sometimes if those values pulled from Key Vault contain certain characters, `sed` doesn't properly escape them, and this results in improper substitution of the placeholder values in either of those two files.
- The TFE license file is present at `~ubuntu/<filename>.rli` and its checksum matches the checksum on the original file that you should have.
- The SSL cert was generated properly and is present in `~ubuntu/.acme.sh/<tfe_hostname>`.
- When TFE starts and connects to an otherwise empty database, it creates the pieces it needs automatically: three schemas called `rails`, `registry` and `vault`. You can check that those are present if TFE didn't come up.
- You can run `sudo docker ps`, which will either show no containers running, or a bunch of containers running. If no containers are running, then something is definitely wrong, but unfortunately there isn't a published list of containers that should be running. In other words, just because you do see running containers doesn't really mean anything, only that Docker was installed and that some containers were able to start.

Refer to the [replicatedctl reference](https://help.replicated.com/api/replicatedctl/) for some advanced troubleshooting and back-end management commands for TFE. HashiCorp partners with an organization called Replicated to manage the packaging, deployment and licensing of the enterprise versions of its apps, and the `replicatedctl` tool is used for a number of things.

For example, when contacting HashiCorp for support, they will often ask for a "support bundle". You can generate it by following [these steps](https://www.terraform.io/docs/enterprise/support/index.html), but if you are unable to load the UI, you may still be able to obtain the support bundle by accessing the VM via SSH and running `replicatedctl support-bundle`. This will generate a tarball that you can copy to your workstation and send over to HashiCorp.