################################################################################################################################################
# Name: ConfigMgr Import Tool
# File Name: ConfigMgr-Import-Tool-v1.0.ps1
#Orginal Author:http://www.danielclasson.com/configmgr-import-tool-v1-0/
#Modified: Nikhil
# Date: 2018-10-10
# syntax: Powershell.exe -ExecutionPolicy ByPass .\ConfigMgr-Import-Tool-v1.0.ps1 -SiteServer <SiteServer> -SiteCode <SiteCode> -LogPath <Path to write log files to> -CSVPath <Initial directory used when browsing for CSV files> -Container <Collection Folder>
# Usage:.\ConfigMgr-Import-Tool-v1.0.ps1 -SiteServer vwdcpv-msapp110.emea.vorwerk.org -SiteCode PRI -LogPath c:\Logs\test.log 
################################################################################################################################################


[CmdletBinding()]
param(
[Parameter(Mandatory=$false)]
[string]$CSVPath = "", #UNC path to CSV initial directory. OPTIONAL.
[string]$LogPath = "" #UNC path to write logs to. REQUIRED if log files are to be created.
)

#[Parameter(Mandatory=$true)]
[string]$Container = '$operating system deployment' #Folder containing OSD collections.
#[Parameter(Mandatory=$true)]
[string]$SiteCode = "PRI" #Site Code.
#[Parameter(Mandatory=$true)]
[string]$SiteServer = "vwdcpv-msapp110.emea.vorwerk.org" #FQDN of Primary Site server. REQUIRED


#region Tool functions

Function Disable-Controls {
        $ImportButton.Enabled = $False
        $AddToSelectionButton.Enabled = $False
        $BrowseButton.Enabled = $False
        $RemoveFromSelectionButton.Enabled = $False
        $CollectionComboBox.Enabled = $False
        $MACAddressTextBox.Enabled = $False
        $DeviceNameTextBox.Enabled = $False
}

Function Invoke-CollectionList {
        Try {
            $ContainerNodeId = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -ErrorAction SilentlyContinue -Filter "Name='$($Container)'").ContainerNodeId
            $IDs = Get-WmiObject -Class SMS_ObjectContainerItem -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ContainerNodeID='$ContainerNodeID'" -ErrorAction SilentlyContinue
            ForEach ($Id in $IDs) {
                $CollectionId = $Id.InstanceKey
                $CollectionName = (Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -ErrorAction SilentlyContinue -Filter "CollectionID='$CollectionId'").Name
                $CollectionComboBox.Items.Add($CollectionName)
            }
        }
        Catch [System.Management.Automation.ActionPreferenceStopException] {
               Disable-Controls
               Write-StatusBox -Type ERROR "Unable to connect to $SiteServer. Verify network connectivity."
        }
        Catch [System.UnauthorizedAccessException] {
            Write-StatusBox -Type ERROR "Access denied when retrieving Collections from $SiteServer using $($Script:Crendtials.Username) .Try using alternate credentials"
        }
}

Function Set-Default {
        If ($LogPath.Length -gt 1) {
            $Script:LogPathExists = Test-Path $LogPath
        }
        Else {
            Write-StatusBox -Type WARNING -StatusBoxMessage "Log path has not been specified. No log files will be created."
        }
        If ($CSVPath.Length -gt 1) {
            $Script:CSVPathExists = Test-Path $CSVPath
        }
        If ($Script:LogPathExists -eq $False) {
            Write-StatusBox -Type ERROR -StatusBoxMessage "Log path: $LogPath can not be found. No log files will be created."
        }
        If ($Script:CSVPathExists -eq $False) {
            Write-StatusBox -Type ERROR -StatusBoxMessage "CSV path: $CSVPath can not be found. There may be issues when retrieving CSV files."
        }
        Try {
        Invoke-CollectionList
        Write-StatusBox -Type INFO -StatusBoxMessage "Connected to $SiteServer with account: '$env:userdomain\$env:username'"
        }
        Catch [System.Management.Automation.ActionPreferenceStopException] {
               Disable-Controls
               Write-StatusBox -Type ERROR "Unable to connect to $SiteServer. Verify network connectivity."
        }
        $ImportButton.Text = "Import Devices"
        $BrowseButton.Visible = $False
        $CSVFileLabel.Visible = $False
}

