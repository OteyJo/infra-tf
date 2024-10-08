locals {
  tags            = { ProjectName = "Modern Enterprise Search", BuildNumber = var.buildNumber }
  azure_roles     = jsondecode(file("${path.module}/azure_roles.json"))
  selected_roles  = ["CognitiveServicesOpenAIUser", 
                      "StorageBlobDataReader", 
                      "StorageBlobDataContributor", 
                      "SearchIndexDataReader", 
                      "SearchIndexDataContributor"]
}

data "azurerm_client_config" "current" {}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

// Organize resources in a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName != "" ? var.resourceGroupName : "mes-${var.environmentName}"
  location = var.location
  tags     = local.tags
}

module "entraObjects" {
  source                            = "./core/aad"
  isInAutomation                    = var.isInAutomation
  requireWebsiteSecurityMembership  = var.requireWebsiteSecurityMembership
  randomString                      = random_string.random.result
  azure_websites_domain             = var.azure_websites_domain
  aadWebClientId                    = var.aadWebClientId
  aadMgmtClientId                   = var.aadMgmtClientId
  aadMgmtServicePrincipalId         = var.aadMgmtServicePrincipalId
  aadMgmtClientSecret               = var.aadMgmtClientSecret
  entraOwners                       = var.entraOwners
  serviceManagementReference        = var.serviceManagementReference
  password_lifetime                 = var.password_lifetime
}

// Create the Virtual Network, Subnets, and Network Security Group
module "network" {
  source                          = "./core/network/network"
  count                           = var.is_secure_mode ? 1 : 0
  vnet_name                       = "mes-vnet-${random_string.random.result}"
  nsg_name                        = "mes-nsg-${random_string.random.result}"
  ddos_name                       = "mes-ddos-${random_string.random.result}"
  dns_resolver_name               = "mes-dns-${random_string.random.result}"
  enabledDDOSProtectionPlan       = var.enabledDDOSProtectionPlan
  ddos_plan_id                    = var.ddos_plan_id
  location                        = var.location
  tags                            = local.tags
  resourceGroupName               = azurerm_resource_group.rg.name
  vnetIpAddressCIDR               = var.virtual_network_CIDR
  snetAzureMonitorCIDR            = var.azure_monitor_CIDR
  snetStorageAccountCIDR          = var.storage_account_CIDR
  snetCosmosDbCIDR                = var.cosmos_db_CIDR
  snetAzureAiCIDR                 = var.azure_ai_CIDR
  snetKeyVaultCIDR                = var.key_vault_CIDR
  snetAppCIDR                     = var.webapp_CIDR
  snetFunctionCIDR                = var.functions_CIDR
  snetEnrichmentCIDR              = var.enrichment_app_CIDR
  snetIntegrationCIDR             = var.integration_CIDR
  snetSearchServiceCIDR           = var.search_service_CIDR
  snetAzureVideoIndexerCIDR       = var.azure_video_indexer_CIDR
  snetBingServiceCIDR             = var.bing_service_CIDR
  snetAzureOpenAICIDR             = var.azure_openAI_CIDR
  snetACRCIDR                     = var.acr_CIDR
  snetDnsCIDR                     = var.dns_CIDR
  arm_template_schema_mgmt_api    = var.arm_template_schema_mgmt_api
  azure_environment               = var.azure_environment
}

// Create the Private DNS Zones for all the services
module "privateDnsZoneAzureOpenAi" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_openai_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-azure-openai-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneAzureAi" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_ai_private_link_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-azure-ai-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneApp" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_websites_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-app-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneKeyVault" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_keyvault_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-kv-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneStorageAccountBlob" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.blob.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-storage-blob-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}


module "privateDnsZoneStorageAccountFile" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.file.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-storage-file-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneStorageAccountTable" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.table.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-storage-table-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneStorageAccountQueue" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.queue.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-storage-queue-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneSearchService" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_search_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-search-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneCosmosDb" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.cosmosdb_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-cosmos-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "privateDnsZoneACR" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_acr_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "mes-acr-vnetlink-${random_string.random.result}"
  virtual_network_id = var.is_secure_mode ? module.network[0].vnet_id : null
  tags               = local.tags
  depends_on = [ module.network[0] ]
}

