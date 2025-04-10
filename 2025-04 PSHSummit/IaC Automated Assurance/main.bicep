@description('Storage Account type')
@allowed([
  'dev'
  'prod'
  'uat'
])
param environment string = 'uat'

@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountType string = 'Standard_LRS'

@description('The storage account location.')
param location string = resourceGroup().location

param storageAccountName string

var metricAlerts_Used_capacity_name = 'Used capacity'
var actionGroup = '{storageAccountName}-ag'
var metricAlerts_Storage_Availability_name = 'Storage Availability'
var metricAlerts_Transactions_threshold_name = 'Transaction threshold'

resource actionGroup_resource 'microsoft.insights/actionGroups@2024-10-01-preview' = {
  name: actionGroup
  location: 'Global'
  properties: {
    groupShortName: 'storage'
    enabled: true
    emailReceivers: [
      {
        name: 'admin'
        emailAddress: 'admin@contoso.com'
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: []
    webhookReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: []
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
  }
  tags: {
    costCentre: 'a10000'
    env: environment
  }
}

resource metricAlerts_Storage_Availability_name_resource 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: metricAlerts_Storage_Availability_name
  location: 'global'
  properties: {
    severity: 3
    enabled: true
    scopes: [
      storageAccount.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          threshold: json('90')
          name: 'Metric1'
          metricNamespace: 'Microsoft.Storage/storageAccounts'
          metricName: 'Availability'
          operator: 'LessThan'
          timeAggregation: 'Average'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Storage/storageAccounts'
    targetResourceRegion: 'westus2'
    actions: [
      {
        actionGroupId: actionGroup_resource.id
        webHookProperties: {}
      }
    ]
  }
}

resource metricAlerts_Transactions_threshold_name_resource 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: metricAlerts_Transactions_threshold_name
  location: 'global'
  properties: {
    severity: 3
    enabled: true
    scopes: [
      storageAccount.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          alertSensitivity: 'Medium'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 4
          }
          name: 'Metric1'
          metricNamespace: 'Microsoft.Storage/storageAccounts'
          metricName: 'Transactions'
          operator: 'GreaterOrLessThan'
          timeAggregation: 'Total'
          skipMetricValidation: false
          criterionType: 'DynamicThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Storage/storageAccounts'
    targetResourceRegion: 'westus2'
    actions: [
      {
        actionGroupId: actionGroup_resource.id
        webHookProperties: {}
      }
    ]
  }
}

resource metricAlerts_Used_capacity_name_resource 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: metricAlerts_Used_capacity_name
  location: 'global'
  properties: {
    severity: 3
    enabled: true
    scopes: [
      storageAccount.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          threshold: json('10')
          name: 'Metric1'
          metricNamespace: 'Microsoft.Storage/storageAccounts'
          metricName: 'UsedCapacity'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Storage/storageAccounts'
    targetResourceRegion: 'westus2'
    actions: [
      {
        actionGroupId: actionGroup_resource.id
        webHookProperties: {}
      }
    ]
  }
}