Function Set-RadioButton {
    Param(
    [Parameter(Mandatory=$True)]
    [ValidateSet("RadioButton1", "RadioButton2", "RadioButton3")]
    [string]$RadioButton,
    [Parameter(Mandatory=$True)]
    [ValidateSet("Enabled", "Disabled")]
    [string]$State
    )

    If ($RadioButton1.Checked -eq $True) {
        $ImportButton.Text = "Import Devices"
        $AddToSelectionButton.Enabled = $False
        $AddToSelectionButton.Visible = $True
        $BrowseButton.Visible = $False
        $RemoveFromSelectionButton.Enabled = $True
        $RemoveFromSelectionButton.Visible = $True
        $ValidateButton.Enabled = $True
        $ValidateButton.Visible = $True
        $DeviceNameLabel.Visible = $True
        $MACAddressLabel.Visible = $True 
        $CSVFileLabel.Visible = $False
        $BulkImportLabel.Visible = $True
        $MACAddressTextBox.Visible = $True 
        $DeviceNameTextBox.Visible = $True
        $MACAddressTextBox.Clear()
        $DeviceNameTextBox.Clear()
        $ErrorProvider.Clear()
        $StatusBox.Clear()
        $DGV.Rows.Clear()
    }
    
    ElseIf ($RadioButton2.Checked -eq $True) {
        $ImportButton.Text = "Import Devices"
        $AddToSelectionButton.Visible = $False
        $BrowseButton.Enabled = $True
        $BrowseButton.Visible = $True
        $RemoveFromSelectionButton.Enabled = $False
        $RemoveFromSelectionButton.Visible = $False
        $ValidateButton.Enabled = $False
        $ValidateButton.Visible = $False
        $DeviceNameLabel.Visible = $False
        $MACAddressLabel.Visible = $False
        $CSVFileLabel.Enabled = $True
        $CSVFileLabel.Visible = $True
        $BulkImportLabel.Enabled = $True
        $MACAddressTextBox.Visible = $False
        $DeviceNameTextBox.Visible = $False
        $MACAddressTextBox.Clear()
        $DeviceNameTextBox.Clear()
        $ErrorProvider.Clear()
        $StatusBox.Clear()
        $DGV.Rows.Clear()
    } 
}

Function Write-Log
{
 
    PARAM(
        [String]$Message,
        [int]$Severity,
        [string]$Component
        )

            $TimeZoneBias = Get-WMIObject -Query "Select Bias from Win32_TimeZone"
            $Date= Get-Date -Format "HH:mm:ss.fff"
            $Date2= Get-Date -Format "MM-dd-yyyy"
            $Type=1
         
            "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $LogPath\Add-WorkstationTool.log -Append -NoClobber -Encoding default
}

Function Write-StatusBox {
    Param(
    [Parameter(Mandatory=$True)]
    [string]$StatusBoxMessage,
    [ValidateSet("WARNING","ERROR","INFO")]
    [string]$Type
     )
    Begin {
    }
    Process {
        If ($StatusBox.Text.Length -eq 0) {
            $StatusBox.Text = "$($Type): $($StatusBoxMessage)"
            [System.Windows.Forms.Application]::DoEvents()
            $StatusBox.SelectionStart = $StatusBox.Text.Length
            $StatusBox.ScrollToCaret()
     }
        Else {
            $StatusBox.AppendText("`n$($Type): $($StatusBoxMessage)")
            [System.Windows.Forms.Application]::DoEvents()
            $StatusBox.SelectionStart = $StatusBox.Text.Length
            $StatusBox.ScrollToCaret()
        }  
    }
}

#endregion

#region Bulk stage Devices

Function Get-CSVFile {
    If ($CollectionComboBox.SelectedItem -eq $Null) {
        $ErrorProvider.SetError($CollectionComboBox, "Please select a valid collection before selecting a CSV")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please select a valid collection before selecting a CSV"
    }
    Else {
        $ErrorProvider.Clear()
        $StatusBox.Clear()
        $BrowseFile = New-Object System.Windows.Forms.OpenFileDialog
        $BrowseFile.InitialDirectory = $CSVPath
        $BrowseFile.Filter = "CSV (*.CSV)| *.CSV"
        $BrowseFile.ShowDialog() | Out-Null
        $BrowseFile.FileName
        If ($BrowseFile.Filename.Length -ge "1") {
            $DGV.ReadOnly = $False
            $AddToSelectionButton.Enabled = $True
            $RemoveFromSelectionButton.Enabled = $True
            $Script:CSV = Import-CSV -Path $BrowseFile.Filename
            Foreach ($Device in $Script:CSV) {
                $DGV.Rows.Add($Device.ComputerName, $Device.MAC, $CollectionComboBox.SelectedItem)
            }
            Write-StatusBox -Type INFO -StatusBoxMessage "Successfully added workstations from $($BrowseFile.FileName) to the gridview for prestaging"
        }
    }
}

#endregion

#region Prestage functions

