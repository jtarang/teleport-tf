 $Global:DscalsBinaryName = "dsacls" 


function IsInstalled ([String]$binaryName) {
    if (Get-Command $binaryName -errorAction SilentlyContinue)
    {
        return $True
    }
    return $False
}


function InstallRsatAdTools() {
    if (-not (IsInstalled -binaryName $Global:DscalsBinaryName)) {
        Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature -IncludeManagementTools
    } else {
        Write-Host "RSAT Tools are already installed"
    }
}

function Main() {
    InstallRsatAdTools
}


# Run Main function
Main 
