$mainPath = '\\adc01lrl\Software'
$psver    = $PSVersionTable.PSVersion.ToString()
$winver   = Get-WmiObject -Class Win32_Operatingsystem | select -ExpandProperty caption
Write-Host "$winver" -ForegroundColor DarkCyan
$is_win2008 = $winver -contains '2008'
Write-Host "PS Version: $psver" -ForegroundColor DarkCyan
if ( $PSVersionTable.PSVersion.Major -lt 5 ){
	Write-Host "PS Version too Old" -ForegroundColor Red
	$path = "$mainPath\WMF5.1\"
	if ( $is_win2008 ) {
		[string]$arglist="${path}Win7AndW2K8R2-KB3191566-x64\Win7AndW2K8R2-KB3191566-x64.msu"
	} else {
		[string]$arglist="${path}Win8.1AndW2K12R2-KB3191564-x64.msu"
	}
	Write-Host "Installing $arglist" -ForegroundColor DarkCyan
	$arglist -match "(?<kb>KB\d{6})"
	$kbid = $Matches['kb']
	$arglist = @($arglist,'/quiet','/norestart')
	Start-Process -FilePath 'c:\windows\system32\wusa.exe' -ArgumentList $arglist -NoNewWindow -Wait
	$kb = wmic qfe get hotfixid | Select-String -Pattern $kbid
	if ($kb) {
		Write-Host "  Installed!" -ForegroundColor Green
		Restart-Computer localhost -Confirm
	} else {
		Write-Host "  NOT Installed!" -ForegroundColor Red
	}
	exit
}

$mainPath = '\\adc01lrl\Software'
$mainPath = "$mainPath\SDLprereqsSoftware"
Start-Process "$mainPath\Firefox Setup 52.0.exe" -ArgumentList '/S ' -NoNewWindow -Wait
Start-Process "$mainPath\npp.7.3.2.Installer.exe" -ArgumentList '/S ' -NoNewWindow -Wait
Start-Process "$mainPath\WinMerge-2.14.0-Setup.exe" -ArgumentList '/VERYSILENT /SP- /NORESTART' -NoNewWindow -Wait

# MSDTC timeout --------------------------
# ----------------------------------------
$time = 3600
$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$LocalColl = $comAdmin.Connect("localhost")
$LocalComputer = $LocalColl.GetCollection("LocalComputer",$LocalColl.Name)
$LocalComputer.Populate()

$LocalComputerItem = $LocalComputer.Item(0)
$CurrVal = $LocalComputerItem.Value("TransactionTimeout")
Write-Host "Transaction Timeout = $CurrVal" -ForegroundColor DarkCyan

$LocalComputerItem.Value("TransactionTimeout") = $time
$LocalComputer.SaveChanges()
Get-Service -Name MSDTC | Restart-Service -Verbose

# Establishing a dedicated system user ---
# ----------------------------------------
$user = "oradev\infoshare"
 #$pass = ConvertTo-SecureString -String 'Change.me1' -AsPlainText -Force
 #New-LocalUser -Name 'InfoShare' -FullName $user -Description 'SDL System User' -UserMayNotChangePassword -PasswordNeverExpires -Password $pass

Get-LocalGroupMember -Name Administrators -Member $user -EV gpoerr -EA SilentlyContinue
if ($gpoerr.Count -gt 0) {
	Add-LocalGroupMember -Name Administrators -Member $user
}

$ntprincipal = new-object System.Security.Principal.NTAccount $user
$sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
$sidstr = $sid.Value.ToString()
Write-Host "SID ($user): $sidstr" -ForegroundColor DarkCyan

$tmp = [System.IO.Path]::GetTempFileName()
secedit.exe /export /cfg "$($tmp)" 
$c = Get-Content -Path $tmp
$currentSetting = ""
foreach($s in $c) {
	if( $s -like "SeServiceLogonRight*") {
		$x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		$currentSetting = $x[1].Trim()
	}
}
if( $currentSetting -notlike "*$($sidstr)*" ) {
	Write-Host "Modify Setting ""Logon as a Service""" -ForegroundColor DarkCyan

	if( [string]::IsNullOrEmpty($currentSetting) ) {
		$currentSetting = "*$($sidstr)"
	} else {
		$currentSetting = "*$($sidstr),$($currentSetting)"
	}

	Write-Host "$currentSetting"
	$outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = $($currentSetting)
"@

	$tmp2 = [System.IO.Path]::GetTempFileName()
	Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
	$outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force

	Push-Location (Split-Path $tmp2)
    secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
    Pop-Location
} else {
	Write-Host "NO ACTIONS REQUIRED! Account already in ""Logon as a Service""" -ForegroundColor DarkCyan
}

