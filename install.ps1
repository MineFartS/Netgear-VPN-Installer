
# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-Location $PSScriptRoot
    
Start-Process "msiexec.exe" -Wait -ArgumentList @(
    '/i', "OpenVPN-2.5.5-I602-amd64.msi",
    'ADDLOCAL=ALL',
    '/qb+', '/norestart', '/passive'
)

# Copy Configuration
Copy-Item -Force -Verbose `
    -Path "config\*" `
    -Destination "C:\Program Files\OpenVPN\config\"

# Patch profiles to fix the 'fragment' crash and enable Pre-Logon properties
Get-ChildItem "C:\Program Files\OpenVPN\config\*.ovpn" | ForEach-Object {
    $Content = Get-Content $_.FullName
    $Content = $Content -replace '^(fragment\s.*)', '# $1'
    $Content += "`n`n# Compatibility and Pre-Logon Configurations"
    $Content += "`nallow-compression yes"
    $Content += "`nmssfix 1360"
    $Content += "`nmanagement 127.0.0.1 12345"
    $Content += "`nmanagement-hold"
    $Content += "`nmanagement-query-passwords"
    $Content += "`nauth-retry interact"
    Set-Content -Path $_.FullName -Value $Content -Force -Verbose
}

# Configure interface adapter
$Adapter = Get-NetAdapter | Where-Object InterfaceDescription -like '*TAP*V9*'
$Adapter | Rename-NetAdapter -NewName 'NETGEAR-VPN' -Verbose
$Adapter | Set-NetIPInterface -InterfaceMetric 1 -Verbose

# Configure OpenVPN Service
$service = Get-Service -name '*openvpn*'
$service | Set-Service -StartupType Automatic -Verbose
$service | Restart-Service -Force -Verbose

Pause