module "logging" {
  depends_on = [ module.network ]
  source = "./core/logging/loganalytics"
  logAnalyticsName        = var.logAnalyticsName != "" ? var.logAnalyticsName : "mes-la-${random_string.random.result}"
  applicationInsightsName = var.applicationInsightsName != "" ? var.applicationInsightsName : "mes-ai-${random_string.random.result}"
  location                = var.location
  tags                    = local.tags
  skuName                 = "PerGB2018"
  resourceGroupName       = azurerm_resource_group.rg.name
  is_secure_mode                        = var.is_secure_mode
  privateLinkScopeName                  = "mes-ampls-${random_string.random.result}"
  privateDnsZoneNameMonitor             = "privatelink.${var.azure_monitor_domain}"
  privateDnsZoneNameOms                 = "privatelink.${var.azure_monitor_oms_domain}"
  privateDnSZoneNameOds                 = "privatelink.${var.azure_monitor_ods_domain}"
  privateDnsZoneNameAutomation          = "privatelink.${var.azure_automation_domain}"
  privateDnsZoneResourceIdBlob          = var.is_secure_mode ? module.privateDnsZoneStorageAccountBlob[0].privateDnsZoneResourceId : null
  privateDnsZoneNameBlob                = var.is_secure_mode ? module.privateDnsZoneStorageAccountBlob[0].privateDnsZoneName : null
  groupId                               = "azuremonitor"
  subnet_name                           = var.is_secure_mode ? module.network[0].snetAmpls_name : null
  vnet_name                             = var.is_secure_mode ? module.network[0].vnet_name : null
  ampls_subnet_CIDR                     = var.azure_monitor_CIDR
  vnet_id                               = var.is_secure_mode ? module.network[0].vnet_id : null
  nsg_id                                = var.is_secure_mode ? module.network[0].nsg_id : null
  nsg_name                              = var.is_secure_mode ? module.network[0].nsg_name : null
}

module "storage" {
  source                          = "./core/storage"
  name                            = var.storageAccountName != "" ? var.storageAccountName : "messtore${random_string.random.result}"
  location                        = var.location
  tags                            = local.tags
  accessTier                      = "Hot"
  allowBlobPublicAccess           = false
  resourceGroupName               = azurerm_resource_group.rg.name
  arm_template_schema_mgmt_api    = var.arm_template_schema_mgmt_api
  key_vault_name                  = module.kvModule.keyVaultName
  deleteRetentionPolicy = {
    days                          = 7
  }
  containers                      = ["content","website","upload","function","logs","config"]
  queueNames                      = ["pdf-submit-queue","pdf-polling-queue","non-pdf-submit-queue","media-submit-queue","text-enrichment-queue","image-enrichment-queue","embeddings-queue"]
  is_secure_mode                  = var.is_secure_mode
  subnet_name                     = var.is_secure_mode ? module.network[0].snetStorage_name : null
  vnet_name                       = var.is_secure_mode ? module.network[0].vnet_name : null
  private_dns_zone_ids            = var.is_secure_mode ? [module.privateDnsZoneStorageAccountBlob[0].privateDnsZoneResourceId,
                                       module.privateDnsZoneStorageAccountFile[0].privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountTable[0].privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountQueue[0].privateDnsZoneResourceId] : null
  network_rules_allowed_subnets   = var.is_secure_mode ? [module.network[0].snetIntegration_id, module.network[0].snetFunction_id] : null
  kv_secret_expiration            = var.kv_secret_expiration
  logAnalyticsWorkspaceResourceId = module.logging.logAnalyticsId
}

module "kvModule" {
  source                        = "./core/security/keyvault" 
  name                          = "mes-kv-${random_string.random.result}"
  location                      = var.location
  kvAccessObjectId              = data.azurerm_client_config.current.object_id 
  spClientSecret                = module.entraObjects.azure_ad_mgmt_app_secret 
  resourceGroupName             = azurerm_resource_group.rg.name
  tags                          = local.tags
  is_secure_mode                = var.is_secure_mode
  subnet_name                   = var.is_secure_mode ? module.network[0].snetKeyVault_name : null
  vnet_name                     = var.is_secure_mode ? module.network[0].vnet_name : null
  subnet_id                     = var.is_secure_mode ? module.network[0].snetKeyVault_id : null
  private_dns_zone_ids          = var.is_secure_mode ? [module.privateDnsZoneApp[0].privateDnsZoneResourceId] : null
  depends_on                    = [ module.entraObjects, module.privateDnsZoneKeyVault[0] ]
  azure_keyvault_domain         = var.azure_keyvault_domain
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  kv_secret_expiration          = var.kv_secret_expiration
}

