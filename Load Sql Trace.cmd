rem set trace=ProdTrace_64
set trace=%1
set folder=C:\projects\sqltraces
set dbname=SqlTraces

REM sqlcmd -S localhost -Q "DROP TAble %dbname%.dbo.trace%trace%"
sqlcmd -S localhost -E -d %dbname% -Q "SELECT IDENTITY(int, 1, 1) AS RowNumber, CAST( TextData AS VARCHAR(500) ) AS ShortText, HostName, ApplicationName, LoginName, DatabaseName, SPID, Duration, StartTime, EndTime, Reads, Writes, CPU, EventClass, RowCounts, TextData INTO trace%trace% FROM fn_trace_gettable( '%folder%%trace%.trc', default )"

FOR %%G IN (CPU Duration EventClass Reads Writes StartTime EndTime ApplicationName LoginName DatabaseName) DO sqlcmd -S localhost -E -d %dbname% -Q "CREATE NONCLUSTERED INDEX [IX_trace%trace%_%%G] ON [trace%trace%] ( [%%G] ASC )"
