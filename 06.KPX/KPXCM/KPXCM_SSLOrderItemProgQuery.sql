IF OBJECT_ID('KPXCM_SSLOrderItemProgQuery') IS NOT NULL
    DROP PROC KPXCM_SSLOrderItemProgQuery
GO 

-- v2015.10.29 

-- KPXCM �� by����õ 

-- Ver.20140630
  /*********************************************************************************************************************  
     ȭ��� : ����ǰ��������Ȳ  
     SP Name: KPXCM_SSLOrderItemProgQuery  
     �ۼ��� : 2008.09.25 : CREATEd by ������      
     ������ : 2013.04.25 : UPDATE BY ��³� :: ��ǰ �������(�ŷ������� ���࿩��) ��ȸ���� �߰�   
 ********************************************************************************************************************/  
 CREATE PROC KPXCM_SSLOrderItemProgQuery    
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.  
     @WorkingTag     NVARCHAR(10) = '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS         
     DECLARE @docHandle      INT,  
             @BizUnit        INT,   
             @OrderDateFr    NCHAR(8),   
             @OrderDateTo    NCHAR(8),   
             @DVDateFr       NCHAR(8),   
             @DVDateTo       NCHAR(8),   
             @UMOrderKind    INT,   
             @OrderNo        NVARCHAR(100),  
             @DeptSeq        INT,   
             @EmpSeq         INT,   
             @CustSeq        INT,  
             @PoNo           NVARCHAR(100),   
             @ItemSeq        INT,   
             @ItemNo         NVARCHAR(100),   
             @ModelName      NVARCHAR(100),  
             @WHSeq          INT,  
             @SMProgressType      INT,
             @Seq            INT,
             @OrderSeq       INT,
             @OrderSerl      INT,
             @SubSeq         INT, 
             @SpecName       NVARCHAR(200), 
             @SpecValue      NVARCHAR(200),
             @a              INT,
             @SMInCompleteType INT,
             @Spec              NVARCHAR(200), 
             @CustNoFr          NVARCHAR(200), 
             @CustNoTo          NVARCHAR(200), 
             @ItemSName         NVARCHAR(200), 
             @CustUseFlag       INT, 
             @UMUseTypeDetail   INT, 
             @SLDeptSeq         INT, 
             @AssetSeq          INT, 
             @MultiCustUseFlag NVARCHAR(MAX),  
             @MultiSLDeptSeq NVARCHAR(MAX),  
             @MultiAssetSeq NVARCHAR(MAX)
    
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
   
     -- Temp�� INSERT      
     SELECT  @BizUnit        = ISNULL(BizUnit, 0),   
             @OrderDateFr    = ISNULL(OrderDateFr, ''),   
             @OrderDateTo    = ISNULL(OrderDateTo, ''),   
             @DVDateFr       = ISNULL(DVDateFr, ''),   
             @DVDateTo       = ISNULL(DVDateTo, ''),   
             @UMOrderKind    = ISNULL(UMOrderKind, 0),   
             @OrderNo        = LTRIM(RTRIM(ISNULL(OrderNo, ''))),  
             @DeptSeq        = ISNULL(DeptSeq, 0),   
             @EmpSeq         = ISNULL(EmpSeq, 0),   
             @CustSeq        = ISNULL(CustSeq, 0),  
             @ItemSeq        = ISNULL(ItemSeq, 0),  
             @ItemNo         = LTRIM(RTRIM(ISNULL(ItemNo, ''))),   
             @PoNo           = LTRIM(RTRIM(ISNULL(PONo, ''))),   
             @ModelName      = LTRIM(RTRIM(ISNULL(ModelName, ''))),  
             @WHSeq          = ISNULL(WHSeq , 0),  
             @SMProgressType      = ISNULL(SMProgressType, 0),
             @SMInCompleteType    = ISNULL(SMInCompleteType, 0),
             @Spec           = ISNULL(Spec, ''), 
             @CustNoFr        = ISNULL(CustNoFr       ,''), 
             @CustNoTo        = ISNULL(CustNoTo       ,''), 
             @ItemSName       = ISNULL(ItemSName      ,''), 
             @CustUseFlag     = ISNULL(CustUseFlag    ,0), 
             @UMUseTypeDetail = ISNULL(UMUseTypeDetail,0),
             @SLDeptSeq       = ISNULL(SLDeptSeq      ,0),
             @AssetSeq        = ISNULL(AssetSeq       ,0), 
             @MultiCustUseFlag = ISNULL(MultiCustUseFlag,''),  
             @MultiSLDeptSeq = ISNULL(MultiSLDeptSeq,''),  
             @MultiAssetSeq = ISNULL(MultiAssetSeq,'') 
             
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
     WITH (
            BizUnit INT, 
            OrderDateFr NCHAR(8), 
            OrderDateTo NCHAR(8), 
            UMOrderKind INT,     
            OrderNo NVARCHAR(100),   
            DeptSeq INT, 
            DVDateFr    NCHAR(8), 
            DVDateTo    NCHAR(8), 
            EmpSeq      INT,     
            CustSeq INT,     
            ItemSeq INT, 
            ItemNo  NVARCHAR(100), 
            WHSeq       INT,      
            PONo NVARCHAR(100),   
            SMProgressType INT,   
            ModelName NVARCHAR(100),
            SMInCompleteType INT, 
            Spec NVARCHAR(200), 
            CustNoFr          NVARCHAR(200),
            CustNoTo          NVARCHAR(200),
            ItemSName         NVARCHAR(200),
            CustUseFlag       INT, 
            UMUseTypeDetail   INT, 
            SLDeptSeq         INT, 
            AssetSeq          INT, 
            MultiCustUseFlag NVARCHAR(MAX),  
            MultiSLDeptSeq   NVARCHAR(MAX),  
            MultiAssetSeq    NVARCHAR(MAX) 
          )    
    
    
    IF @OrderDateTo = ''  
        SELECT @OrderDateTo = '99991231'  
    IF @OrderDateTo = ''   
        SELECT @OrderDateTo = '99991231'    
   
 /***********************************************************************************************************************************************/  
 --_SCOMProgressTracking  
 --_SCOMSourceTracking  
  ---------------------- ������ ���� ����  
     DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)  
   
     IF @OrderDateTo = '99991231'  
         SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)  
     ELSE  
         SELECT  @OrgStdDate = @OrderDateTo  
   
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
   
 ---------------------- ������ ���� ����  
     
     -- ����üũ�� ���̺� ���̺�  
     CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))  
     
    -- ����üũ�� ������ ���̺�  
    CREATE TABLE #Temp_Order
    ( 
        IDX_NO          INT IDENTITY, 
        OrderSeq        INT, 
        OrderSerl       INT, 
        OrderSubSerl    INT, 
        CompleteCHECK   INT, 
        SMProgressType  INT NULL, 
        IsStop          NCHAR(1), 
        UMUseTypeDetail INT, 
        UMUseTypeDetailName NVARCHAR(100), 
        CustUseFlag       INT, 
        CustUseFlagName   NVARCHAR(100), 
        AssetSeq        INT, 
        AssetName       NVARCHAR(100), 
        SLDeptSeq       INT, 
        SLDeptName      NVARCHAR(100), 
        CustNo          NVARCHAR(100), 
        ItemSName       NVARCHAR(100) 
    )  
    
    -- ����� ���� ���̺� : _SCOMProgressTracking ���� ���  
    CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,  
                                       Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))      
    -- ����� ������ ���η� �����ִ� ���̺�  
    CREATE TABLE #OrderTracking(IDX_NO INT,  
                                DVReqQty   DECIMAL(19,5), DVReqAmt   DECIMAL(19,5),   
                                InvoiceQty DECIMAL(19,5), InvoiceAmt DECIMAL(19,5),   
                                POReqQty   DECIMAL(19,5), POReqAmt   DECIMAL(19,5),   
                                SalesQty   DECIMAL(19,5), SalesAmt   DECIMAL(19,5), 
                                ProdReqQty DECIMAL(19,5), ProdReqAmt DECIMAL(19,5), 
                                DelvInQty  DECIMAL(19,5), DelvInAmt  DECIMAL(19,5),
                                ProdQty    DECIMAL(19,5),   ProdAmt    DECIMAL(19,5),
                                OSPInQty   DECIMAL(19,5),   OSPInAmt    DECIMAL(19,5),
                                )  
    INSERT #TMP_PROGRESSTABLE   
    SELECT 1, '_TSLDVReqItem'    --�����Ƿ�
    UNION    
    SELECT 2, '_TSLInvoiceItem'   --�ŷ�����
    UNION  
    SELECT 3, '_TPUORDPOReqItem'  --���ſ�û
    UNION   
    SELECT 4, '_TSLSalesItem'  --����
    UNION
    SELECT 5, '_TPDMPSProdReqItem'--�����Ƿ�
    UNION  
    SELECT 6, '_TPUDelvInItem' -- �����԰�
    UNION  
    SELECT 7, '_TPDSFCWorkReport' -- �������
    UNION  
    SELECT 8, '_TUIImpDelvItem' -- �����԰�
    UNION  
    SELECT 9, '_TPDOSPDelvInItem' -- �����԰�
    
    INSERT INTO #Temp_Order
    ( 
        OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, IsStop,
        UMUseTypeDetail, UMUseTypeDetailName, CustUseFlag, CustUseFlagName, AssetSeq, 
        AssetName, SLDeptSeq, SLDeptName, CustNo, ItemSName
    )  
    SELECT A.OrderSeq, B.OrderSerl, B.OrderSubSerl, -1, B.IsStop,  -- A.IsStop -> B.IsStop 20130310 �ڼ�ȣ
           U.UMUseTypeDetail, G.MinorName, T.UMUseType, H.MinorName, D.AssetSeq, 
           I.AssetName, F.SLDeptSeq, J.DeptName, E.CustNo, D.ItemEngSName
       FROM _TSLOrder                           AS A WITH(NOLOCK)   
       JOIN _TSLOrderItem                       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.OrderSeq = B.OrderSeq  
       LEFT OUTER JOIN _TDASMinorValue          AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.SMExpKind = C.MinorSeq  
       LEFT OUTER JOIN _TDAItem                 AS D WITH(NOLOCK) ON B.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSeq
       LEFT OUTER JOIN _TDACust                 AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
       LEFT OUTER JOIN KPX_TSLOrderAdd          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.OrderSeq = A.OrderSeq ) 
       LEFT OUTER JOIN KPX_TSLOrderItemAdd      AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.OrderSeq = B.OrderSeq AND T.OrderSerl = B.OrderSerl AND T.OrderSubSerl = B.OrderSubSerl ) 
       LEFT OUTER JOIN KPX_TSLCustItemUseAdd    AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.CustSeq = A.CustSeq AND U.ItemSeq = B.ItemSeq AND U.UMUseType = T.UMUseType ) 
       LEFT OUTER JOIN _TDAUMinor               AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = U.UMUseTypeDetail ) 
       LEFT OUTER JOIN _TDAUMinor               AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = T.UMUseType ) 
       LEFT OUTER JOIN _TDAItemAsset            AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.AssetSeq = D.AssetSeq ) 
       LEFT OUTER JOIN _TDADept                 AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.DeptSeq = F.SLDeptSeq ) 
      WHERE A.CompanySeq = @CompanySeq    
        AND (@BizUnit = 0  OR A.BizUnit = @BizUnit)  
        AND (A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo)  
        AND (@UMOrderKind = 0 OR A.UMOrderKind = @UMOrderKind)  
 ---------- ������ ���� ���� �κ�    
        AND (@DeptSeq = 0   
             OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
             OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
 ---------- ������ ���� ���� �κ�    
        AND (@EmpSeq  = 0  OR A.EmpSeq  = @EmpSeq)  
        AND (@CustSeq = 0  OR A.CustSeq = @CustSeq)  
        AND (@ItemSeq = 0  OR B.ItemSeq = @ItemSeq) 
        AND (@ItemNo  = '' OR D.ItemNo  LIKE @ItemNo + '%') 
        AND (@WHSeq   = 0  OR B.WHSeq   = @WHSeq)  
        AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')   
        AND (@PoNo = '' OR A.PONo LIKE @PoNo + '%')  
        AND (@DVDateFr = '' OR (B.DVDate >= @DVDateFr) OR (B.DVDate = '' AND A.DVDate >= @DVDateFr))
        AND (@DVDateTo = '' OR (B.DVDate <= @DVDateTo) OR (B.DVDate = '' AND A.DVDate <= @DVDateTo))
        AND C.Serl = 1001 AND C.ValueText = '1'  -- ��������
        AND (@Spec = '' OR D.Spec LIKE @Spec + '%')  
        AND (@ItemSName   = '' OR D.ItemEngSName  LIKE @ItemSName + '%')  
        AND (@CustNoFr = ''  OR E.CustNo >= @CustNoFr)  
        AND (@CustNoTo = ''  OR E.CustNo <= @CustNoTo OR E.CustNo LIKE @CustNoTo + '%' )  
        AND (@UMUseTypeDetail = 0 or U.UMUseTypeDetail = @UMUseTypeDetail )  
        AND ( 0 = (SELECT max(code) FROM _FCOMXmlToSeq(@SLDeptSeq, @MultiSLDeptSeq)  )  
              OR F.SLDeptSeq   IN (SELECT CODE FROM _FCOMXmlToSeq(@SLDeptSeq, @MultiSLDeptSeq) AS BB ) )              
        AND ( 0 = (SELECT max(code) FROM _FCOMXmlToSeq(@AssetSeq, @MultiAssetSeq)  )  
              OR D.AssetSeq   IN (SELECT CODE FROM _FCOMXmlToSeq(@AssetSeq, @MultiAssetSeq) AS BB ) )     
        AND ( 0 = (SELECT max(code) FROM _FCOMXmlToSeq(@CustUseFlag, @MultiCustUseFlag)  )  
              OR T.UMUseType   IN (SELECT CODE FROM _FCOMXmlToSeq(@CustUseFlag, @MultiCustUseFlag) AS BB ) )  
    
     -- �������, 2012.04.24 by ��ö��   
     EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036001, '#Temp_Order', 'OrderSeq', 'OrderSerl', 'OrderSubSerl', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT', 'OrderSeq', 'OrderSerl', '', '_TSLOrder', @PgmSeq           
     
     UPDATE #Temp_Order           
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --�����ߴ�          
                                          WHEN B.MinorSeq = 1037009 THEN 1037009 -- �Ϸ�          
                                          WHEN A.IsStop = '1' THEN 1037005 -- �ߴ�          
                                          ELSE B.MinorSeq END)          
       FROM #Temp_Order              AS A           
       LEFT OUTER JOIN _TDASMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MajorSeq = 1037 AND A.CompleteCHECK = B.Minorvalue )  
     
     -- ������� END 
     
  
  
     EXEC _SCOMProgressTracking @CompanySeq, '_TSLOrderItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''  
     
     ------------------------------------------------------------------------------------------------------  
     -- �����԰�� ���࿬���� �ȵǹǷ� ������������͸� ������ ��ȸ�Ѵ�                                      
     ------------------------------------------------------------------------------------------------------  
     -- ������������ʹ� ����� �������� ���������� �����´�. �׷��� �����ȹ�� �񱳰� �ȴ�.
     -- ��������� ���������� �ƴ� ���� ����
     DELETE #TCOMProgressTracking 
       FROM #TCOMProgressTracking  AS A 
            JOIN _TPDSFCWorkReport AS B WITH(NOLOCK)ON A.Seq = B.WorkReportSeq 
      WHERE B.CompanySeq = @CompanySeq
        AND A.IDOrder    = 7 
        AND B.IsLastProc <> '1'
     
  
  
     -- �����԰� ���� ��� ������ �־ ���� �۾��� �� 20110711 by kskwon
     SELECT TOP 1 @a = 1 FROM #TCOMProgressTracking WHERE IDOrder = 7
     IF @@rowcount <> 0
     BEGIN
             UPDATE #TCOMProgressTracking
                SET Qty = ISNULL((SELECT SUM(ProdQty) FROM _TPDSFCGoodIn WHERE CompanySeq = @CompanySeq AND WorkReportSeq = A.Seq), 0)
               FROM #TCOMProgressTracking A
              WHERE A.IDOrder = 7   
     END
 --    -- _TPDSFCGoodIn�� CompanySeq ���ǿ� �־ ���� 2011-06-02 kskwon
 --    UPDATE A        
 --       SET Qty = ISNULL(B.ProdQty, 0)        
 --      FROM #TCOMProgressTracking            AS A        
 --        --LEFT OUTER JOIN _TPDSFCWorkReport   AS W WITH(NOLOCK) ON A.Seq = W.WorkReportSeq        
 --        --                                                     AND W.IsLastProc = '1'        
 --          LEFT OUTER JOIN _TPDSFCGoodIn     AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  AND A.Seq = B.WorkReportSeq
 --     WHERE A.IDOrder = 7        
 ----       AND B.CompanySeq = @CompanySeq    2011-06-02 kskwon �ּ�ó�� ��
        
  
  
     -- #TCOMProgressTracking�� �ִ� �����͸� ���η� ������ش�                    
     INSERT INTO #OrderTracking    
     SELECT A.IDX_NO,    
            SUM(CASE A.IDOrder WHEN 1 THEN A.Qty     ELSE 0 END),    
            SUM(CASE A.IDOrder WHEN 1 THEN A.Amt     ELSE 0 END),    
     
            SUM(CASE IDOrder WHEN 2 THEN A.Qty     ELSE 0 END),    
            SUM(CASE IDOrder WHEN 2 THEN A.Amt     ELSE 0 END),    
             SUM(CASE A.IDOrder WHEN 3 THEN A.Qty     ELSE 0 END),    
            SUM(CASE A.IDOrder WHEN 3 THEN A.Amt     ELSE 0 END),    
     
            SUM(CASE A.IDOrder WHEN 4 THEN A.Qty     ELSE 0 END),    
            SUM(CASE A.IDOrder WHEN 4 THEN A.Amt     ELSE 0 END),   
   
            SUM(CASE A.IDOrder WHEN 5 THEN A.Qty     ELSE 0 END),   
            SUM(CASE A.IDOrder WHEN 5 THEN A.Amt     ELSE 0 END),  
   
            SUM(CASE A.IDOrder WHEN 6 THEN A.Qty     ELSE 0 END) + SUM(CASE IDOrder WHEN 8 THEN Qty     ELSE 0 END),   
            SUM(CASE A.IDOrder WHEN 6 THEN A.Amt     ELSE 0 END) + SUM(CASE IDOrder WHEN 8 THEN Amt     ELSE 0 END),  
              
            SUM(CASE A.IDOrder WHEN 7 THEN A.Qty     ELSE 0 END),   
            SUM(CASE A.IDOrder WHEN 7 THEN A.Amt     ELSE 0 END),  
     
            SUM(CASE A.IDOrder WHEN 9 THEN A.Qty     ELSE 0 END),   
            SUM(CASE A.IDOrder WHEN 9 THEN A.Amt     ELSE 0 END)  
       FROM #TCOMProgressTracking A
      GROUP BY A.IDX_No    
      
      
  
  
  -- �ŷ����� �� ��� �ܰ������� �߻��� �� �� �־ ������ �ݾ��� ������ ���� �ȵ�(2012.02.16 by kskwon)
 -- �ŷ����� �ܰ� ������ ����� ���� ����
     UPDATE #OrderTracking SET
         InvoiceAmt = B.CurAmt
     FROM #OrderTracking A JOIN (SELECT A.IDX_No, SUM(B.CurAmt) AS CurAmt
                                              FROM #TCOMProgressTracking A JOIN _TSLInvoiceItem B
                                                                             ON B.CompanySeq    = @CompanySeq
                                                                            AND A.Seq           = B.InvoiceSeq
                                                                            AND A.Serl          = B.InvoiceSerl
                                             WHERE A.IDOrder = 2        -- �ŷ�����
                                            Group by A.IDX_No) B
                            ON A.IDX_No = B.IDX_No
         
   
  
  
      ------------------------------------------------------------------------------------------------------  
     -- ������ �׸�                                                                                        
     ------------------------------------------------------------------------------------------------------  
     Create Table #TempSOSpec
     (
         Seq      INT IDENTITY,
         OrderSeq INT,
         OrderSerl INT,
         SpecName  NVARCHAR(200),
         SpecValue NVARCHAR(200)
     )
      INSERT INTO #TempSOSpec
     SELECT DISTINCT A.OrderSeq, A.OrderSerl,'',''
       FROM #Temp_Order AS A
       JOIN _TSLOrderItemspecItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.OrderSeq = B.OrderSeq AND A.OrderSerl = B.OrderSerl )
     
     SELECT @Seq = 0
      WHILE (1=1)
     BEGIN
         SET ROWCOUNT 1
          SELECT @Seq = Seq, @OrderSeq = OrderSeq, @OrderSerl = OrderSerl
           FROM #TempSOSpec
          WHERE Seq > @Seq
          ORDER BY Seq
          IF @@Rowcount = 0 BREAK
          SET ROWCOUNT 0
          SELECT @SubSeq = 0, @SpecName = '', @SpecValue = ''
          WHILE(1=1)
         BEGIN
             SET ROWCOUNT 1
              SELECT @SubSeq = OrderSpecSerl
               FROM _TSLOrderItemspecItem WITH(NOLOCK)
              WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl > @SubSeq AND CompanySeq = @CompanySeq
              ORDER BY OrderSpecSerl
              IF @@Rowcount = 0 BREAK
              SET ROWCOUNT 0
              IF ISNULL(@SpecName,'') = ''
             BEGIN
                 SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')
                                                                                             ELSE ISNULL(A.SpecItemValue, '') END)
                   FROM _TSLOrderItemspecItem AS A WITH(NOLOCK) 
                        JOIN _TSLSpec AS B  WITH(NOLOCK)ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq
                  WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq
             END
             ELSE
             BEGIN
                 SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')
                                                                             ELSE ISNULL(A.SpecItemValue, '') END)
                   FROM _TSLOrderItemspecItem AS A WITH(NOLOCK)
                        JOIN _TSLSpec AS B WITH(NOLOCK) ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq
                  WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq
             END
              UPDATE #TempSOSpec
                SET SpecName = @SpecName, SpecValue = @SpecValue
              WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl
          END
      END
     SET ROWCOUNT 0
  
  
      ------------------------------------------------------------------------------------------------------  
     -- ������ȸ                                                                                            
     ------------------------------------------------------------------------------------------------------  
     SELECT Cfm.CfmCode                  AS Confirm,         --Ȯ��
            CASE A.IsStop WHEN '1' THEN '1' ELSE B.IsStop END    AS IsStop,  -- �ߴܿ���
            (SELECT BizUnitName FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit) AS BizUnitName,     --����ι�  
            A.OrderSeq                   AS OrderSeq,        --���ֳ��ι�ȣ  
            A.OrderNo                    AS OrderNo,         --���ֹ�ȣ  
            B.OrderSerl                  AS OrderSerl,       --���ּ���  
            A.OrderDate                  AS OrderDate,       --��������  
            (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.CustSeq = CustSeq)      AS CustName,        --�ŷ�ó  
            B.ItemSeq                    AS ItemSeq,         --ǰ���ڵ�  
            I.ItemName                   AS ItemName,        --ǰ���  
            I.ItemNo                     AS ItemNo,          --ǰ���ȣ  
            I.Spec                       AS Spec,            --�԰�  
            (SELECT UnitName FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)      AS UnitName,        --�ǸŴ���  
            (SELECT UnitName FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq)   AS STDUnitName,     --���ش���  
            ISNULL(B.Qty, 0)            AS Qty,          --���ּ���  
            ISNULL(C.ProdReqQty, 0)     AS ProdReqQty,   --�����Ƿڼ���(������)  
            ISNULL(C.ProdQty, 0)        AS ProdQty,      --�����԰����(������)  
            ISNULL(C.DVReqQty, 0)       AS DelvReqQty,   --�����Ƿڼ���
            ISNULL(C.DVReqAmt, 0)       AS DelvReqAmt,   --�����Ƿڱݾ� 20121217 �߰� �ڼ�ȣ  
            ISNULL(C.InvoiceQty, 0)     AS InvoiceQty,   --�ŷ���������  
            ISNULL(C.SalesQty, 0)       AS SalesQty,     --�������  
            ISNULL(C.POreqQty, 0)       AS POReqQty,     --���ſ�û����  
            ISNULL(DelvInQty, 0)        AS DelvInQty,    --�����԰����  
            
            ISNULL(C.OSPInQty,0)        AS OSPInQty  ,   --�����԰����
            (SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.UMOrderKind = MinorSeq)     AS UMOrderKindName,         --���ֱ���  
            (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)     AS DeptName,                --�μ�  
            (SELECT EmpName  FROM _TDAEmp  WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.EmpSeq  = EmpSeq)      AS EmpName,                 --�����  
            (SELECT CurrName FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.CurrSeq = CurrSeq)     AS CurrName,                --��ȭ  
            ISNULL(A.ExRate, 0)         AS ExRate,       --ȯ��  
            ISNULL(B.ItemPrice, 0)      AS ItemPrice,    --ǰ��ܰ�  
            ISNULL(B.CustPrice, 0)      AS CustPrice,    --ȸ��ܰ�  
  --           CASE WHEN B.IsInclusedVAT = '1' THEN CASE ISNULL(B.Qty, 0) WHEN 0 THEN ISNULL(B.CurAmt, 0) + ISNULL(B.CurAmt * ISNULL(B.VATRate, 0) /100, 0)    
 --                                                ELSE (ISNULL(B.CurAmt, 0) + ISNULL(B.CurVAT, 0)) / ISNULL(B.Qty, 0)  END    
 --                                           ELSE CASE ISNULL(B.Qty, 0) WHEN 0 THEN ISNULL(B.CurAmt, 0) ELSE ISNULL(B.CurAmt, 0) / ISNULL(B.Qty, 0) END    
 --                                           END AS Price,--�ǸŴܰ�  
             -- �ܰ����� :: �̼���
            CASE WHEN B.Price IS NOT NULL
                 THEN B.Price
         ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN CASE ISNULL(B.Qty, 0) WHEN 0 THEN ISNULL(B.CurAmt, 0) + ISNULL(B.CurAmt * ISNULL(B.VATRate, 0) /100, 0)    
                                                                              ELSE (ISNULL(B.CurAmt, 0) + ISNULL(B.CurVAT, 0)) / ISNULL(B.Qty, 0)  END    
                                            ELSE CASE ISNULL(B.Qty, 0) WHEN 0 THEN ISNULL(B.CurAmt, 0) ELSE ISNULL(B.CurAmt, 0) / ISNULL(B.Qty, 0) END    
                                            END) END AS Price,     --�ǸŴܰ�
             B.IsInclusedVAT             AS IsInclusedVAT,--�ΰ�������  
            B.VATRate                   AS VATRate,      --�ΰ�����  
            ISNULL(B.CurAmt, 0)         AS CurAmt,       --�Ǹűݾ�  
            ISNULL(B.CurVAT, 0)         AS CurVAT,       --�ΰ���  
            ISNULL(B.DomAmt, 0)         AS DomAmt,       --��ȭ�ǸŴܰ�  
            ISNULL(B.DomVAT, 0)         AS DomVAT,       --��ȭ�ΰ���  
            CASE WHEN ISNULL(B.DVDate, '') = '' THEN ISNULL(A.DVDate, '') ELSE ISNULL(B.DVDate, '') END AS DVDate,       --������
            (SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.WHSeq = WHSeq)              AS WHName,        --â��
            ISNULL(A.PONo, '')          AS PONo,
            --ISNULL(S.CustItemNo, '')    AS CustItemNo,
            --ISNULL(S.CustItemName, '')  AS CustItemName,
            --ISNULL(S.CustItemSpec, '')  AS CustItemSpec,
            ISNULL(CASE ISNULL(S.CustItemName, '')     
                   WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                           ELSE ISNULL(S.CustItemName, '') END, '')  AS CustItemName, -- �ŷ�óǰ��    
            ISNULL(CASE ISNULL(S.CustItemNo, '')     
                   WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                           ELSE ISNULL(S.CustItemNo, '') END, '')        AS CustItemNo,   -- �ŷ�óǰ��    
            ISNULL(CASE ISNULL(S.CustItemSpec, '')     
                   WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                   ELSE ISNULL(S.CustItemSpec, '') END, '')  AS CustItemSpec,  -- �ŷ�óǰ��԰�    
            CASE WHEN ISNULL(B.DVPlaceSeq,0) = 0 THEN '' ELSE (SELECT DVPlaceName FROM _TSLDeliveryCust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DVPlaceSeq = B.DVPlaceSeq) END AS DVPlaceName,
            CASE WHEN ISNULL(M.SpecName,'') = '' THEN '0' ELSE '1' END AS IsSpec ,--���  
            M.SpecName           AS SpecName,
            M.SpecValue          AS SpecValue,
            C.InvoiceAmt   AS InvoiceAmt, -- 2010�� 07�� 20�� ������ �ŷ������ݾ� �߰�
            C.SalesAmt   AS SalesAmt, -- 2010�� 07�� 20�� ������ ����ݾ� �߰�
            (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.SMConsignKind = MinorSeq)     AS SMConsignKindName,        --��Ź����
            A.Remark, --�����ͺ��
            B.Remark AS IRemark,
            (ISNULL(B.Qty, 0)    - ISNULL(C.InvoiceQty, 0)) AS UnpaidQty, -- �̳����� 20121217 �߰� �ڼ�ȣ
            (ISNULL(B.CurAmt, 0) - ISNULL(C.InvoiceAmt, 0)) AS UnpaidAmt,  -- �̳��ݾ� 20121217 �߰� �ڼ�ȣ
            A.SMExpKind,   
            (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE MinorSeq = A.SMExpKind AND CompanySeq = @CompanySeq) AS SMExpKindName,
            ISNULL(B.Dummy1, '')  AS Dummy1,
            ISNULL(B.Dummy2, '')  AS Dummy2,
            ISNULL(B.Dummy3, '')  AS Dummy3,
            ISNULL(B.Dummy4, '')  AS Dummy4,
            ISNULL(B.Dummy5, '')  AS Dummy5,
            ISNULL(B.Dummy6, 0)   AS Dummy6,
            ISNULL(B.Dummy7, 0)   AS Dummy7,
            ISNULL(B.Dummy8, '')  AS Dummy8,
            ISNULL(B.Dummy9, '')  AS Dummy9,
            ISNULL(B.Dummy10, '') AS Dummy10, -- 20120107 �ڼ�ȣ �߰�(Dummy1 ~ Dummy10)   
            X.UMUseTypeDetail, 
            X.UMUseTypeDetailName, 
            X.CustUseFlag, 
            X.CustUseFlagName, 
            X.AssetSeq, 
            X.AssetName, 
            X.SLDeptSeq, 
            X.SLDeptName, 
            X.CustNo, 
            X.ItemSName
            
       FROM #Temp_Order AS X
             LEFT OUTER JOIN _TSLOrder AS A WITH(NOLOCK) ON X.OrderSeq = A.OrderSeq
             LEFT OUTER JOIN _TSLOrder_Confirm AS Cfm WITH(NOLOCK) ON A.CompanySeq = Cfm.CompanySeq
                                                                  AND A.OrderSeq   = Cfm.CfmSeq
                                                                  AND Cfm.CfmSerl  = 0
             LEFT OUTER JOIN _TSLOrderItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                            AND X.OrderSeq   = B.OrderSeq  
                                                            AND X.OrderSerl  = B.OrderSerl  
             LEFT OUTER JOIN #OrderTracking  AS C ON X.IDX_No = C.IDX_No  
             LEFT OUTER JOIN _TDAItem   AS I WITH(NOLOCK) ON B.CompanySeq = I.CompanySeq  
                                                         AND B.ItemSeq    = I.ItemSeq  
             LEFT OUTER JOIN _TSLCustItem AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                           AND S.CustSeq    = @CustSeq
                                                           AND B.ItemSeq    = S.ItemSeq
                                                           AND B.UnitSeq    = S.UnitSeq
             LEFT OUTER JOIN #TempSOSpec AS M ON B.CompanySeq = @CompanySeq
                                             AND B.OrderSeq   = M.OrderSeq
                                             AND B.OrderSerl  = M.OrderSerl
       WHERE A.CompanySeq = @CompanySeq 
        AND (@SMProgressType = 0 OR (X.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND X.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )
     AND (@SMInCompleteType = 0 
          OR (@SMInCompleteType = 8097001 AND ISNULL(C.InvoiceQty,0) = 0)
    OR (@SMInCompleteType = 8097002 AND ISNULL(C.InvoiceQty,0) <> 0 AND B.Qty <> ISNULL(C.InvoiceQty,0) )
    OR (@SMInCompleteType = 8097003 AND ISNULL(C.InvoiceQty,0) <> 0 AND B.Qty = ISNULL(C.InvoiceQty,0))
    OR (@SMInCompleteType = 8097004 AND (ISNULL(C.InvoiceQty,0) = 0 OR (ISNULL(C.InvoiceQty,0) <> 0 AND B.Qty <> ISNULL(C.InvoiceQty,0)))))
       ORDER BY A.OrderDate, A.OrderNo, B.OrderSerl  
  
   
 RETURN
 GO
exec KPXCM_SSLOrderItemProgQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMProgressType />
    <BizUnit>1</BizUnit>
    <OrderDateFr>20151001</OrderDateFr>
    <OrderDateTo>20151029</OrderDateTo>
    <DVDateFr />
    <DVDateTo />
    <UMOrderKind />
    <OrderNo />
    <CustUseFlag />
    <MultiCustUseFlag />
    <DeptSeq />
    <UMUseTypeDetail />
    <EmpSeq />
    <AssetSeq />
    <MultiAssetSeq>&amp;lt;XmlString&amp;gt;&amp;lt;/XmlString&amp;gt;</MultiAssetSeq>
    <CustSeq />
    <SLDeptSeq />
    <MultiSLDeptSeq />
    <PONo />
    <ItemSName />
    <WHSeq />
    <SMInCompleteType />
    <CustNoFr />
    <ItemSeq />
    <CustNoTo />
    <ItemNo />
    <Spec />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032855,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027202