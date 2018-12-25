Get-Service trisoft* | Format-Table
Get-Service trisoft* | Format-List

Start-Service -DisplayName *BackgroundTask*
STart-Service -DisplayName *crawler*

Restart-Service trisoft*
Restart-Service -name *backgroundtask*

Stop-Service trisoft*