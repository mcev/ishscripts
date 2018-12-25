Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
Install-Module ISHRemote -Repository PSGallery -Scope CurrentUser -Force

get-module -ListAvailable -name ISHRemote

#access commands
$devsession = New-IshSession -WsBaseUrl "https://ccms-dev.us.oracle.com/infosharews" -PSCredential "Martin Cevallos"
$intsession = New-IshSession -WsBaseUrl "https://ccms-int.us.oracle.com/infosharews" -PSCredential "Martin Cevallos"
$prodsession = New-IshSession -WsBaseUrl "https://ccms.us.oracle.com/infosharews" -PSCredential "Martin Cevallos"

#getting fields for users given filter
$rmeta = $rmeta | Set-IshRequestedMetadataField -IshSession $devsession -Name "FISHUSERROLES" -Level None
$filterf = Set-IshMetadataFilterField -IshSession $devsession -Name "NAME" -Value "Joe" -Level "None" -FilterOperator Like
$users = Find-IshUser -IshSession $devsession  -RequestedMetadata $rmeta -MetadataFilter $filterf

#getting child folders from a given path
$fmetadata = Set-IshRequestedMetadataField -IshSession $devsession -Name "FNAME" |
Set-IshRequestedMetadataField -IshSession $devsession -Name "FISHFOLDERPATH" |
Set-IshRequestedMetadataField -IshSession $devsession -Name "FDOCUMENTTYPE" |
Set-IshRequestedMetadataField -IshSession $devsession -Name "NAME"

Get-IshFolder -IshSession $devsession -FolderPath "General\@dev" -RequestedMetadata $fmetadata -Recurse -Depth 1 | ForEach-Object
Get-IshMetadataField -IshSession $devsession -Name FISHFOLDERPATH

Get-IshFolder -IshSession $devsession -FolderPath "General\@dev" -RequestedMetadata $fmetadata -Recurse |
Get-IshFolderContent -IshSession $devsession

$folders = Get-IshFolder -IshSession $devsession -FolderPath "General\@dev" -RequestedMetadata $fmetadata -Recurse 

ForEach-Object -InputObject $topics {Get-IshDocumentObj -IshSession $devsession -LogicalId $_.ishref}

$topics = Get-IshFolder -IshSession $devsession -FolderPath "General\@dev" -RequestedMetadata $fmetadata -Recurse |
Where-Object -Property "IshFolderType" -EQ -Value "ISHModule" |
ForEach-Object {Get-IshFolderContent -IshSession $devsession -FolderId $_.IshFolderRef | Get-Member}

$tmetadata = Set-IshRequestedMetadataField -IshSession $devsession -Name "FISHLASTMODIFIEDBY" -Level Lng

ForEach-Object -InputObject $topics {
Get-IshDocumentObj -IshSession $devsession -LogicalId $_.IshRef -RequestedMetadata $tmetadata
} 