module "enrichmentApp" {
  source                                    = "./core/host/enrichmentapp"
  name                                      = var.enrichmentServiceName != "" ? var.enrichmentServiceName : "mes-enrichmentweb-${random_string.random.result}"
  plan_name                                 = var.enrichmentAppServicePlanName != "" ? var.enrichmentAppServicePlanName : "mes-enrichmentasp-${random_string.random.result}"
  location                                  = var.location 
  tags                                      = local.tags
  sku = {
    size                                    = var.enrichmentAppServiceSkuSize
    tier                                    = var.enrichmentAppServiceSkuTier
    capacity                                = 3
  }
  kind                                      = "linux"
  reserved                                  = true
  resourceGroupName                         = azurerm_resource_group.rg.name
  storageAccountId                          = "/subscriptions/${var.subscriptionId}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${module.storage.name}/services/queue/queues/${var.embeddingsQueue}"
  scmDoBuildDuringDeployment                = false
  enableOryxBuild                           = false
  managedIdentity                           = true
  logAnalyticsWorkspaceResourceId           = module.logging.logAnalyticsId
  applicationInsightsConnectionString       = module.logging.applicationInsightsConnectionString
  alwaysOn                                  = true
  healthCheckPath                           = "/health"
  appCommandLine                            = ""
  keyVaultUri                               = module.kvModule.keyVaultUri
  keyVaultName                              = module.kvModule.keyVaultName
  container_registry                        = module.acr.login_server
  container_registry_admin_username         = module.acr.admin_username
  container_registry_admin_password         = module.acr.admin_password
  container_registry_id                     = module.acr.acr_id
  is_secure_mode                            = var.is_secure_mode
  subnetIntegration_id                      = var.is_secure_mode ? module.network[0].snetIntegration_id : null
  subnet_name                               = var.is_secure_mode ? module.network[0].snetEnrichment_name : null
  vnet_name                                 = var.is_secure_mode ? module.network[0].vnet_name : null
  private_dns_zone_ids                      = var.is_secure_mode ? [module.privateDnsZoneApp[0].privateDnsZoneResourceId] : null
  azure_environment                         = var.azure_environment

  appSettings = {
    EMBEDDINGS_QUEUE                        = var.embeddingsQueue
    LOG_LEVEL                               = "DEBUG"
    DEQUEUE_MESSAGE_BATCH_SIZE              = 1
    AZURE_BLOB_STORAGE_ACCOUNT              = module.storage.name
    AZURE_BLOB_STORAGE_CONTAINER            = var.contentContainerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER     = var.uploadContainerName
    AZURE_BLOB_STORAGE_ENDPOINT             = module.storage.primary_endpoints
    COSMOSDB_URL                            = module.cosmosdb.CosmosDBEndpointURL
    COSMOSDB_LOG_DATABASE_NAME              = module.cosmosdb.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME             = module.cosmosdb.CosmosDBLogContainerName
    MAX_EMBEDDING_REQUEUE_COUNT             = 5
    EMBEDDING_REQUEUE_BACKOFF               = 60
    AZURE_OPENAI_SERVICE                    = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.openaiServices.name
    AZURE_OPENAI_ENDPOINT                   = var.useExistingAOAIService ? "https://${var.azureOpenAIServiceName}.${var.azure_openai_domain}/" : module.openaiServices.endpoint
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME  = var.azureOpenAIEmbeddingDeploymentName
    AZURE_SEARCH_INDEX                      = var.searchIndexName
    AZURE_SEARCH_SERVICE                    = module.searchServices.name
    TARGET_EMBEDDINGS_MODEL                 = var.useAzureOpenAIEmbeddings ? "azure-openai_${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    EMBEDDING_VECTOR_SIZE                   = var.useAzureOpenAIEmbeddings ? 1536 : var.sentenceTransformerEmbeddingVectorSize
    AZURE_SEARCH_SERVICE_ENDPOINT           = module.searchServices.endpoint
  }
}