Function Add-DirectMembership {
     Param (
    [string]$DeviceName,
    [string]$CollectionName
    )
    Try {
        $DirectWMI = (Get-WMIObject -Namespace root\SMS\site_$($SiteCode) -Class SMS_CollectionRuleDirect -ComputerName $SiteServer -List).CreateInstance()
        $DirectWMI.ResourceClassName = "SMS_R_SYSTEM"
        $DirectWMI.ResourceID = (Get-WmiObject -Class SMS_R_System -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$($DeviceName)'").ResourceId
        $DirectWMI.Rulename = $DeviceName
 
        $OSDCollection = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/Site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$($CollectionName)'"
        $OSDCollection.AddMemberShipRule($DirectWMI)
    }
    Catch {
        Write-Error "There was an error adding $($DeviceName) to $($CollectionName)"
    }
}


Function Add-ToSelection {

    $Devices = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "Name like '$($DeviceNameTextBox.Text)'"
    $MACAddresses = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "MACAddresses like '$($MACAddressTextBox.Text)'"

    If($DeviceNameTextBox.Text.Length -eq 0) {
        $ErrorProvider.SetError($DeviceNameTextBox, "Please enter a valid Device name")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please enter a valid Device name"         
    }
    ElseIf ($MACAddressTextBox.Text.Length -lt 17) {
        $ErrorProvider.SetError($MACAddressTextBox, "Please enter a valid MAC address")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please enter a valid MAC address"
    }
    ElseIf ($CollectionComboBox.SelectedItem -eq $Null) {
        $ErrorProvider.SetError($CollectionComboBox, "Please select a valid collection")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please select a valid collection" 
    }
    Else {
        $ErrorProvider.Clear()
        $DeviceNameTextBox.text.toupper()
        $DGV.Rows.Add($DeviceNameTextBox.Text.toupper(), $MACAddressTextBox.Text, $CollectionComboBox.SelectedItem)
        Write-StatusBox -Type INFO -StatusBoxMessage "Adding $($DeviceNameTextBox.Text) to the gridview for installation"
        $AddToSelectionButton.Enabled = $False
        $MACAddressTextBox.Clear()
    }
}


Function Remove-FromSelection {

    $SelectedRow = $DGV.CurrentRow
    If ($SelectedRow -ne $Null) {
        $DGV.Rows.Remove($SelectedRow)
        Write-StatusBox -Type INFO -StatusBoxMessage "Removed Device from the grid view"
    }   
}


#Function to import the new Device
Function Import-NewDevice {
    Param (
    [string]$DeviceName,
    [string]$MACAddress
    )
    $ImportWMI = Get-WMIObject -Namespace root\SMS\site_$($SiteCode) -Class SMS_Site -ComputerName $SiteServer -List
    $NewEntry = $ImportWMI.psbase.GetMethodParameters("ImportMachineEntry")
    $NewEntry.MACAddress = $MACAddress
    $NewEntry.NetbiosName = $DeviceName.ToUpper()
    $NewEntry.OverwriteExistingRecord = $True
    Try {
        $ImportWMI.psbase.InvokeMethod("ImportMachineEntry",$NewEntry,$Null)
    }
    Catch {
        Write-Log -Severity 3 -Message "There was an error importing Device: $($DeviceName) with MAC Address: $($MACAddress). Verify import information"
        Write-StatusBox -Type ERROR -StatusBoxMessage "There was an error importing Device: $($DeviceName) with MAC Address: $($MACAddress). Verify import information"
       
    }
    Invoke-WmiMethod -Path "ROOT\SMS\Site_$($SiteCode):SMS_Collection.CollectionId='SMS00001'" -Name RequestRefresh -ComputerName $SiteServer
}

Function Import-Device {
  
        $ErrorProvider.Clear()    


        If ($RadioButton2.Checked -eq $True) {
            If ($Script:CSV.length -le 0) {
                $ErrorProvider.SetError($BrowseButton, "Please retrieve a CSV file to import")
                Write-StatusBox -Type ERROR "Please retrieve a CSV file to import" 
            }
            If ($CollectionComboBox.SelectedItem -eq $Null) {
                $ErrorProvider.SetError($CollectionComboBox, "Please provide an OSD collection")
                Write-StatusBox -Type ERROR "Please provide an OSD collection" 
            }
            Else {
                $CollectionName = $CollectionComboBox.SelectedItem
                Foreach ($DeviceRow in $Script:CSV) {
                    $DeviceName = $($DeviceRow.ComputerName)
                    $MACAddress = $($DeviceRow.MAC)
                    $Devices = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "Name like '$($DeviceName)'" 
                    If ($Devices -eq $Null) {
                        Import-NewDevice -DeviceName $($DeviceName) -MACAddress $($MACAddress)
                        Add-DirectMembership -DeviceName $($DeviceName) -CollectionName $($CollectionName)
                        Write-StatusBox -Type INFO -StatusBoxMessage "Adding new device $($DeviceName) with MAC Address $($MACAddress) to $($CollectionName)"
                        If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                            Write-Log -Severity 1 -Component "New Workstation" -Message "Adding new device $($DeviceName) with MAC Address $($MACAddress) to $($CollectionName) using account: $($Env:Username)."
                        }
                    }
                    Else {
                        Foreach ($Device in $Devices) {

                            If ($($Device.ResourceID) -like "20*") {
                                $($Device).Psbase.Delete()
                                Import-NewDevice -DeviceName $($DeviceName) -MACAddress $($MACAddress)
                                Add-DirectMembership -DeviceName $($DeviceName) -CollectionName $($CollectionName)
                                Write-StatusBox -Type INFO -StatusBoxMessage "$($DeviceName) was found as a discovered object in ConfigMgr. Removing it and adding a new object in the database."
                                If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                    Write-Log -Severity 1 -Component "Discovered Workstation" -Message "$($DeviceName) was found as a discovered object in ConfigMgr. Removing it and adding a new object in the database using account: $($Env:Username)."
                                }
                            }
                            ElseIf (($Device -ne $Null) -and ($MACAddress -ne $MACAddress)) {
                                Import-NewDevice -DeviceName $($DeviceName) -MACAddress $($MACAddress)
                                Add-DirectMembership -DeviceName $($DeviceName) -CollectionName $($CollectionName)
                                Write-StatusBox -Type INFO -StatusBoxMessage "Changing MAC of $($DeviceName) to $($MACAddress) and adding to $($CollectionName)"
                                If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                    Write-Log -Severity 1 -Component "MAC Address Change" -Message "Changing MAC of $($DeviceName) to $($MACAddress) and adding to $($CollectionName) using account: $($Env:Username)."
                                }
                            }
                            ElseIf (($Device -ne $Null) -and ($MACAddress -eq $MACAddress)) {
                                Add-DirectMembership -DeviceName $($DeviceName) -CollectionName $($CollectionName)
                                Write-StatusBox -Type INFO -StatusBoxMessage "Adding $($DeviceName) to $($CollectionName) for reinstallation"
                                If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                    Write-Log -Severity 1 -Component "Reinstall Workstation" -Message "Adding $($DeviceName) to $($CollectionName) for reinstallation using account: $($Env:Username)."
                                }    
                            }
                        }  
                    }              
               }
               Write-StatusBox -Type INFO -StatusBoxMessage "Completed prestaging of workstations from CSV"
            }
        }

        ElseIf ($RadioButton1.Checked -eq $True) {
            For ($Row = 0; $Row -lt $DGV.RowCount; $Row++) {
                $DeviceName = $DGV.Rows[$Row].Cells["Device Name"].Value 
                $MACAddress = $DGV.Rows[$Row].Cells["MAC Address"].Value 
                $CollectionName = $DGV.Rows[$Row].Cells["Collection"].Value
                $Devices = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "Name like '$($DeviceName)'"
                $MACAddresses = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "MACAddresses like '$($MACAddressTextBox.Text)'"
                If ($Devices -eq $Null) {
                    Import-NewDevice -DeviceName $($DeviceName) -MACAddress $($MACAddress)
                    Add-DirectMembership -DeviceName $($DeviceName) -CollectionName $($CollectionName)
                    Write-StatusBox -Type INFO -StatusBoxMessage "Adding new device $($DeviceName) with MAC Address $($MACAddress) to $($CollectionName)"
                    If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                        Write-Log -Severity 1 -Component "New Workstation" -Message "Adding new device $($DeviceName) with MAC Address $($MACAddress) to $($CollectionName) using account: $($Env:Username)."
                    }
                }
                    Else { 
                    Foreach ($Device in $Devices) {
                        If ($($Device.ResourceID) -like "20*") {
                            $($Device).Psbase.Delete()
                            $Device = $($Device.Netbiosname)    
                            Import-NewDevice -DeviceName $($Device) -MACAddress $($MACAddress)
                            Add-DirectMembership -DeviceName $($Device) -CollectionName $($CollectionName)
                            Write-StatusBox -Type INFO -StatusBoxMessage "$($Device) was found as a discovered object in ConfigMgr. Removing it and adding a new object in the database."
                            If (($LogPath -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                Write-Log -Severity 1 -Component "Discovered Workstation" -Message "$($Device) was found as a discovered object in ConfigMgr. Removing it and adding a new object in the database using account: $($Env:Username)."
                            }
                        }
                        ElseIf (($MACAddresses -ne $Null) -and ($($MACAddresses.netbiosname) -ne $Device)) {
                            $Device = $($Device.Netbiosname)
                            Write-StatusBox -Type ERROR -StatusBoxMessage "MAC address already belongs to $($MACAddresses.netbiosname). Please remove it before proceeding."
                            If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                Write-Log -Severity 1 -Component "MAC Address Change" -Message "MAC address already belongs to $($MACAddresses.netbiosname). Please remove it before proceeding."
                            }
                        }
                        ElseIf (($Devices -ne $Null) -and ($MACAddress -ne $Devices.MACAddresses)) {
                            $Device = $($Device.Netbiosname)
                            Import-NewDevice -DeviceName $($Device) -MACAddress $($MACAddress)
                            Add-DirectMembership -DeviceName $($Device) -CollectionName $($CollectionName)
                            Write-StatusBox -Type INFO -StatusBoxMessage "Changing MAC address of $($Device) to $($MACAddress) and adding to $($CollectionName)"
                            If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                Write-Log -Severity 1 -Component "MAC Address Change" -Message "Changing MAC address of $($Device) to $($MACAddress) and adding to $($CollectionName) using account: $($Env:Username)."
                            }
                        }
                        ElseIf (($Devices -ne $Null) -and ($MACAddress -eq $Devices.MACAddresses)) {
                            $Device = $($Device.Netbiosname)
                            Add-DirectMembership -DeviceName $Device -CollectionName $($CollectionName)
                            Write-StatusBox -Type INFO -StatusBoxMessage "Adding $($Device) to $($CollectionName) for reinstallation"
                            If (($LogPath.Length -gt 1) -or ($Script:LogPathExists -eq $True)) {
                                Write-Log -Severity 1 -Component "Reinstall Workstation" -Message "Adding $($Device) to $($CollectionName) for reinstallation using account: $($Env:Username)."  
                            } 
                        }
                    }  
                }  
            }
        }
    }


