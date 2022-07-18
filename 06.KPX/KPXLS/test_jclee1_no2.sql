drop proc test_jclee1_no2 
go
create proc test_jclee1_no2

as 




--CREATE TABLE #Temp (Module  NVARCHAR(30),PgmSeq  INT )


create table #temp (Module nvarchar(30), pgmseq int ) 

INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1313 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1316 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1320 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',3569 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',4345 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',4801 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',6997 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1021324 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1021326 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1021449 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1023613 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1024279 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1024842 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1024984 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1025032 
INSERT INTO #Temp (Module, PgmSeq) SELECT '영업',1025509 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1009 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1015 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1035 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1092 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',8055 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1027474 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1027503 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1027522 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1027746 
INSERT INTO #Temp (Module, PgmSeq) SELECT '생산',1028180 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1017 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1042 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1137 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1147 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1323 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1329 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1333 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1337 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1358 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1365 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1368 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1371 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',3317 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',4012 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',5070 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',5376 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',5484 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',5545 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',5548 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',5557 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',6881 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',6885 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1021340 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1021423 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1022377 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1022450 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1025120 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1025462 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1025503 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1026717 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1026723 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1026919 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1027780 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1027835 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1027837 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1027979 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1027997 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028010 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028014 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028022 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028076 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028083 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028266 
INSERT INTO #Temp (Module, PgmSeq) SELECT '구매',1028497 

--select * from #Temp 



select distinct b.Module, BizServiceName, BizServiceSeq, BizMethodName, BizMethodSeq
  from KPXLScommon.._VCMPgmServiceSP as a 
  join #Temp as b on ( b.pgmseq = a.pgmseq ) 
 where BizServiceName is not null 
   and BizMethodName Not like '%조회%' and BizMethodName Not like '%확인%'  and BizMethodName Not like '%점프%' and BizMethodName Not like '%프로젝트%' and BizMethodName Not like '%가져오기%'
   and Module = '생산'
   order by 1 




return 
go
begin tran 

exec test_jclee1_no2

rollback 


--select distinct BizServiceName, BizServiceSEq 
--  from ksystemcommon.._VCMPgmServiceSP where PgmSeq = 3096