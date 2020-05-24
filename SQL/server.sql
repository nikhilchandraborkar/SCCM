-- Export New Village Servers
/* 
	SCCM Server Inventory Query for Import to ITSM CMDB

	Author:
		Nikhil Borkar
		Ruben van Laack

	Version:        5.0
	Creation Date:  13th May 2020

*/

SET ANSI_WARNINGS OFF
SELECT 

-- machineID
computer.MachineID, -- 1160 Results

-- Site
(select case 
when computer.name00 LIKE '%BRN%' then 'Bern'
when computer.name00 LIKE '%LGN%' then 'Lengnau'
when computer.name00 LIKE '%MBR%' then 'Marburg'
when computer.name00 LIKE '%KAN%' then 'Kankakee'
when computer.name00 LIKE '%BMW%' then 'Broadmeadows'
else 'Global' END) as 'Site',

-- Name
computer.name00 as Name, 

-- Pending Reboot?
(SELECT 
		CASE WHEN (CDR.ClientState > 0 AND CDR.ClientActiveStatus = 1)
		THEN 'True'
		ELSE 'False'
		END
	FROM vSMS_CombinedDeviceResources CDR
	WHERE computer.MachineID = CDR.MachineID) AS PendingReboot,

-- OSType
'Windows' as OSType,

-- OS
ISNULL(LTRIM(RTRIM(replace(replace(replace(replace(replace(replace(replace(osSysData.Caption00,'enterprise',''),'standard',''),'edition',''),'®',''),'(R)',''),',',''),'Microsoft',''))),'') as OS,

-- OSEdition
(select case when osSysData.Caption00 like '%standard%' then 'Standard'
else (select case when osSysData.Caption00 like '%enterprise%' then 'Enterprise'
else (select case when osSysData.Caption00 like '%datacenter%' then 'Datacenter' 
else '' end) end) end) as OSEdition,

-- OSPatchLevel
ISNULL(osSysData.CSDVersion00+' ('+ osSysData.Version00 + ')', osSysData.Version00) as OSPatchLevel,

-- Manufacturer
(select case when (computer.Manufacturer00 like '%dell%') then 'Dell' 
	else (select case when (computer.Manufacturer00 like '%ibm%') then 'IBM' 
	else (select case when (computer.Manufacturer00 like '%compaq%') then 'Compaq' 
	else (select case when (computer.Manufacturer00 like '%lenovo%') then 'Lenovo' 
	else (select case when (computer.Manufacturer00 like '%fujitsu%') then 'Fujitsu Siemens' 
	else (select case when ((computer.Manufacturer00 like '%hp%') or (computer.Manufacturer00 like '%hewlett%')) then 'Hewlett-Packard' 
	else (select case when (computer.Manufacturer00 like '%vm%') then 'VMWare'
	else computer.Manufacturer00 end) end) end) end) end) end) end) as 'Manufacturer',

-- Model
computer.Model00 as Model, 

-- SerialNumber
(select case when (bios.SerialNumber00 like 'VM%') then 'N/A' else bios.SerialNumber00 end) as SerialNumber,

-- Total Memory
cast(MemoryInfo.TotalCapacity as varchar)+' MB' as MemoryText,

-- Total Memory
MemoryInfo.TotalCapacity as Memory,

-- CPU Info
-- VMWare | 4 CPU(s);  1 Core(s) / CPU;  4 Total Cores;
(SELECT 
	CASE WHEN (computer.Manufacturer00 like '%vm%')
		THEN ('VMWare | ' + cast(CPUInfo.TotalCPUs as varchar) + ' CPU(s); ' + cast(CPUInfo.MaxNumbersOfCoresPerCPU as varchar) + ' Core(s) / CPU;  ' +  cast(CPUInfo.TotalNumberOfCores as varchar) + ' Total Cores;')
		ELSE (CPUInfo.SelectedCPUName_Clean + ' | ' + cast(CPUInfo.TotalCPUs as varchar) + ' CPU(s); ' + cast(CPUInfo.MaxNumbersOfCoresPerCPU as varchar) + ' Core(s) / CPU;  ' +  cast(CPUInfo.TotalNumberOfCores as varchar) + ' Total Cores;')
	END
	) AS 'CPUInfo',

-- Disk Info
DiskInfo.DiskInfo  as 'DiskInfo',
-- FreeSpaceTotal
DiskInfo.TotalFreeSpace as 'FreeSpaceTotal',
-- MaxSpaceTotal
DiskInfo.MaxSpaceTotal as 'MaxSpaceTotal',