Function Validate-Device {
    Param (
    [string]$DeviceName,
    [string]$MACAddress
    )

    $Device = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "Name like '$($DeviceNameTextBox.Text)'"
    $DeviceMAC = $($Device.MACAddresses)
    $MACAddresses = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "MACAddresses like '$($MACAddressTextBox.Text)'"

    If ($DeviceNameTextBox.Text.Length -lt 1) {
        $ErrorProvider.Clear()
        $ErrorProvider.SetError($DeviceNameTextBox, "Please enter a valid device name")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please enter a valid device name"
    }
        ElseIf (($Device -ne $Null) -and ($DeviceMAC -ne $Null)) {        $MACAddressTextBox.Text = $DeviceMAC        $AddToSelectionButton.Enabled = $True        Write-StatusBox -Type INFO -StatusBoxMessage "Retrieved $($DeviceMAC) from $($DeviceNameTextBox.Text)"    }
    ElseIf (($Device -ne $Null) -and ($DeviceMAC -eq $Null) -and ($MACAddressTextBox.Text.Length -lt 17)) {
        $ErrorProvider.Clear()
        $MACAddressTextBox.Clear()
        $ErrorProvider.SetError($MACAddressTextBox, "Please enter a valid MAC address")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please enter a valid MAC address"
    }
    ElseIf (($Device -eq $Null) -and ($MACAddressTextBox.Text.Length -lt 17)) {
        $ErrorProvider.SetError($MACAddressTextBox, "$($DeviceNameTextBox.Text) does not exist. Please enter the MAC adress of the device.")
        Write-StatusBox -Type ERROR -StatusBoxMessage "$($DeviceNameTextBox.Text) does not exist. Please enter the MAC adress of the device."
    }
    ElseIf (($Device -eq $Null) -and ($MACAddresses -ne $Null)) {
        $ErrorProvider.SetError($MACAddressTextBox, "Device with MAC $($MACAddressTextBox.Text) already exists and belongs to $($MACAddresses.Name)")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Device with MAC $($MACAddressTextBox.Text) already exists and belongs to $($MACAddresses.Name)"
    }

    ElseIf (($MACAddressTextBox.Text.Length -lt 17) -and ($Device -eq $Null)) {
        $ErrorProvider.Clear()
        $ErrorProvider.SetError($MACAddressTextBox, "Please enter a valid MAC address")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please enter a valid MAC address"
    }

    ElseIf (($MACAddressTextBox.Text.Length -eq 17) -and ($DeviceNameTextBox.Text.Length -gt 1)) {
        $ErrorProvider.Clear()
        $AddToSelectionButton.Enabled = $True
        Write-StatusBox -Type INFO -StatusBoxMessage "$($DeviceNameTextBox.Text) with MAC $($MACAddressTextBox.Text) passed validation"
    }
}   

