Get-WindowsFeature -Name *NET* | Format-Table
Get-WindowsFeature -Name *HTTP-Act* | Format-List
Get-WindowsFeature -Name *web* | Format-Table

Import-Module ServerManager