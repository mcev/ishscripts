
Import-Module ServerManager

#Add NET-Framework-45-Core & HTTPActivation for WCF
#Add-WindowsFeature NET-Framework-45-Core
Add-WindowsFeature NET-WCF-HTTP-Activation45

#Configuring Application Server Role
Add-WindowsFeature AS-Dist-Transaction
Add-WindowsFeature AS-Incoming-Trans
Add-WindowsFeature AS-Outgoing-Trans

#Configuring IIS and ASP Web services on Windows 2012 R2
Add-WindowsFeature Web-Common-Http
Add-WindowsFeature Web-Dir-Browsing
Add-WindowsFeature Web-Http-Errors
Add-WindowsFeature Web-Static-Content
Add-WindowsFeature Web-ASP
Add-WindowsFeature Web-Asp-Net45
Add-WindowsFeature Web-Net-Ext45
Add-WindowsFeature Web-ISAPI-Ext
Add-WindowsFeature Web-ISAPI-Filter
Add-WindowsFeature Web-Stat-Compression
Add-WindowsFeature Web-Dyn-Compression
Add-WindowsFeature Web-Http-Logging
Add-WindowsFeature Web-Request-Monitor
Add-WindowsFeature Web-Mgmt-Console

