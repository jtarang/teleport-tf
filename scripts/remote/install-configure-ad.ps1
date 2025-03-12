# Set Variables
$DomainName = "jasmitdemo.local"  # Change this to your domain name
$NetBIOSName = "JASMITDEMO"       # Change this to your NetBIOS name
$SafeModePassword = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force  # Change this!

# Install Active Directory Role
Write-Host "Installing Active Directory Domain Services (AD DS)..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Write-Host "Promoting Server to Domain Controller..." -ForegroundColor Cyan
Install-ADDSForest -DomainName $DomainName -DomainNetBIOSName $NetBIOSName -SafeModeAdministratorPassword $SafeModePassword -Force

# Wait for AD to initialize
Start-Sleep -Seconds 60

# Define GPO Variables
$GPOName = "DefaultSecurityPolicy"
$DomainDN = (Get-ADDomain).DistinguishedName
$GPOTarget = "DC=$DomainDN"

# Create and Link GPO
if (-not (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue)) {
    New-GPO -Name $GPOName | New-GPLink -Target $GPOTarget
    Write-Host "Created and Linked GPO: $GPOName" -ForegroundColor Green
} else {
    Write-Host "GPO $GPOName already exists. Updating settings..." -ForegroundColor Yellow
}

# Configure Password Policy
Write-Host "Configuring Password Policy..." -ForegroundColor Cyan
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "MaximumPasswordAge" -Type DWord -Value 60
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "MinimumPasswordLength" -Type DWord -Value 12
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "PasswordComplexity" -Type DWord -Value 1

# Configure Account Lockout Policy
Write-Host "Configuring Account Lockout Policy..." -ForegroundColor Cyan
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "LockoutThreshold" -Type DWord -Value 5
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "LockoutDuration" -Type DWord -Value 30
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "ResetLockoutCount" -Type DWord -Value 30

# Disable Guest Account
Write-Host "Disabling Guest Account..." -ForegroundColor Cyan
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SAM\SAM\Domains\Account" `
    -ValueName "GuestAccount" -Type DWord -Value 0

# Enable Windows Defender
Write-Host "Ensuring Windows Defender is Enabled..." -ForegroundColor Cyan
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" `
    -ValueName "DisableAntiSpyware" -Type DWord -Value 0
Set-GPRegistryValue -Name $GPOName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" `
    -ValueName "DisableRealtimeMonitoring" -Type DWord -Value 0

# Apply the GPO
Write-Host "Forcing Group Policy Update..." -ForegroundColor Cyan
gpupdate /force

Write-Host "Active Directory and Group Policy Setup Completed!" -ForegroundColor Green
