New-PSDrive -Name z -Root \\dadvip0032\Software -Persist -PSProvider FileSystem

Copy-Item Z:\2014Prereqs -Destination C:\LCAWorkingDirectory -Recurse

Start-Process -FilePath C:\SP3prereqs\npp.6.7.4.Installer.exe -ArgumentList "/S"

Start-Process -FilePath 'Z:\SP3prereqs\Oracle Data Access Components\ODTwithODAC121012\setup.exe'
