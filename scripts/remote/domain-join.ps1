 $domain = "jasmitdemo.local"
$ou = "OU=IT,DC=jasmitdemo,DC=local"  # IT OU in jasmitdemo.local domain
$user = "Administrator"  # Domain Admin username
$password = "YourSecurePassword123!"  # Domain Admin password

# Define the DNS server IP (your Domain Controller's IP)
$dnsServerIP = "10.0.2.223"  # Replace with your Domain Controller's private IP

# Get the network adapter (assumes the adapter is 'Up')
$networkAdapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Set the DNS server for the network adapter
Set-DnsClientServerAddress -InterfaceIndex $networkAdapter.InterfaceIndex -ServerAddresses $dnsServerIP

# Verify DNS configuration
Get-DnsClientServerAddress -InterfaceIndex $networkAdapter.InterfaceIndex

# Convert password to secure string
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Create the credentials object
$credential = New-Object System.Management.Automation.PSCredential ($user, $securePassword)

# Join the machine to the domain
Add-Computer -DomainName $domain -OUPath $ou -Credential $credential -Restart 

