$ErrorActionPreference = "Stop"

$AD_USER_NAME="Teleport Service Account"
$SAM_ACCOUNT_NAME="svc-teleport"
$BLOCK_GPO_NAME="Block teleport-svc Interactive Login"
$ACCESS_GPO_NAME="Teleport Access Policy"

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

$TELEPORT_CA_CERT_PEM = "-----BEGIN CERTIFICATE-----
MIIEBzCCAu+gAwIBAgIRAKOXDaPhN+nbq2aqtFmR0OIwDQYJKoZIhvcNAQELBQAw
gZwxMzAxBgNVBAoTKm5lYnVsYS1kYXNoLXN0YWdpbmcuY2xvdWQuZ3Jhdml0YXRp
b25hbC5pbzEzMDEGA1UEAxMqbmVidWxhLWRhc2gtc3RhZ2luZy5jbG91ZC5ncmF2
aXRhdGlvbmFsLmlvMTAwLgYDVQQFEycyMTc0NDg0NzY3OTM3OTcxMDYwNDU0OTA4
NDczOTA0MzM5MjMyOTgwHhcNMjUwMjE2MDIxNTIzWhcNMzUwMjE0MDIxNTIzWjCB
nDEzMDEGA1UEChMqbmVidWxhLWRhc2gtc3RhZ2luZy5jbG91ZC5ncmF2aXRhdGlv
bmFsLmlvMTMwMQYDVQQDEypuZWJ1bGEtZGFzaC1zdGFnaW5nLmNsb3VkLmdyYXZp
dGF0aW9uYWwuaW8xMDAuBgNVBAUTJzIxNzQ0ODQ3Njc5Mzc5NzEwNjA0NTQ5MDg0
NzM5MDQzMzkyMzI5ODCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANF7
kdQwS2azJeEkPuwDNVB8ozs3hJe0Hwk1X6eiRgbWrutVmXGqq4N2EHomg/TJnzVD
N8U7syHtfZC186iBaObE3f9VFpDxDQtxilJDKDWsTKntZzsPkRN1rQ+kYb5jhPBE
d5w8ExDXDX/mgkBiSjYISOocfJ7FBUax+JqChHCobpwMINTQxOn8eSwFffXx/xlR
DdS1nM3uKsvPMlp9JrRmAHdbMPwpmzPNW9tX91X/DceNjaLef58qta0pfKy6lqFv
yqZ7NNch1OyciceCJVtz+fT4gtJt3F/SOsQlhoa1pleg1hoJ+gbULSIMEi6C2StF
HpysTBYAe7QCKFFSsvECAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgGmMA8GA1UdEwEB
/wQFMAMBAf8wHQYDVR0OBBYEFKSKJIoDeDg5hPIy61/52diTb2RDMA0GCSqGSIb3
DQEBCwUAA4IBAQAEptzc7Yqq73oKmC7ja0DkvNqXED64iAG2R0AM6I+thfwpNrdZ
c22WU5Wieke+QSVtpXzYThNdhOfqVGzMLVkzcPx5ENiR33AQ9s9GqXo4Y0cnika1
5RSNClhglEzjfRL++vcTiOF0Vm6OpYt0/2nAVgSQFCCTTsWY2TUI1ci247t3H4Dv
JMrgn8NFLt11C4Gl24kFf7Wu6sq4q/ilo52CqlLXAzORfdDktKknZ1V4tiznYn5M
0OSZsc4YMn8JGqM5q9YsscvUuGPBf5HT0ACqitDvKEnwjEeKVn4zzl9jh3pCPCwH
vZI9mu+Kb1PI4jgoticqJ5PtIoYDzIUYSwmm
-----END CERTIFICATE-----
"
$TELEPORT_CA_CERT_SHA1 = "2FBAA8385CCB879661446EB84AD3BA871DF5625D"
$TELEPORT_CA_CERT_BLOB_BASE64 = "IAAAAAEAAAALBAAAMIIEBzCCAu+gAwIBAgIRAKOXDaPhN+nbq2aqtFmR0OIwDQYJKoZIhvcNAQELBQAwgZwxMzAxBgNVBAoTKm5lYnVsYS1kYXNoLXN0YWdpbmcuY2xvdWQuZ3Jhdml0YXRpb25hbC5pbzEzMDEGA1UEAxMqbmVidWxhLWRhc2gtc3RhZ2luZy5jbG91ZC5ncmF2aXRhdGlvbmFsLmlvMTAwLgYDVQQFEycyMTc0NDg0NzY3OTM3OTcxMDYwNDU0OTA4NDczOTA0MzM5MjMyOTgwHhcNMjUwMjE2MDIxNTIzWhcNMzUwMjE0MDIxNTIzWjCBnDEzMDEGA1UEChMqbmVidWxhLWRhc2gtc3RhZ2luZy5jbG91ZC5ncmF2aXRhdGlvbmFsLmlvMTMwMQYDVQQDEypuZWJ1bGEtZGFzaC1zdGFnaW5nLmNsb3VkLmdyYXZpdGF0aW9uYWwuaW8xMDAuBgNVBAUTJzIxNzQ0ODQ3Njc5Mzc5NzEwNjA0NTQ5MDg0NzM5MDQzMzkyMzI5ODCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANF7kdQwS2azJeEkPuwDNVB8ozs3hJe0Hwk1X6eiRgbWrutVmXGqq4N2EHomg/TJnzVDN8U7syHtfZC186iBaObE3f9VFpDxDQtxilJDKDWsTKntZzsPkRN1rQ+kYb5jhPBEd5w8ExDXDX/mgkBiSjYISOocfJ7FBUax+JqChHCobpwMINTQxOn8eSwFffXx/xlRDdS1nM3uKsvPMlp9JrRmAHdbMPwpmzPNW9tX91X/DceNjaLef58qta0pfKy6lqFvyqZ7NNch1OyciceCJVtz+fT4gtJt3F/SOsQlhoa1pleg1hoJ+gbULSIMEi6C2StFHpysTBYAe7QCKFFSsvECAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgGmMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFKSKJIoDeDg5hPIy61/52diTb2RDMA0GCSqGSIb3DQEBCwUAA4IBAQAEptzc7Yqq73oKmC7ja0DkvNqXED64iAG2R0AM6I+thfwpNrdZc22WU5Wieke+QSVtpXzYThNdhOfqVGzMLVkzcPx5ENiR33AQ9s9GqXo4Y0cnika15RSNClhglEzjfRL++vcTiOF0Vm6OpYt0/2nAVgSQFCCTTsWY2TUI1ci247t3H4DvJMrgn8NFLt11C4Gl24kFf7Wu6sq4q/ilo52CqlLXAzORfdDktKknZ1V4tiznYn5M0OSZsc4YMn8JGqM5q9YsscvUuGPBf5HT0ACqitDvKEnwjEeKVn4zzl9jh3pCPCwHvZI9mu+Kb1PI4jgoticqJ5PtIoYDzIUYSwmm"
$TELEPORT_PROXY_PUBLIC_ADDR = "<no value>"
$TELEPORT_PROVISION_TOKEN = "<no value>"

