# on the remote VM check C:\Packages\Plugins\Microsoft.CPlat.Core.RunCommandWindows\1.1.15\Downloads

$ResourceGroup = "imageBuilderRG"
$hostPool = "Lab1HP"
$location = "eastus2"

###################################
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# ForEach-Object -Parallel
# req PS 7 
# iex "&amp; { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

# Just an example
# PsExec.exe /accepteula \\CZ###APPNPADC01 cmd.exe /c "powershell.exe -ExecutionPolicy Bypass -File C:\Users\lvolk\Scripts\AD_Add_PSscript.ps1"
# regsvr32.exe /s /u /i:test.sct scrobj.dll
##################################################
# Testing passing parameters to the VM's PS script
##################################################
# $ResourceGroup = "lab1hprg"
# $location = "eastus"
# $RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# # (Get-Command ./AADextention.ps1).Parameters
# $RunningVMs | ForEach-Object -Parallel {
#     Invoke-AzVMRunCommand `
#         -ResourceGroupName $_.ResourceGroupName `
#         -VMName $_.Name `
#         -CommandId 'RunPowerShellScript' `
#         -Parameter @{ResourceGroup = $using:ResourceGroup;location = $using:location} `
#         -ScriptPath '.\param_invoke.ps1'
# }

##################################################
# Add_2_Domain
##################################################
$DomainName = "lvolk.com"
$OUPath = "OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com"
$user = 'lvolk\lv'
$pass = 'DomainAdminPass'

$ResourceGroup = 'Lab1HPRG'
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# (Get-Command ./AADextention.ps1).Parameters
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{DomainName = $using:DomainName;OUPath = $using:OUPath;user = $using:user;pass = $using:pass} `
        -ScriptPath '.\AD_Add_PSscript.ps1'
}
##################################################
# AD_Remove
##################################################
$user = 'LocalAdmin'
$pass = 'LocalAdminPass'

$ResourceGroup = 'Lab1HPRG'
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{user = $using:user;pass = $using:pass} `
        -ScriptPath '.\AD_Remove.ps1'
}
################################
#     Installing Fslogix       #
################################
$VMRG = "AVD-GEN-HP-RG"
$ProfilePath = "\\adsavdprofile.file.core.windows.net\profiles"
$RedirectXML = "\\adsavdprofile.file.core.windows.net\avdshares"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ProfilePath = $using:ProfilePath;RedirectXML = $using:RedirectXML} `
        -ScriptPath './fslogix_install.ps1'
}

#######################################
# Adjusting Fslogix RegKey for AAD SA #
######################################
$VMRG = "AVD-GEN-HP-RG"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$ProfilePath = "\\adsavdprofile.file.core.windows.net\profiles"
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ProfilePath = $using:ProfilePath} `
        -ScriptPath './fslogix_regkey_AADSA.ps1'
}

#######################################
# COPY Fslogix AppMasking Rules       #
######################################
$VMRG = "AVD-GEN-HP-RG"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$AppMaskPath = "\\adsavdprofile.file.core.windows.net\avdshares\AppMask"
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{AppMaskPath= $using:AppMaskPath} `
        -ScriptPath './Copy_AppMaskingRules.ps1'
}

################################
#    Adding AVD agents to VMs  #
################################
$VMRG = "imageBuilderRG"
$HPRG = "AADJoinedAVD"
$HPName = "AADJoined"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RegistrationToken = (New-AzWvdRegistrationInfo -ResourceGroupName $HPRG -HostPoolName $HPName -ExpirationTime $((get-date).ToUniversalTime().AddHours(3).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))).Token
# $RegistrationToken = Get-AzWvdRegistrationInfo -ResourceGroupName $HPRG -HostPoolName $HPName
#$RunFilePath = '.\hostpool_vms.ps1'
#((Get-Content -path $RunFilePath -Raw) -replace '<__param1__>', $RegistrationToken.Token) | Set-Content -Path $RunFilePath
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{HPRegToken = $using:RegistrationToken} `
        -ScriptPath '.\hostpool_vms.ps1'
}

################################
#   Updating DNS Suffixes      #
################################
$VMRG = "imageBuilderRG"
$DnsSufix = "lvolk.com"
$SAfqdn = "lvolklab11.file.core.windows.net"
$SApe = "10.100.40.11"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{DnsSufix = $using:DnsSufix;SAfqdn = $using:SAfqdn;SApe = $using:SApe} `
        -ScriptPath './DNS_suffix.ps1'
}


################################
#   Updating Proxy Suffixes    #
################################
$VMRG = "imageBuilderRG"
$ProxyServer = "10.199.0.19:3128"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ProxyServer = $using:ProxyServer} `
        -ScriptPath './ProxySettings.ps1'
}