Function ADValidation-Device{

Param (
    [string]$DeviceName,
    [string]$MACAddress
    )
    Import-Module Activedirectory -Global -Force -ErrorAction SilentlyContinue
    [string]$getmachine="$($ADDeviceNameTextBox.Text)"+"*"
    $ADDevice = Get-ADComputer -Filter 'Name -like $getmachine' -ErrorAction SilentlyContinue
    $device = $ADDevice.Name 
    $DeviceMAC = $($Device.MACAddresses)
    $MACAddresses = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -ComputerName $SiteServer -Class SMS_R_System -Filter "MACAddresses like '$($MACAddressTextBox.Text)'"

    If ($ADDeviceNameTextBox.Text.Length -lt 1) {
        $ErrorProvider.Clear()
        $ErrorProvider.SetError($ADDeviceNameTextBox, "Please enter a valid device name")
        Write-StatusBox -Type ERROR -StatusBoxMessage "Please enter a valid device name"
    }
    ElseIf ($Device -eq $Null)  {
        $ErrorProvider.SetError($DeviceNameTextBox, "$($ADDeviceNameTextBox.Text) does not exist in AD. Please enter the device name & MAC adress of the device to check in SCCM.")
        Write-StatusBox -Type ERROR -StatusBoxMessage "$($ADDeviceNameTextBox.Text) does not exist in AD. Please enter the device name & the MAC adress of the device."
    }
    ElseIf (($Device -ne $Null) -and ($ADDeviceNameTextBox.Text.Length -gt 1)) {
        $ErrorProvider.Clear()
        $AddToSelectionButton.Enabled = $True
        Write-StatusBox -Type INFO -StatusBoxMessage "$($ADDeviceNameTextBox.Text) exists in AD passed validation"
    }

}

