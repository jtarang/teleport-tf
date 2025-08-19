<powershell>
$Global:LogPath = "C:\DomainSetup.log"
Function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp  $Message" | Out-File -FilePath $Global:LogPath -Append -Encoding utf8
    Write-Host $Message
}

function Install-ADFeatures {
    Write-Log 'Installing the AD services and administration tools...'
    Install-WindowsFeature AD-Domain-Services, RSAT-AD-AdminCenter, RSAT-ADDS-Tools | Out-Null
    Write-Log 'AD services and admin tools installed.'
}

function Install-ADForest {
    param (
        [string]$Domain,
        [System.Security.SecureString]$SafeModeAdministratorPassword
    )

    $NET_BIOS_DOMAIN = ($Domain -split '\.')[0].ToUpperInvariant()

    Write-Log 'Installing AD DS (forest/domain)...'
    try {
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
        Write-Log 'Forest/domain installation initiated. A reboot is required.'
    }
    catch {
        Write-Log "ERROR during AD DS forest install: $($_.Exception.Message)"
        throw
    }

    Write-Log "Scheduling post-reboot setup..."
    $PostRebootScript = @"
`$LogPath = 'C:\DomainSetup.log'
Function Write-Log {
    param([string]`$Message)
    `$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`$Timestamp  `$Message" | Out-File -FilePath `$LogPath -Append -Encoding utf8
}

Write-Log 'Post-reboot setup started.'
Start-Sleep -Seconds 60  # Wait for AD services to initialize

try {
    Write-Log 'Installing AD CS...'
    Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools | Out-Null
    Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -HashAlgorithmName SHA384 -Force | Out-Null
    Write-Log 'AD CS installed.'

    # Create AD Admin User
    `$Username = "${WINDOWS_AD_ADMIN_USERNAME}"
    `$Password = "${WINDOWS_AD_ADMIN_PASSWORD}"
    `$AdminPassword = ConvertTo-SecureString `$Password -AsPlainText -Force
    Write-Log "Creating AD admin user `$Username..."
    New-ADUser -Name `$Username -AccountPassword `$AdminPassword -Enabled `$true -PassThru | Out-Null
    Add-ADGroupMember -Identity 'Domain Admins' -Members `$Username
    Write-Log 'AD admin user created and added to Domain Admins.'

    # Cleanup task
    Unregister-ScheduledTask -TaskName 'PostRebootSetup' -Confirm:`$false
    Write-Log 'Scheduled task removed. Post-reboot setup complete.'
    Restart-Computer -Force
}
catch {
    Write-Log "ERROR in post-reboot script: `$($_.Exception.Message)"
}
"@

    $ScriptPath = "C:\PostRebootSetup.ps1"
    $PostRebootScript | Out-File -FilePath $ScriptPath -Encoding utf8

    # Register scheduled task (runs at startup as SYSTEM)
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
    Register-ScheduledTask -TaskName "PostRebootSetup" -Action $Action -Trigger $Trigger -Principal $Principal -Force

    Write-Log "Scheduled task created for post-reboot setup."
    Write-Log "Rebooting the server to complete domain setup..."
    Restart-Computer -Force
}

$DOMAIN = "${WINDOWS_AD_DOMAIN_NAME}"
$SafeModeAdministratorPassword = ConvertTo-SecureString "${WINDOWS_AD_ADMIN_PASSWORD}" -AsPlainText -Force

Write-Log "========== Domain Setup Script Started =========="
Install-ADFeatures
Install-ADForest -Domain $DOMAIN -SafeModeAdministratorPassword $SafeModeAdministratorPassword
</powershell>