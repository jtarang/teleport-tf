param(
    [Switch]$Install,
    [String]$SysvolPath
)

# Resolve SYSVOL_PATH from parameter, env var, or fallback default
if (-not $SysvolPath) {
    if ($env:SYSVOL_PATH) {
        $SysvolPath = $env:SYSVOL_PATH
    } else {
        $SysvolPath = "C:\Windows\SYSVOL"
    }
}

# Throw error if still empty
if ([string]::IsNullOrWhiteSpace($SysvolPath)) {
    throw "SYSVOL path is not defined. Please provide it via the -SysvolPath parameter or set the SYSVOL_PATH environment variable."
}

# Make it global so functions can access
$global:SYSVOL_PATH = $SysvolPath


function Is-Installed ([String]$binaryName) {
    if (Get-Command $binaryName -ErrorAction SilentlyContinue) {
        return $True
    }
    return $False
}

function Install-RSAT-AD-Tools() {
    if (-not (Is-Installed -binaryName "dsacls")) {
        if ($Install) {
            Write-Host "RSAT-AD-Tools not found. Installing..." -ForegroundColor Yellow
            Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature
            Write-Host "RSAT-AD-Tools installation completed." -ForegroundColor Green
        } else {
            Write-Host "[Dry-Run] RSAT-AD-Tools are missing and would be installed." -ForegroundColor Cyan
        }
    } else {
        Write-Host "RSAT Tools are already installed." -ForegroundColor Green
    }
}

function Install-ADCS() {
    $adcsFeature = Get-WindowsFeature -Name ADCS-Cert-Authority

    if ($adcsFeature -and $adcsFeature.Installed) {
        Write-Host "ADCS Certificate Authority is already installed." -ForegroundColor Green
    } else {
        if ($Install) {
            Write-Host "ADCS not found. Installing..." -ForegroundColor Yellow
            Add-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
            Write-Host "Installing Enterprise Root CA with SHA384..." -ForegroundColor Yellow
            Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -HashAlgorithmName SHA384 -Force
            Write-Host "ADCS installation completed." -ForegroundColor Green
        } else {
            Write-Host "[Dry-Run] ADCS would be installed and configured." -ForegroundColor Cyan
        }
    }
}

function Verify-AD-CS-Health() {
    $addsFeature = Get-WindowsFeature -Name AD-Domain-Services
    if ($addsFeature.Installed) {
        Write-Host "AD Domain Services feature is installed." -ForegroundColor Green
    } else {
        Write-Host "AD Domain Services feature is NOT installed!" -ForegroundColor Red
    }

    try {
        $forest = (Get-ADForest).RootDomain
        $domain = (Get-ADDomain).DistinguishedName

        if ($forest -and $domain) {
            Write-Host "Connected to AD Forest: $forest" -ForegroundColor Green
            Write-Host "Connected to AD Domain: $domain" -ForegroundColor Green
        } else {
            throw "Unable to retrieve AD Forest or Domain information!"
        }
    } catch {
        Write-Error "Failed to connect to Active Directory. Error: $_"
    }

    $adcsFeatures = Get-WindowsFeature -Name AD-Certificate*
    $installedADCSFeatures = $adcsFeatures | Where-Object { $_.Installed -eq $true }

    if ($installedADCSFeatures) {
        Write-Host "Found installed AD CS features:" -ForegroundColor Green
        $installedADCSFeatures | ForEach-Object { Write-Host "- $($_.Name)" -ForegroundColor Green }
    } else {
        Write-Host "No AD Certificate Services features found installed!" -ForegroundColor Red
    }

    Write-Host "Pinging the Certificate Authority using certutil..." -ForegroundColor Yellow
    $pingResult = certutil -config - -ping
    if ($pingResult -match "CertUtil: -ping command completed successfully.") {
        Write-Host "Certificate Authority ping successful!" -ForegroundColor Green
    } else {
        Write-Host "Certificate Authority ping failed!" -ForegroundColor Red
    }
}

function Check-Sysvol() {
    if (-not (Test-Path -Path $SYSVOL_PATH)) {
        Write-Host "Sysvol Path not found: $SYSVOL_PATH" -ForegroundColor Red
    } else {
        Write-Host "SYSVOL path found: $SYSVOL_PATH" -ForegroundColor Green
    }
}

function Verify-Requirements() {
    Install-RSAT-AD-Tools
    Install-ADCS
    Check-Sysvol
    Verify-AD-CS-Health
}

function Main {
    try {
        if ($Install) {
            Write-Host "Running in INSTALL mode..." -ForegroundColor Yellow
        } else {
            Write-Host "Running in DRY-RUN mode (no changes will be made)..." -ForegroundColor Cyan
        }

        Verify-Requirements
        Write-Host "All checks completed." -ForegroundColor Green
    } catch {
        Write-Error "Requirement verification failed: $_"
    }
}

# Start the script
Main
