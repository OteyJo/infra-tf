# Modern Enterprise Search Infrastructure

Here is the Terraform code necessary to deploy the infrastructure for the Modern Enterprise Search application

This repository is organized into several directories and files to manage different aspects of the infrastructure deployment. Here’s a brief overview of the structure:

### `/infra`

The main directory containing Terraform configurations.

- **`backend.tf.ci`** - Terraform backend configuration for Continuous Integration environment.
- **`backend.tf.us.ci`** - Terraform backend configuration for US Continuous Integration environment.
- **`main.tf`** - Main Terraform configuration file that orchestrates the infrastructure deployment.
- **`providers.tf`** - Provider configurations for Azure and other necessary providers.
- **`variables.tf`** - Global variable definitions used across the Terraform configuration.
- **`outputs.tf`** - Definitions for outputs that can be used to get information from the deployed infrastructure.

### `/infra/core`

Contains core infrastructure components.

#### `/infra/core/aad`
- **`entra.tf`** - Terraform configuration for Azure Active Directory (AAD) resources.
- **`variables.tf`** - Variables for AAD resources.

#### `/infra/core/ai`
- **`/bingSearch`** - Configuration for Bing Search services.
  - **`bingSearch.tf`** - Terraform configuration for Bing Search.
  - **`outputs.tf`** - Outputs for Bing Search.
  - **`variables.tf`** - Variables for Bing Search.

- **`/cogServices`** - Configuration for Cognitive Services.
  - **`cogServices.tf`** - Terraform configuration for Cognitive Services.
  - **`outputs.tf`** - Outputs for Cognitive Services.
  - **`variables.tf`** - Variables for Cognitive Services.

- **`/docintelligence`** - Configuration for Document Intelligence services.
  - **`docintelligence.tf`** - Terraform configuration for Document Intelligence.
  - **`outputs.tf`** - Outputs for Document Intelligence.
  - **`variables.tf`** - Variables for Document Intelligence.

- **`/openaiservices`** - Configuration for OpenAI Services.
  - **`openaiservices.tf`** - Terraform configuration for OpenAI Services.
  - **`outputs.tf`** - Outputs for OpenAI Services.
  - **`variables.tf`** - Variables for OpenAI Services.

#### `/infra/core/container_registry`
- **`container_registry.tf`** - Terraform configuration for Azure Container Registry.
- **`outputs.tf`** - Outputs for Container Registry.
- **`variables.tf`** - Variables for Container Registry.

#### `/infra/core/db`
- **`cosmosdb.tf`** - Configuration for Azure Cosmos DB.
- **`outputs.tf`** - Outputs for Cosmos DB.
- **`variables.tf`** - Variables for Cosmos DB.

#### `/infra/core/host`
- **`/enrichmentapp`** - Configuration for the Enrichment App.
  - **`enrichmentapp.tf`** - Terraform configuration for Enrichment App.
  - **`outputs.tf`** - Outputs for Enrichment App.
  - **`variables.tf`** - Variables for Enrichment App.

- **`/functions`** - Configuration for Azure Functions.
  - **`functions.tf`** - Terraform configuration for Azure Functions.
  - **`outputs.tf`** - Outputs for Azure Functions.
  - **`variables.tf`** - Variables for Azure Functions.

- **`/webapp`** - Configuration for Web Application.
  - **`webapp.tf`** - Terraform configuration for Web Application.
  - **`outputs.tf`** - Outputs for Web Application.
  - **`variables.tf`** - Variables for Web Application.

#### `/infra/core/logging`
- **`/loganalytics`** - Configuration for Log Analytics.
  - **`logging.tf`** - Terraform configuration for Log Analytics.
  - **`outputs.tf`** - Outputs for Log Analytics.
  - **`variables.tf`** - Variables for Log Analytics.

- **`/monitor`** - Configuration for Azure Monitor.
  - **`monitor.tf`** - Terraform configuration for Azure Monitor.
  - **`variables.tf`** - Variables for Azure Monitor.

#### `/infra/core/network`
- **`/network`** - Configuration for Azure Network.
  - **`network.tf`** - Terraform configuration for Network.
  - **`output.tf`** - Outputs for Network.
  - **`variables.tf`** - Variables for Network.

- **`/privateDNS`** - Configuration for Private DNS Zones.
  - **`privateDNS.tf`** - Terraform configuration for Private DNS.
  - **`outputs.tf`** - Outputs for Private DNS.
  - **`variables.tf`** - Variables for Private DNS.

#### `/infra/core/search`
- **`search-services.tf`** - Configuration for Search Services.
- **`outputs.tf`** - Outputs for Search Services.
- **`variables.tf`** - Variables for Search Services.

#### `/infra/core/security`
- **`/keyvault`** - Configuration for Azure Key Vault.
  - **`keyvault.tf`** - Terraform configuration for Key Vault.
  - **`outputs.tf`** - Outputs for Key Vault.
  - **`variables.tf`** - Variables for Key Vault.

- **`/keyvaultSecret`** - Configuration for Key Vault Secrets.
  - **`keyvaultSecret.tf`** - Terraform configuration for Key Vault Secrets.
  - **`outputs.tf`** - Outputs for Key Vault Secrets.
  - **`variables.tf`** - Variables for Key Vault Secrets.

- **`/role`** - Configuration for Azure Roles.
  - **`role.tf`** - Terraform configuration for Azure Roles.
  - **`variables.tf`** - Variables for Azure Roles.

#### `/infra/core/sharepoint`
- **`sharepoint.tf`** - Configuration for SharePoint.
- **`variables.tf`** - Variables for SharePoint.

#### `/infra/core/storage`
- **`storage-account.tf`** - Configuration for Azure Storage Account.
- **`outputs.tf`** - Outputs for Storage Account.
- **`variables.tf`** - Variables for Storage Account.

#### `/infra/core/videoindexer`
- **`vi.tf`** - Configuration for Video Indexer.
- **`variables.tf`** - Variables for Video Indexer.

### `/infra/local.env.example`

Example environment variable file.


## Azure Cost Calculator

To estimate the cost of the infrastructure deployment, use the Azure Cost Calculator linked below:

[Azure Cost Calculator](https://azure.com/e/ae102543d82a4e7da4f083904947fc32)

---

For any questions or issues, please do not hestitate to contact me.
