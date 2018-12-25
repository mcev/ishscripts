Enable-PSRemoting

$Credential = $host.ui.PromptForCredential("Oradev login", "Please enter your password.", "oradev\mcevallo", "NetBiosUserName")

# prod services
Invoke-Command -ComputerName adc01lft, adc01lri, adc01lrl, adc01lrn, adc01lrp -Credential $Credential {Get-Service -DisplayName "Tri*" -Verbose} |Select-Object Name, Status, StartType, PSComputerName| Out-GridView

# int services
Invoke-Command -ComputerName adc01eam, adc01eal, adc01lfu -Credential $Credential {Get-Service -DisplayName "Tri*"} | Select-Object Name, Status, StartType, PSComputerName| Out-GridView

# dev services
Invoke-Command -ComputerName adc01lrr, adc01lfs, slc12dea -Credential $Credential {Get-Service -DisplayName "Tri*"} | Select-Object Name, Status, StartType, PSComputerName| Out-GridView

Enter-PSSession -ComputerName adc01lri -Credential $Credential