# // The application frontend
module "webapp" {
  source                              = "./core/host/webapp"
  name                                = var.backendServiceName != "" ? var.backendServiceName : "mes-web-${random_string.random.result}"
  plan_name                           = var.appServicePlanName != "" ? var.appServicePlanName : "mes-asp-${random_string.random.result}"
  sku = {
    tier                              = var.appServiceSkuTier
    size                              = var.appServiceSkuSize
    capacity                          = 1
  }
  kind                                = "linux"
  resourceGroupName                   = azurerm_resource_group.rg.name
  location                            = var.location
  tags                                = merge(local.tags, { "azd-service-name" = "backend" })
  runtimeVersion                      = "3.10" 
  scmDoBuildDuringDeployment          = false
  managedIdentity                     = true
  alwaysOn                            = true
  appCommandLine                      = ""
  healthCheckPath                     = "/health"
  logAnalyticsWorkspaceResourceId     = module.logging.logAnalyticsId
  azure_portal_domain                 = var.azure_portal_domain
  enableOryxBuild                     = false
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString
  keyVaultUri                         = module.kvModule.keyVaultUri
  keyVaultName                        = module.kvModule.keyVaultName
  tenantId                            = var.tenantId
  is_secure_mode                      = var.is_secure_mode
  subnet_id                           = var.is_secure_mode ? module.network[0].snetApp_id : null
  vnet_name                           = var.is_secure_mode ? module.network[0].vnet_name : null
  snetIntegration_id                  = var.is_secure_mode ? module.network[0].snetIntegration_id : null
  private_dns_zone_ids                = var.is_secure_mode ? [module.privateDnsZoneApp[0].privateDnsZoneResourceId] : null
  private_dns_zone_name               = var.is_secure_mode ? module.privateDnsZoneApp[0].privateDnsZoneName : null

  container_registry                  = module.acr.login_server
  container_registry_admin_username   = module.acr.admin_username
  container_registry_admin_password   = module.acr.admin_password
  container_registry_id               = module.acr.acr_id
  randomString                        = random_string.random.result
  azure_environment                   = var.azure_environment 

  appSettings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING   = module.logging.applicationInsightsConnectionString
    AZURE_BLOB_STORAGE_ACCOUNT              = module.storage.name
    AZURE_BLOB_STORAGE_ENDPOINT             = module.storage.primary_endpoints
    AZURE_BLOB_STORAGE_CONTAINER            = var.contentContainerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER     = var.uploadContainerName
    AZURE_OPENAI_SERVICE                    = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.openaiServices.name
    AZURE_OPENAI_RESOURCE_GROUP             = var.useExistingAOAIService ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
    AZURE_OPENAI_ENDPOINT                   = var.useExistingAOAIService ? "https://${var.azureOpenAIServiceName}.${var.azure_openai_domain}/" : module.openaiServices.endpoint
    AZURE_OPENAI_AUTHORITY_HOST             = var.azure_openai_authority_host
    AZURE_ARM_MANAGEMENT_API                = var.azure_arm_management_api
    AZURE_SEARCH_INDEX                      = var.searchIndexName
    AZURE_SEARCH_SERVICE                    = module.searchServices.name
    AZURE_SEARCH_SERVICE_ENDPOINT           = module.searchServices.endpoint
    AZURE_OPENAI_CHATGPT_DEPLOYMENT         = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
    AZURE_OPENAI_CHATGPT_MODEL_NAME         = var.chatGptModelName
    AZURE_OPENAI_CHATGPT_MODEL_VERSION      = var.chatGptModelVersion
    USE_AZURE_OPENAI_EMBEDDINGS             = var.useAzureOpenAIEmbeddings
    EMBEDDING_DEPLOYMENT_NAME               = var.useAzureOpenAIEmbeddings ? var.azureOpenAIEmbeddingDeploymentName : var.sentenceTransformersModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_NAME      = var.azureOpenAIEmbeddingsModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION   = var.azureOpenAIEmbeddingsModelVersion
    APPINSIGHTS_INSTRUMENTATIONKEY          = module.logging.applicationInsightsInstrumentationKey
    COSMOSDB_URL                            = module.cosmosdb.CosmosDBEndpointURL
    COSMOSDB_LOG_DATABASE_NAME              = module.cosmosdb.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME             = module.cosmosdb.CosmosDBLogContainerName
    QUERY_TERM_LANGUAGE                     = var.queryTermLanguage
    AZURE_SUBSCRIPTION_ID                   = data.azurerm_client_config.current.subscription_id
    CHAT_WARNING_BANNER_TEXT                = var.chatWarningBannerText
    TARGET_EMBEDDINGS_MODEL                 = var.useAzureOpenAIEmbeddings ? "azure-openai_${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    ENRICHMENT_APPSERVICE_URL               = module.enrichmentApp.uri
    AZURE_AI_ENDPOINT                       = module.cognitiveServices.cognitiveServiceEndpoint
    AZURE_AI_LOCATION                       = var.location
    APPLICATION_TITLE                       = var.applicationtitle == "" ? "Modern Enterprise Search" : var.applicationtitle
    USE_SEMANTIC_RERANKER                   = var.use_semantic_reranker
    BING_SEARCH_ENDPOINT                    = var.enableWebChat ? module.bingSearch[0].endpoint : ""
    ENABLE_WEB_CHAT                         = var.enableWebChat
    ENABLE_BING_SAFE_SEARCH                 = var.enableBingSafeSearch
    ENABLE_UNGROUNDED_CHAT                  = var.enableUngroundedChat
    ENABLE_MULTIMEDIA                       = var.enableMultimedia
    MAX_CSV_FILE_SIZE                       = var.maxCsvFileSize
  }

  aadClientId = module.entraObjects.azure_ad_web_app_client_id
  depends_on = [ module.kvModule ]
}

