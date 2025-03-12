 # Define Variables
$DomainName = "jasmitdemo.local"

# Organizational Units (OUs) to create
$OUs = @("IT", "HR", "Finance", "Marketing", "Sales")

# Users to create (Modify as needed)
$Users = @(
    @{FirstName="John"; LastName="Doe"; OU="IT"; Password="P@ssw0rd123"},
    @{FirstName="Jane"; LastName="Smith"; OU="HR"; Password="P@ssw0rd123"},
    @{FirstName="Michael"; LastName="Brown"; OU="Finance"; Password="P@ssw0rd123"}
)

# Create Organizational Units
foreach ($OU in $OUs) {
    $OUPath = "OU=$OU,DC=" + ($DomainName -replace "\.",",DC=")
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $OU -Path "DC=$($DomainName -replace '\.', ',DC=')" -ProtectedFromAccidentalDeletion $false
        Write-Host "Created OU: $OU" -ForegroundColor Green
    } else {
        Write-Host "OU $OU already exists. Skipping..." -ForegroundColor Yellow
    }
}

# Create Users
foreach ($User in $Users) {
    $OUPath = "OU=$($User.OU),DC=" + ($DomainName -replace "\.",",DC=")
    $SamAccountName = ($User.FirstName.Substring(0,1) + $User.LastName).ToLower()
    $UserPrincipalName = "$SamAccountName@$DomainName"
    
    # Convert password to secure string
    $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force

    # Check if user exists
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name "$($User.FirstName) $($User.LastName)" `
                   -GivenName $User.FirstName `
                   -Surname $User.LastName `
                   -SamAccountName $SamAccountName `
                   -UserPrincipalName $UserPrincipalName `
                   -Path $OUPath `
                   -AccountPassword $SecurePassword `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true
        Write-Host "Created User: $SamAccountName in OU: $($User.OU)" -ForegroundColor Green
    } else {
        Write-Host "User $SamAccountName already exists. Skipping..." -ForegroundColor Yellow
    }
}

Write-Host "AD OU and User Setup Completed!" -ForegroundColor Cyan
 
