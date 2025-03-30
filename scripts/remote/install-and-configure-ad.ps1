<powershell>
function Install-ADFeatures {
    Write-Host 'Installing the AD services and administration tools...'
    Install-WindowsFeature AD-Domain-Services, RSAT-AD-AdminCenter, RSAT-ADDS-Tools
}

function Install-ADForest {
    param (
        [string]$Domain,
        [System.Security.SecureString]$SafeModeAdministratorPassword
    )

    $NET_BIOS_DOMAIN = ($Domain -split '\.')[0].ToUpperInvariant()

    Write-Host 'Installing AD DS (be patient, this may take a while to install)...'
    Import-Module ADDSDeployment
    Install-ADDSForest `
        -InstallDns `
        -CreateDnsDelegation:$false `
        -ForestMode 'Win2012R2' `
        -DomainMode 'Win2012R2' `
        -DomainName $Domain `
        -DomainNetbiosName $NET_BIOS_DOMAIN `
        -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
        -Force

    Write-Host "Scheduling post-reboot setup..."
    $PostRebootScript = @'
Write-Host "Running post-reboot setup..."
Start-Sleep -Seconds 60  # Wait for AD services to be fully available

# Install AD CS
Write-Host "Installing AD CS..."
Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -HashAlgorithmName SHA384 -Force

# Create AD Admin User
$Username = "${WINDOWS_AD_ADMIN_USERNAME}"
$Password = "${WINDOWS_AD_ADMIN_PASSWORD}"
$AdminPassword = ConvertTo-SecureString $Password -AsPlainText -Force
Write-Host "Creating AD admin user..."
New-ADUser -Name $Username -AccountPassword $AdminPassword -Enabled $true -PassThru
Add-ADGroupMember -Identity "Domain Admins" -Members $Username

# Cleanup - Remove the RunOnce entry so it doesn't run again
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "PostRebootSetup" -Force
Write-Host "Post-reboot setup complete!"
'@

    $ScriptPath = "C:\PostRebootSetup.ps1"
    $PostRebootScript | Out-File -FilePath $ScriptPath -Encoding utf8

    # Add script to RunOnce registry key (executes on next login & then deletes itself)
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "PostRebootSetup" -Value "powershell.exe -ExecutionPolicy Bypass -File $ScriptPath"

    Write-Host "Rebooting the server to complete domain setup..."
    Restart-Computer -Force
}

$DOMAIN = "${WINDOWS_AD_DOMAIN_NAME}"
$SafeModeAdministratorPassword = ConvertTo-SecureString  "${WINDOWS_AD_ADMIN_PASSWORD}"-AsPlainText -Force

Install-ADFeatures
Install-ADForest -Domain $DOMAIN -SafeModeAdministratorPassword $SafeModeAdministratorPassword
</powershell>