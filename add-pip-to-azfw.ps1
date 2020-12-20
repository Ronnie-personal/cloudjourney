# create public ip prefix
# https://docs.microsoft.com/en-us/powershell/module/az.network/new-azpublicipprefix?view=azps-5.2.0#example-1--create-a-new-public-ip-prefix
$prefixName = "pip-prefix-ronniepersonal"
$rgName = "ronniepersonal"
$publicIpPrefix = New-AzPublicIpPrefix -Name $prefixName -ResourceGroupName $rgName -PrefixLength 29

# create public ip from the prefix
#https://docs.microsoft.com/en-us/powershell/module/az.network/new-azpublicipaddress?view=azps-5.2.0&viewFallbackFrom=azps-2.0.0#example-4--create-a-new-public-ip-address-from-a-prefix

$publicIpPrefix = Get-AzPublicIPPrefix -Name $prefixName -ResourceGroupName $rgName
$publicIpName2 = "pip-ronniepersonal2"
$publicIpName3 = "pip-ronniepersonal3"
$location = "eastus"
$publicIp2 = New-AzPublicIpAddress -Name $publicIpName2 -ResourceGroupName $rgName -AllocationMethod Static -Location $location -PublicIpPrefix $publicIpPrefix -Sku Standard 
$publicIp3 = New-AzPublicIpAddress -Name $publicIpName3 -ResourceGroupName $rgName -AllocationMethod Static -Location $location -PublicIpPrefix $publicIpPrefix -Sku Standard
