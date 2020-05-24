Adobe Acrobat DC installer

$InstDir = Split-Path -parent $MyInvocation.MyCommand.Definition 
#Getting Current directory for the script


$logFile = "C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_17.009.20044_Wrapper.log"
$Component = "Installation"

Function LogWrite {
	[CmdletBinding()]
	Param(
	  [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
	  $sLogMsg
	)
PROCESS {
	# Populate the variables to log

	$sTime = (Get-Date -Format HH:mm:ss) + ".000+000"
	$sDate = Get-Date -Format MM-dd-yyyy
	$sTempMsg = "<![LOG[$sLogMsg]LOG]!><time=""$sTime"" date=""$sDate"" component=""$Component"" context="""" type="""" thread="""" file=""$Component"">"


	# Create the component log entry

	Write-Output $sTempMsg | Out-File -FilePath $logFile -Encoding "Default" -Append

}
} # End of Create-LogEntry function

#Stop further install if Adobe Acrobat DC is on the machine

if (${env:programfiles(x86)})
  { $AdobeAcrobatReaderDC_path = join-path "${env:programfiles(x86)}" "Adobe\Acrobat Reader DC" }
else
  { $AdobeAcrobatReaderDC_path = join-path "${env:programfiles}" "Adobe\Acrobat Reader DC" }

if (test-path $AdobeAcrobatReaderDC_path)
{
  #MSP Configuration
$Parameters = ' /P "AcroRdrDCUpd1700920044.msp" /qn /L*V C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_17.009.20044_Install.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $InstDir
$ExtVal = $process.ExitCode
LogWrite "Adobe Acrobat Reader DC Patch Install Complete"
 

}

else

{

#Uninstall Adobe Acrobat Reader DC MUI 15.007.20033
$WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Parameters = ' /X {A8413EE9-6B0C-4863-B2A1-7480BBFD8DD4} /qn /L*V C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_15.007.20033_Uninstall.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $WorkingDirectory

#Uninstall Adobe Acrobat Reader DC MUI 15.007.20033 from TS
$WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Parameters = ' /X {AC76BA86-7AD7-FFFF-7B44-AC0F074E4100} /qn /L*V C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_15.007.20033_TS_Uninstall.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $WorkingDirectory

#Uninstall Adobe Acrobat Reader DC MUI
$WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Parameters = ' /X {DDD4E3BB-D1E9-4F7C-877E-7DB9B7F868FC} /qn /L*V C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_15.007.20033_TS1_Uninstall.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $WorkingDirectory

#Uninstall Adobe Reader XI (11.0.06)
$WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Parameters = ' /X {AC76BA86-7AD7-1033-7B44-AB0000000001} /qn /L*V C:\Windows\FNMA\Logs\AdobeReaderXI_11.0.06_Uninstall.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $WorkingDirectory

#Uninstall Adobe Reader XI (11.0.19)  MUI
$WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Parameters = ' /X {AC76BA86-7AD7-FFFF-7B44-AB0000000001} /qn /L*V C:\Windows\FNMA\Logs\AdobeReaderXI_11.0.06_Uninstall.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $WorkingDirectory

#MSI Configuration
$Parameters = ' /I "AcroRead.msi" TRANSFORMS="AcroRead.mst" /qn /L*V C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_15.016.20039_Install.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $InstDir
$ExtVal = $process.ExitCode
LogWrite "Adobe Acrobat Reader DC Base Install Complete"

#MSP Configuration
$Parameters = ' /P "AcroRdrDCUpd1700920044.msp" /qn /L*V C:\Windows\FNMA\Logs\AdobeAcrobatReaderDC_17.009.20044_Install.log'
$Commandtorun = "MSIEXEC.EXE"
$process= Start-Process $CommandToRun $Parameters -PassThru -wait -workingdirectory $InstDir
$ExtVal = $process.ExitCode
LogWrite "Adobe Acrobat Reader DC Patch Install Complete"

}

#Delete Task Scheduler 

LogWrite "Deleting Task Scheduler"

function Search-And-Delete-Scheduled-Task($TaskName){
  $objSchTaskService = New-Object -ComObject Schedule.Service
  $objSchTaskService.connect('localhost')
 
  $RootFolder = $objSchTaskService.getfolder("\")
  $ScheduledTasks = $RootFolder.GetTasks(0)
  $Task = $ScheduledTasks | Where-Object{$_.Name -eq "$TaskName"}
 
  If ($Task -ne $Null){
    Try {
      $RootFolder.DeleteTask($Task.Name,0)
      return 'Success'
    }
    Catch [System.Exception]{
      return 'Exception Returned'
    }
  }
  else{
    return "Task Not Found"
  }
  }

  Clear-Host
$TaskName = 'Adobe Acrobat Update Task'
$Result = Search-And-Delete-Scheduled-Task($TaskName)
$TaskDescription = [char]34 + $TaskName + [char]34
 
if ($Result -eq 'Success'){
  Write-Host "$TaskDescription was deleted successfully!" -ForegroundColor Green
}
elseif ($Result -eq 'Exception Returned'){
  Write-Host "Attempting to delete task $TaskDescription caused an exception to occur." -ForegroundColor Red
}
elseif ($Result -eq 'Task Not Found'){
  Write-Host "Unable to locate a task with the name of $TaskDescription" -ForegroundColor Yellow
}
else{
  Write-Host "An unexpected result was returned while attempting to delete task $TaskDescription." -ForegroundColor Yellow
  Write-Host "The unexpected return was: " -ForegroundColor Yellow
  Write-Host "                - $Result" -ForegroundColor Yellow
}
