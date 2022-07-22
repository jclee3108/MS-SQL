IF OBJECT_ID('hencom_SPSLRealTimeDHListSS3Query') IS NOT NULL 
    DROP PROC hencom_SPSLRealTimeDHListSS3Query
GO 
/************************************************************
 ��  �� - ������-���� �ǽð�������Ȳ : SS2��ȸ
 �ۼ��� - 20161028
 �ۼ��� - ������
************************************************************/
CREATE PROC hencom_SPSLRealTimeDHListSS3Query                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle INT,
		    @DeptSeq   INT,
            @WorkDate  NCHAR(10),
			@EstSeq	   INT 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @DeptSeq   = ISNULL(DeptSeq   ,0) ,
            @WorkDate  = ISNULL(WorkDate  ,'') ,
			@EstSeq    = ISNULL(EstSeq    ,0)
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)
	  WITH (DeptSeq    INT ,
            WorkDate   NCHAR(10),
			EstSeq     INT )
	SET @WorkDate = Replace(@WorkDate, '-', '')
	
	-- ���� �ڷ� �ӽ����̺� ����
	CREATE TABLE #TMPMesViewData
	(
		HC01PGBN	NVARCHAR(3),	-- ������ڵ�(��ü)
		CODEERP		DECIMAL(10),	-- ������ڵ�(ERP)
		TRADE		NVARCHAR(100),	-- ����Ҹ�
		HC01DATE	NCHAR(10),		-- 
		HC01SEQ		NVARCHAR(3),	-- ������ȣ
		HC01TRNM	NVARCHAR(200),	-- �ŷ�ó��
		HC01SPNM	NVARCHAR(200),	-- �����
		HC01YQTY	DECIMAL(19,5),  -- ������ ��������
		HC02SPECNAME   NVARCHAR(200), -- �԰ݸ�
		HC02SEQ		NVARCHAR(10),	-- �������
		HC02TIME	NVARCHAR(10),	-- ����ð�
		HC02QTY		DECIMAL(19,5),  -- ����������
		HC02ADDQTY	DECIMAL(19,5),  -- ���庰 ���跮
		HC02CNT		DECIMAL(19,5),  -- ����������ī��Ʈ
		HC02ADDCNT	DECIMAL(19,5),  -- ��������������ī��Ʈ
		HC02CRCD	NVARCHAR(10),	-- �����ڵ�
		HC02CRNO	NVARCHAR(10)	-- ������ȣ
	)
	INSERT INTO #TMPMesViewData
	EXEC daehan_SMESDataOpenQuery @CompanySeq,@WorkDate,@WorkDate

    -- ���� �ߺ������ͷ� ���� ���ձ������θ�...
    DELETE FROM #TMPMesViewData WHERE HC01PGBN = 'BID'

	INSERT INTO #TMPMesViewData
	EXEC daehan_SMESDataOpenQuery_Oracle @CompanySeq,@WorkDate,@WorkDate
	-- SELECT * FROM #TMPMesViewData
		--SELECT	TRADE
		--,		CODEERP
		--,		HC01DATE
		--,		HC01SEQ
		--,		HC01TRNM
		--,		HC01SPNM
		--,		HC01YQTY
		--,		SUM(HC02QTY) AS HC02QTY
		--FROM	#TMPMesViewData
		--GROUP BY TRADE
		--,		CODEERP
		--,		HC01DATE
		--,		HC01SEQ
		--,		HC01TRNM
		--,		HC01SPNM
		--,		HC01YQTY
	SELECT	TRADE AS DeptName
	,		CODEERP AS DeptSeq
	,		HC01DATE AS WorkDate 
	,		HC01SEQ AS EstSeq
	,		HC01TRNM AS CustName
	,		HC01SPNM AS PjtName
	,       HC02SPECNAME AS SpecName
	,		HC02TIME AS WTIME
	,		HC02SEQ AS SendNo
	,		isNull(HC01YQTY, 0) AS PlanQty
	,		isNull(HC02QTY, 0) AS OutQty
	FROM	#TMPMesViewData AS A
	WHERE	CODEERP = @DeptSeq
	AND     HC01SEQ = @EstSeq

RETURN
go
exec hencom_SPSLRealTimeDHListSS3Query @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <WorkDate>20180523</WorkDate>
    <DeptSeq>10</DeptSeq>
    <EstSeq>508</EstSeq>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1039041,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031837