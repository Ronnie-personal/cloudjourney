Connect-AzAccount
Set-AzContext $env:secondSubId

# create resource group
$rgName = $env:myRG
$location = "westus"
New-AzResourceGroup -Name $rgName -Location $location

<# create a new AAD user and grant Azure RBAC permission
  if you haven't installed AzureAD module, run following command
  Install-Module -Name AzureAD
  When run Connect-AzureAD, the interactive sign in window might hide in the background
  https://azsec.azurewebsites.net/2018/01/13/connect-to-azure-ad-using-microsoft-account-with-powershell/
  #>
Connect-AzureAD -TenantId "$env:tenantId"
Get-AzureADCurrentSessionInfo
$domainName = ((Get-AzureAdTenantDetail).VerifiedDomains)[0].Name
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = $env:password
$passwordProfile.ForceChangePasswordNextLogin = $false
New-AzureADUser -AccountEnabled $true -DisplayName 'testuser1' -PasswordProfile $passwordProfile -MailNickName 'testuser1' -UserPrincipalName "testuser1@$domainName"

# get user's object Id and assign Azure resource RBAC permission
$objectId = (Get-AzADUser -UserPrincipalName "testuser1@$domainName").Id
New-AzRoleAssignment -ResourceGroupName $rgName -RoleDefinitionName "reader" -ObjectId $objectId 

# create IP group
$ipGroupName = "workloadGroup"
$ipGroup = @{
    Name              = $ipGroupName
    ResourceGroupName = $rgName
    Location          = $location
    IpAddress         = @('10.2.0.0/24', '10.2.1.0/26') 
}

New-AzIpGroup @ipGroup

(Get-AzIPGroup -ResourceGroupName $rgName -Name 'workloadGroup').IpAddresses

<# To create a client ID, https://www.seb8iaan.com/the-difference-between-azuread-app-registrations-and-enterprise-applications-explained/
   https://adatum.no/azure/azure-ad-application-using-powershell
#>
$AzureMgmtPrincipal = Get-AzureADServicePrincipal -All $true | Where-Object {$_.DisplayName -eq "Windows Azure Service Management API"}
$AzureMgmtAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureMgmtAccess.ResourceAppId = $AzureMgmtPrincipal.AppId

# Permissions
# .Oauth2Permissions
## Delegated Permissions
# Azure Mgmt
$AzureSvcMgmt = New-Object -TypeName "microsoft.open.azuread.model.resourceAccess" -ArgumentList "41094075-9dad-400e-a0bd-54e686782033", "Scope"

# Add permission objects to the resource access object
$AzureMgmtAccess.ResourceAccess = $AzureSvcMgmt

# Create the new apps
$demoApp = New-AzureADApplication -DisplayName $env:myClientName -PublicClient $true -RequiredResourceAccess @($AzureMgmtAccess)

<#  get access token using OAuth 2.0 Resource Owner Password Credentials (ROPC) grant,
https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth-ropc
https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent#openid-connect-scopes
https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/app-aad-token#--username-password-flow-programmatic
#>
$tokenURI = "https://login.microsoftonline.com/toronto714yahoo.onmicrosoft.com/oauth2/v2.0/token"
$tokenArguments = @{
    OutVariable = 'tokenStatus'
    Method = 'POST'
    Headers = @{'Content-Type'='application/x-www-form-urlencoded'}
}

$tokenRequestBody = @{
    scope="https://management.azure.com/user_impersonation offline_access"
    client_id= "$($demoApp.AppId)"
    grant_type="password"
    username="testuser1@$domainName"
    password="$env:password"
}
Invoke-WebRequest -uri $tokenURI -Body $tokenRequestBody  @tokenArguments
$accessToken = ($tokenStatus.Content|ConvertFrom-Json).access_token

<# in case you would like to get access token from powershell context
https://medium.com/objectsharp/how-to-get-azure-rest-apis-access-tokens-using-powershell-cfb3ded739ed
#>

# Call Azure Rest API to query IP Group
$ipGroupURI = "https://management.azure.com/subscriptions/$secondSubId/resourceGroups/$rgName/providers/Microsoft.Network/ipGroups/$($ipGroupName)?api-version=2020-07-01"
$ipGroupArguments = @{
    OutVariable = 'response'
    Method = 'GET'
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $accessToken"
}
}
Invoke-WebRequest -uri $ipGroupURI @ipGroupArguments

# cleanup
Remove-AzIpGroup -ResourceGroupName $rgName -Name $ipGroupName -Force


