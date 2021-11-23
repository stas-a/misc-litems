USE [master]
GO

/****** Object:  StoredProcedure [dbo].[spCreateAndStartBlackBoxTrace]    Script Date: 1/18/2018 12:03:37 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spCreateAndStartBlackBoxTrace]
as
begin

declare @tracefile nvarchar(256)
set @tracefile =  N'C:\MSSQL\Traces\black-box-trace'

if exists (select 1 from fn_trace_getinfo( default ) where [property] = 2 and cast( [value] as nvarchar(256) ) like @tracefile + '%')
begin
	declare @existingTraceID int
	
	select @existingTraceID = traceid from fn_trace_getinfo( default ) 
	where [property] = 2 and cast( [value] as nvarchar(256) ) like @tracefile + '%'

	raiserror( 'Trace writing to the path [%s] already exists. Trace ID: %d', 16, 1, @tracefile, @existingTraceID )
	return
end

-- Black box trace: records SQL statements and RPC calls, max 10Gb of data, 100x102Mb files are rolled over
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 102 
exec @rc = sp_trace_create @TraceID output, 2, @tracefile, @maxfilesize, NULL, 100
if (@rc != 0) goto error

-- Set the events
declare @rowID int, @eventID int, @on bit
declare @events table( RowID int identity(1,1), EventID int )

insert into @events( EventID ) values( 10 ) -- RPC:Completed
insert into @events( EventID ) values( 11 ) -- RPC:Starting
insert into @events( EventID ) values( 40 ) -- SQL:StmtStarting
insert into @events( EventID ) values( 41 ) -- SQL:StmtCompleted
insert into @events( EventID ) values( 25 ) -- Lock:Deadlock
insert into @events( EventID ) values( 59 ) -- Lock:Deadlock Chain
insert into @events( EventID ) values( 148 ) -- Deadlock Graph
insert into @events( EventID ) values( 181 ) -- TM: Begin Tran Starting
insert into @events( EventID ) values( 186) -- TM: Commit Tran Completed
insert into @events( EventID ) values( 188) -- TM: Rollback Tran Complete  

set @on = 1

while 1 = 1
begin 
	select @rowID = coalesce( @rowID, 0 ) + 1
	select @eventID = EventID from @events where RowID = @rowID
	if @@rowcount = 0 break
	
	exec sp_trace_setevent @TraceID, @eventID, 7, @on	-- NTDomainName 
	exec sp_trace_setevent @TraceID, @eventID, 15, @on	-- EndTime 
	exec sp_trace_setevent @TraceID, @eventID, 31, @on	-- Error 
	exec sp_trace_setevent @TraceID, @eventID, 8, @on	-- HostName 
	exec sp_trace_setevent @TraceID, @eventID, 16, @on	-- Reads 
	exec sp_trace_setevent @TraceID, @eventID, 48, @on	-- RowCounts 
	exec sp_trace_setevent @TraceID, @eventID, 64, @on	-- SessionLoginName 
	exec sp_trace_setevent @TraceID, @eventID, 1, @on	-- TextData 
	exec sp_trace_setevent @TraceID, @eventID, 17, @on	-- Writes 
	exec sp_trace_setevent @TraceID, @eventID, 6, @on	-- NTUserName 
	exec sp_trace_setevent @TraceID, @eventID, 10, @on	-- ApplicationName 
	exec sp_trace_setevent @TraceID, @eventID, 14, @on	-- StartTime
	exec sp_trace_setevent @TraceID, @eventID, 18, @on	-- CPU
	exec sp_trace_setevent @TraceID, @eventID, 11, @on	-- LoginName 
	exec sp_trace_setevent @TraceID, @eventID, 35, @on	-- DatabaseName 
	exec sp_trace_setevent @TraceID, @eventID, 12, @on	-- SPID 
	exec sp_trace_setevent @TraceID, @eventID, 60, @on	-- IsSystem 
	exec sp_trace_setevent @TraceID, @eventID, 13, @on	-- Duration 
end

exec sp_trace_setfilter @TraceID, 11, 0, 7, N'SQL Server Profiler'
exec sp_trace_setfilter @TraceID, 35, 1, 6, N'LancelotProd'

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID = @TraceID

goto finish

error: 
select ErrorCode = @rc

finish: 

end
GO

EXEC sp_procoption N'[dbo].[spCreateAndStartBlackBoxTrace]', 'startup', '1'

GO


