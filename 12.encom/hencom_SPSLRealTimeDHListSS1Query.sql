IF OBJECT_ID('hencom_SPSLRealTimeDHListSS1Query') IS NOT NULL 
    DROP PROC hencom_SPSLRealTimeDHListSS1Query
GO 

-- v2018.05.25 

-- ��¥ �Ⱓ���� ��ȸ �� �� �ֵ��� �ݿ� by����õ 
/************************************************************
 ��  �� - ������-���� �ǽð�������Ȳ : SS1��ȸ
 �ۼ��� - 20161026
 �ۼ��� - ������
************************************************************/
CREATE PROC hencom_SPSLRealTimeDHListSS1Query
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle  INT,
		    @WorkDateFr NCHAR(8), 
            @WorkDateTo NCHAR(8) 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @WorkDateFr  = ISNULL(WorkDateFr,''), 
            @WorkDateTo  = ISNULL(WorkDateTo,'')
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
	  WITH (WorkDateFr   NCHAR(8), 
            WorkDateTo   NCHAR(8) )
	
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
	EXEC daehan_SMESDataOpenQuery @CompanySeq,@WorkDateFr, @WorkDateTo

    -- ���� �ߺ������ͷ� ���� ���ձ������θ�...
    DELETE FROM #TMPMesViewData WHERE HC01PGBN = 'BID'
    
	INSERT INTO #TMPMesViewData
	EXEC daehan_SMESDataOpenQuery_Oracle @CompanySeq,@WorkDateFr, @WorkDateTo


	SELECT	TRADE AS DeptName
	,		CODEERP AS DeptSeq
	--,		(CASE WHEN LEN(HC01DATE) = 10 THEN LEFT(HC01DATE, 4) + SUBSTRING(HC01DATE, 6, 2) + RIGHT(HC01DATE, 2) ELSE HC01DATE END) AS WorkDate
	,		SUM(isNull(HC01YQTY, 0)) AS PlanQty
	,		SUM(isNull(HC02QTY, 0)) AS OutQty
	,		SUM(isNull(HC01YQTY, 0)) - SUM(isNull(HC02QTY, 0)) AS RemainQty
	,		(CASE WHEN SUM(isNull(HC01YQTY, 0)) = 0 THEN 0 ELSE ROUND(SUM(isNull(HC02QTY, 0)) / SUM(isNull(HC01YQTY, 0)) * 100, 0) END) AS ProgRate
	FROM	(
		SELECT	TRADE
		,		CODEERP
		,		HC01DATE
		,		HC01SEQ
		,		MAX(HC01YQTY) AS HC01YQTY
		,		SUM(HC02QTY) AS HC02QTY
		FROM	#TMPMesViewData 
		GROUP BY TRADE
		,		CODEERP
		,		HC01DATE
		,		HC01SEQ
		--,		HC01YQTY
	) AS T
	GROUP BY TRADE
	,		CODEERP
	--,		HC01DATE
RETURN