[string]$SiteCode = "PRI" #Site Code.
#[Parameter(Mandatory=$true)]
[string]$SiteServer = "vwdcpv-msapp110.emea.vorwerk.org" #FQDN of Primary Site server. REQUIRED

$collectionQuery = Get-WmiObject -Namespace "root\sms\Site_$SiteCode" -Query "
select * from SMS_Collection where collectionid like '$SiteCode%'

" -ComputerName "$SiteServer"

$date =Get-date -Format M-d-yyyy
$collections= "Collections_"+ $date
$collectionQuery | Select-Object -Property Name, CollectionID, Objectpath, MemberCount, LimitTOCollectionName, IsReferenceCollection, LastChangeTime, Comment | Sort-Object Name |Export-Csv -Path "\\10.192.10.46\Applications\Reports\Collections\$collections.csv" -Force -NoTypeInformation