-- Domain
COALESCE(vsys.Full_Domain_Name0, 'CSLMFG.NET') as 'Domain',

-- IP Address
STUFF((SELECT ';' + IP.IP_Addresses0 
          FROM v_RA_System_IPAddresses IP
          WHERE computer.MachineID = IP.ResourceID and
          IP.IP_Addresses0 like '%.%.%.%' and
          IP.IP_Addresses0 not like '169.%.%.%' and
          IP.IP_Addresses0 not like '0.0.0.0' 
          FOR XML PATH('')), 1, 1, '') as 'IPAddress'

--------------------------------------------------------------------------------------------------
FROM Computer_system_Data computer
LEFT JOIN Operating_System_DATA osSysData ON computer.MachineID = osSysData.MachineID
left join v_r_system as vsys on vsys.ResourceID = computer.MachineID
left join System_DATA sysData on sysData.MachineID = computer.MachineID
left join System_DISC sysDisk on sysDisk.ItemKey = computer.MachineID

-- Bios Data 
left join (SELECT PC_BIOS_DATA.MachineID, PC_BIOS_DATA.InstanceKey, PC_BIOS_DATA.SerialNumber00, PC_BIOS_DATA.TimeKey, PC_BIOS_DATA.Description00, PC_BIOS_DATA.Manufacturer00, PC_BIOS_DATA.ReleaseDate00, PC_BIOS_DATA.BIOSVersion00,
				vsys.SMBIOS_GUID0 AS 'GUID', ROW_NUMBER() OVER (PARTITION BY PC_BIOS_DATA.MachineID ORDER BY PC_BIOS_DATA.InstanceKey DESC) AS rowRank
			FROM PC_BIOS_DATA
				LEFT JOIN v_r_system vsys on PC_BIOS_DATA.MachineID = vsys.ResourceID
			) AS bios on bios.MachineID = computer.MachineID and bios.rowRank = 1

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

-- CPU Info
left join (SELECT pro.resourceid AS 'ResourceId', COUNT(pro.resourceid) AS 'TotalCPUs', 
	SUM(pro.NumberOfCores0) AS 'TotalNumberOfCores', MAX(pro.MaxClockSpeed0) AS 'MaxClockSpeed', MIN(pro.Manufacturer0) AS 'SelectedManufacturer', 
	MIN(pro.Name0) AS 'SelectedCPUName', REPLACE(REPLACE(REPLACE(MIN(pro.Name0), '(R)', ''), '(TM)', ''), ' CPU', '') AS 'SelectedCPUName_Clean',
	MAX(pro.NumberOfCores0) AS 'MaxNumbersOfCoresPerCPU', (CASE WHEN MAX(pro.Is64Bit0) > 0 THEN 'x64' ELSE 'x86' END) AS 'SelectedCPUArchitecture'
			FROM v_GS_PROCESSOR pro 
			GROUP BY pro.resourceid) AS CPUInfo ON CPUInfo.ResourceId = computer.MachineID

-- Disk Info
left join (SELECT diskData.MachineID, COUNT(diskData.MachineID) AS 'DiskCount',
				(SUM(diskData.FreeSpace00)/1024) AS 'TotalFreeSpace', (SUM(diskData.Size00)/1024) AS 'MaxSpaceTotal',
				REPLACE((
					(select 'Disk' + cast(Index00 as varchar) + ': ' + cast((Size00/1024) as varchar) + ' GB, ' from Disk_DATA d where d.MachineID = diskData.MachineID order by Index00 FOR XML path(''), elements) + ' / ' +
					(select 'Part' + cast(InstanceKey as varchar) + ': ' + cast((Size00/1024) as varchar) + ' GB, ' from Partition_DATA p where p.MachineID = diskData.MachineID order by InstanceKey FOR XML path(''), elements) + ' / ' +
					(select DeviceID00 + cast(Size00/1024 as varchar) + ' GB, ' from Logical_Disk_DATA l where l.MachineID = diskData.MachineID and FileSystem00 is not NULL order by DeviceID00 FOR XML path(''), elements)
				), ',  / ', ' / ')
				 AS 'DiskInfo'
			FROM Logical_Disk_DATA diskData
			GROUP BY diskData.MachineID) AS DiskInfo ON DiskInfo.MachineID = computer.MachineID

WHERE sysData.SystemRole0 = 'Server' and sysDisk.active0 = 1 and sysDisk.Obsolete0 = 0 and vsys.Operating_system_name_and0 like '%Windows%Server%' 
ORDER BY computer.MachineID