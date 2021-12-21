----------------------------------------------------------------------------------------------------------
--Autor          : Hidequel Puga
--Fecha          : 2021-12-21
--Descripción    : Documenting Maintenance Plans
--Ref            : https://itsalljustelectrons.blogspot.com/2019/09/Documenting-Maintenance-Plans.html
----------------------------------------------------------------------------------------------------------




IF OBJECT_ID(N'tempdb..#Temp1') IS NOT NULL
	BEGIN
		DROP TABLE #Temp1
	END

IF OBJECT_ID(N'tempdb..#Temp2') IS NOT NULL
	BEGIN
		DROP TABLE #Temp2
	END

IF OBJECT_ID(N'tempdb..#Temp3') IS NOT NULL
	BEGIN
		DROP TABLE #Temp3
	END

;WITH XMLNAMESPACES
(
   'www.microsoft.com/SqlServer/Dts'               AS DTS
 , 'www.microsoft.com/SqlServer/Dts/Tasks'         AS DTSTask
)
, Maintplan_ssispackages
AS
(
	SELECT CAST(CAST([packagedata] AS VARBINARY(MAX)) AS XML) AS package_data
	     , [name]                                             AS package_name
		 , id                                                 AS package_id
		 , createdate                                         AS create_date
		 , isencrypted                                        AS is_encrypted
      FROM [msdb].[dbo].[sysssispackages]
     WHERE packagetype = 6 --Maintenance Plans
)
, Maintplan_subplans
AS
(
	SELECT plan_id
	     , subplan_id
		 , subplan_name
		 , subplan_description
		 , job_id
	  FROM [msdb].[dbo].[sysmaintplan_subplans]
)
, Sysjobs_schedules
AS 
(
-- jobs with a daily schedule
	SELECT sysjobs.job_id
	     , sysjobs.name      job_name
		 , CASE WHEN sysjobs.enabled = 0 THEN 'Disabled'
		        WHEN sysjobs.enabled = 1 THEN 'Enabled' 
		        ELSE ''
		    END job_status
		 , sysschedules.name schedule_name
		 , CASE WHEN freq_type = 4 THEN 'Daily'
			END frequency
		 , 'Occurs every ' + cast(freq_interval AS VARCHAR(3)) + ' day(s)' [days]
		 , CASE  WHEN freq_subday_type = 2 THEN ' every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' seconds' + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				 WHEN freq_subday_type = 4 THEN ' every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' minutes' + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				 WHEN freq_subday_type = 8 THEN ' every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' hours'   + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				 ELSE ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
			END [time]
	  FROM msdb.dbo.sysjobs
INNER JOIN msdb.dbo.sysjobschedules
	    ON sysjobs.job_id = sysjobschedules.job_id
INNER JOIN msdb.dbo.sysschedules
	    ON sysjobschedules.schedule_id = sysschedules.schedule_id
     WHERE freq_type = 4
	   AND sysjobs.category_id = 3 -- Category : Database Maintenance
	
	UNION

-- jobs with a weekly schedule
	SELECT sysjobs.job_id
	     , sysjobs.name job_name
		 , CASE WHEN sysjobs.enabled = 0 THEN 'Disabled'
		        WHEN sysjobs.enabled = 1 THEN 'Enabled' 
		        ELSE ''
		    END job_status
		 , sysschedules.name schedule_name
		 , CASE WHEN freq_type = 8 THEN 'Weekly'
			END frequency
		 , 'Occurs every ' + REPLACE(CASE WHEN freq_interval & 1 = 1   THEN 'Sunday, '    ELSE '' END + 
							  CASE WHEN freq_interval & 2 = 2   THEN 'Monday, '    ELSE '' END + 
							  CASE WHEN freq_interval & 4 = 4   THEN 'Tuesday, '   ELSE '' END + 
							  CASE WHEN freq_interval & 8 = 8   THEN 'Wednesday, ' ELSE '' END + 
							  CASE WHEN freq_interval & 16 = 16 THEN 'Thursday, '  ELSE '' END + 
							  CASE WHEN freq_interval & 32 = 32 THEN 'Friday, '    ELSE '' END + 
							  CASE WHEN freq_interval & 64 = 64 THEN 'Saturday, '  ELSE '' END, ', ', '') [days]
		 , CASE WHEN freq_subday_type = 2 THEN ' Occurs every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' seconds' + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				WHEN freq_subday_type = 4 THEN ' Occurs every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' minutes' + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				WHEN freq_subday_type = 8 THEN ' Occurs every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' hours'   + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				ELSE ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
			END [time]
	  FROM msdb.dbo.sysjobs
INNER JOIN msdb.dbo.sysjobschedules
	    ON sysjobs.job_id = sysjobschedules.job_id
INNER JOIN msdb.dbo.sysschedules
	    ON sysjobschedules.schedule_id = sysschedules.schedule_id
     WHERE freq_type = 8
	   AND sysjobs.category_id = 3 -- Category : Database Maintenance

	 UNION

-- jobs with a monthly schedule
	SELECT sysjobs.job_id
	     , sysjobs.name job_name
		 , CASE WHEN sysjobs.enabled = 0 THEN 'Disabled'
		        WHEN sysjobs.enabled = 1 THEN 'Enabled' 
		        ELSE ''
		    END job_status
		 , sysschedules.name schedule_name
		 , CASE WHEN freq_type = 4  THEN 'Daily'
				WHEN freq_type = 8  THEN 'Weekly'
				WHEN freq_type = 16 THEN 'Monthly'
				WHEN freq_type = 32 THEN 'Monthly'
			END frequency
		 , CASE WHEN freq_type = 32 THEN ( CASE WHEN freq_relative_interval = 1  THEN 'First '
												WHEN freq_relative_interval = 2  THEN 'Second '
												WHEN freq_relative_interval = 4  THEN 'Third '
												WHEN freq_relative_interval = 8  THEN 'Fourth '
												WHEN freq_relative_interval = 16 THEN 'Last '
											END + 
											REPLACE(CASE WHEN freq_interval = 1  THEN 'Sunday, '       ELSE '' END + 
													CASE WHEN freq_interval = 2  THEN 'Monday, '       ELSE '' END + 
													CASE WHEN freq_interval = 3  THEN 'Tuesday, '      ELSE '' END + 
													CASE WHEN freq_interval = 4  THEN 'Wednesday, '    ELSE '' END + 
													CASE WHEN freq_interval = 5  THEN 'Thursday, '     ELSE '' END + 
													CASE WHEN freq_interval = 6  THEN 'Friday, '       ELSE '' END + 
													CASE WHEN freq_interval = 7  THEN 'Saturday, '     ELSE '' END + 
													CASE WHEN freq_interval = 8  THEN 'Day of Month, ' ELSE '' END + 
													CASE WHEN freq_interval = 9  THEN 'Weekday, '      ELSE '' END + 
													CASE WHEN freq_interval = 10 THEN 'Weekend day, '  ELSE '' END, ', ', '')
										  )
			    ELSE 'Occurs on day ' + cast(freq_interval AS VARCHAR(3)) + ' of the month'
			END [days]
		 , CASE WHEN freq_subday_type = 2 THEN ' Occurs every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' seconds' + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				WHEN freq_subday_type = 4 THEN ' Occurs every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' minutes' + ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				WHEN freq_subday_type = 8 THEN ' Occurs every ' + cast(freq_subday_interval AS VARCHAR(7)) + ' hours' + ' at '   + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
				ELSE ' at ' + FORMAT(msdb.dbo.agent_datetime(active_start_date, active_start_time), 'T')
			END AS [time]
	  FROM msdb.dbo.sysjobs
INNER JOIN msdb.dbo.sysjobschedules
	    ON sysjobs.job_id = sysjobschedules.job_id
INNER JOIN msdb.dbo.sysschedules
	    ON sysjobschedules.schedule_id = sysschedules.schedule_id
     WHERE freq_type IN (16, 32)
       AND sysjobs.category_id = 3 -- Category : Database Maintenance
)

