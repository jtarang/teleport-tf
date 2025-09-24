<powershell>

if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    Function Write-Log {
        param([string]$Message)
        $Global:LogPath = $Global:LogPath | ForEach-Object { $_ }  # preserve global path if already set
        if (-not $Global:LogPath) { $Global:LogPath = "C:\DomainSetup.log" }

        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$Timestamp  $Message" | Out-File -FilePath $Global:LogPath -Append -Encoding utf8
        Write-Host $Message
    }
}

$Global:LogPath = "C:\DomainSetup.log"
Write-Log "========== Domain Setup Script Started =========="

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

    # Post-reboot setup script
    $PostRebootScript = @"
# Ensure Write-Log exists in post-reboot script
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function Write-Log {
        param([string]`$Message)
        `$LogPath = 'C:\DomainSetup.log'
        `$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "`$Timestamp  `$Message" | Out-File -FilePath `$LogPath -Append -Encoding utf8
        Write-Host `$Message
    }
}

Write-Log 'Post-reboot setup started.'
Start-Sleep -Seconds 60  # wait for AD services to initialize

try {
    Write-Log 'Installing AD CS...'
    Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools | Out-Null
    Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -CACommonName "CorpRootCA" -KeyLength 2048 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 10 -Force | Out-Null
    Write-Log 'AD CS installed.'

    # Create AD Admin User
    `$Username = "${WINDOWS_AD_ADMIN_USERNAME}".Trim()
    `$Password = "${WINDOWS_AD_ADMIN_PASSWORD}".Trim()
    `$AdminPassword = ConvertTo-SecureString `$Password -AsPlainText -Force
    Write-Log "Creating AD admin user `$Username..."
    New-ADUser -Name `$Username -AccountPassword `$AdminPassword -Enabled `$true -PassThru | Out-Null
    Add-ADGroupMember -Identity 'Domain Admins' -Members `$Username
    Write-Log 'AD admin user created and added to Domain Admins.'

    $ErrorActionPreference = "Stop"

    $AD_USER_NAME = "Teleport Service Account"
    $SAM_ACCOUNT_NAME = "svc-teleport"
    $BLOCK_GPO_NAME = "Block teleport-svc Interactive Login"
    $ACCESS_GPO_NAME = "Teleport Access Policy"
    $SYSVOL_PATH = "\\$((Get-ADDomain).DNSRoot)\SYSVOL\$((Get-ADDomain).DNSRoot)"

    $TELEPORT_CA_CERT_PEM = "-----BEGIN CERTIFICATE-----
    MIIDtjCCAp6gAwIBAgIQLUsXpIFeVsfizNATzkSwhDANBgkqhkiG9w0BAQsFADB1
    MSAwHgYDVQQKExduZWJ1bGEtZGFzaC50ZWxlcG9ydC5zaDEgMB4GA1UEAxMXbmVi
    dWxhLWRhc2gudGVsZXBvcnQuc2gxLzAtBgNVBAUTJjYwMjA1MTYxNjAzNTg4NDc3
    Nzg1MzQxNzczNDYyMjA2OTg0MzI0MB4XDTI1MDIxNjAxNTIxOVoXDTM1MDIxNDAx
    NTIxOVowdTEgMB4GA1UEChMXbmVidWxhLWRhc2gudGVsZXBvcnQuc2gxIDAeBgNV
    BAMTF25lYnVsYS1kYXNoLnRlbGVwb3J0LnNoMS8wLQYDVQQFEyY2MDIwNTE2MTYw
    MzU4ODQ3Nzc4NTM0MTc3MzQ2MjIwNjk4NDMyNDCCASIwDQYJKoZIhvcNAQEBBQAD
    ggEPADCCAQoCggEBANjgKQklQQtAxuducADqOdTkpEBZT+AzL/rjubkF7cwxi1wU
    KoHc57m9JZVvRq+9oFYYBCkjwguKKElPS4fzLq0FZwDDG88HPZuKutpkhNCjaIty
    AnURNGFg1wkWe86eS4QNRjP8sI4DtAQiyQf+w2KJDAqcESdUAq3hrV0tc4MrFVez
    MwVewK1o9AgXlJxW9Ygnm9dQ5E5U0XraDEoK+y9gruWQk7IkcipiXdk/EpD32qqh
    GyKeObhhjLEt2cs7aXTuI72V9/ITqoDPST7k9TpKMQHQs6eEh3R2cSoZ4ORVpOo9
    Xmjgm5PZHWBVTvVv4Y9yagvlSw1kURrWBSkE9TMCAwEAAaNCMEAwDgYDVR0PAQH/
    BAQDAgGmMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOjavAiUnP/Lf5wJQbpK
    wKVULnloMA0GCSqGSIb3DQEBCwUAA4IBAQAijVUBClDJCLbui9J/ME4vRv7uj7wf
    6z3m41gpK0VWLausqfEkxqeGwqymQTXehqSifKNgSNZ5UGLxZ7EaKpjaPDI+U8F/
    2+FXP4uJivAyGaS8GxU1QKKAiaOv84zi3RuITyvCLC10Xi15LyyhE1UOfFezY/0b
    NIVVP+pCvKuh04Kli2R4TvTxcvf8ecA/ULcZcLV2HklU5y8Osdg0wapv6O6Oa2s8
    Tni2EgKTDIQu3fxssFdwIY05WzDEllcCbs1ZVV/37AWSkEYQnr1EpeTfLO0ALQO5
    KCP3tz9Hi9Y3X3FNQGWQL3twIwZdTYjQT2mzf6bbOkey3lzcVyYw6fH1
    -----END CERTIFICATE-----
    "
    $TELEPORT_CA_CERT_SHA1 = "2F36FC9293C0DB9B712559915C575CF4D1F66F02"
    $TELEPORT_CA_CERT_BLOB_BASE64 = "IAAAAAEAAAC6AwAAMIIDtjCCAp6gAwIBAgIQLUsXpIFeVsfizNATzkSwhDANBgkqhkiG9w0BAQsFADB1MSAwHgYDVQQKExduZWJ1bGEtZGFzaC50ZWxlcG9ydC5zaDEgMB4GA1UEAxMXbmVidWxhLWRhc2gudGVsZXBvcnQuc2gxLzAtBgNVBAUTJjYwMjA1MTYxNjAzNTg4NDc3Nzg1MzQxNzczNDYyMjA2OTg0MzI0MB4XDTI1MDIxNjAxNTIxOVoXDTM1MDIxNDAxNTIxOVowdTEgMB4GA1UEChMXbmVidWxhLWRhc2gudGVsZXBvcnQuc2gxIDAeBgNVBAMTF25lYnVsYS1kYXNoLnRlbGVwb3J0LnNoMS8wLQYDVQQFEyY2MDIwNTE2MTYwMzU4ODQ3Nzc4NTM0MTc3MzQ2MjIwNjk4NDMyNDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANjgKQklQQtAxuducADqOdTkpEBZT+AzL/rjubkF7cwxi1wUKoHc57m9JZVvRq+9oFYYBCkjwguKKElPS4fzLq0FZwDDG88HPZuKutpkhNCjaItyAnURNGFg1wkWe86eS4QNRjP8sI4DtAQiyQf+w2KJDAqcESdUAq3hrV0tc4MrFVezMwVewK1o9AgXlJxW9Ygnm9dQ5E5U0XraDEoK+y9gruWQk7IkcipiXdk/EpD32qqhGyKeObhhjLEt2cs7aXTuI72V9/ITqoDPST7k9TpKMQHQs6eEh3R2cSoZ4ORVpOo9Xmjgm5PZHWBVTvVv4Y9yagvlSw1kURrWBSkE9TMCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgGmMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOjavAiUnP/Lf5wJQbpKwKVULnloMA0GCSqGSIb3DQEBCwUAA4IBAQAijVUBClDJCLbui9J/ME4vRv7uj7wf6z3m41gpK0VWLausqfEkxqeGwqymQTXehqSifKNgSNZ5UGLxZ7EaKpjaPDI+U8F/2+FXP4uJivAyGaS8GxU1QKKAiaOv84zi3RuITyvCLC10Xi15LyyhE1UOfFezY/0bNIVVP+pCvKuh04Kli2R4TvTxcvf8ecA/ULcZcLV2HklU5y8Osdg0wapv6O6Oa2s8Tni2EgKTDIQu3fxssFdwIY05WzDEllcCbs1ZVV/37AWSkEYQnr1EpeTfLO0ALQO5KCP3tz9Hi9Y3X3FNQGWQL3twIwZdTYjQT2mzf6bbOkey3lzcVyYw6fH1"
    $TELEPORT_PROXY_PUBLIC_ADDR = "<no value>"
    $TELEPORT_PROVISION_TOKEN = "<no value>"

    $DOMAIN_NAME = (Get-ADDomain).DNSRoot
    $DOMAIN_DN = $((Get-ADDomain).DistinguishedName)


    function Prompt-ForAcknowledgment {
        # Display a high-level summary of the script's actions and require user acknowledgment before proceeding
        $summary = @"
This script will configure your Active Directory system to integrate with Teleport for secure access to Windows desktops. The following actions will be performed:

1. Create a restrictive service account named $AD_USER_NAME with the SAM account name $SAM_ACCOUNT_NAME and create the necessary LDAP containers.
2. Prevent the service account from performing interactive logins by creating and linking a Group Policy Object (GPO) named $BLOCK_GPO_NAME.
3. Configure a GPO named $ACCESS_GPO_NAME to allow Teleport connections, including:
    - Importing the Teleport CA certificate.
    - Configuring firewall rules.
    - Allowing remote RDP connections.
    - Enabling RemoteFX for improved remote desktop performance.

Ensure you've reviewed this script itself and/or the equivalent manual documentation before proceeding.
For the manual documentation, see: https://goteleport.com/docs/enroll-resources/desktop-access/active-directory

Press 'Y' to acknowledge and continue, or any other key to exit.
"@

        Write-Output $summary
        $acknowledge = Read-Host "Acknowledge (Y/N)"
        if ($acknowledge -ne 'Y') {
            Write-Output "Script execution aborted by user."
            exit
        }
    }

    function Create-ServiceAccount {
        try {
            Get-ADUser -Identity $SAM_ACCOUNT_NAME
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Add-Type -AssemblyName 'System.Web'
            do {
                $PASSWORD = [System.Web.Security.Membership]::GeneratePassword(15, 1)
            } until ($PASSWORD -match '\d')
            $SECURE_STRING_PASSWORD = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
            New-ADUser -Name $AD_USER_NAME -SamAccountName $SAM_ACCOUNT_NAME -AccountPassword $SECURE_STRING_PASSWORD -Enabled $true
        }
    }

    function Create-LDAPContainers {
        # Create the CDP/Teleport container.
        try {
            Get-ADObject -Identity "CN=Teleport,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN"
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            New-ADObject -Name "Teleport" -Type "container" -Path "CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN"
        }

        # Gives Teleport the ability to create LDAP containers in the CDP container.
        dsacls "CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN" /I:T /G "$($SAM_ACCOUNT_NAME):CC;container;"
        # Gives Teleport the ability to create and delete cRLDistributionPoint objects in the CDP/Teleport container.
        dsacls "CN=Teleport,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN" /I:T /G "$($SAM_ACCOUNT_NAME):CCDC;cRLDistributionPoint;"
        # Gives Teleport the ability to write the certificateRevocationList property in the CDP/Teleport container.
        dsacls "CN=Teleport,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN " /I:T /G "$($SAM_ACCOUNT_NAME):WP;certificateRevocationList;"
        # Gives Teleport the ability to read the cACertificate property in the NTAuthCertificates container.
        dsacls "CN=NTAuthCertificates,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN" /I:T /G "$($SAM_ACCOUNT_NAME):RP;cACertificate;"

        $SAM_ACCOUNT_SID = (Get-ADUser -Identity $SAM_ACCOUNT_NAME).SID.Value
    }

    function Configure-BlockingGPO {
        # Step 2/7. Prevent the service account from performing interactive logins
        try {
            $BLOCK_GPO = Get-GPO -Name $BLOCK_GPO_NAME
        }
        catch [System.ArgumentException] {
            $BLOCK_GPO = New-GPO -Name $BLOCK_GPO_NAME
            $BLOCK_GPO | New-GPLink -Target $DOMAIN_DN
        }

        $DENY_SECURITY_TEMPLATE = @"
[Unicode]
Unicode=yes
[Version]
signature=`"$CHICAGO$`"
[Privilege Rights]
SeDenyRemoteInteractiveLogonRight=*{0}
SeDenyInteractiveLogonRight=*{0}
"@ -f $SAM_ACCOUNT_SID


        $BLOCK_POLICY_GUID = $BLOCK_GPO.Id.Guid.ToUpper()
        $BLOCK_GPO_PATH =  Join-Path -Path $SYSVOL_PATH -ChildPath "\$DOMAIN_NAME\Policies\{$BLOCK_POLICY_GUID}\Machine\Microsoft\Windows NT\SecEdit"
        New-Item -Force -Type Directory -Path $BLOCK_GPO_PATH
        New-Item -Force -Path $BLOCK_GPO_PATH -Name "GptTmpl.inf" -ItemType "file" -Value $DENY_SECURITY_TEMPLATE
    }

    function Configure-AccessGPO {
        # Step 3/7. Configure a GPO to allow Teleport connections
        try {
            $ACCESS_GPO = Get-GPO -Name $ACCESS_GPO_NAME
        }
        catch [System.ArgumentException] {
            $ACCESS_GPO = New-GPO -Name $ACCESS_GPO_NAME
            $ACCESS_GPO | New-GPLink -Target $DOMAIN_DN
        }

        $CERT = [System.Convert]::FromBase64String("$TELEPORT_CA_CERT_BLOB_BASE64")
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\SystemCertificates\Root\Certificates\$TELEPORT_CA_CERT_SHA1" -ValueName "Blob" -Type Binary -Value $CERT

        $global:TeleportPEMFile = $env:TEMP + "\teleport.pem"
        Write-Output $TELEPORT_CA_CERT_PEM | Out-File -FilePath $TeleportPEMFile

        certutil -dspublish -f $TeleportPEMFile RootCA
        certutil -dspublish -f $TeleportPEMFile NTAuthCA
        certutil -pulse

        $ACCESS_SECURITY_TEMPLATE=@'
    [Unicode]
    Unicode=yes
    [Version]
    signature="$CHICAGO$"
    [Service General Setting]
    "SCardSvr",2,""
    '@

        $COMMENT_XML = @"
    <?xml version='1.0' encoding='utf-8'?>
    <policyComments xmlns:xsd=`"http://www.w3.org/2001/XMLSchema`" xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`" revision=`"1.0`" schemaVersion=`"1.0`" xmlns=`"http://www.microsoft.com/GroupPolicy/CommentDefinitions`">
    <policyNamespaces>
        <using prefix=`"ns0`" namespace=`"Microsoft.Policies.TerminalServer`"></using>
    </policyNamespaces>
    <comments>
        <admTemplate></admTemplate>
    </comments>
    <resources minRequiredRevision=`"1.0`">
        <stringTable></stringTable>
    </resources>
    </policyComments>
    "@


        $ACCESS_POLICY_GUID = $ACCESS_GPO.Id.Guid.ToUpper()
        $ACCESS_GPO_PATH = Join-Path -Path $SYSVOL_PATH -ChildPath "\$DOMAIN_NAME\Policies\{$ACCESS_POLICY_GUID}\Machine\Microsoft\Windows NT\SecEdit"

        New-Item -Force -Type Directory -Path $ACCESS_GPO_PATH
        New-Item -Force -Path $ACCESS_GPO_PATH -Name "GptTmpl.inf" -ItemType "file" -Value $ACCESS_SECURITY_TEMPLATE
        New-Item -Force -Path "$SYSVOL_PATH\$DOMAIN_NAME\Policies\{$ACCESS_POLICY_GUID}\Machine" -Name "comment.cmtx" -ItemType "file" -Value $COMMENT_XML

        # Firewall
        $FIREWALL_USER_MODE_IN_TCP = "v2.31|Action=Allow|Active=TRUE|Dir=In|Protocol=6|LPort=3389|App=%SystemRoot%\system32\svchost.exe|Svc=termservice|Name=@FirewallAPI.dll,-28775|Desc=@FirewallAPI.dll,-28756|EmbedCtxt=@FirewallAPI.dll,-28752|"
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsFirewall" -ValueName "PolicyVersion" -Type DWORD -Value 543
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Type String -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsFirewall\FirewallRules" -ValueName "RemoteDesktop-UserMode-In-TCP" -Value $FIREWALL_USER_MODE_IN_TCP


        # Allow remote RDP connections
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDenyTSConnections" -Type DWORD -Value 0
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "UserAuthentication" -Type DWORD -Value 0

        # Disable `"Always prompt for password upon connection`"
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fPromptForPassword" -Type DWORD -Value 0

        # Enable RemoteFX
        # As described here: https://github.com/Devolutions/IronRDP/blob/55d11a5000ebd474c2ddc294b8b3935554443112/README.md?plain=1#L17-L24
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "ColorDepth" -Type DWORD -Value 5
        Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fEnableVirtualizedGraphics" -Type DWORD -Value 1
    }

    function Export-LDAPCertificate {
        # # Step 5/7. Export your LDAP CA certificate
        $global:WindowsDERFile = $env:TEMP + "\windows.der"
        $global:WindowsPEMFile = $env:TEMP + "\windows.pem"
        certutil "-ca.cert" $WindowsDERFile | Out-Null
        certutil -encode $WindowsDERFile $WindowsPEMFile | Out-Null

        gpupdate.exe /force | Out-Null

        $CA_CERT_PEM = Get-Content -Path $WindowsPEMFile
        $CA_CERT_YAML = $CA_CERT_PEM | ForEach-Object { "      " + $_ } | Out-String
        return $CA_CERT_YAML
    }

    function Generate-LDAPConfig($CA_CERT_YAML) {

        $NET_BIOS_NAME = (Get-ADDomain).NetBIOSName
        $LDAP_USERNAME = "$NET_BIOS_NAME\$SAM_ACCOUNT_NAME"
        $LDAP_USER_SID = (Get-ADUser -Identity $SAM_ACCOUNT_NAME).SID.Value

        $COMPUTER_NAME = (Resolve-DnsName -Type A $Env:COMPUTERNAME).Name
        $COMPUTER_IP = (Resolve-DnsName -Type A $Env:COMPUTERNAME).Address
        $LDAP_ADDR = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*'} | Sort-Object InterfaceMetric | Select-Object -First 1).IPAddress + ":636"

        $LDAP_CONFIG_YAML = @"
windows_desktop_service:
  enabled: yes
  ldap:
    # Ensure this is a public IP address or DNS name.
    addr:        '$LDAP_ADDR'
    # The Active Directory domain name.
    domain:    '$DOMAIN_NAME'
    # The service account username, prefixed with the NetBIOS name of the domain.
    username: '$LDAP_USERNAME'
    # The security identifier of the service account specified by the username
    # field above.
    sid: '$LDAP_USER_SID'
    # The server name to use when validating the LDAP server's
    # certificate. Useful in cases where addr is an IP but the server
    # presents a cert with some other hostname.
    server_name: '$COMPUTER_NAME'
    insecure_skip_verify: false
    # The PEM encoded LDAP CA certificate of this AD's LDAP server.
    ldap_ca_cert: |
$CA_CERT_YAML
  discovery:
    base_dn: '*'
  labels:
    env: prd
"@
        return $LDAP_CONFIG_YAML
    }

    function Display-CompletionMessage($LDAP_CONFIG_YAML) {
        $OUTPUT = @"
    Your Teleport Desktop Access configuration is complete. A restrictive service account
    named $AD_USER_NAME has been created with the SAM account name $SAM_ACCOUNT_NAME.
    That account has been prevented from performing interactive logins by creating and
    linking a Group Policy Object (GPO) named $BLOCK_GPO_NAME. Finally a GPO named
    $ACCESS_GPO_NAME has been configured and applied to your domain to allow Teleport
    connections.

    `n{0}

    The next step is to connect a Windows Desktop Service to your Teleport cluster and configure
    it to connect to the LDAP server of this domain. Instructions for this can be found starting at
    https://goteleport.com/docs/enroll-resources/desktop-access/active-directory/#step-67-configure-teleport.
    You may use the `ldap` section printed above as the basis for your Windows Desktop Service
    configuration, which contains values derived from the configuration of this domain.`n
    "@ -f $LDAP_CONFIG_YAML

        Write-Output $OUTPUT

        if ($host.name -match 'ISE') {
            $WHITESPACE_WARNING = @"
    # WARNING:
    # If you're copying and pasting the ldap config from above, PowerShell ISE will add whitespace to the start - delete this before you save the config.
    "@

            Write-Output $WHITESPACE_WARNING
        }
    }

    function Cleanup-Files($TeleportPEMFile, $WindowsDERFile, $WindowsPEMFile) {
        # cleanup files that were created during execution of this script
        Remove-Item $TeleportPEMFile -Recurse
        Remove-Item $WindowsDERFile -Recurse
        Remove-Item $WindowsPEMFile -Recurse

        # Prompt the user to press any key to exit
        #$x = Read-Host "Press close this window..."
    }


    function Is-Installed ([String]$binaryName) {
        if (Get-Command $binaryName -errorAction SilentlyContinue)
        {
            return $True
        }
        return $False
    }

    function Install-RSAT-AD-Tools() {
        if (-not (Is-Installed -binaryName "dsacls")) {
            Install-WindowsFeature -Name RSAT-AD-Tools
        } else {
            Write-Host "RSAT Tools are already installed"
        }
    }


    function Verify-Requirements() {
    Install-RSAT-AD-Tools
    if (-not (Test-Path -Path $SYSVOL_PATH)) {
        throw [System.Exception]::new("Sysvol Path not found : $SYSVOL_PATH")
    }
    }

    #Prompt-ForAcknowledgment
    Verify-Requirements
    Create-ServiceAccount
    Create-LDAPContainers
    Configure-BlockingGPO
    Configure-AccessGPO
    $LDAP_CONFIG = (Generate-LDAPConfig -CA_CERT_YAML (Export-LDAPCertificate))
    Display-CompletionMessage $LDAP_CONFIG
    Write-Log "{$LDAP_CONFIG}"
    Cleanup-Files $TeleportPEMFile $WindowsDERFile $WindowsPEMFile

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

    # Register scheduled task
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
    Register-ScheduledTask -TaskName "PostRebootSetup" -Action $Action -Trigger $Trigger -Principal $Principal -Force

    Write-Log "Scheduled task created for post-reboot setup."
    Write-Log "Rebooting the server to complete domain setup..."
    Restart-Computer -Force
}

$DOMAIN = "${WINDOWS_AD_DOMAIN_NAME}".Trim()
$SafeModeAdministratorPassword = ConvertTo-SecureString "${WINDOWS_AD_ADMIN_PASSWORD}".Trim() -AsPlainText -Force

Install-ADFeatures
Install-ADForest -Domain $DOMAIN -SafeModeAdministratorPassword $SafeModeAdministratorPassword