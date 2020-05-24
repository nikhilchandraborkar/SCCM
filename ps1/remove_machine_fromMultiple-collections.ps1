#This will remove mutliple machines from multiple collections 
#to get the package ids for collections use SQL report
#an example is shown below for the same
#Populate the below Variables with dyamic data from your orchestrator workflow or set it statically in the code.
 
$SCCMServer = "vwdcpv-msapp110.emea.vorwerk.org"
$SmsSiteCode = "PRI"
$CollectionIDs = @("PRI000A0"
"PRI0008A"
"PRI000A7"
"PRI00264"
"PRI000A4"
"PRI000A2"
"PRI00279"
"PRI004EF"
"PRI00235"
"PRI00092"
"PRI000C7"
"PRI00233"
"PRI00435"
"PRI00241"
"PRI0050A"
"PRI0031B"
"PRI00099"
"PRI00272"
"PRI0022E"
"PRI000A6"
"PRI00397"
"PRI00542"
"PRI00242"
"PRI00086"
"PRI003BE"
"PRI0023B"
"PRI00098"
"PRI000A9"
"PRI000A3"
"PRI0008E"
"PRI001AF"
"PRI00091"
"PRI0009A"
"PRI0009F"
"PRI000A1"
"PRI0009B"
"PRI000A8"
"PRI00087"
"PRI0024F"
"PRI00415"
"PRI00096"
"PRI002F6"
"PRI00549"
"PRI005BF"
"PRI00093"
"PRI0009C"
"PRI0009E"
"PRI0008F"
)
$ComputerNames = @("w5dectsdc0005")

foreach($computerName in $ComputerNames){
foreach($collectionID in $CollectionIDs){ 
$Collection = Get-WmiObject -Namespace "root\SMS\Site_$SmsSiteCode" -Query "select * from SMS_Collection Where SMS_Collection.CollectionID='$CollectionID'" -computername $SCCMServer
 
$Collection.Get()
 
ForEach ($Rule in $($Collection.CollectionRules | Where {$_.RuleName -eq "$ComputerName"}))
 
 
{
 
 
 # Get the SMS_R_System object for the rule
 
 $ComputerObject = Get-WmiObject -Namespace "root\SMS\Site_$SmsSiteCode" -Query "select * from SMS_R_System where Name='$ComputerName'" -computername $SCCMServer
 $ResourceID = $ComputerObject.ResourceID
 
 $smsObject = Get-WmiObject -Namespace "root\SMS\Site_$SmsSiteCode" -Query "Select * From SMS_R_System Where ResourceID='$ResourceID'" -computername $SCCMServer
 
 
 # If the resource is a agent
 
 if($smsObject.Name -eq "$ComputerName")
 
 {
 
 
 #Delete the membership rule
 $Collection.DeleteMemberShipRule($Rule) | out-null
 
 }
 
 
}
}
}