# // Function App 
module "functions" { 
  source = "./core/host/functions"

  name                                  = var.functionsAppName != "" ? var.functionsAppName : "mes-func-${random_string.random.result}"
  location                              = var.location
  tags                                  = local.tags
  keyVaultUri                           = module.kvModule.keyVaultUri
  keyVaultName                          = module.kvModule.keyVaultName 
  plan_name                             = var.appServicePlanName != "" ? var.appServicePlanName : "mes-func-asp-${random_string.random.result}"
  sku                                   = {
    size                                = var.functionsAppSkuSize
    tier                                = var.functionsAppSkuTier
    capacity                            = 2
  }
  kind                                  = "linux"
  runtime                               = "python"
  resourceGroupName                     = azurerm_resource_group.rg.name
  azure_portal_domain                   = var.azure_portal_domain
  appInsightsConnectionString           = module.logging.applicationInsightsConnectionString
  appInsightsInstrumentationKey         = module.logging.applicationInsightsInstrumentationKey
  blobStorageAccountName                = module.storage.name
  blobStorageAccountEndpoint            = module.storage.primary_endpoints
  blobStorageAccountOutputContainerName = var.contentContainerName
  blobStorageAccountUploadContainerName = var.uploadContainerName 
  blobStorageAccountLogContainerName    = var.functionLogsContainerName 
  formRecognizerEndpoint                = module.aiDocIntelligence.formRecognizerAccountEndpoint
  CosmosDBEndpointURL                   = module.cosmosdb.CosmosDBEndpointURL
  CosmosDBLogDatabaseName               = module.cosmosdb.CosmosDBLogDatabaseName
  CosmosDBLogContainerName              = module.cosmosdb.CosmosDBLogContainerName
  chunkTargetSize                       = var.chunkTargetSize
  targetPages                           = var.targetPages
  formRecognizerApiVersion              = var.formRecognizerApiVersion
  pdfSubmitQueue                        = var.pdfSubmitQueue
  pdfPollingQueue                       = var.pdfPollingQueue
  nonPdfSubmitQueue                     = var.nonPdfSubmitQueue
  mediaSubmitQueue                      = var.mediaSubmitQueue
  maxSecondsHideOnUpload                = var.maxSecondsHideOnUpload
  maxSubmitRequeueCount                 = var.maxSubmitRequeueCount
  pollQueueSubmitBackoff                = var.pollQueueSubmitBackoff
  pdfSubmitQueueBackoff                 = var.pdfSubmitQueueBackoff
  textEnrichmentQueue                   = var.textEnrichmentQueue
  imageEnrichmentQueue                  = var.imageEnrichmentQueue
  maxPollingRequeueCount                = var.maxPollingRequeueCount
  submitRequeueHideSeconds              = var.submitRequeueHideSeconds
  pollingBackoff                        = var.pollingBackoff
  maxReadAttempts                       = var.maxReadAttempts
  enrichmentEndpoint                    = module.cognitiveServices.cognitiveServiceEndpoint
  enrichmentName                        = module.cognitiveServices.cognitiveServicerAccountName
  enrichmentLocation                    = var.location
  targetTranslationLanguage             = var.targetTranslationLanguage
  maxEnrichmentRequeueCount             = var.maxEnrichmentRequeueCount
  enrichmentBackoff                     = var.enrichmentBackoff
  enableDevCode                         = var.enableDevCode
  EMBEDDINGS_QUEUE                      = var.embeddingsQueue
  azureSearchIndex                      = var.searchIndexName
  azureSearchServiceEndpoint            = module.searchServices.endpoint
  endpointSuffix                        = var.azure_storage_domain
  logAnalyticsWorkspaceResourceId       = module.logging.logAnalyticsId
  is_secure_mode                        = var.is_secure_mode
  vnet_name                             = var.is_secure_mode ? module.network[0].vnet_name : null
  subnet_name                           = var.is_secure_mode ? module.network[0].snetFunction_name : null
  subnetIntegration_id                  = var.is_secure_mode ? module.network[0].snetIntegration_id : null
  private_dns_zone_ids                  = var.is_secure_mode ? [module.privateDnsZoneApp[0].privateDnsZoneResourceId] : null
  container_registry                    = module.acr.login_server
  container_registry_admin_username     = module.acr.admin_username
  container_registry_admin_password     = module.acr.admin_password
  container_registry_id                 = module.acr.acr_id
  azure_environment                     = var.azure_environment
}

