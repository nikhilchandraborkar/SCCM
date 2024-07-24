DECLARE @FillFactor INT = 80
DECLARE @FragLowThreshold INT = 5
DECLARE @FragMedThreshold INT = 30

DECLARE @IndexFrag INT
DECLARE @IndexName VARCHAR(255)
DECLARE @TableName VARCHAR(255)

DECLARE @SQLCommand NVARCHAR(500)

DECLARE IndexCursor CURSOR FOR
	SELECT T.name as 'Table', I.name as 'Index', DDIPS.avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
		INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
		INNER JOIN sys.schemas S on T.schema_id = S.schema_id
		INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id AND DDIPS.index_id = I.index_id
	WHERE DDIPS.database_id = DB_ID() and I.name is not null
		AND DDIPS.avg_fragmentation_in_percent > @FragLowThreshold
	ORDER BY DDIPS.avg_fragmentation_in_percent desc

OPEN IndexCursor
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @IndexFrag

WHILE (@@FETCH_STATUS != -1)
BEGIN
	IF @IndexFrag < @FragMedThreshold
		SET @SQLCommand = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REORGANIZE'
	ELSE
		SET @SQLCommand = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD WITH (ONLINE=OFF,MAXDOP=1,FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'

	PRINT @SQLCommand

	BEGIN TRY
		EXEC (@SQLCommand)
	END TRY
	BEGIN CATCH
		PRINT GetDate()
		PRINT ERROR_NUMBER()
		PRINT ERROR_MESSAGE()
	END CATCH

FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @IndexFrag
END

CLOSE IndexCursor
DEALLOCATE IndexCursor

EXEC sp_MSforeachtable 'UPDATE STATISTICS ? WITH FULLSCAN, ALL'