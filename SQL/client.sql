-- Export New Village Clients
/* 
	SCCM Client Inventory Query for Import to ITSM CMDB

	Author:
		Nikhil Borkar
		Ruben van Laack

	Version:        5.0
	Creation Date:  14th May 2020

*/
SET ANSI_WARNINGS OFF
SELECT DISTINCT

-- MachineID
computer.MachineID, -- 20.931 Results

-- Status
--'Active' as 'Status',

-- Site - By Computer Name Prefix - !! New Prafixes need to be added manually!!
(select case 
when computer.name00 LIKE '%BRN%' then 'Bern'
when computer.name00 LIKE '%LGN%' then 'Lengnau'
when computer.name00 LIKE '%MBR%' then 'Marburg'
when computer.name00 LIKE '%KAN%' then 'Kankakee'
when computer.name00 LIKE '%BMW%' then 'Broadmeadows'
else 'Global' END) as 'Site',
/******* End *******/

-- Owner
computer.UserName00 AS 'Owner',

-- Name (FQDN without Domain)
computer.Name00 as 'Name',

-- Device Type (Desktop, Notebook, ThinClient, Virtual Machine)
(select 
	CASE WHEN (bios.SerialNumber00 LIKE 'VMWare*') OR (computer.Model00 = 'VMware Virtual Platform') 
	THEN 'Virtual Machine'
	ELSE (
		case sysEncData.ChassisTypes00
		When '8' Then 'Notebook'
		When '9' Then 'Notebook'
		When '10' Then 'Notebook'
		When '11' Then 'Notebook'
		When '12' Then 'Notebook'
		When '14' Then 'Notebook'
		When '18' Then 'Notebook'
		When '21' Then 'Notebook'
		When '3' Then 'Desktop'
		When '4' Then 'Desktop'
		When '5' Then 'Desktop'
		When '6' Then 'Desktop'
		When '7' Then 'Desktop'
		When '15' Then 'Desktop'
		When '16' Then 'Desktop'
		Else 'Desktop' END)
	END)
	AS 'DeviceType',

-- Manufacturer
(select case when (computer.Manufacturer00 like '%dell%') then 'Dell' 
else (select case when (computer.Manufacturer00 like '%ibm%') then 'IBM' 
else (select case when (computer.Manufacturer00 like '%compaq%') then 'Compaq' 
else (select case when (computer.Manufacturer00 like '%lenovo%') then 'Lenovo' 
else (select case when (computer.Manufacturer00 like '%fujitsu%') then 'Fujitsu Siemens' 
else (select case when ((computer.Manufacturer00 like '%hp%') or (computer.Manufacturer00 like '%hewlett%')) then 'Hewlett-Packard' 
else (select case when (computer.Manufacturer00 like '%vm%') then 'VMWare'
else computer.Manufacturer00 end) end) end) end) end) end) end) AS 'Manufacturer',

-- Model
computer.Model00 AS 'Model',


-- Chassis Type
-- See: https://docs.microsoft.com/en-us/archive/blogs/brandonlinton/updated-win32_systemenclosure-chassis-types
(case sysEncData.ChassisTypes00
	When '1' Then 'Other'
	When '2' Then 'Unknown'
	When '3' Then 'Desktop'
	When '4' Then 'Low Profile Desktop'
	When '5' Then 'Pizza Box'
	When '6' Then 'Mini Tower'
	When '7' Then 'Tower'
	When '8' Then 'Portable'
	When '9' Then 'Laptop'
	When '10' Then 'Notebook'
	When '11' Then 'Hand Held'
	When '12' Then 'Docking Station'
	When '13' Then 'All in One'
	When '14' Then 'Sub Notebook'
	When '15' Then 'Space-Saving'
	When '16' Then 'Lunch Box'
	When '17' Then 'Main System Chassis'
	When '18' Then 'Expansion Chassis'
	When '19' Then 'SubChassis'
	When '20' Then 'Bus Expansion Chassis'
	When '21' Then 'Peripheral Chassis'
	When '22' Then 'RAID Chassis'
	When '23' Then 'Rack Mount Chassis'
	When '24' Then 'Sealed-case PC'
	When '25' Then 'Multi-system chassis'
	When '26' Then 'Compact PCI'
	When '27' Then 'Advanced TCA'
	When '28' Then 'Blade'
	When '29' Then 'Blade Enclosure'
	When '30' Then 'Tablet'
	When '31' Then 'Convertible'
	When '32' Then 'Detachable'
	When '33' Then 'IoT Gateway'
	When '34' Then 'Embedded PC'
	When '35' Then 'Mini PC'
	When '36' Then 'Stick PC'
	Else '' END) + ' (' + sysEncData.ChassisTypes00 + ')' AS 'ChassisType',