module "openaiServices" {
  source                          = "./core/ai/openaiservices"
  name                            = var.openAIServiceName != "" ? var.openAIServiceName : "mes-aoai-${random_string.random.result}"
  location                        = var.location
  tags                            = local.tags
  resourceGroupName               = azurerm_resource_group.rg.name
  openaiServiceKey                = var.azureOpenAIServiceKey
  useExistingAOAIService          = var.useExistingAOAIService
  is_secure_mode                  = var.is_secure_mode
  subnet_name                     = var.is_secure_mode ? module.network[0].snetAzureOpenAI_name : null
  vnet_name                       = var.is_secure_mode ? module.network[0].vnet_name : null
  subnet_id                       = var.is_secure_mode ? module.network[0].snetAzureOpenAI_id : null
  private_dns_zone_ids            = var.is_secure_mode ? [module.privateDnsZoneAzureOpenAi[0].privateDnsZoneResourceId] : null
  arm_template_schema_mgmt_api    = var.arm_template_schema_mgmt_api
  key_vault_name                  = module.kvModule.keyVaultName
  kv_secret_expiration            = var.kv_secret_expiration
  logAnalyticsWorkspaceResourceId = module.logging.logAnalyticsId

  deployments = [
    {
      name            = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
      model           = {
        format        = "OpenAI"
        name          = var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k"
        version       = var.chatGptModelVersion != "" ? var.chatGptModelVersion : "0613"
      }
      sku_name        = var.chatGptModelSkuName
      sku_capacity    = var.chatGptDeploymentCapacity
      rai_policy_name = "Microsoft.Default"
    },
    {
      name            = var.azureOpenAIEmbeddingDeploymentName != "" ? var.azureOpenAIEmbeddingDeploymentName : "text-embedding-ada-002"
      model           = {
        format        = "OpenAI"
        name          = var.azureOpenAIEmbeddingsModelName != "" ? var.azureOpenAIEmbeddingsModelName : "text-embedding-ada-002"
        version       = "2"
      }
      sku_name        = var.azureOpenAIEmbeddingsModelSku
      sku_capacity    = var.embeddingsDeploymentCapacity
      rai_policy_name = "Microsoft.Default"
    }
  ]
}