SELECT packages.package_id           
	 , packages.package_name         
	 , REPLACE(REPLACE(dtstasks.value('(../@DTS:DTSID)', 'VARCHAR(4000)'), '{', ''), '}', '')  AS subplan_id
	 , dtstasks.value('(../@DTS:ObjectName)', 'VARCHAR(4000)')  AS subplan_name
	 , subplans.job_id
	 , js.[job_name]  AS job_name
	 , js.job_status 
	 , js.frequency 
	 , js.[days]
	 , js.[time]
INTO #Temp1
  FROM Maintplan_ssispackages AS packages 
 CROSS APPLY package_data.nodes('//DTS:Executable[@DTS:ExecutableType="STOCK:SEQUENCE"]/DTS:Executables') AS pd(dtstasks)
  JOIN Maintplan_subplans AS subplans
    ON subplans.subplan_id = REPLACE(REPLACE(dtstasks.value('(../@DTS:DTSID)', 'VARCHAR(4000)'), '{', ''), '}', '') 
  JOIN Sysjobs_schedules AS js
    ON js.job_id = subplans.job_id

;WITH XMLNAMESPACES
(
   'www.microsoft.com/SqlServer/Dts'               AS DTS
 , 'www.microsoft.com/SqlServer/Dts/Tasks'         AS DTSTask
 , 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask
)
, Maintplan_ssispackages
AS
(
	SELECT CAST(CAST([packagedata] AS VARBINARY(MAX)) AS XML) AS package_data
	     , [name]                                             AS package_name
		 , id                                                 AS package_id
		 , createdate                                         AS create_date
		 , isencrypted                                        AS is_encrypted
      FROM [msdb].[dbo].[sysssispackages]
     WHERE packagetype = 6 --Maintenance Plans
)
SELECT packages.package_id
     , packages.package_name
	 , REPLACE(REPLACE(pd.sqltaskdata.value('(../../../../@DTS:DTSID)', 'NVARCHAR(MAX)'), '{', ''), '}', '')  AS subplan_id
     , pd.sqltaskdata.value('(../../../../@DTS:ObjectName)', 'NVARCHAR(MAX)') AS subplan_name
     , pd.sqltaskdata.value('(../../@DTS:ObjectName)', 'NVARCHAR(MAX)') AS [object_name]
	 , pd.sqltaskdata.value('(../../@DTS:ExecutableType)', 'NVARCHAR(MAX)') AS executable_type
     , pd.sqltaskdata.value('(@SQLTask:FolderPath)', 'VARCHAR(4000)')  AS folder_path
	 , pd.sqltaskdata.value('(@SQLTask:FileExtension)', 'VARCHAR(4000)')  AS file_extension
	 
	 , pd.sqltaskdata.value('(@SQLTask:AgeBased)', 'VARCHAR(4000)')  AS age_based

	 , pd.sqltaskdata.value('(@SQLTask:RemoveOlderThan)', 'VARCHAR(4000)')  AS remove_older_than
	 , pd.sqltaskdata.value('(@SQLTask:TimeUnitsType)', 'INT') AS time_units_type  
	 , CASE pd.sqltaskdata.value('(@SQLTask:TimeUnitsType)', 'INT')  
			WHEN 0 THEN 'Day(s)'
			WHEN 1 THEN 'Week(s)'
			WHEN 2 THEN 'Month(s)'
			WHEN 3 THEN 'Year(s)'
			WHEN 5 THEN 'Hour(s)' 
		    ELSE '' 
		END AS time_units_desc