-- Serial Number
bios.SerialNumber00 as 'SerialNumber',

-- Domain Name
COALESCE((SELECT DISTINCT vsys.Full_Domain_Name0 FROM v_r_system vsys WHERE vsys.ResourceID = computer.MachineID), 'CSLMFG.NET') as 'Domain',

-- CPU Count
CPUInfo.TotalCPUs AS 'CPUCount',

-- Total Number of CPU's / CPU Cores
(case when CPUInfo.TotalNumberOfCores <> '' then CPUInfo.TotalNumberOfCores else '1' end) AS 'CPUCores',

-- CPU Speed (MHz)
CPUInfo.MaxClockSpeed as 'CPUSpeed',

-- CPU Name
CPUInfo.SelectedCPUName AS 'CPUName',

-- CPU Manufacturer
CPUInfo.SelectedManufacturer AS 'CPUManufacturer',

-- CPU Architecture
CPUInfo.SelectedCPUArchitecture AS 'CPUArchitecture',

-- Memory / RAM
MemoryInfo.TotalCapacity as 'Memory',
cast(MemoryInfo.TotalCapacity as varchar)+' MB' as MemoryText,

-- Memory Slot Count
MemoryInfo.DimmCount AS 'MemorySlotCount',

-- BIOS Date
CONVERT(VARCHAR, bios.ReleaseDate00, 121) as 'BIOSDate', -- yyyy-mm-dd hh:mi:ss.mmm

-- BIOS Manufacturer
LTRIM(RTRIM(bios.Manufacturer00)) as 'BIOSManufacturer',

-- BIOS Guid
bios.GUID AS BIOSGuid,

-- BIOS Version
LTRIM(RTRIM(bios.BIOSVersion00)) as 'BIOSversion',

-- Total Disk Space (MB)
(SELECT SUM(Logical_Disk_DATA.Size00) FROM Logical_Disk_DATA where Logical_Disk_DATA.MachineID = computer.MachineID group by Logical_Disk_DATA.MachineID) AS 'TotalDiskSpace',

-- FreeDiskSpace (MB)
(SELECT SUM(Logical_Disk_DATA.FreeSpace00) FROM Logical_Disk_DATA where Logical_Disk_DATA.MachineID = computer.MachineID group by Logical_Disk_DATA.MachineID) AS 'FreeDiskSpace',

-- MAC
STUFF((SELECT ';' + Mac.MAC_Addresses0
          FROM v_RA_System_MACAddresses Mac
          WHERE computer.MachineID = Mac.ResourceID
          FOR XML PATH('')), 1, 1, '') as 'MACAddress',

-- IP Address
STUFF((SELECT ';' + IP.IP_Addresses0 
          FROM v_RA_System_IPAddresses IP
          WHERE computer.MachineID = IP.ResourceID and
          IP.IP_Addresses0 like '%.%.%.%' and
          IP.IP_Addresses0 not like '169.%.%.%' and
          IP.IP_Addresses0 not like '0.0.0.0' 
          FOR XML PATH('')), 1, 1, '') as 'IPAddress',

