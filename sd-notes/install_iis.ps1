# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Allow incoming HTTP traffic through the Windows Firewall
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80