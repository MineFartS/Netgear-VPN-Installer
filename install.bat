@echo off

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

:: Install OpenVPN
start /wait msiexec.exe /i "OpenVPN-2.5.5-I602-amd64.msi" /qn /norestart /passive

:: Copy Configuration
xcopy "config\*.*" "C:\Program Files\OpenVPN\config" /Y

powershell -Command ^
    "$Adapter = Get-NetAdapter | Where-Object InterfaceDescription -like '*TAP*V9*';" ^
    "$Adapter | Rename-NetAdapter -NewName 'NETGEAR-VPN';" ^
    "$Adapter | Set-NetIPInterface -InterfaceMetric 1;"

pause
