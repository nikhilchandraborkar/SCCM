$sn = '00ba23e0e32c9dbe02'
$storeName = "TrustedPublisher"
 
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store Root, LocalMachine
$store1 = New-Object System.Security.Cryptography.X509Certificates.X509Store Root, CurrentUser
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
$store1.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly) 
$localmachine = (@( ($store.Certificates | where {$_.SerialNumber -eq $sn}) ).count)
$currentuser = (@( ($store1.Certificates | where {$_.SerialNumber -eq $sn}) ).count)
$localmachine
$currentuser
if(($localmachine -lt "1") -or ($currentuser -ge "1")){
write-host "complaint"}
else
{
write-host "Non-complaint"
}

$store.Close()
$store1.close()