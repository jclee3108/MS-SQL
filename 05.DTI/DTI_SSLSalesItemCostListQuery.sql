
IF OBJECT_ID('DTI_SSLSalesItemCostListQuery') IS NOT NULL 
    DROP PROC DTI_SSLSalesItemCostListQuery
GO 

-- v2014.02.10 

-- ����ǰ�������Ȳ(��ȸ) by����õ (����ȣ�߰�)
CREATE PROC DTI_SSLSalesItemCostListQuery          
     @xmlDocument    NVARCHAR(MAX),                
     @xmlFlags       INT     = 0,                
     @ServiceSeq     INT     = 0,                
     @WorkingTag     NVARCHAR(10)= '',                
     @CompanySeq     INT     = 1,                
     @LanguageSeq    INT     = 1,                
     @UserSeq        INT     = 0,                
     @PgmSeq         INT     = 0                
 AS                 
    
    DECLARE @docHandle      INT,                  
            @BizUnit        INT,                   
            @SalesDateFr    NCHAR(8),                   
            @SalesDateTo    NCHAR(8),                 
            @SalesNo        NVARCHAR(20),                    
            @SMExpKind      INT,                 
            @DeptSeq        INT,                   
            @EmpSeq         INT,                   
            @CustSeq        INT,                  
            @CustNo         NVARCHAR(20),                   
            @ItemSeq        INT,                   
            @ItemNo         NVARCHAR(30),                  
            @PJTName        NVARCHAR(100),                  
            @PJTNo          NVARCHAR(100),                
            @AssetSeq       INT,                
            @BillNo         NVARCHAR(20),                
            @InvoiceNo      NVARCHAR(20),            
            @UMItemClassL   INT,            
            @UMItemClassM   INT,            
            @UMItemClassS   INT,            
            @ItemTypeSeq    INT,            
            @ContractNo     NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                   
    
    
    SELECT @BizUnit        = ISNULL(BizUnit, 0),                   
           @SalesDateFr    = ISNULL(SalesDateFr, ''),                   
           @SalesDateTo    = ISNULL(SalesDateTo, ''),                  
           @SalesNo        = LTRIM(RTRIM(ISNULL(SalesNo, ''))),                 
           @SMExpKind      = ISNULL(SMExpKind, 0),                   
           @DeptSeq        = ISNULL(DeptSeq, 0),                   
           @EmpSeq         = ISNULL(EmpSeq, 0),                   
           @ItemSeq        = ISNULL(ItemSeq, 0),                  
           @ItemNo         = LTRIM(RTRIM(ISNULL(ItemNo, ''))),                   
           @CustSeq        = ISNULL(CustSeq, 0),                  
           @CustNo         = LTRIM(RTRIM(ISNULL(CustNo, ''))),                   
           @PJTName        = ISNULL(PJTName, ''),                  
           @PJTNo          = ISNULL(PJTNo, ''),                
           @AssetSeq       = ISNULL(AssetSeq, 0),                
           @BillNo         = ISNULL(BillNo, ''),                
           @InvoiceNo      = ISNULL(InvoiceNo, ''),            
           @UMItemClassL   = ISNULL(UMItemClassL, 0),             
           @UMItemClassM   = ISNULL(UMItemClassM, 0),             
           @UMItemClassS   = ISNULL(UMItemClassS, 0),             
           @ItemTypeSeq    = ISNULL(ItemTypeSeq, 0),              
           @ContractNo     = ISNULL(ContractNo, '') 
    
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                       
     WITH (  BizUnit         INT,                 
             SalesDateFr     NCHAR(8),                 
             SalesDateTo     NCHAR(8),                 
             SalesNo         NVARCHAR(20),                 
             SMExpKind       INT,                   
             DeptSeq         INT,                 
             EmpSeq          INT,                      
             CustSeq         INT,                       
             CustNo          NVARCHAR(20),                 
             ItemSeq         INT,                 
             ItemNo          NVARCHAR(30),                   
             PJTName         NVARCHAR(100),                 
             PJTNo           NVARCHAR(100),                
             AssetSeq        INT,                
             BillNo          NVARCHAR(20),                
             InvoiceNo       NVARCHAR(20),            
             UMItemClassL    INT,            
             UMItemClassM    INT,            
             UMItemClassS    INT,            
             ItemTypeSeq     INT, 
             ContractNo      NVARCHAR(100) 
          )               
    
    IF @SalesDateTo = ''                  
        SELECT @SalesDateTo = '99991231'               
     --=====================================================================================================================              
     -- �������� �˻�              
     --=====================================================================================================================              
 ---------------------- ������ ���� ����  ----------------------                
    DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)                  
    
    IF @SalesDateTo = '99991231'                  
        SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)                  
    ELSE                  
        SELECT  @OrgStdDate = @SalesDateTo                 
    
    SELECT  @SMOrgSortSeq = 0                  
    SELECT  @SMOrgSortSeq = SMOrgSortSeq                  
      FROM  _TCOMOrgLinkMng                  
     WHERE  CompanySeq = @CompanySeq                  
       AND  PgmSeq     = @PgmSeq                  
    
    DECLARE @DeptTable Table                  
    (   DeptSeq     INT)                  
    
    INSERT  @DeptTable                  
    SELECT  DISTINCT DeptSeq                  
      FROM  dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)                  
    
 ---------------------- ������ ���� ���� ----------------------                
    
    CREATE TABLE #Temp_Sales              
    (              
        IDX_NO      INT IDENTITY(1,1),                    
        SalesSeq    INT,                    
        SalesSerl   INT,              
        BillSeq     INT              
     )              
    
    INSERT INTO #Temp_Sales (SalesSeq, SalesSerl, BillSeq)                
    SELECT A.SalesSeq, A.SalesSerl, F.BillSeq                
      FROM _TSLSalesItem AS A WITH (NOLOCK)                
             JOIN _TSLSales AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq                
                                              AND A.SalesSeq = B.SalesSeq                
             LEFT OUTER JOIN _TDACust AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq                
                                                         AND B.CustSeq = C.CustSeq                                                             
                 
             LEFT OUTER JOIN _TDAItem AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq                
                                                         AND A.ItemSeq = D.ItemSeq                
             LEFT OUTER JOIN _TPJTProject AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySeq                
                                                            AND A.PJTSeq = E.PJTSeq                
             LEFT OUTER JOIN _TSLSalesBillRelation AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq                
                                                                    AND A.SalesSeq   = F.SalesSeq                
                                                                    AND A.SalesSerl  = F.SalesSerl                
                             
     WHERE A.CompanySeq = @CompanySeq                
       AND (@BizUnit = 0 OR B.BizUnit = @BizUnit)                  
       AND (B.SalesDate BETWEEN @SalesDateFr AND @SalesDateTo)                  
       AND (@SalesNo = '' OR B.SalesNo LIKE @SalesNo + '%')                  
       AND (@SMExpKind = 0 OR B.SMExpKind = @SMExpKind)                
 ---------- ������ ���� ���� �κ�                    
       AND (@DeptSeq = 0                   
            OR (@SMOrgSortSeq = 0 AND B.DeptSeq = @DeptSeq)                        
            OR (@SMOrgSortSeq > 0 AND B.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))                        
 ---------- ������ ���� ���� �κ�                       
       AND (@EmpSeq = 0 OR B.EmpSeq = @EmpSeq)                  
       AND (@CustSeq = 0 OR B.CustSeq = @CustSeq)                  
       AND (@CustNo = '' OR C.CustNo LIKE @CustNo + '%')                  
       AND (@ItemSeq = 0 OR A.ItemSeq = @ItemSeq)                  
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')                         
       AND (@PJTName = '' OR E.PJTName LIKE @PJTName + '%')          
       AND (@PJTNo   = '' OR E.PJTNo   LIKE @PJTNo   + '%')                     
       AND (@AssetSeq = 0 OR D.AssetSeq = @AssetSeq)                
               
     --=====================================================================================================================              
     -- ���������� �ŷ�����, �������� SourceTracking              
     --=====================================================================================================================              
               
     -- ��� ���̺�              
    CREATE TABLE #TCOMSourceTracking                  
    (                     
         IDX_NO      INT,                  
         IDOrder     INT,                  
         Seq         INT,                 Serl        INT,                  
         SubSerl     INT,                  
         FromQty     DECIMAL(19, 5),                  
         FromAmt     DECIMAL(19, 5) ,                  
         ToQty       DECIMAL(19, 5),                  
         ToAmt       DECIMAL(19, 5)                  
    )                
    
    CREATE TABLE #TMP_SOURCETABLE                   
    (                    
        IDOrder     INT,                    
        TABLENAME   NVARCHAR(100)                    
    )               
    
    INSERT #TMP_SOURCETABLE               
        SELECT '1', '_TSLInvoiceItem'   -- 1. �ŷ�����              
    UNION ALL              
        SELECT '2', '_TSLOrderItem'     -- 2. ����              
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLSalesItem', '#Temp_Sales', 'SalesSeq', 'SalesSerl', ''                   
    
     --=====================================================================================================================              
     -- ���Կ������� �˻�              
     --=====================================================================================================================              
     -- �����԰�              
    CREATE TABLE #TMP_DelvIn              
    (              
        IDX_NO      INT,              
        Seq         INT,              
        Serl        INT,              
        InDate      NCHAR(8),              
        CustSeq     INT,              
        UnitSeq     INT,              
        Price       DECIMAL(19,5),              
        Qty         INT,              
        CurAmt      DECIMAL(19,5),              
        DomAmt      DECIMAL(19,5),              
        STDUnitSeq  INT,              
        STDQty      INT              
    )              
               
    -- ������� �����˻�              
    DECLARE @StartYM    NCHAR(6),              
            @InitYM     NCHAR(6)              
               
    SET @StartYM = CONVERT(CHAR(6), @SalesDateFr)              
    EXEC dbo._SCOMEnv @CompanySeq,1006, @UserSeq, @@PROCID, @StartYM OUTPUT                      
               
    SELECT @InitYM = FrSttlYM FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND @StartYM BETWEEN FrSttlYM AND ToSttlYM                
    
    INSERT INTO #TMP_DelvIn ( IDX_NO, Seq, Serl, InDate, CustSeq, UnitSeq, Price, Qty, CurAmt, DomAmt, STDUnitSeq, STDQty )              
    SELECT A.IDX_NO, 0, 0, '', 0, 0, (C.Amt / NULLIF(C.Qty, 0)) AS Price, C.Qty, C.Amt, C.Amt, 0, 0              
      FROM #Temp_Sales AS AA               
           INNER JOIN _TSLSales AS AB WITH (NOLOCK) ON AB.CompanySeq = @CompanySeq AND AB.SalesSeq = AA.SalesSeq              
           INNER JOIN _TSLSalesItem AS AC WITH (NOLOCK) ON AC.CompanySeq = @CompanySeq AND AC.SalesSeq = AA.SalesSeq AND AC.SalesSerl = AA.SalesSerl              
           INNER JOIN #TCOMSourceTracking AS A ON A.IDX_NO = AA.IDX_NO AND A.IDOrder = '1' AND  AC.DomAmt * A.FromAmt >= 0     -- �ŷ�����      
           INNER JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl              
           INNER JOIN _TESMGMonthlyLotStockAmt AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.LotNo = B.LotNo AND C.ItemSeq = B.ItemSeq AND C.InOutKind = 8023000              
           INNER JOIN _TESMDCostKey AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.SMCostMng = 5512001 AND D.CostYM = @InitYM AND D.CostKeySeq = C.CostKeySeq              
     WHERE A.IDOrder = '1' 
    
     -- �����԰� �����˻�              
    INSERT INTO #TMP_DelvIn ( IDX_NO, Seq, Serl, InDate, CustSeq, UnitSeq, Price, Qty, CurAmt, DomAmt, STDUnitSeq, STDQty )              
    SELECT A.IDX_NO, C.DelvInSeq, C.DelvInSerl, D.DelvInDate, D.CustSeq, C.UnitSeq, C.DomPrice, C.Qty, C.CurAmt, C.DomAmt, C.StdUnitSeq, C.StdUnitQty --             
      FROM #Temp_Sales AS AA               
           INNER JOIN _TSLSales AS AB WITH (NOLOCK) ON AB.CompanySeq = @CompanySeq AND AB.SalesSeq = AA.SalesSeq              
           INNER JOIN _TSLSalesItem AS AC WITH (NOLOCK) ON AC.CompanySeq = @CompanySeq AND AC.SalesSeq = AA.SalesSeq AND AC.SalesSerl = AA.SalesSerl              
           
                 --INNER JOIN #TCOMSourceTracking AS A ON A.IDX_NO = AA.IDX_NO AND A.IDOrder = '1' AND  AC.DomAmt * A.FromAmt >= 0     -- �ŷ�����      
                 JOIN ( SELECT A.*   
                 FROM #TCOMSourceTracking AS A   
                 JOIN ( SELECT IDX_NO, MAX(Seq) AS Seq FROM #TCOMSourceTracking GROUP BY IDX_NO ) AS B ON ( A.IDX_NO = B.IDX_NO AND A.Seq = B.Seq )  
             ) AS A ON A.IDX_NO = AA.IDX_NO    
                   
         INNER JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl              
         INNER JOIN _TPUDelvInItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.LotNo = B.LotNo AND C.ItemSeq = B.ItemSeq              
         INNER JOIN _TPUDelvIn AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DelvInSeq = C.DelvInSeq              
     WHERE A.IDOrder = '1'              
       AND NOT EXISTS (SELECT 1 FROM #TMP_DelvIn WHERE IDX_NO = A.IDX_NO)              
            
            
            
      INSERT INTO #TMP_DelvIn ( IDX_NO, Seq, Serl, InDate, CustSeq, UnitSeq, Price, Qty, CurAmt, DomAmt, STDUnitSeq, STDQty )              
     SELECT              
         A.IDX_NO, C.DelvSeq, C.DelvSerl, D.DelvDate, D.CustSeq, C.UnitSeq,        
          CASE WHEN ISNULL(C.Qty, 0) = 0 THEN 0 ELSE (C.DomAmt / C.Qty) END,--C.Price,         
          C.Qty, C.OKCurAmt, C.OKDomAmt, C.StdUnitSeq, C.STDQty              
     FROM #Temp_Sales AS AA               
                 INNER JOIN _TSLSales AS AB WITH (NOLOCK) ON AB.CompanySeq = @CompanySeq AND AB.SalesSeq = AA.SalesSeq              
                 INNER JOIN _TSLSalesItem AS AC WITH (NOLOCK) ON AC.CompanySeq = @CompanySeq AND AC.SalesSeq = AA.SalesSeq AND AC.SalesSerl = AA.SalesSerl              
                   
                 --INNER JOIN #TCOMSourceTracking AS A ON A.IDX_NO = AA.IDX_NO AND A.IDOrder = '1' AND  AC.DomAmt * A.FromAmt >= 0     -- �ŷ�����      
               JOIN ( SELECT A.*   
                 FROM #TCOMSourceTracking AS A   
                 JOIN ( SELECT IDX_NO, MAX(Seq) AS Seq FROM #TCOMSourceTracking GROUP BY IDX_NO ) AS B ON ( A.IDX_NO = B.IDX_NO AND A.Seq = B.Seq )  
             ) AS A ON A.IDX_NO = AA.IDX_NO    
                   
         INNER JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl              
         INNER JOIN _TUIImpDelvItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.LotNo = B.LotNo AND C.ItemSeq = B.ItemSeq              
         INNER JOIN _TUIImpDelv AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DelvSeq = C.DelvSeq              
     WHERE A.IDOrder = '1'              
       AND NOT EXISTS (SELECT 1 FROM #TMP_DelvIn WHERE IDX_NO = A.IDX_NO)                
       --select * from #TMP_DelvIn            
     --=====================================================================================================================              
     -- ������ �����м���Ȳ �˻�              
     --=====================================================================================================================              
 SELECT              
         A.*,              
         (CASE WHEN A.TmpOrderGPRate < -100 THEN -100 WHEN A.TmpOrderGPRate > 100 THEN 100 ELSE A.TmpOrderGPRate END) AS OrderGPRate,    -- ����GP              
         (CASE WHEN A.TmpInvGPRate < -100 THEN -100 WHEN A.TmpInvGPRate > 100 THEN 100 ELSE A.TmpInvGPRate END) AS InvGPRate,            -- �ŷ�����GP              
         (CASE WHEN A.TmpSalesGPRate < -100 THEN -100 WHEN A.TmpSalesGPRate > 100 THEN 100 ELSE A.TmpSalesGPRate END) AS SalesGPRate     -- ����GP              
     FROM              
     (              
         SELECT              
             A.*,              
             B.ItemNo        AS ItemNo,          -- ǰ���ȣ              
             B.ItemName      AS ItemName,        -- ǰ���              
             B.Spec          AS Spec,            -- �԰�              
           C.AssetName     AS AssetName,       -- ǰ���ڻ�з�              
             J.SlipID        AS SlipID,          -- ��ǥ��ȣ              
             D.CustName      AS CustName,        -- ����ó��              
             D.CustNo        AS CustNo,          -- ����ó��ȣ   OrderInAmtGPCal   InvoiceInAmtGPCal   SalesInAmtGPCal      
             (ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmtGPCal, 0)) AS OrderGP,     -- ����GP              
                 (CASE WHEN (ISNULL(A.OrderDomAmt, 0) = ISNULL(A.OrderInAmtGPCal, 0)) THEN 0               
                       WHEN ISNULL(A.OrderDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.OrderInAmtGPCal, 0)) * 100, 2)               
                       ELSE ISNULL(ROUND((ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmtGPCal, 0)) / NULLIF(A.OrderDomAmt, 0) * 100, 2), 0) END) AS TmpOrderGPRate,              
             (ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmtGPCal, 0)) AS InvGP,     -- �ŷ�����GP              
               (CASE WHEN (ISNULL(A.InvDomAmt, 0) = ISNULL(A.InvoiceInAmtGPCal, 0)) THEN 0               
                       WHEN ISNULL(A.InvDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.InvoiceInAmtGPCal, 0)) * 100, 2)               
                       ELSE ISNULL(ROUND((ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmtGPCal, 0)) / NULLIF(A.InvDomAmt, 0) * 100, 2), 0) END) AS TmpInvGPRate,              
             (ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmtGPCal, 0)) AS SalesGP,     -- ����GP = ��ȭ�Ǹűݾ� - ���Կ���_����ݾ�          
                 (CASE WHEN (ISNULL(A.DomAmt, 0) = ISNULL(A.SalesInAmtGPCal, 0)) THEN 0               
                       WHEN ISNULL(A.DomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.SalesInAmtGPCal, 0)) * 100, 2)               
                       ELSE ISNULL(ROUND((ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmtGPCal, 0)) / NULLIF(A.DomAmt, 0) * 100, 2), 0) END) AS TmpSalesGPRate,              
               --(ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmt, 0)) AS OrderGP,     -- ����GP              
             --    (CASE WHEN (ISNULL(A.OrderDomAmt, 0) = ISNULL(A.OrderInAmt, 0)) THEN 0               
             --          WHEN ISNULL(A.OrderDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.OrderInAmt, 0)) * 100, 2)               
             --          ELSE ISNULL(ROUND((ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmt, 0)) / NULLIF(A.OrderDomAmt, 0) * 100, 2), 0) END) AS TmpOrderGPRate,              
             --(ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmt, 0)) AS InvGP,     -- �ŷ�����GP              
             --  (CASE WHEN (ISNULL(A.InvDomAmt, 0) = ISNULL(A.InvoiceInAmt, 0)) THEN 0               
             --          WHEN ISNULL(A.InvDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.InvoiceInAmt, 0)) * 100, 2)               
             --          ELSE ISNULL(ROUND((ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmt, 0)) / NULLIF(A.InvDomAmt, 0) * 100, 2), 0) END) AS TmpInvGPRate,              
             --(ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmt, 0)) AS SalesGP,     -- ����GP = ��ȭ�Ǹűݾ� - ���Կ���_����ݾ�          
             --    (CASE WHEN (ISNULL(A.DomAmt, 0) = ISNULL(A.SalesInAmt, 0)) THEN 0               
             --          WHEN ISNULL(A.DomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.SalesInAmt, 0)) * 100, 2)               
             --          ELSE ISNULL(ROUND((ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmt, 0)) / NULLIF(A.DomAmt, 0) * 100, 2), 0) END) AS TmpSalesGPRate,              
             (CASE WHEN A.TmpOrderSalesGPRate < -100 THEN -100 WHEN A.TmpOrderSalesGPRate > 100 THEN 100 ELSE A.TmpOrderSalesGPRate END) AS OrderSalesGPRate,    -- ����GP              
             (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,-- ����ι���              
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,         -- ���źμ���              
             (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,              -- ���Ŵ���ڸ�              
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.InvDeptSeq) AS InvDeptName,   -- �ŷ������μ���              
             (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.InvEmpSeq) AS InvEmpName,        -- �ŷ���������ڸ�              
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.InvCustSeq) AS InvCustName,   -- �ŷ���������ó              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq) AS UnitName,         -- �ǸŴ�����              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.STDUnitSeq) AS STDUnitName,   -- ���ֱ��ش�����              
             (SELECT WHName FROM _TDAWH WHERE CompanySeq = @CompanySeq AND WHSeq = A.WHSeq) AS WHName,                   -- â���              
             (SELECT AccName FROM _TDAAccount WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.AccSeq) AS AccName,     -- �������              
             (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMExpKind) AS SMExpKindName,      -- ���ⱸ�и�                
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.OrderUnitSeq) AS OrderUnitName,       -- �����ǸŴ�����              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.OrderSTDUnitSeq) AS OrderSTDUnitName, -- ���ֱ��ش�����              
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.InCustSeq) AS InCustName,             -- ���԰ŷ�ó              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InUnitSeq) AS InUnitName,             -- �����ǸŴ�����              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InSTDUnitSeq) AS InSTDUnitName,       -- ���Ա��ش�����              
               (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InvUnitSeq) AS InvUnitName,             -- �ŷ������ǸŴ�����              
           (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InvSTDUnitSeq) AS InvSTDUnitName,        -- �ŷ��������ش�����            
              CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')               
                                                                FROM _TDAUMinor WITH(NOLOCK)               
                                                               WHERE CompanySeq = @CompanySeq               
                                                                 AND MinorSeq = L.ValueSeq) END AS ItemClassLName,              
              CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')               
                                                                FROM _TDAUMinor WITH(NOLOCK)               
                                                               WHERE CompanySeq = @CompanySeq               
                                                                 AND MinorSeq = K.ValueSeq) END AS ItemClassMName,              
             ISNULL(H.MinorName,'') AS ItemClassSName, -- ǰ��Һз�              
             ISNULL(Y.MinorName, '') AS ItemType--  ����ǰ��������               
         FROM            
         (              
             SELECT              
                 A.SalesSeq          AS SalesSeq,        -- ���⳻���ڵ�              
                 A.SalesSerl         AS SalesSerl,       -- ���⳻�μ���              
                 B.BizUnit           AS BizUnit,         -- ����ι�              
                 B.SalesDate         AS SalesDate,       -- ������              
                 B.SalesNo           AS SalesNo,         -- �����ȣ               
                 B.SMExpKind         AS SMExpKind,       -- ���ⱸ��              
                 B.DeptSeq           AS DeptSeq,         -- �μ�              
                 B.EmpSeq            AS EmpSeq,          -- �����              
                 B.CustSeq           AS CustSeq,         -- �ŷ�ó              
                 EI.LotNo            AS LotNo,           -- Lot NO              
                 C.ItemSeq           AS ItemSeq,         -- ǰ���ڵ�              
                 C.UnitSeq           AS UnitSeq,         -- �ǸŴ���              
                 C.ItemPrice         AS ItemPrice,       -- ǰ��ܰ�              
                 C.CustPrice         AS CustPrice,       -- ȸ��ܰ�              
                 (C.DomAmt / NULLIF(C.Qty, 0))  AS Price,-- �ǸŴܰ�              
                 C.Qty               AS Qty,             -- ����              
                 C.IsInclusedVAT     AS IsInclusedVAT,   -- �ΰ������Կ���              
                 C.VATRate           AS VATRate,         -- �ΰ�����              
                 C.CurAmt            AS CurAmt,          -- �Ǹűݾ�              
                 C.CurVAT            AS CurVAT,          -- �ΰ�����              
                 C.DomAmt            AS DomAmt,          -- ��ȭ�Ǹűݾ�              
                 C.DomVAT            AS DomVAT,          -- ��ȭ�ΰ�����              
                 C.STDUnitSeq        AS STDUnitSeq,      -- ���ش���              
                 C.STDQty            AS STDQty,          -- ���ش�������              
                 C.WHSeq             AS WHSeq,           -- â���ڵ�              
                 C.Remark            AS Remark,          -- ���              
                 C.AccSeq            AS AccSeq,          -- �������              
                 G.OrderSeq          AS OrderSeq,        -- ���ֳ����ڵ�              
                 G.OrderSerl         AS OrderSerl,       -- ���ֳ��μ���              
                 G.UnitSeq           AS OrderUnitSeq,        -- �����ǸŴ���              
                 G.ItemPrice         AS OrderItemPrice,      -- ����ǰ��ܰ�              
                 G.CustPrice         AS OrderCustPrice,      -- ����ȸ��ܰ�              
                   (G.DomAmt / G.Qty)  AS OrderPrice,          -- �����ǸŴܰ�              
                 G.Qty               AS OrderQty,            -- ���ּ���              
                 G.IsInclusedVAT     AS OrderIsInclusedVAT,  -- ���ֺΰ������Կ���              
                 G.VATRate           AS OrderVATRate,        -- ���ֺΰ�����              
                 G.CurAmt            AS OrderCurAmt,         -- �����Ǹűݾ�              
                 G.CurVAT            AS OrderCurVAT,         -- ���ֺΰ�����              
                 G.DomAmt            AS OrderDomAmt,         -- ���ֿ�ȭ�Ǹűݾ� **************************                
                 G.DomVAT            AS OrderDomVAT,         -- ���ֿ�ȭ�ΰ�����              
                 G.STDUnitSeq        AS OrderSTDUnitSeq,     -- ���ֱ��ش���              
                 G.STDQty            AS OrderSTDQty,         -- ���ֱ��ش�������              
                 E.InvoiceSeq        AS InvoiceSeq,      -- �ŷ����������ڵ�              
                 E.InvoiceNo         AS InvoiceNo,       -- �ŷ�������ȣ              
                 E.DeptSeq           AS InvDeptSeq,      -- �ŷ��������μ�              
                 E.EmpSeq            AS InvEmpSeq,       -- �ŷ����������              
                 E.CustSeq           AS InvCustSeq,      -- �ŷ������ŷ�ó              
                 EI.InvoiceSerl      AS InvoiceSerl,                
                 EI.UnitSeq          AS InvUnitSeq,          -- �ŷ����� �ǸŴ���              
                 EI.ItemPrice        AS InvItemPrice,        -- �ŷ����� ǰ��ܰ�              
                 EI.CustPrice        AS InvCustPrice,        -- �ŷ����� ȸ��ܰ�              
                 (EI.DomAmt / EI.Qty) AS InvPrice,           -- �ŷ����� �ǸŴܰ�              
                 EI.Qty              AS InvQty,              -- �ŷ����� ����              
                 EI.IsInclusedVAT    AS InvIsInclusedVAT,    -- �ŷ����� �ΰ������Կ���              
                 EI.VATRate          AS InvVATRate,          -- �ŷ����� �ΰ�����              
                 EI.CurAmt           AS InvCurAmt,           -- �ŷ����� �Ǹűݾ�              
                 EI.CurVAT           AS InvCurVAT,           -- �ŷ����� �ΰ�����              
                 EI.DomAmt           AS InvDomAmt,           -- �ŷ����� ��ȭ�Ǹűݾ� **************************             
                 EI.DomVAT           AS InvDomVAT,           -- �ŷ����� ��ȭ�ΰ�����              
                 EI.STDUnitSeq       AS InvSTDUnitSeq,       -- �ŷ����� ���ش���              
                 EI.STDQty           AS InvSTDQty,           -- �ŷ����� ���ش�������              
                 I.BillSeq           AS BillSeq,             -- ���ݰ�꼭�����ڵ�              
                 I.BillNo            AS BillNo,              -- ���ݰ�꼭��ȣ              
                 J.InDate            AS InDate,              -- ��������              
                 J.CustSeq           AS InCustSeq,           -- ���԰ŷ�ó              
                 J.UnitSeq           AS InUnitSeq,           -- ���Դ���              
                 J.Price             AS InPrice,             -- ���Կ���              
                 J.Qty               AS InQty,               -- ���Լ���              
                 J.CurAmt            AS InCurAmt,            -- ���Կ����ݾ�              
                 J.DomAmt            AS InDomAmt,            -- ���Կ�ȭ�ݾ�              
                 J.STDUnitSeq        AS InSTDUnitSeq,        -- ���Ա��ش���              
                 J.STDQty            AS InSTDQty,            -- ���Ա��ش�������              
                 J.Price             AS LOTPrice,       
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty)* G.Qty) END  AS OrderInAmtGPCal,          -- ���Կ���           
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * EI.Qty) END  AS InvoiceInAmtGPCal,        -- ���Կ���      
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * C.Qty) END  AS SalesInAmtGPCal,           -- ���Կ���      
                   
                 -- ���԰ǿ� ���Ͽ� J.Price �� �����԰�ܰ��̰� �����԰�����ܰ��� �ƴϱ⿡ ���̰� �߻� ��   
                 -- �����԰���� = �԰�ݾ� + ���  
                   --(J.Price * G.Qty)   AS OrderInAmt,          -- ���Կ���_���ֱݾ�  **************************            
                 --(J.Price * EI.Qty)  AS InvoiceInAmt,        -- ���Կ���_�ŷ������ݾ�     **************************         
                 --(J.Price * C.Qty)  AS SalesInAmt,          -- ���Կ���_����ݾ�      **************************        
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty)* G.Qty) END  AS OrderInAmt,          -- ���Կ���           
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * EI.Qty) END  AS InvoiceInAmt,        -- ���Կ���      
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * C.Qty) END  AS SalesInAmt,           -- ���Կ���      
                   
                 (CASE WHEN B.SlipSeq = 0 THEN I.SlipSeq ELSE B.SlipSeq END) AS SlipSeq,     -- ��ǥ�ڵ�              
                 (ISNULL(G.DomAmt, 0) - ISNULL(C.DomAmt, 0)) AS OrderSalesGP,     -- ����-����GP              
                     (CASE WHEN (ISNULL(G.DomAmt, 0) = ISNULL(C.DomAmt, 0)) THEN 0               
                           WHEN ISNULL(G.DomAmt, 0) = 0 THEN ROUND((0 - ISNULL(C.DomAmt, 0)) * 100, 2)               
                           ELSE ISNULL(ROUND((ISNULL(G.DomAmt, 0) - ISNULL(C.DomAmt, 0)) / NULLIF(G.DomAmt, 0) * 100, 2), 0) END) AS TmpOrderSalesGPRate,                   
                 K.ContractNo 
             FROM #Temp_Sales AS A               
                 INNER JOIN _TSLSales AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq              
                 INNER JOIN _TSLSalesItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.SalesSeq = A.SalesSeq AND C.SalesSerl = A.SalesSerl              
                   
                 --LEFT OUTER JOIN #TCOMSourceTracking AS D ON D.IDX_NO = A.IDX_NO AND D.IDOrder = '1'  AND  C.DomAmt * D.FromAmt >= 0     -- �ŷ�����              
                 LEFT OUTER JOIN ( SELECT A.*   
                            FROM #TCOMSourceTracking AS A   
                            JOIN ( SELECT IDX_NO, MAX(Seq) AS Seq FROM #TCOMSourceTracking GROUP BY IDX_NO ) AS B ON ( A.IDX_NO = B.IDX_NO AND A.Seq = B.Seq )  
                           ) AS D ON A.IDX_NO = D.IDX_NO    
                   
                 LEFT OUTER JOIN _TSLInvoice AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.InvoiceSeq = D.Seq              
                 LEFT OUTER JOIN _TSLInvoiceItem AS EI WITH (NOLOCK) ON EI.CompanySeq = @CompanySeq AND EI.InvoiceSeq = D.Seq AND EI.InvoiceSerl = D.Serl             
                 LEFT OUTER JOIN #TCOMSourceTracking AS F ON F.IDX_NO = A.IDX_NO AND F.IDOrder = '2'    -- ����              
                 LEFT OUTER JOIN _TSLOrderItem AS G WITH (NOLOCK) ON G.CompanySeq = @CompanySeq AND G.OrderSeq = F.Seq AND G.OrderSerl = F.Serl              
                 LEFT OUTER JOIN _TSLBill AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.BillSeq = A.BillSeq              
                 LEFT OUTER JOIN #TMP_DelvIn AS J ON J.IDX_NO = D.IDX_NO 
                 LEFT OUTER JOIN DTI_TSLContractMngItem AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.ContractSeq = CONVERT(INT,G.Dummy6) AND H.ContractSerl = CONVERT(INT,G.Dummy7) ) 
                 LEFT OUTER JOIN DTI_TSLContractMng     AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.ContractSeq = H.ContractSeq ) 
             WHERE (@InvoiceNo = '' OR E.InvoiceNo LIKE @InvoiceNo + '%')              
               AND (@BillNo = '' OR I.BillNo LIKE @BillNo + '%')     AND C.DomAmt * EI.DomAmt >= 0 
               AND (@ContractNo = '' OR K.ContractNo LIKE @ContractNo +'%') 
         ) AS A              
             LEFT OUTER JOIN _TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq              
             LEFT OUTER JOIN _TDAItemAsset AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq              
             LEFT OUTER JOIN _TDACust AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq              
             LEFT OUTER JOIN _TACSlipRow AS J WITH (NOLOCK) ON J.CompanySeq = @CompanySeq AND J.SlipSeq = A.SlipSeq            
             LEFT OUTER JOIN _TDAItemClass AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq            
                                                           AND A.ItemSeq    = O.ItemSeq              
                                                             AND O.UMajorItemClass IN (2001,2004)             
            LEFT OUTER JOIN _TDAUMinor AS H WITH(NOLOCK)    ON H.CompanySeq  = @CompanySeq     -- ǰ��Һз�          
                                                           AND O.UMItemClass = H.MinorSeq               
            LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON K.CompanySeq  = @CompanySeq --ǰ���ߺз�             
                                                             AND H.MinorSeq   = K.MinorSeq               
                                                             AND K.Serl = (CASE O.UMajorItemClass WHEN 2001 THEN 1001 ELSE 2001 END)         
                                                             --AND K.MajorSeq IN (2001,2004)              
            LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON L.CompanySeq  = @CompanySeq   --ǰ���з�            
                                                             AND K.ValueSeq   = L.MinorSeq               
                                                             AND L.MajorSeq IN (2002,2005)              
            LEFT OUTER JOIN _TDAItemClass AS Z WITH(NOLOCK) ON Z.CompanySeq  = @CompanySeq              
                                                           AND A.ItemSeq    = Z.ItemSeq  --����ǰ��������            
                                                           AND Z.UMajorItemClass = 1000203             
            LEFT OUTER JOIN _TDAUMinor AS Y WITH(NOLOCK)    ON Y.CompanySeq  = @CompanySeq              
                                                           AND Z.UMItemClass = Y.MinorSeq            
             WHERE (@UMItemClassL = 0 OR L.ValueSeq = @UMItemClassL)            
               AND (@UMItemClassM = 0 OR K.ValueSeq = @UMItemClassM)            
               AND (@UMItemClassS = 0 OR O.UMItemClass = @UMItemClassS)            
               AND (@ItemTypeSeq  = 0 OR Z.UMItemClass = @ItemTypeSeq)            
     ) AS A            
     ORDER BY A.SalesSeq, A.SalesSerl              
     --=====================================================================================================================              
     -- �ӽ����̺� ����               
     --=====================================================================================================================       
  --SELECT              
  --              C.DomAmt , D.FromAmt, C.DomAmt * D.FromAmt, *              
  --           FROM #Temp_Sales AS A               
  --               INNER JOIN _TSLSales AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq              
  --               INNER JOIN _TSLSalesItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.SalesSeq = A.SalesSeq AND C.SalesSerl = A.SalesSerl              
  --               INNER JOIN #TCOMSourceTracking AS D ON D.IDX_NO = A.IDX_NO AND D.IDOrder = '1' AND  C.DomAmt * D.FromAmt >= 0     -- �ŷ�����              
  --               LEFT OUTER JOIN _TSLInvoice AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.InvoiceSeq = D.Seq              
  --               LEFT OUTER JOIN _TSLInvoiceItem AS EI WITH (NOLOCK) ON EI.CompanySeq = @CompanySeq AND EI.InvoiceSeq = D.Seq AND EI.InvoiceSerl = D.Serl             
  --               LEFT OUTER JOIN #TCOMSourceTracking AS F ON F.IDX_NO = A.IDX_NO AND F.IDOrder = '2'    -- ����              
  --               LEFT OUTER JOIN _TSLOrderItem AS G WITH (NOLOCK) ON G.CompanySeq = @CompanySeq AND G.OrderSeq = F.Seq AND G.OrderSerl = F.Serl              
  --               LEFT OUTER JOIN _TSLBill AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.BillSeq = A.BillSeq              
  --               LEFT OUTER JOIN #TMP_DelvIn AS J ON J.IDX_NO = D.IDX_NO              
  --           WHERE (@InvoiceNo = '' OR E.InvoiceNo LIKE @InvoiceNo + '%')              
  --             AND (@BillNo = '' OR I.BillNo LIKE @BillNo + '%')         
                   
  --             select * from #TMP_DelvIn    
  --             select * from #TCOMSourceTracking where IDOrder = '1'     
    --             select * from #TCOMSourceTracking where IDOrder = '2'     
     --DROP TABLE #Temp_Sales              
     --DROP TABLE #TMP_DelvIn              
     --DROP TABLE #TMP_SOURCETABLE              
     --DROP TABLE #TCOMSourceTracking                  
      
    RETURN         