INTO #Temp2
  FROM Maintplan_ssispackages AS packages 
 CROSS APPLY package_data.nodes('//DTS:Executable[@DTS:ExecutableType="STOCK:SEQUENCE"]/DTS:Executables/DTS:Executable/DTS:ObjectData/SQLTask:SqlTaskData') AS pd(sqltaskdata)
 WHERE pd.sqltaskdata.value('(../../@DTS:ExecutableType)', 'NVARCHAR(MAX)')  = 'Microsoft.DbMaintenanceFileCleanupTask'

;WITH XMLNAMESPACES
(
   'www.microsoft.com/SqlServer/Dts'               AS DTS
 , 'www.microsoft.com/SqlServer/Dts/Tasks'         AS DTSTask
 , 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask
)
, Maintplan_ssispackages
AS
(
	SELECT CAST(CAST([packagedata] AS VARBINARY(MAX)) AS XML) AS package_data
	     , [name]                                             AS package_name
		 , id                                                 AS package_id
		 , createdate                                         AS create_date
		 , isencrypted                                        AS is_encrypted
      FROM [msdb].[dbo].[sysssispackages]
     WHERE packagetype = 6 --Maintenance Plans
)

SELECT packages.package_id
     , packages.package_name
	 , REPLACE(REPLACE(pd.sqltaskdata.value('(../../../../@DTS:DTSID)', 'NVARCHAR(MAX)'), '{', ''), '}', '')  AS subplan_id
     , pd.sqltaskdata.value('(../../../../@DTS:ObjectName)', 'NVARCHAR(MAX)') AS subplan_name
     , pd.sqltaskdata.value('(../../@DTS:ObjectName)', 'NVARCHAR(MAX)') AS [object_name]
	 , pd.sqltaskdata.value('(../../@DTS:ExecutableType)', 'NVARCHAR(MAX)') AS executable_type
     , pd.sqltaskdata.value('(@SQLTask:BackupDestinationAutoFolderPath)', 'VARCHAR(4000)')  AS backup_destination_auto_folder_path
	 , pd.sqltaskdata.value('(@SQLTask:BackupAction)', 'VARCHAR(4000)')  AS backup_action
	 , pd.sqltaskdata.value('(@SQLTask:BackupIsIncremental)', 'VARCHAR(4000)') AS backup_is_incremental
	 , CASE pd.sqltaskdata.value('(@SQLTask:DatabaseSelectionType)', 'INT') 
			WHEN 1 THEN 'All Databases'
			WHEN 2 THEN 'All System Databases'
			WHEN 3 THEN 'All User Databases'
			ELSE 'Especific Databases' 
		END AS database_selection_type