#Import-Module international
#$lang = Get-WinSystemLocale
#Write-Host "Current Language: $($lang.DisplayName)" -ForegroundColor DarkCyan
#if ($lang.Name -ne 'en-US' ) {
#   Set-WinSystemLocale en-US
#}
#}
Write-Host "Changing default date format" -ForegroundColor DarkCyan
$val = @('sShortDate','sLongDate','sShortTime','sLongTime')
$val = Get-ItemPropertyValue -Path 'Registry::HKEY_USERS\.DEFAULT\Control Panel\International' -Name $val -ErrorVariable regerr -EA SilentlyContinue
if ($regerr.Count -eq 0) {
    Write-Host "Current Short date: $($val[0])" -ForegroundColor DarkCyan
    Write-Host "Current Long  date: $($val[1])" -ForegroundColor DarkCyan
    Write-Host "Current Short Time: $($val[2])" -ForegroundColor DarkCyan
    Write-Host "Current Long  Time: $($val[3])" -ForegroundColor DarkCyan
}

$Short_date = 'dd/MM/yyyy'
$Long_date  = 'ddddd d MMMM yyyy'
$Short_time = 'HH:mm:ss'
$Long_time  = 'HH:mm:ss'
$reg_path = 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\.DEFAULT\Control Panel\International'
Set-ItemProperty -Path $reg_path -Name sShortDate -Value $Short_date
Set-ItemProperty -Path $reg_path -Name sLongDate  -Value $Long_date
Set-ItemProperty -Path $reg_path -Name sShortTime -Value $Short_time
Set-ItemProperty -Path $reg_path -Name sLongTime  -Value $Long_time

# Changing the Local Group Policy --------
# ----------------------------------------
Write-Host "LGP" -ForegroundColor DarkCyan
$rkey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$forceun = Get-ItemProperty -Path $rkey -Name DisableForceUnload -ErrorAction SilentlyContinue
if ($forceun -eq $null) {
	New-ItemProperty -Path $rkey -Name DisableForceUnload -Value 1 -Force
	#gpedit.msc
}

# Oracle Data Access Components ----------
# dev | int | prod
$env='dev'
# ----------------------------------------
#Oracle Data Provider for .NET. 12.1.0.1.0
#Oracle Provider for OLE DB 12.1.0.1.0
#Oracle Services for Microsoft Transaction Server 12.1.0.1.0
#Oracle Instant Client 12.1.0.1.0
Write-Host "Intalling ODAC" -ForegroundColor DarkCyan
$path="$mainPath\Oracle Data Access Components"
Copy-Item -Path "$path\auto.ini" -Destination 'C:\auto.ini' -Force
Start-Process -FilePath "$path\ODTwithODAC121012\setup.exe" -ArgumentList 'ORACLE_BASE="C:\Oracle"' -Wait -NoNewWindow #,'-silent C:\auto.ini'
Copy-Item -Path "$path\$env\tnsnames.ora" `
	-Destination 'C:\Oracle\product\12.1.0\client_1\Network\Admin' `
	-Force
if ($false) {
    Start-Process -FilePath 'C:\Oracle\product\12.1.0\client_1\sqlplus.exe' `
        -ArgumentList 'isource/pru5HuthaxAgaJuj@ish'
}


# Microsoft XML Parser
Write-Host "Installing XML Parser" -ForegroundColor DarkCyan
$path="$mainPath\Microsoft XML Parser"
$test1 = Test-Path -Path C:\windows\system32\msxml6.dll
$test2 = Test-Path -Path C:\Windows\syswow64\msxml6.dll
if ($test1 -and $test2) { }
else {	
	#Start-Process -FilePath "$path\msxml6-KB973686-enu-x86.exe" `
	#	-ArgumentList '/quiet','/qn'
	#Start-Process -FilePath "$path\msxml6-KB973686-enu-amd64.exe" `
	#	-ArgumentList '/quiet','/qn'
	Write-Host "XML Parser installed" -ForegroundColor DarkCyan
}
Start-Process -FilePath "$path\msxml4sp3.msi" -ArgumentList '/quiet','/qn' -Wait