$DOMAIN_NAME=(Get-ADDomain).DNSRoot
$DOMAIN_DN=$((Get-ADDomain).DistinguishedName)

try {
  Get-ADUser -Identity $SAM_ACCOUNT_NAME
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
  Add-Type -AssemblyName 'System.Web'
  do {
    $PASSWORD=[System.Web.Security.Membership]::GeneratePassword(15,1)
  } until ($PASSWORD -match '\d')
  $SECURE_STRING_PASSWORD=ConvertTo-SecureString $PASSWORD -AsPlainText -Force
  New-ADUser -Name $AD_USER_NAME -SamAccountName $SAM_ACCOUNT_NAME -AccountPassword $SECURE_STRING_PASSWORD -Enabled $true
}

# Create the CDP/Teleport container.
try {
  Get-ADObject -Identity "CN=Teleport,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$DOMAIN_DN"
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
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

$SAM_ACCOUNT_SID=(Get-ADUser -Identity $SAM_ACCOUNT_NAME).SID.Value


# Step 2/7. Prevent the service account from performing interactive logins
try {
  $BLOCK_GPO = Get-GPO -Name $BLOCK_GPO_NAME
}
catch [System.ArgumentException]
{
  $BLOCK_GPO = New-GPO -Name $BLOCK_GPO_NAME
  $BLOCK_GPO | New-GPLink -Target $DOMAIN_DN
}

$DENY_SECURITY_TEMPLATE=@'
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
[Privilege Rights]
SeDenyRemoteInteractiveLogonRight=*{0}
SeDenyInteractiveLogonRight=*{0}
'@ -f $SAM_ACCOUNT_SID


$BLOCK_POLICY_GUID=$BLOCK_GPO.Id.Guid.ToUpper()
$BLOCK_GPO_PATH="$env:SystemRoot\SYSVOL\sysvol\$DOMAIN_NAME\Policies\{$BLOCK_POLICY_GUID}\Machine\Microsoft\Windows NT\SecEdit"
New-Item -Force -Type Directory -Path $BLOCK_GPO_PATH
New-Item -Force -Path $BLOCK_GPO_PATH -Name "GptTmpl.inf" -ItemType "file" -Value $DENY_SECURITY_TEMPLATE


# Step 3/7. Configure a GPO to allow Teleport connections
try {
  $ACCESS_GPO = Get-GPO -Name $ACCESS_GPO_NAME
}
catch [System.ArgumentException]
{
  $ACCESS_GPO = New-GPO -Name $ACCESS_GPO_NAME
  $ACCESS_GPO | New-GPLink -Target $DOMAIN_DN
}

$CERT = [System.Convert]::FromBase64String($TELEPORT_CA_CERT_BLOB_BASE64)
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\SystemCertificates\Root\Certificates\$TELEPORT_CA_CERT_SHA1" -ValueName "Blob" -Type Binary -Value $CERT

$TeleportPEMFile = $env:TEMP + "\teleport.pem"
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

$COMMENT_XML=@'
<?xml version='1.0' encoding='utf-8'?>
<policyComments xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" revision="1.0" schemaVersion="1.0" xmlns="http://www.microsoft.com/GroupPolicy/CommentDefinitions">
  <policyNamespaces>
    <using prefix="ns0" namespace="Microsoft.Policies.TerminalServer"></using>
  </policyNamespaces>
  <comments>
    <admTemplate></admTemplate>
  </comments>
  <resources minRequiredRevision="1.0">
    <stringTable></stringTable>
  </resources>
</policyComments>
'@


$ACCESS_POLICY_GUID=$ACCESS_GPO.Id.Guid.ToUpper()
$ACCESS_GPO_PATH="$env:SystemRoot\SYSVOL\sysvol\$DOMAIN_NAME\Policies\{$ACCESS_POLICY_GUID}\Machine\Microsoft\Windows NT\SecEdit"

New-Item -Force -Type Directory -Path $ACCESS_GPO_PATH
New-Item -Force -Path $ACCESS_GPO_PATH -Name "GptTmpl.inf" -ItemType "file" -Value $ACCESS_SECURITY_TEMPLATE
New-Item -Force -Path "$env:SystemRoot\SYSVOL\sysvol\$DOMAIN_NAME\Policies\{$ACCESS_POLICY_GUID}\Machine" -Name "comment.cmtx" -ItemType "file" -Value $COMMENT_XML

# Firewall
$FIREWALL_USER_MODE_IN_TCP = "v2.31|Action=Allow|Active=TRUE|Dir=In|Protocol=6|LPort=3389|App=%SystemRoot%\system32\svchost.exe|Svc=termservice|Name=@FirewallAPI.dll,-28775|Desc=@FirewallAPI.dll,-28756|EmbedCtxt=@FirewallAPI.dll,-28752|"
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsFirewall" -ValueName "PolicyVersion" -Type DWORD -Value 543
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Type String -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsFirewall\FirewallRules" -ValueName "RemoteDesktop-UserMode-In-TCP" -Value $FIREWALL_USER_MODE_IN_TCP


# Allow remote RDP connections
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDenyTSConnections" -Type DWORD -Value 0
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "UserAuthentication" -Type DWORD -Value 0

# Disable "Always prompt for password upon connection"
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fPromptForPassword" -Type DWORD -Value 0

# Enable RemoteFX
# As described here: https://github.com/Devolutions/IronRDP/blob/55d11a5000ebd474c2ddc294b8b3935554443112/README.md?plain=1#L17-L24
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "ColorDepth" -Type DWORD -Value 5
Set-GPRegistryValue -Name $ACCESS_GPO_NAME -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fEnableVirtualizedGraphics" -Type DWORD -Value 1

# # Step 5/7. Export your LDAP CA certificate
$WindowsDERFile = $env:TEMP + "\windows.der"
$WindowsPEMFile = $env:TEMP + "\windows.pem"
certutil "-ca.cert" $WindowsDERFile
certutil -encode $WindowsDERFile $WindowsPEMFile

gpupdate.exe /force

$CA_CERT_PEM = Get-Content -Path $WindowsPEMFile
$CA_CERT_YAML = $CA_CERT_PEM | ForEach-Object { "        " + $_  } | Out-String


$NET_BIOS_NAME = (Get-ADDomain).NetBIOSName
$LDAP_USERNAME = "$NET_BIOS_NAME\$SAM_ACCOUNT_NAME"
$LDAP_USER_SID=(Get-ADUser -Identity $SAM_ACCOUNT_NAME).SID.Value

$COMPUTER_NAME = (Resolve-DnsName -Type A $Env:COMPUTERNAME).Name
$COMPUTER_IP = (Resolve-DnsName -Type A $Env:COMPUTERNAME).Address
$LDAP_ADDR="$COMPUTER_IP" + ":636"

$LDAP_CONFIG_YAML=@"
  ldap:
    # Ensure this is a public IP address or DNS name.
    addr:     '$LDAP_ADDR'
    # The Active Directory domain name.
    domain:   '$DOMAIN_NAME'
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
"@

$OUTPUT=@"
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

if ($host.name -match 'ISE')
{
  $WHITESPACE_WARNING=@'
# WARNING:
# If you're copying and pasting the ldap config from above, PowerShell ISE will add whitespace to the start - delete this before you save the config.
'@

  Write-Output $WHITESPACE_WARNING
}

# cleanup files that were created during execution of this script
Remove-Item $TeleportPEMFile -Recurse
Remove-Item $WindowsDERFile -Recurse
Remove-Item $WindowsPEMFile -Recurse

# Prompt the user to press any key to exit
Write-Output "Press any key to exit, which will close this window."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
