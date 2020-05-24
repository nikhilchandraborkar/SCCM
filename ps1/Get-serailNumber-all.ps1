Param
(
    [Parameter(Mandatory=$False)]
    [String]$SerialNumber,
    [Parameter(Mandatory=$False)]
    [String]$ComputerName
)
Process
{
    # Change this - Add the Configuration Manager database server name
    $DatabaseServerName = "vwdcpv-msapp110.emea.vorwerk.org"
    # Change this - Add ths Configuration Manager database name
    $DatabaseName = "CM_PRI"
    try
    {
        $Connection = new-object system.data.sqlclient.sqlconnection
        $Connection.ConnectionString ="server=$DatabaseServerName;database=$DatabaseName;trusted_connection=True"

        # Connect to Database and Run Query
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        
        If ($SerialNumber -eq "" -and $ComputerName -eq "")
        {
            $SqlQuery = @"
                SELECT Name0 AS [ComputerName], SerialNumber00 AS [SerialNumber], Manufacturer00 AS [Manufacturer]
                FROM PC_BIOS_DATA
                INNER JOIN System_DATA
                ON PC_BIOS_DATA.MachineID = System_DATA.MachineID
"@
        }
        If ($SerialNumber -ne "")
        {
            $SqlQuery = @"
                SELECT Name0 AS [ComputerName], SerialNumber00 AS [SerialNumber], Manufacturer00 AS [Manufacturer]
                FROM PC_BIOS_DATA
                INNER JOIN System_DATA
                ON PC_BIOS_DATA.MachineID = System_DATA.MachineID
                WHERE PC_BIOS_DATA.SerialNumber00='$SerialNumber'
"@
        }
        If ($ComputerName -ne "")
        {
            $SqlQuery = @"
                SELECT Name0 AS [ComputerName], SerialNumber00 AS [SerialNumber], Manufacturer00 AS [Manufacturer]
                FROM PC_BIOS_DATA
                INNER JOIN System_DATA
                ON PC_BIOS_DATA.MachineID = System_DATA.MachineID
                WHERE System_DATA.Name0='$ComputerName'
"@
        }
        $Connection.open()
        $SqlCmd.CommandText = $SqlQuery
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $SqlCmd.Connection = $Connection
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet)
        $DataSet.Tables[0]
        $Connection.Close()
    }
    Catch
    {
        Write-host "Connection to database unsuccessful."
        $Connection.Close()
    }
}