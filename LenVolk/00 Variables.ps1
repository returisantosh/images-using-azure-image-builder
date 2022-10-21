# $subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
# Connect-AzAccount -Subscription $subscription
# Disconnect-AzAccount


# Register providers / check provider state
# Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages, Microsoft.Network |
#   Where-Object RegistrationState -ne Registered |
#   Register-AzResourceProvider
# OR you can run Invoke-AIBProviderCheck



# Ref https://powers-hell.com/2020/09/20/preparing-custom-image-templates-with-azure-image-builder-powershell/

# Install-Module Az.ImageBuilder.Tools
# Install-Module -Name Az.ImageBuilder -RequiredVersion 0.1.2
# PS 7 
# iex "&amp; { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"


$aibRG = "imageBuilderRG"
$subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$location = "eastus2"

$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)