#endregion

#region Define script variables

#Define script variables

$Script:CSV = ""
$Script:CSVPathExists = ""
$Script:LogPathExists = ""

#region Draw GUI

#Load assemblies

[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Data") | Out-Null

    
#GUI
$Form = New-Object System.Windows.Forms.Form
$Form.StartPosition = "CenterScreen"
$Form.AutoSize = $True
$Form.ClientSize = "550,570"
$Form.DataBindings.DefaultDataSourceUpdateMode = 0
$Form.Name = "Form1"
$Form.Text = "ConfigMgr Import Tool v1.0"
$Form.add_Load($handler_form1_Load)

#Import Button
$ImportButton = New-Object System.Windows.Forms.Button
$ImportButton.DataBindings.DefaultDataSourceUpdateMode = 0
$ImportButton.Location = "15,390"
$ImportButton.Name = "button1"
$ImportButton.Size = "250,23"
$ImportButton.TabIndex = 4
$ImportButton.Text = "Install New Devices"
$ImportButton.UseVisualStyleBackColor = $True
$ImportButton.add_Click({Import-Device})
$Form.Controls.Add($ImportButton)

#Add To Selection Button
$AddToSelectionButton = New-Object System.Windows.Forms.Button
$AddToSelectionButton.DataBindings.DefaultDataSourceUpdateMode = 0
$AddToSelectionButton.Enabled = $False
$AddToSelectionButton.Location = "15,200"
$AddToSelectionButton.Name = "button1"
$AddToSelectionButton.Size = "250,23"
$AddToSelectionButton.TabIndex = 4
$AddToSelectionButton.Text = "Add to selection"
$AddToSelectionButton.UseVisualStyleBackColor = $True
$AddToSelectionButton.add_Click({Add-ToSelection})
$Form.Controls.Add($AddToSelectionButton)

#Remove From Selection Button
$RemoveFromSelectionButton = New-Object System.Windows.Forms.Button
$RemoveFromSelectionButton.DataBindings.DefaultDataSourceUpdateMode = 0
$RemoveFromSelectionButton.Location = "285,200"
$RemoveFromSelectionButton.Name = "button5"
$RemoveFromSelectionButton.Size = "250,23"
$RemoveFromSelectionButton.Text = "Remove from selection"
$RemoveFromSelectionButton.UseVisualStyleBackColor = $True
$RemoveFromSelectionButton.Add_MouseClick({Remove-FromSelection})
$Form.Controls.Add($RemoveFromSelectionButton)
    
#Browse for CSV Button
$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.DataBindings.DefaultDataSourceUpdateMode = 0
$BrowseButton.Location = "285,157"
$BrowseButton.Name = "button3"
$BrowseButton.Size = "250,23"
$BrowseButton.Text = "Browse"
$BrowseButton.UseVisualStyleBackColor = $True
$BrowseButton.Add_MouseClick({Get-CSVFile})
$Form.Controls.Add($BrowseButton)


#Validate Button
$ValidateButton = New-Object System.Windows.Forms.Button
$ValidateButton.DataBindings.DefaultDataSourceUpdateMode = 0
$ValidateButton.Location = "220,75"
$ValidateButton.Name = "button6"
$ValidateButton.Size = "55,23"
$ValidateButton.Text = "Validate"
$ValidateButton.UseVisualStyleBackColor = $True
$ValidateButton.Add_MouseClick({Validate-Device})
$Form.Controls.Add($ValidateButton)

#AD Validate Button
$ADValidateButton = New-Object System.Windows.Forms.Button
$ADValidateButton.DataBindings.DefaultDataSourceUpdateMode = 0
$ADValidateButton.Location = "220,45"
$ADValidateButton.Name = "button6"
$ADValidateButton.Size = "55,23"
$ADValidateButton.Text = "Validate"
$ADValidateButton.UseVisualStyleBackColor = $True
$ADValidateButton.Add_MouseClick({ADValidation-Device})
$Form.Controls.Add($ADValidateButton)

#Collection Selection Box
$CollectionComboBox = New-Object System.Windows.Forms.ComboBox
$CollectionComboBox.DataBindings.DefaultDataSourceUpdateMode = 0
$CollectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$CollectionComboBox.FormattingEnabled = $False
$CollectionComboBox.Location = "285,130"
$CollectionComboBox.Name = "comboBox1"
$CollectionComboBox.SelectedItem = "0"
$CollectionComboBox.Size = "250,21"
$CollectionComboBox.TabIndex = "3"
$Form.Controls.Add($CollectionComboBox)

#DataGridView
$DGV = New-Object System.Windows.Forms.DataGridView
$DGV.AllowUserToAddRows = $False
$DGV.AllowUserToDeleteRows = $True
$DGV.AutoSizeColumnsMode = "Fill"
$DGV.BackGroundColor = "White"
$DGV.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGV.ColumnCount = 4
$DGV.ColumnHeadersVisible = $true
$DGV.Columns[0].Name = "Device Name"
$DGV.Columns[0].Width = 70
$DGV.Columns[1].Name = "MAC Address"
$DGV.Columns[1].Width = 70
$DGV.Columns[2].Name = "Collection"
$DGV.Columns[2].Width = 70
$DGV.columns[2].Visible = $True
$DGV.Columns[3].Name = "Username"
$DGV.Columns[3].Width = 0
$DGV.columns[3].Visible = $False
$DGV.Location = "15, 240"
$DGV.MultiSelect = $True
$DGV.Name = "DGV"
$DGV.ReadOnly = $True
$DGV.RowHeadersVisible = $False
$DGV.RowHeadersWidthSizeMode = "DisableResizing"
$DGV.Size = "520, 140"
$DGV.ScrollBars = "Vertical"
$Form.Controls.Add($DGV)

#ErrorProvider
$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider

#Manual Import Label
$ManualImportLabel = New-Object System.Windows.Forms.Label
$ManualImportLabel.AutoSize = $True
$ManualImportLabel.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$ManualImportLabel.Location = "40,15"
$ManualImportLabel.Name = "label2"
$ManualImportLabel.Size = "20, 100"
$ManualImportLabel.Text = "Manually Import Devices"
$Form.Controls.Add($ManualImportLabel)

#AD Device Name Label
$CheckinAD = New-Object System.Windows.Forms.Label
$CheckinAD.DataBindings.DefaultDataSourceUpdateMode = 0
$CheckinAD.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$CheckinAD.Location = "15,48"
$CheckinAD.Name = "CheckinAD"
$CheckinAD.AutoSize = $true
$CheckinAD.Size = "100,20"
$CheckinAD.Text = "CheckinAD if Machine Exists :"
$Form.Controls.Add($CheckinAD)
    
#Device Name Label
$DeviceNameLabel = New-Object System.Windows.Forms.Label
$DeviceNameLabel.DataBindings.DefaultDataSourceUpdateMode = 0
$DeviceNameLabel.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$DeviceNameLabel.Location = "15,78"
$DeviceNameLabel.Name = "DeviceNameLabel"
$DeviceNameLabel.AutoSize = $true
$DeviceNameLabel.Size = "100,20"
$DeviceNameLabel.Text = "Device name:"
$Form.Controls.Add($DeviceNameLabel)

#MAC Address Label
$MACAddressLabel = New-Object System.Windows.Forms.Label
$MACAddressLabel.AutoSize = $True
$MACAddressLabel.DataBindings.DefaultDataSourceUpdateMode = 0
$MACAddressLabel.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$MACAddressLabel.Location = "15,104"
$MACAddressLabel.Name = "label3"
$MACAddressLabel.Size = "100,20"
$MACAddressLabel.TabIndex = 7
$MACAddressLabel.Text = "MAC address:"
$Form.Controls.Add($MACAddressLabel)

#Collection Label

$CollectionLabel = New-Object System.Windows.Forms.Label
$CollectionLabel.DataBindings.DefaultDataSourceUpdateMode = 0
$CollectionLabel.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$CollectionLabel.Location = "15,130"
$CollectionLabel.Name = "CollectionLabel"
$CollectionLabel.AutoSize = $True
$CollectionLabel.Size = "150,21"
$CollectionLabel.TabIndex = 8
$CollectionLabel.Text = "OS Deployment Collection:"
$Form.Controls.Add($CollectionLabel)

#CSV File Label

$CSVFileLabel = New-Object System.Windows.Forms.Label
$CSVFileLabel.AutoSize = $true   
$CSVFileLabel.DataBindings.DefaultDataSourceUpdateMode = 0
$CSVFileLabel.Enabled = $False
$CSVFileLabel.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$CSVFileLabel.Location = "15,156"
$CSVFileLabel.Name = "CSVFileLabel"
$CSVFileLabel.Size = "150,21"
$CSVFileLabel.Text = "CSV File"
$Form.Controls.Add($CSVFileLabel)

#Bulk Import Label

$BulkImportLabel = New-Object System.Windows.Forms.Label
$BulkImportLabel.AutoSize = $True
$BulkImportLabel.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$BulkImportLabel.Location = "235,15"
$BulkImportLabel.Name = "BulkImportLabel"
$BulkImportLabel.Text = "Bulk Import Devices"
$Form.Controls.Add($BulkImportLabel)

#MAC Address TextBox
$MACAddressTextBox = New-Object System.Windows.Forms.MaskedTextBox
$MACAddressTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
$MACAddressTextBox.Location = "285,104"
$MACAddressTextBox.Name = "MAC Address Text Box"
$MACAddressTextBox.Size = "250,20"
$MACAddressTextBox.TabIndex = 2
$MACAddressTextBox.Mask = "CC:CC:CC:CC:CC:CC"
$Form.Controls.Add($MACAddressTextBox)

#StatusBox
$StatusBox = New-Object System.Windows.Forms.RichTextBox
$StatusBox.Location = New-Object System.Drawing.Point(15,425)
$StatusBox.Size = New-Object System.Drawing.Size(520,100)
$StatusBox.Font = "Tahoma"
$StatusBox.BackColor = "white"
$StatusBox.ReadOnly = $true
$StatusBox.MultiLine = $true
$StatusBox.ScrollBars = "Vertical"
$Form.Controls.Add($StatusBox)

#Manual Import Radio Button
$RadioButton1 = New-Object System.Windows.Forms.RadioButton
$RadioButton1.AutoCheck = $True
$RadioButton1.AutoSize = $True
$RadioButton1.Checked = $True
$RadioButton1.Location = "15, 15"
$RadioButton1.Add_CheckedChanged({Set-RadioButton -RadioButton RadioButton1 -State Enabled})
$Form.Controls.Add($RadioButton1)

#Bulk Import Radio Button
$RadioButton2 = New-Object System.Windows.Forms.RadioButton
$RadioButton2.AutoSize = $True
$RadioButton2.Checked = $False
$RadioButton2.Location = "210, 15"
$RadioButton2.Add_CheckedChanged({Set-RadioButton -RadioButton RadioButton2 -State Enabled})
$Form.Controls.Add($RadioButton2)

# Blog URL
$OpenURL = {[System.Diagnostics.Process]::Start("http://www.cognizant.com")}
$BlogURL = New-Object System.Windows.Forms.LinkLabel
$BlogURL.Location = "15,550"
$BlogURL.Size = New-Object System.Drawing.Size(150,25)
$BlogURL.Text = "www.Cognizant.com"
$BlogURL.Add_Click($OpenURL)
$Form.Controls.Add($BlogURL)

#Device Name TextBox
$DeviceNameTextBox = New-Object System.Windows.Forms.TextBox
$DeviceNameTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
$DeviceNameTextBox.Location = "285,78"
$DeviceNameTextBox.Name = "DeviceNameTextBox"
$DeviceNameTextBox.Size = "250,20"
$DeviceNameTextBox.TabIndex = 1
$Form.Controls.Add($DeviceNameTextBox)

#AD Device Name TextBox
$ADDeviceNameTextBox = New-Object System.Windows.Forms.TextBox
$ADDeviceNameTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
$ADDeviceNameTextBox.Location = "285,48"
$ADDeviceNameTextBox.Name = "ADDeviceNameTextBox"
$ADDeviceNameTextBox.Size = "250,20"
$ADDeviceNameTextBox.TabIndex = 1
$Form.Controls.Add($ADDeviceNameTextBox)

#endregion

#Load GUI
$Form.Add_Load({Set-Default})
$Form.ShowDialog()| Out-Null

