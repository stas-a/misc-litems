echo on
set zippedTracesFolder=C:\projects\sqltraces
set tempFolder=C:\projects\sqltraces\tmp
set traceName=ProdTrace
set dbName=SqlTraces

@if "%1" equ "" goto :paramError
@if "%2" equ "" goto :paramError
@if "%3" equ "" goto :paramError

del "%tempFolder%\*.trc"
REM Copy all files here, because of that timestamp in filenames
for /f "delims=|" %%f in ('dir /b %zippedTracesFolder%') do (
	"C:\Program Files\7-Zip\7z" -aoa e "%zippedTracesFolder%\%%f" -o"%tempFolder%"
)

goto :end

REM Load only ones in the range
sqlcmd -S localhost -E -d %dbName% -Q "SELECT IDENTITY(int, 1, 1) AS RowNumber, CAST( TextData AS VARCHAR(500) ) AS ShortText, HostName, ApplicationName, LoginName, DatabaseName, SPID, Duration, StartTime, EndTime, Reads, Writes, CPU, EventClass, RowCounts, TextData INTO %3 FROM fn_trace_gettable( '%tempFolder%\%traceName%_%1.trc', default )"

FOR %%G IN (CPU Duration EventClass Reads Writes StartTime EndTime ApplicationName LoginName DatabaseName) DO sqlcmd -S localhost -E -d %dbName% -Q "CREATE NONCLUSTERED INDEX [IX_%3_%%G] ON [%3] ( [%%G] ASC )"

del "%tempFolder%\*.7z"
del "%tempFolder%\*.trc"

@goto end

:paramError
@dir "%zippedTracesFolder%\%traceName%*.7z"
@echo ***********************************************************************************************
@echo Required parameter(s) missing! Please specify start file number, end file number and table name.
@echo ***********************************************************************************************

:end