# create public ip prefix
# https://docs.microsoft.com/en-us/powershell/module/az.network/new-azpublicipprefix?view=azps-5.2.0#example-1--create-a-new-public-ip-prefix
$prefixName = "pip-prefix-ronniepersonal"
$rgName = "ronniepersonal"
$publicIpPrefix = New-AzPublicIpPrefix -Name $prefixName -ResourceGroupName $rgName -PrefixLength 29

# create public ip from the prefix
#https://docs.microsoft.com/en-us/powershell/module/az.network/new-azpublicipaddress?view=azps-5.2.0&viewFallbackFrom=azps-2.0.0#example-4--create-a-new-public-ip-address-from-a-prefix

$publicIpPrefix = Get-AzPublicIPPrefix -Name $prefixName -ResourceGroupName $rgName
$publicIpName = "pip-ronniepersonal"
$location = (Get-AzResourceGroup -Name $rgName).Location
$data = @{}
for ($i = 2; $i -le 3; $i++) { 
    $data["var$i"] = New-AzPublicIpAddress -Name "$publicIpName$i" -ResourceGroupName $rgName -AllocationMethod Static -Location $location -PublicIpPrefix $publicIpPrefix -Sku Standard 
}

Write-Host ($data.Values).Name

# Add new PIPs for AZFW
#https://docs.microsoft.com/en-us/azure/firewall/deploy-multi-public-ip-powershell
$azfwName = "azfw-ronniepersonal"
$azFw = Get-AzFirewall `
  -Name $azfwName `
  -ResourceGroupName $rgName

$data.Values | ForEach-Object { $azFw.AddPublicIpAddress($_) }

$azFw | Set-AzFirewall