-- Subnet
STUFF((SELECT ';' + subnet.IP_Subnets0
          FROM v_RA_System_IPSubnets subnet
          WHERE computer.MachineID = subnet.ResourceID and
          subnet.IP_Subnets0 like '%.%.%.%' and
          subnet.IP_Subnets0 not like '169.%.%.%' and
          subnet.IP_Subnets0 not like '0.0.0.0' 
          FOR XML PATH('')), 1, 1, '') as 'IPSubnet',

-- Operating System
ISNULL(LTRIM(RTRIM(replace(replace(replace(replace(replace(replace(replace(operatingsystem.Caption00,'enterprise',''),'standard',''),'edition',''),'®',''),'(R)',''),',',''),'Microsoft',''))),'') as 'OperatingSystem',

-- OS Edition
(select case 
	when operatingsystem.Caption00 like '%standard%' then 'Standard'
	else (select case when operatingsystem.Caption00 like '%enterprise%' then 'Enterprise'
	else (select case when operatingsystem.Caption00 like '%datacenter%' then 'Datacenter' 
	else '' end) end) end) as 'OSEdition',

-- OS Patch Level
--ISNULL(operatingsystem.CSDVersion00+' ('+ operatingsystem.Version00 + ')', NULL) as 'OSPatchLevel',

-- Last Login
(SELECT CONVERT(VARCHAR, cdres.ADLastLogonTime, 121) FROM vSMS_CombinedDeviceResources cdres WHERE cdres.MachineID = computer.MachineID) AS LastLogonTime,

-- % Free Space
( (100.0 / (SELECT SUM(Logical_Disk_DATA.Size00) FROM Logical_Disk_DATA where Logical_Disk_DATA.MachineID = computer.MachineID group by Logical_Disk_DATA.MachineID))
	* (SELECT SUM(Logical_Disk_DATA.FreeSpace00) FROM Logical_Disk_DATA where Logical_Disk_DATA.MachineID = computer.MachineID group by Logical_Disk_DATA.MachineID) 
) AS 'PercentFreeStorageSpace'

/*
(select case when (bitlockerInfo.ConversionStatus is null) then 'N/A' else bitlockerInfo.ConversionStatus end) as 'BitLocker_ConversionStatus',
(select case when (bitlockerInfo.EncryptMethod is null) then 'N/A' else bitlockerInfo.EncryptMethod end) as 'BitLocker_EncryptionMethod',
(select case when (bitlockerInfo.ProtectionStatus is null) then 'N/A' else bitlockerInfo.ProtectionStatus end) as 'BitLocker_ProtectionStatus',
(select case when (bitlockerInfo.BitLockerVersion is null) then 'N/A' else bitlockerInfo.BitLockerVersion end) as 'BitLocker_Version',
(select case when (bitlockerInfo.BitlockerRecoveryKey  is null) then 'N/A' else bitlockerInfo.BitlockerRecoveryKey end) as 'Bitlocker_RecoveryKey'
*/

--------------------------------------------------------------------------------
FROM Computer_system_Data computer
left join System_DATA sysData on sysData.MachineID = computer.MachineID
left join System_DISC sysDisk on sysDisk.ItemKey = computer.MachineID
left join System_enclosure_Data sysEncData on computer.MachineID = sysEncData.MachineID
left join Operating_System_DATA operatingsystem on operatingsystem.MachineID = computer.MachineID

-- Bios Data 
left join (SELECT PC_BIOS_DATA.MachineID, PC_BIOS_DATA.InstanceKey, PC_BIOS_DATA.SerialNumber00, PC_BIOS_DATA.TimeKey, PC_BIOS_DATA.Description00, PC_BIOS_DATA.Manufacturer00, PC_BIOS_DATA.ReleaseDate00, PC_BIOS_DATA.BIOSVersion00,
				vsys.SMBIOS_GUID0 AS 'GUID', ROW_NUMBER() OVER (PARTITION BY PC_BIOS_DATA.MachineID ORDER BY PC_BIOS_DATA.InstanceKey DESC) AS rowRank
			FROM PC_BIOS_DATA
				LEFT JOIN v_r_system vsys on PC_BIOS_DATA.MachineID = vsys.ResourceID
			) AS bios on bios.MachineID = computer.MachineID and bios.rowRank = 1

