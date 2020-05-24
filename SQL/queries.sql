

0. select * from information_schema.tables

1. Get the name of the application from SCCM and run below report- 


select distinct
aa.ApplicationName,
ae.AssignmentID,
aa.CollectionName as 'Target Collection',
ae.descript as 'Deployment Type Name',
s1.netbios_name0 as 'Computer Name',
ci2.LastComplianceMessageTime,
ae.AppEnforcementState,
case when ae.AppEnforcementState = 1000 then 'Success'
when ae.AppEnforcementState = 1001 then 'Already Compliant'
when ae.AppEnforcementState = 1002 then 'Simulate Success'
when ae.AppEnforcementState = 2000 then 'In Progress'
when ae.AppEnforcementState = 2001 then 'Waiting for Content'
when ae.AppEnforcementState = 2002 then 'Installing'
when ae.AppEnforcementState = 2003 then 'Restart to Continue'
when ae.AppEnforcementState = 2004 then 'Waiting for maintenance window'
when ae.AppEnforcementState = 2005 then 'Waiting for schedule'
when ae.AppEnforcementState = 2006 then 'Downloading dependent content'
when ae.AppEnforcementState = 2007 then 'Installing dependent content'
when ae.AppEnforcementState = 2008 then 'Restart to complete'
when ae.AppEnforcementState = 2009 then 'Content downloaded'
when ae.AppEnforcementState = 2010 then 'Waiting for update'
when ae.AppEnforcementState = 2011 then 'Waiting for user session reconnect'
when ae.AppEnforcementState = 2012 then 'Waiting for user logoff'
when ae.AppEnforcementState = 2013 then 'Waiting for user logon'
when ae.AppEnforcementState = 2014 then 'Waiting to install'
when ae.AppEnforcementState = 2015 then 'Waiting retry'
when ae.AppEnforcementState = 2016 then 'Waiting for presentation mode'
when ae.AppEnforcementState = 2017 then 'Waiting for Orchestration'
when ae.AppEnforcementState = 2018 then 'Waiting for network'
when ae.AppEnforcementState = 2019 then 'Pending App-V Virtual Environment'
when ae.AppEnforcementState = 2020 then 'Updating App-V Virtual Environment'
when ae.AppEnforcementState = 3000 then 'Requirements not met'
when ae.AppEnforcementState = 3001 then 'Host platform not applicable'
when ae.AppEnforcementState = 4000 then 'Unknown'
when ae.AppEnforcementState = 5000 then 'Deployment failed'
when ae.AppEnforcementState = 5001 then 'Evaluation failed'
when ae.AppEnforcementState = 5002 then 'Deployment failed'
when ae.AppEnforcementState = 5003 then 'Failed to locate content'
when ae.AppEnforcementState = 5004 then 'Dependency installation failed'
when ae.AppEnforcementState = 5005 then 'Failed to download dependent content'
when ae.AppEnforcementState = 5006 then 'Conflicts with another application deployment'
when ae.AppEnforcementState = 5007 then 'Waiting retry'
when ae.AppEnforcementState = 5008 then 'Failed to uninstall superseded deployment type'
when ae.AppEnforcementState = 5009 then 'Failed to download superseded deployment type'
when ae.AppEnforcementState = 5010 then 'Failed to updating App-V Virtual Environment'
End as 'State Message'
from v_R_System_Valid s1
join vAppDTDeploymentResultsPerClient ae on ae.ResourceID=s1.ResourceID
join v_CICurrentComplianceStatus ci2 on ci2.CI_ID=ae.CI_ID AND
ci2.ResourceID=s1.ResourceID
join v_ApplicationAssignment aa on ae.AssignmentID = aa.AssignmentID
where ae.AppEnforcementState is not null and aa.ApplicationName='NetScaler Gateway Plug-in 12.0.53.13'
order by LastComplianceMessageTime Desc

2. Get the  targeted deployments by pivoting the table in excel sheet


3. Get the details of the collections the app is deployed to -

select * from v_Collection where Name in ('VP''s and 7''s (UserMachines)')
select * from v_Collection where Name in ('IPU_EXECSUPPORTS',
'IPU_REM_I_All',
'IPU_URBANA (9107)',
'Phase 0 (LAB)',
'Phase 5 (MR)',
'Urbana - VPN (IP RANGE)')


4. Get the details of the inclusion,exclusion and limited to by using this -

select distinct c.name as [Collection Name],
c.collectionid,
cdepend.SourceCollectionID as 'Collection Dependency',
cc.Name as 'Collection Dependency Name',
Case When
cdepend.relationshiptype = 1 then 'Limited To ' + cc.name + ' (' + cdepend.SourceCollectionID + ')'
when cdepend.relationshiptype = 2 then 'Include ' + cc.name + ' (' + cdepend.SourceCollectionID + ')'
when cdepend.relationshiptype = 3 then 'Exclude ' + cc.name + ' (' + cdepend.SourceCollectionID + ')'
end as 'Type of Relationship'
from v_Collection c
join vSMS_CollectionDependencies cdepend on cdepend.DependentCollectionID=c.CollectionID
join v_Collection cc on cc.CollectionID=cdepend.SourceCollectionID
where c.CollectionID in ('FMU0113F',
'FMU0117A',
'FMU01141',
'FMU0103A',
'FMU0114A',
'FMU00F62',
'FMU00826',
'FMU007C0',
'FMU00143',
'FMU01127',
'FMU01124')



SCCM metering

select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_SYSTEM inner join SMS_MonthlyUsageSummary on SMS_R_SYSTEM.ResourceID = SMS_MonthlyUsageSummary.ResourceID    INNER JOIN SMS_MeteredFiles ON SMS_MonthlyUsageSummary.FileID = SMS_MeteredFile.MeteredFileID    WHERE DateDiff(day, SMS_MonthlyUsageSummary.LastUsage, GetDate()) < 90  AND SMS_MeteredFiles.RuleID = 16777321



