    Enable-PSRemoting

$Credential = $host.ui.PromptForCredential("domIN login", "Please enter your password.", "DOMAIN/USR", "NetBiosUserName")


#Prod
Invoke-Command -ComputerName adc01lri -Credential $Credential {
    Get-IshTypeFieldDefinition -IshSession (New-IshSession -WsBaseUrl "https:///infosharews" -PSCredential "") -TriDKXmlSetupFilePath "C:\InfoShare\App\Database\Common\DatabaseIndependent\Examples\Full-Export\exportInfoshare_result.xml"
} | Out-GridView
#Int
Invoke-Command -ComputerName adc01eam -Credential $Credential {
    Get-IshTypeFieldDefinition -IshSession (New-IshSession -WsBaseUrl "https:///infosharews" -PSCredential "") -TriDKXmlSetupFilePath "C:\InfoShare\App\Database\Common\DatabaseIndependent\Examples\Full-Export\exportInfoshare_result.xml"
} | Out-GridView
#Dev
Invoke-Command -ComputerName adc01lrr -Credential $Credential {
    Get-IshTypeFieldDefinition -IshSession (New-IshSession -WsBaseUrl "https:///infosharews" -PSCredential "") -TriDKXmlSetupFilePath "C:\InfoShare\App\Database\Common\DatabaseIndependent\Examples\Full-Export\exportInfoshare_result.xml"
} | Out-GridView

