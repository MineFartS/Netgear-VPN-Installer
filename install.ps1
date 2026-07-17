
# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-Location $PSScriptRoot

# Install OpenVPN
& msiexec.exe `
    /i "OpenVPN-2.5.5-I602-amd64.msi" `
    ADDLOCAL=OpenVPN.Service,OpenVPN.PLAP.Register,Drivers.TAPWindows6,OpenVPN `
    /qn /norestart /passive

# Copy Configuration
Copy-Item -Force -Verbose `
    -Path "config\*" `
    -Destination "C:\Program Files\OpenVPN\config\"

# Configure interface adapter
$Adapter = Get-NetAdapter | Where-Object InterfaceDescription -like '*TAP*V9*'
$Adapter | Rename-NetAdapter -NewName 'NETGEAR-VPN' -Verbose
$Adapter | Set-NetIPInterface -InterfaceMetric 1 -Verbose

# Configure OpenVPN Service
$service = Get-Service -name '*openvpn*'
$service | Set-Service -StartupType Automatic -Verbose
$service | Restart-Service -Force -Verbose

Pause