# JAVA -----------------------------------
# ----------------------------------------
Write-Host "Installing JAVA" -ForegroundColor DarkCyan
$path="$mainPath\Java"
Start-Process -FilePath "$path\jdk-7u21-windows-x64.exe" -ArgumentList '/quiet','/qn' -Wait -NoNewWindow
Start-Process -FilePath "$path\jre-7u21-windows-x64.exe" -ArgumentList '/quiet','/qn' -Wait -NoNewWindow


Write-Host "Installing NET C++" -ForegroundColor DarkCyan
$path="$mainPath\NET Framework"
Start-Process -FilePath "$path\NETFramework2012_4.5_MicrosoftVisualC++Redistributable_(vcredist_x64).exe" `
	-ArgumentList '/quiet','/qn' -Wait -NoNewWindow


# Configuration requirements -------------
# ----------------------------------------
Write-Host "Copying JavaHelp" -ForegroundColor DarkCyan
$path="$mainPath\JavaHelp\javahelp-2_0_05\jh2.0"
New-Item -Path 'C:\JavaHelp' -ItemType Directory
Write-Host 'Copying folder JAVAHELP...' -ForegroundColor DarkCyan
Copy-Item -Path "$path" -Destination 'C:\JavaHelp' -Recurse
#if (!(Test-Path -Path 'C:\JavaHelp\src.jar')) {
#	if (Test-Path -Path 'C:\JavaHelp') {
#        Write-Host 'Removing partial folder...' -ForegroundColor DarkCyan
#        Remove-Item -Path 'C:\JavaHelp' -Recurse
#	}
#   Write-Host 'Copying folder JAVAHELP...' -ForegroundColor DarkCyan
#	Copy-Item -Path "$path" -Destination 'C:\JavaHelp' -Recurse
#}

# HTML HELP
Write-Host "Installing HTML Help" -ForegroundColor DarkCyan
$path="$mainPath\HTML Help"
$dest = 'C:\Program Files (x86)\HTML Help Workshop'
New-Item -Path $dest -ItemType Directory
Start-Process -FilePath "$path\htmlhelp.exe" -ArgumentList '/Q' -Wait -NoNewWindow


Write-Host "Installing Antenna House" -ForegroundColor DarkCyan
$path="$mainPath\AntennaHouse\AntennaHouse V6.0"
@"
[InstallShield Silent]
Version=v7.00
File=Response File
[File Transfer]
OverwrittenReadOnly=NoToAll
[{BD84DF52-3451-4215-AEC2-99293C665751}-DlgOrder]
Dlg0={BD84DF52-3451-4215-AEC2-99293C665751}-SdLicense-0
Count=6
Dlg1={BD84DF52-3451-4215-AEC2-99293C665751}-SdAskDestPath-0
Dlg2={BD84DF52-3451-4215-AEC2-99293C665751}-AskOptions-0
Dlg3={BD84DF52-3451-4215-AEC2-99293C665751}-AskYesNo-0
Dlg4={BD84DF52-3451-4215-AEC2-99293C665751}-AskOptions-1
Dlg5={BD84DF52-3451-4215-AEC2-99293C665751}-SdFinish-0
[{BD84DF52-3451-4215-AEC2-99293C665751}-SdLicense-0]
Result=1
[{BD84DF52-3451-4215-AEC2-99293C665751}-SdAskDestPath-0]
szDir=C:\Program Files\Antenna House\AHFormatterV6
Result=1
[{BD84DF52-3451-4215-AEC2-99293C665751}-AskOptions-0]
Result=1
Sel-0=0
Sel-1=1
[Application]
Name=
Version=
Company=
Lang=0009
[{BD84DF52-3451-4215-AEC2-99293C665751}-AskYesNo-0]
Result=1
[{BD84DF52-3451-4215-AEC2-99293C665751}-AskOptions-1]
Result=1
Sel-0=0
[{BD84DF52-3451-4215-AEC2-99293C665751}-SdFinish-0]
Result=1
bOpt1=0
bOpt2=0
"@ | Out-File 'C:\Windows\setup.iss'
Start-Process -FilePath "$path\V6-0-M7-Windows_X64_64E.exe" -NoNewWindow -Wait

$env='Non-Prod (2)'
Copy-Item -Path "$path\Oracle_AntennaHouse_v62_5176License\5176License\$env\AHFormatter.lic" `
    -Destination 'C:\Program Files\Antenna House\AHFormatterV6'


