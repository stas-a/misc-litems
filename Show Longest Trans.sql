select t1.RowNumber AS BeginRowNumber, (select min(rownumber) from traceProdTrace_65 t2 where t1.rownumber<t2.rownumber and t1.spid=t2.spid and (t2.shorttext='COMMIT TRANSACTION' OR t2.shorttext='ROLLBACK TRANSACTION')) as CommitRowNumber
into #trans
from traceProdTrace_65 t1(NOLOCK)
where shorttext='BEGIN TRANSACTION'

select DATEDIFF (s, t1.starttime , t2.starttime), t1.spid, t1.starttime, t2.starttime, BeginRowNumber, CommitRowNumber, t1.DatabaseName,
	'SELECT * FROM traceProdTrace_65 WHERE rownumber between ' + CAST(BeginRowNumber AS VARCHAR(10)) + ' AND ' + CAST(CommitRowNumber AS VARCHAR(10)) + ' AND SPID='+CAST(t1.SPID AS VARCHAR(10)) + ' ORDER BY RowNumber',
	t2.TextData
from #trans
join traceProdTrace_65 t1(NOLOCK) on BeginRowNumber=rownumber
join traceProdTrace_65 t2(NOLOCK) on CommitRowNumber=t2.rownumber
order by 1 DESC

DROP TABLE #trans 