-- CPU Info
left join (SELECT pro.resourceid AS 'ResourceId', COUNT(pro.resourceid) AS 'TotalCPUs', SUM(pro.NumberOfCores0) AS 'TotalNumberOfCores', MAX(pro.MaxClockSpeed0) AS 'MaxClockSpeed', MIN(pro.Manufacturer0) AS 'SelectedManufacturer', MIN(pro.Name0) AS 'SelectedCPUName',
				(CASE WHEN MAX(pro.Is64Bit0) > 0 THEN 'x64' ELSE 'x86' END) AS 'SelectedCPUArchitecture'
			FROM v_GS_PROCESSOR pro 
			GROUP BY pro.resourceid) AS CPUInfo ON CPUInfo.ResourceId = computer.MachineID

-- Memory Info
left join (SELECT phyMem.MachineID, COUNT(phyMem.MachineID) AS 'DimmCount', SUM(phyMem.Capacity00) AS 'TotalCapacity'
				/* -- Not needed fields, save time on aggregation
				,MAX(phyMem.FormFactor00) AS 'FormFactor', 
				STUFF((SELECT '/' + phyMem2.Manufacturer00
						   FROM PHYSICAL_MEMORY_DATA phyMem2
						   WHERE phyMem.MachineID = phyMem2.MachineID
						   ORDER BY phyMem2.Manufacturer00 ASC
						   FOR XML PATH ('')
					   ), 1, 1, '')   AS  'Manufacturers'
					   */
			FROM PHYSICAL_MEMORY_DATA phyMem
			GROUP BY phyMem.MachineID) AS MemoryInfo ON MemoryInfo.MachineID = computer.MachineID

-- Bitlocker info
/*
left join (-- CSLMFG Bitlocker Query
	SELECT bitLocker.MachineID AS 'MachineID', CONVERT(varchar, bitLocker.ConversionStatus00)  AS 'ConversionStatus', 
			 CONVERT(varchar, bitLocker.EncryptionMethod00) AS 'EncryptMethod',  CONVERT(varchar, bitLocker.ProtectionStatus00) AS 'ProtectionStatus',  
			 CONVERT(varchar, bitLocker.RevisionID) AS 'BitLockerVersion',  CONVERT(varchar, bitLocker.InstanceKey) AS 'BitlockerRecoveryKey', bitLocker.TimeKey AS 'ActivationTime',
				ROW_NUMBER() OVER (PARTITION BY bitLocker.MachineID ORDER BY bitLocker.TimeKey DESC) AS rowRank
			FROM BITLOCKER_DETAILS_DATA bitLocker
			WHERE bitLocker.DriveLetter00 = 'C:') AS bitlockerInfo ON bitlockerInfo.MachineID = computer.MachineID
			*/
/*
left join ( -- CSLG1 Bitlocker Query
	SELECT bitLocker.MachineID AS 'MachineID', bitLocker.Conversion_Status00 AS 'ConversionStatus', 
			bitLocker.Encryption_Method00  AS 'EncryptMethod', bitLocker.Protection_Status00 AS 'ProtectionStatus', bitLocker.BitLocker_Version00 AS 'BitLockerVersion', bitLocker.Recovery_key00  AS 'BitlockerRecoveryKey', bitLocker.TimeKey AS 'ActivationTime',
				ROW_NUMBER() OVER (PARTITION BY bitLocker.MachineID ORDER BY bitLocker.TimeKey DESC) AS rowRank
			FROM SCCM_BITLOCKER_DATA bitLocker
			WHERE bitLocker.Drive00 = 'C:') AS bitlockerInfo ON bitlockerInfo.MachineID = computer.MachineID
			*/

where sysData.SystemRole0 = 'Workstation' and sysDisk.Active0 = 1 and sysDisk.Obsolete0 = 0
--SystemRole0='Workstation' and d.active0=1 and d.Obsolete0=0 and vsys.Operating_system_name_and0 like '%Windows%10%'
ORDER BY computer.MachineID