module "aiDocIntelligence" {
  source                        = "./core/ai/docintelligence"
  name                          = "mes-docint-${random_string.random.result}"
  location                      = var.location
  tags                          = local.tags
  customSubDomainName           = "mes-docint-${random_string.random.result}"
  resourceGroupName             = azurerm_resource_group.rg.name
  key_vault_name                = module.kvModule.keyVaultName
  is_secure_mode                = var.is_secure_mode
  subnet_name                   = var.is_secure_mode ? module.network[0].snetAzureAi_name : null
  vnet_name                     = var.is_secure_mode ? module.network[0].vnet_name : null
  private_dns_zone_ids          = var.is_secure_mode ? [module.privateDnsZoneAzureAi[0].privateDnsZoneResourceId] : null
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  kv_secret_expiration          = var.kv_secret_expiration
}

module "cognitiveServices" {
  source                        = "./core/ai/cogServices"
  name                          = "mes-aisvc-${random_string.random.result}"
  location                      = var.location 
  tags                          = local.tags
  resourceGroupName             = azurerm_resource_group.rg.name
  is_secure_mode                = var.is_secure_mode
  subnetResourceId              = var.is_secure_mode ? module.network[0].snetAzureAi_id : null
  private_dns_zone_ids          = var.is_secure_mode ? [module.privateDnsZoneAzureAi[0].privateDnsZoneResourceId] : null
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  key_vault_name                = module.kvModule.keyVaultName
  kv_secret_expiration          = var.kv_secret_expiration
  vnet_name                     = var.is_secure_mode ? module.network[0].vnet_name : null
  subnet_name                   = var.is_secure_mode ? module.network[0].snetAzureAi_name : null
}

module "searchServices" {
  source                        = "./core/search"
  name                          = var.searchServicesName != "" ? var.searchServicesName : "mes-search-${random_string.random.result}"
  location                      = var.location
  tags                          = local.tags
  semanticSearch                = var.use_semantic_reranker ? "free" : null
  resourceGroupName             = azurerm_resource_group.rg.name
  azure_search_domain           = var.azure_search_domain
  is_secure_mode                = var.is_secure_mode
  subnet_name                   = var.is_secure_mode ? module.network[0].snetSearch_name : null
  vnet_name                     = var.is_secure_mode ? module.network[0].vnet_name : null
  private_dns_zone_ids          = var.is_secure_mode ? [module.privateDnsZoneSearchService[0].privateDnsZoneResourceId] : null
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  key_vault_name                = module.kvModule.keyVaultName
  kv_secret_expiration          = var.kv_secret_expiration
}

module "cosmosdb" {
  source = "./core/db"
  name                          = "mes-cosmos-${random_string.random.result}"
  location                      = var.location
  tags                          = local.tags
  logDatabaseName               = "statusdb"
  logContainerName              = "statuscontainer"
  resourceGroupName             = azurerm_resource_group.rg.name
  key_vault_name                = module.kvModule.keyVaultName
  is_secure_mode                = var.is_secure_mode  
  subnet_name                   = var.is_secure_mode ? module.network[0].snetCosmosDb_name : null
  vnet_name                     = var.is_secure_mode ? module.network[0].vnet_name : null
  private_dns_zone_ids          = var.is_secure_mode ? [module.privateDnsZoneCosmosDb[0].privateDnsZoneResourceId] : null
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  kv_secret_expiration          = var.kv_secret_expiration
}

module "acr"{
  source                = "./core/container_registry"
  name                  = "mesacr${random_string.random.result}" 
  location              = var.location
  resourceGroupName     = azurerm_resource_group.rg.name
  is_secure_mode        = var.is_secure_mode
  subnet_name           = var.is_secure_mode ? module.network[0].snetACR_name : null
  vnet_name             = var.is_secure_mode ? module.network[0].vnet_name : null
  private_dns_zone_name = var.is_secure_mode ? module.privateDnsZoneACR[0].privateDnsZoneName : null
  private_dns_zone_ids  = var.is_secure_mode ? [module.privateDnsZoneACR[0].privateDnsZoneResourceId] : null
}

// SharePoint Connector is not supported in secure mode
module "sharepoint" {
  count                               = var.is_secure_mode ? 0 : var.enableSharePointConnector ? 1 : 0
  source                              = "./core/sharepoint"
  location                            = azurerm_resource_group.rg.location
  resource_group_name                 = azurerm_resource_group.rg.name
  resource_group_id                   = azurerm_resource_group.rg.id
  subscription_id                     = data.azurerm_client_config.current.subscription_id
  storage_account_name                = module.storage.name
  storage_access_key                  = module.storage.storage_account_access_key
  random_string                       = random_string.random.result
  tags                                = local.tags

