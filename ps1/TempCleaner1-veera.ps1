
$username=$($env:USERNAME)
if((Test-path  "d:\TempClear.log") -eq $false)
{
 New-item -path "d:\TempClear.log" -itemtype file
}
else
{
 clear-content d:\TempClear.log
}
function log 
{
 param($write)
  Add-Content d:\TempClear.log $write

}
$tempFilepaths = @("C:\Users\$username\AppData\Local\Temp",
"C:\Users\$username\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Outlook",
"C:\Users\$username\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.word",
"C:\Users\$username\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.mso",
"C:\Users\$username\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.ie5",
"C:\Users\$username\AppData\Local\Microsoft\Windows\Temporary Internet Files")

for($i = 0; $i -lt $tempfilepaths.length; $i++)
{  
    if(test-path $tempfilepaths[$i])
    {
    write-host "Path--->"$tempfilepaths[$i]
    log ("Path--->"+$tempfilepaths[$i])
    $fileSizeAndCount=get-childitem $tempfilepaths[$i] -recurse  |measure-object length -sum
    write-host "No.of.Files--->"($fileSizeAndCount.count-as [int])
    log ("No.of.Files--->"+($fileSizeAndCount.count-as [int]))
    $calc=[double]$fileSizeAndCount.sum
    $size=@("Bytes","KB","MB","GB")
    $j=0
    $totalsize=""+$calc + " " + $size[$j]
    while($calc -ge 1024 -and $j -lt 4)
    {
     $calc=[double]$calc/1024
     $j++   
     $totalsize=""+$calc + " " + $size[$j]
        
    }
    write-host "Total Size--->" $totalsize
    log ("Total Size--->"+$totalsize)
    remove-item $tempfilepaths[$i] -Recurse -erroraction silentlycontinue | out-null
    write-host  "Completed successfully"
    log ("Completed successfully")
    log ("`n")
    }
}
write-host "Disk Cleanup-----> Started"
log ("Disk Cleanup-----> Started")

cleanmgr /lowdisk 

sleep 1
$wshell = New-Object -ComObject wscript.shell;
$wshell.AppActivate("Disk Cleanup : Drive Selection")
sleep 2
$wshell.SendKeys('~')
$z=0
do
{
sleep 5

    if($wshell.AppActivate("Disk Cleanup for Windows (C:)"))
    {
       
        sleep 2
        $wshell.SendKeys('~')
        sleep 1
        if($wshell.AppActivate("Disk Cleanup"))
         {
             sleep 1
             $wshell.SendKeys('~')
          }   
        $z=1
    }
}
While($z -eq 0)

do
{
sleep 10

    if($wshell.AppActivate("Disk Space Notification"))
    {
    sleep 1
             $wshell.SendKeys('~')
             write-host "Disk Clean up Completed successfully"
             log ("Disk Clean up Completed successfully")
             $z=2
    }
}
While($z -eq 1)


