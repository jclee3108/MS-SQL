
IF OBJECT_ID('yw_SLGLocationStockQuery') IS NOT NULL
    DROP PROC yw_SLGLocationStockQuery
GO
    
-- 2013.08.29 

-- Location�����ȸ_yw by������,����õ
CREATE PROC yw_SLGLocationStockQuery
    @CompanySeq     INT  = 1,
    @WHSeq			INT	 = 0 
AS
    
	CREATE TABLE #GetInOutLot 
    (      
        LotNo       NVARCHAR(30),      
        ItemSeq     INT      
    ) 

	CREATE TABLE #GetInOutLotStock (      
        WHSeq           INT,            
        FunctionWHSeq   INT,            
        LotNo           NVARCHAR(30),          
        ItemSeq         INT,            
        UnitSeq         INT,            
        PrevQty         DECIMAL(19, 5),            
        InQty           DECIMAL(19, 5),            
        OutQty          DECIMAL(19, 5),            
        StockQty        DECIMAL(19, 5),            
        STDPrevQty      DECIMAL(19, 5),            
        STDInQty        DECIMAL(19, 5),            
        STDOutQty       DECIMAL(19, 5),            
        STDStockQty     DECIMAL(19, 5)            
    )
    
    DECLARE @GETDATE NVARCHAR(8) 
    SELECT @GETDATE = CONVERT(NVARCHAR(8),GETDATE(),112) 
    
    INSERT INTO #GetInOutLot(ItemSeq, LotNo)
    SELECT  A.ItemSeq, A.LotNo
      FROM _TLGLotStock AS A WITH(NOLOCK)     
     WHERE A.CompanySeq = @CompanySeq
     GROUP BY A.ItemSeq, A.LotNo
		 
	-- â����� ��������      
    EXEC _SLGGetInOutLotStock   @CompanySeq     = @CompanySeq,  -- �����ڵ�            
                                @BizUnit        = 1,			-- ����ι�            
                                @FactUnit       = 0,            -- ��������            
                                @DateFr         = @GETDATE,     -- ��ȸ�ⰣFr            
                                @DateTo         = @GETDATE,     -- ��ȸ�ⰣTo            
                                @WHSeq          = @WHSeq,       -- â������            
                                @SMWHKind       = 0,            -- â���к� ��ȸ            
                                @CustSeq        = 0,            -- ��Ź�ŷ�ó            
                                @IsTrustCust    = '',           -- ��Ź����            
                                @IsSubDisplay   = '',           -- ���â�� ��ȸ            
                                @IsUnitQry      = '',           -- ������ ��ȸ            
                                @QryType        = 'S'           -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������            
    
    
    DELETE FROM #GetInOutLotStock WHERE StockQty <= 0  -- 0 �̻��� ���� ������������ ����
    
    -- �����û �������� ������ ��� (���൥��������)
    
    SELECT   ROW_NUMBER () OVER(ORDER BY A.OutReqSeq, A.OutReqItemSerl) AS IDX_NO,
            C.WorkCond1     AS LotNo,
            E.CustSeq       AS CustSeq,
            C.WorkOrderSeq,
            C.WorkOrderSerl, 
            A.OutReqSeq,
            A.OutReqItemSerl, 
            A.ItemSeq, 
            C.AssyItemSeq   AS UpperItemSeq, 
            A.Qty
      
      INTO #TPDMMOutReqItem
      FROM _TPDMMOutReqItem             AS A WITH(NOLOCK)
      JOIN #GetInOutLotStock            AS B ON ( A.ItemSeq = B.ItemSeq ) 
      JOIN _TPDSFCWorkOrder             AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND B.LotNo = RTRIM(C.WorkCond1) 
                                                           AND A.WorkOrderSeq = C.WorkOrderSeq AND A.WorkOrderSerl = C.WorkOrderSerl 
                                                             )
      LEFT OUTER JOIN _TPDOSPPOItem     AS D WITH(NOLOCK) ON ( C.CompanySeq = D.CompanySeq AND C.WorkOrderSeq = D.WorkOrderSeq AND C.WorkOrderSerl = D.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDOSPPO         AS E WITH(NOLOCK) ON ( D.CompanySeq = E.CompanySeq AND D.OSPPOSeq = E.OSPPOSeq )       
     WHERE A.CompanySeq = @CompanySeq
    
    -- DELETE, 1 �ŷ�ó�� 2�� �̻� ������� ���� (�ӽ����̺�)
    
    SELECT ItemSeq, LotNo
      INTO #TMP_DupItemSeq
      FROM #TPDMMOutReqItem
    GROUP BY ItemSeq, LotNo
    HAVING MIN(CustSeq) <> MAX(CustSeq)   
    
    DELETE A
      FROM #TPDMMOutReqItem AS A
      JOIN #TMP_DupItemSeq  AS B ON ( A.ItemSeq = B.ItemSeq AND A.LotNo = B.LotNo ) 
    
    -- END, 1 
    
    -- ��������û -> ������� (����)
    
    CREATE TABLE #TMP_ProgressTable 
                 (IDOrder   INT, 
                  TableName NVARCHAR(100)) 

    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
         SELECT 1, '_TPDMMOutItem' 

    CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TPDMMOutReqItem', 
            @TempTableName = '#TPDMMOutReqItem', 
            @TempSeqColumnName = 'OutReqSeq', 
            @TempSerlColumnName = 'OutReqItemSerl', 
            @TempSubSerlColumnName = ''  
    
    -- ��������û -> ������� (����) END,
    
    -- DELETE, 2 �ϳ��� �۾������� 2�� �̻��� �����û�� �ִ� ��� ���� (�ӽ����̺�)
    
    SELECT ItemSeq, LotNo
      INTO #TMP_DupCount
      FROM #TPDMMOutReqItem
    GROUP BY ItemSeq, LotNo
    HAVING MIN(OutReqSeq) <> MAX(OutReqSeq)   
    
    DELETE A
      FROM #TPDMMOutReqItem AS A
      JOIN #TMP_DupCount    AS B ON ( A.ItemSeq = B.ItemSeq AND A.LotNo = B.LotNo ) 
    
    -- END, 2
    
    -- DELETE, 3 ��û������ ��������� ���� ��� ���� (�ӽ����̺�)
    
    SELECT A.IDX_NO, ISNULL(SUM(B.Qty),0) AS Qty, ISNULL(SUM(C.Qty),0) AS ReqQty
      INTO #TMP_SAMEReq
      FROM #TCOMProgressTracking    AS A
      JOIN _TPDMMOUtItem            AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.Seq = B.MatOutSeq AND A.Serl = OutItemSerl ) 
      JOIN #TPDMMOutReqItem         AS C              ON ( C.IDX_NO = A.IDX_NO ) 
     GROUP BY A.IDX_NO 
     HAVING ISNULL(SUM(B.Qty),0) = ISNULL(SUM(C.Qty),0) 

    DELETE A
      FROM #TPDMMOutReqItem AS A
      JOIN #TMP_SAMEReq AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    -- END, 3
        
    -- ������ȸ
    
    SELECT A.LotNo      AS LotNo, 
           C.ItemNo     AS ItemNo, 
           A.StockQty   AS StockQty, 
           C.ItemName   AS ItemName, 
           A.WHSeq      AS WHSeq, 
           A.ItemSeq    AS ItemSeq, 
           D.CustName   AS CustName, 
           B.CustSeq    AS CustSeq, 
           B.OutReqSeq  AS OutReqSeq, 
           B.OutReqItemSerl AS OutReqSerl, 
           B.UpperItemSeq   AS UpperItemSeq
           
      FROM #GetInOutLotStock AS A 
      LEFT OUTER JOIN #TPDMMOutReqItem AS B ON ( B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem         AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDACust         AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq ) 
    
GO
exec yw_SLGLocationStockQuery @CompanySeq = 1, @WHSeq = 1