  depends_on = [
    module.storage
  ]
}

// Video Indexer is not supported in secure mode
module "video_indexer" {
  count                               = var.is_secure_mode ? 0 : var.enableMultimedia ? 1 : 0
  source                              = "./core/videoindexer"
  location                            = azurerm_resource_group.rg.location
  resource_group_name                 = azurerm_resource_group.rg.name
  subscription_id                     = data.azurerm_client_config.current.subscription_id
  random_string                       = random_string.random.result
  tags                                = local.tags
  azuread_service_principal_object_id = module.entraObjects.azure_ad_web_app_client_id
  arm_template_schema_mgmt_api        = var.arm_template_schema_mgmt_api
  video_indexer_api_version           = var.video_indexer_api_version
}

module "azMonitor" {
  source            = "./core/logging/monitor"
  logAnalyticsName  = module.logging.logAnalyticsName
  location          = var.location
  logWorkbookName   = "mes-lw-${random_string.random.result}"
  resourceGroupName = azurerm_resource_group.rg.name 
  componentResource = "/subscriptions/${var.subscriptionId}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.OperationalInsights/workspaces/${module.logging.logAnalyticsName}"
}

// Bing Search is not supported in US Government or Secure Mode
module "bingSearch" {
  count                         = var.azure_environment == "AzureUSGovernment" ? 0 : var.is_secure_mode ? 0 : var.enableWebChat ? 1 : 0
  source                        = "./core/ai/bingSearch"
  name                          = "mes-bing-${random_string.random.result}"
  resourceGroupName             = azurerm_resource_group.rg.name
  tags                          = local.tags
  sku                           = "S1" //supported SKUs can be found at https://www.microsoft.com/en-us/bing/apis/pricing
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  key_vault_name                = module.kvModule.keyVaultName
  kv_secret_expiration          = var.kv_secret_expiration
}

// USER ROLES
module "userRoles" {
  source = "./core/security/role"
  for_each = { for role in local.selected_roles : role => { role_definition_id = local.azure_roles[role] } }

  scope            = azurerm_resource_group.rg.id
  principalId      = data.azurerm_client_config.current.object_id 
  roleDefinitionId = each.value.role_definition_id
  principalType    = var.isInAutomation ? "ServicePrincipal" : "User"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

data "azurerm_resource_group" "existing" {
  count = var.useExistingAOAIService ? 1 : 0
  name  = var.azureOpenAIResourceGroup
}

# # // SYSTEM IDENTITY ROLES
module "openAiRoleBackend" {
  source = "./core/security/role"

  scope            = var.useExistingAOAIService ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "storageRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.StorageBlobDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "searchRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.SearchIndexDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "storageRoleFunc" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.functions.function_app_identity_principal_id
  roleDefinitionId = local.azure_roles.StorageBlobDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "aviRoleBackend" {
  source            = "./core/security/role"
  count             = var.enableMultimedia ? 1 : 0
  scope             = module.video_indexer[0].vi_id
  principalId       = module.webapp.identityPrincipalId
  roleDefinitionId  = local.azure_roles.Contributor
  principalType     = "ServicePrincipal"
  subscriptionId    = data.azurerm_client_config.current.subscription_id
  resourceGroupId   = azurerm_resource_group.rg.id 
}

# // MANAGEMENT SERVICE PRINCIPAL ROLES
module "openAiRoleMgmt" {
  source = "./core/security/role"
  # If leveraging an existing Azure OpenAI service, only make this assignment if not under automation.
  # When under automation and using an existing Azure OpenAI service, this will result in a duplicate assignment error.
  count = var.useExistingAOAIService ? var.isInAutomation ? 0 : 1 : 1
  scope = var.useExistingAOAIService ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg.id
  principalId     = module.entraObjects.azure_ad_mgmt_sp_id
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType   = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

// DEPLOYMENT OF AZURE CUSTOMER ATTRIBUTION TAG
resource "azurerm_resource_group_template_deployment" "customer_attribution" {
  count               = var.cuaEnabled ? 1 : 0
  name                = "pid-${var.cuaId}"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_content    = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": []
}
TEMPLATE
}