
<powershell>
$Global:TeleportCluster = "${TELEPORT_ADDRESS}"
$Global:TeleportEdition = "${TELEPORT_EDITION}"
$Global:CertFile = "teleport.cer"
$Global:CertUrl = "https://${TELEPORT_ADDRESS}/webapi/auth/export?type=windows"
$Global:VersionUrl = "https://${TELEPORT_ADDRESS}/v1/webapi/automaticupgrades/channel/default/version"

# Initialize with default Teleport version
$Global:TeleportVersion = "v17.3.4"  # Default version

Write-Host "Teleport Address: $Global:TeleportCluster"
Write-Host "Teleport Edition: $Global:TeleportEdition"
Write-Host "Using default Teleport Version: $Global:TeleportVersion"

# Function to Get Latest Teleport Version
function Get-LatestTeleportVersion {
    Write-Host "Fetching latest Teleport version..."
    $latestVersion = Invoke-RestMethod -Uri $Global:VersionUrl -ErrorAction SilentlyContinue
    if ($latestVersion) {
        $Global:TeleportVersion = $latestVersion
        Write-Host "Updated Teleport Version: $Global:TeleportVersion"
    } else {
        Write-Host "Failed to fetch the latest version. Continuing with default version."
    }
    $Global:SetupExe = "teleport-windows-auth-setup-$Global:TeleportVersion-amd64.exe"
    $Global:SetupUrl = "https://cdn.teleport.dev/$Global:SetupExe"
}

# Function to Download Teleport Certificate
function Get-TeleportCertificate {
    Write-Host "Downloading Teleport certificate..."
    Invoke-WebRequest -Uri $Global:CertUrl -OutFile $Global:CertFile
    Write-Host "Certificate downloaded as $Global:CertFile"
}

# Function to Download Teleport Windows Auth Setup
function Get-TeleportSetup {
    Write-Host "Downloading Teleport Windows Auth Setup..."
    Invoke-WebRequest -Uri $Global:SetupUrl -OutFile $Global:SetupExe
    Write-Host "Setup executable downloaded as $Global:SetupExe"
}

# Function to Install Teleport Windows Auth
function Install-TeleportAuth {
    Write-Host "Installing Teleport Windows Auth..."
    Start-Process -FilePath ".\$Global:SetupExe" -ArgumentList "install --cert=$Global:CertFile -r" -Wait -NoNewWindow
    Write-Host "Installation complete. A system restart is required."
    Restart-Computer -Force
}

# Execute Functions
Get-LatestTeleportVersion
Get-TeleportCertificate
Get-TeleportSetup
Install-TeleportAuth
</powershell>