INTO #Temp3
  FROM Maintplan_ssispackages AS packages 
 CROSS APPLY package_data.nodes('//DTS:Executable[@DTS:ExecutableType="STOCK:SEQUENCE"]/DTS:Executables/DTS:Executable/DTS:ObjectData/SQLTask:SqlTaskData') AS pd(sqltaskdata)
 WHERE pd.sqltaskdata.value('(../../@DTS:ExecutableType)', 'NVARCHAR(MAX)')  = 'Microsoft.DbMaintenanceBackupTask'

SELECT T1.package_id
     , T1.package_name
	 , T1.subplan_id
     , T1.subplan_name
     , T1.job_id
	 , T1.job_name
     , T1.job_status
     , T1.frequency
     , (T1.[days] + ' ' + T1.[time]) AS [schedule]
	 , T2.backup_task
	 , T2.database_selection_type AS [databases]
	 , T2.backup_type
	 , T2.backup_destination_auto_folder_path AS backup_destination_folder
	 , T2.cleanup_task
	 , T2.retention
  FROM #Temp1 AS T1
  JOIN (
        SELECT Tmp2.package_id
			 , Tmp2.package_name
			 , tmp2.subplan_id
			 , Tmp2.subplan_name
			 , Tmp3.object_name as backup_task
			 , Tmp3.database_selection_type
			 , CASE WHEN (Tmp3.backup_action = '0' AND Tmp3.backup_is_incremental = 'False') THEN 'Full'
			        WHEN (Tmp3.backup_action = '0' AND Tmp3.backup_is_incremental = 'True') THEN 'Differential'
					WHEN (Tmp3.backup_action = '2') THEN 'Transaction Log'
			    END AS backup_type
			 , tmp3.backup_destination_auto_folder_path
			 , Tmp2.[object_name] as cleanup_task
			 , CASE WHEN CONVERT(BIT, Tmp2.age_based) = 'True' THEN (Tmp2.remove_older_than + ' ' + Tmp2.time_units_desc)
			        ELSE 'File age has not been specified '
				END AS retention
		  FROM #Temp2 AS Tmp2
		  JOIN #Temp3 AS Tmp3
			ON Tmp2.package_id = Tmp3.package_id
		   AND Tmp2.subplan_id = TMP3.subplan_id
		   AND Tmp2.folder_path = Tmp3.backup_destination_auto_folder_path
		) AS T2
	ON T1.package_id =  T2.package_id
   AND T1.subplan_id = T2.subplan_id