Write-Host "Installing Windows Features" -ForegroundColor DarkCyan
if ( $is_win2008 ) {
    Add-WindowsFeature NET-Framework-Core, NET-HTTP-Activation
    Add-WindowsFeature Web-Common-Http, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors
    Add-WindowsFeature Web-Asp-Net, Web-Net-Ext, Web-ASP, Web-ISAPI-Ext, Web-ISAPI-Filter
    Add-WindowsFeature Web-Stat-Compression, Web-Dyn-Compression, Web-Http-Logging, Web-Request-Monitor
    Add-WindowsFeature Web-Mgmt-Console
	Add-WindowsFeature AS-Incoming-Trans, AS-Outgoing-Trans
} else {
	# Configuring .NET Framework on Windows 2012
	Install-WindowsFeature NET-Framework-45-Core

	# Configuring HTTP Activation for WCF on Windows 2012R2
	Install-WindowsFeature NET-WCF-HTTP-Activation45

	# Configuring IIS and ASP Web services on Windows 2012 R2
	Install-WindowsFeature Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content
	Install-WindowsFeature Web-Net-Ext45, Web-Asp-Net45, Web-ASP, Web-ISAPI-Ext, Web-ISAPI-Filter
	Install-WindowsFeature Web-Stat-Compression, Web-Dyn-Compression
	Install-WindowsFeature Web-Http-Logging, Web-Request-Monitor
	Install-WindowsFeature Web-Mgmt-Console

	# Configuring Application Server Role
	Install-WindowsFeature AS-Incoming-Trans, AS-Outgoing-Trans
}

# Configuring IIS applicationHost.Config ----------------------------------------
Write-Host "Configuring IIS Config" -ForegroundColor DarkCyan
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/asp /commit:apphost
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/serverRuntime /commit:apphost
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/defaultDocument /commit:apphost
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/staticContent /commit:apphost
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/directoryBrowse /commit:apphost
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/handlers /commit:apphost
C:\Windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/urlCompression /commit:apphost

Set-ExecutionPolicy Unrestricted -Force

Import-Module WebAdministration

# Define the mimetypes for IIS that can be statically compressed
$staticcompression = @(
	@{mimeType='text/*'; enabled='True'},
	@{mimeType='message/*'; enabled='True'},
	@{mimeType='application/x-javascript'; enabled='True'},
	@{mimeType='application/atom+xml'; enabled='True'},
	@{mimeType='application/xaml+xml'; enabled='True'},
 @{mimeType='application/octet-stream'; enabled='True'},
	@{mimeType='*/*'; enabled='False'}
)
# Set the specified static mimetypes in the compression settings
# in applicationHost.config
$filter = 'system.webServer/httpCompression/statictypes'
Set-Webconfiguration -Filter $filter -Value $staticcompression

Set-ExecutionPolicy Unrestricted -Force

Import-Module WebAdministration

# Define the mimetypes for IIS that can be dynamically compressed
$dynamiccompression = @(
	@{mimeType='text/*'; enabled='True'},
	@{mimeType='message/*'; enabled='True'},
	@{mimeType='application/x-javascript'; enabled='True'},
	@{mimeType='application/soap+xml'; enabled='True'},
	@{mimeType='application/xml'; enabled='True'},
	@{mimeType='application/json'; enabled='True'},
 @{mimeType='application/octet-stream'; enabled='True'},
	@{mimeType='*/*'; enabled='False'}	
)
# Set the specified dynamic mimetypes in the compression settings 
# in applicationHost.config
$filter = 'system.webServer/httpCompression/dynamictypes'
Set-Webconfiguration -Filter $filter -Value $dynamiccompression
# Note that compression can be set per web.config file
