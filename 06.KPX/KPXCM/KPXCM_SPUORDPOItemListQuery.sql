
IF OBJECT_ID('KPXCM_SPUORDPOItemListQuery') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOItemListQuery
GO 
/*************************************************************************************************  
  FORM NAME           -       FrmPUORDPOItemList
  DESCRIPTION         -     ���Ź���ǰ����Ȳ
  CREAE DATE          -       2008.07.21      CREATE BY: ����
  LAST UPDATE  DATE   -       2008.10.10         UPDATE BY: ���� 
                              2010.01.26         UPDATE BY: �ڼҿ� :: �г��� ��쿡�� ȯ�� ���������� ����
                              2010.03.25         UPDATE BY: �ڼҿ� :: â������ �������� �߰�
                              2011.01.13         UPDATE BY: �̼��� :: �ߴ�ó�� ���� �߰�
                              2011.06.10         UPDATED BY : �輼ȣ (ǰ�Ǵ���� ��ȸ �߰� )  
                              2011.07.14         UPDATED BY : �輼ȣ (ǰ�Ǻμ� ��ȸ �߰� )
                              2011.11.18         UPDATED BY : �輼ȣ (����������� Į���߰�)
                                                          -- ���ְ� ������ ���ҽ� ���ҵ� ���� �� ���� ��Į���� ��ȸ�ǵ��� 
                              2011.11.21         UPDATED BY : �輼ȣ ( �����Ϻ��Ұ�ǥ�� ����(@IsDiv) ����)
                              2012.01.04         UPDATED BY : �輼ȣ (�̳����� �ߴܰǵ� ��ȸ�ǵ��� ����)
                              2012.01.27         UPDATED BY : SYPARK (���ű׷� ��ȸ���� �߰�)
                              2012.04.13         UPDATED BY : �輼ȣ (��ǰ��ȭ�ݾ�, �԰��ȭ�ݾ� ��ȭ�ݾ� * ȯ���� �����ʰ�
                                                                      �ش� TR�� ��ȭ�ݾ� Į�� �״�� ��ȸ�ǵ��� )
                              2012.4.23          UPDATED BY : ��³� :: �ŷ�ó��ȣ �÷��߰�
                              2012.07.19         UPDATED BY : �輼ȣ (�˻�ǰ ���� Į�� �߰� )
                              2013.07.10         UPDATED BY : õ��� (Memo1~8 �÷� �߰�)
                              2014.03.28         UPDATE  BY : ����� �ߴ�ó���� �����Ͽ� CompanySeq ���� 
                                                            --_TCAUser ���� ���ΰ��� �����ϰ� UserSeq �� ���� Ű���̹Ƿ�
 *************************************************************************************************/  
 CREATE PROCEDURE dbo.KPXCM_SPUORDPOItemListQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS       
     SET NOCOUNT ON        
     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
     
     DECLARE @docHandle        INT,
             @PODateFr         NCHAR(8),
             @PODateTo         NCHAR(8),
             @PONo             NVARCHAR(24),
             @ApproReqNo       NVARCHAR(12),
             @CustName         NVARCHAR(100),
             @CustSeq          INT,
             @DeptSeq          INT,
             @EmpSeq           INT,
             @ItemName         NVARCHAR(100),       
             @ItemNo           NVARCHAR(100),
             @SMAssetType      INT,
             @SMImpType        INT,
             @SMCurrStatus     INT,
             @Cnt              INT,
             @Seq              INT,
             @PJTName          NVARCHAR(60),
             @PJTNo            NVARCHAR(40),
             @UMSupplyType     INT,
             @POReqNo          NVARCHAR(12),
             @POReqEmpSeq      INT,
             @DelvDateFr       NCHAR(8),
             @DelvDateTo       NCHAR(8),
             @SMDelvInType     INT,
             @TopUnitName      NVARCHAR(200),  
             @TopUnitNo        NVARCHAR(200),
             @WHSeq            INT,             -- 20100325 �ڼҿ� �߰�
             @Spec             NVARCHAR(100),
             @ApproReqSeq   INT,
             @POReqSeq    INT,
    @Cnt_POReq    INT,
    @Cnt_Delv    INT,
             @ApproReqEmpSeq   INT,             --  11.06.10 �輼ȣ �߰�  
             @ApproReqDeptSeq  INT,              --  11.07.14 �輼ȣ �߰� 
             @PurGroupDeptSeq  INT,
             @IsPJTPur       INT,
             @UMPOReqType      INT
  
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
      SELECT @PODateFr         = ISNULL(PODateFr       , ''),
            @PODateTo         = ISNULL(PODateTo       , ''),
            @PONo             = ISNULL(PONo          , ''),
            @ApproReqNo       = ISNULL(ApproReqNo     , ''),
            @CustName         = ISNULL(CustName       , ''),
            @CustSeq          = ISNULL(CustSeq        ,  0),
            @DeptSeq          = ISNULL(DeptSeq        ,  0),
            @EmpSeq           = ISNULL(EmpSeq         ,  0),
            @ItemName         = ISNULL(ItemName       , ''),
            @ItemNo           = ISNULL(ItemNo         , ''),
            @SMAssetType      = ISNULL(SMAssetType    ,  0),
            @SMImpType        = ISNULL(SMImpType      ,  0),                    
            @SMCurrStatus     = ISNULL(SMCurrStatus   ,  0),
            @PJTName          = ISNULL(PJTName        , ''),
            @PJTNo            = ISNULL(PJTNo          , ''),
            @UMSupplyType     = ISNULL(UMSupplyType   ,  0),  
            @POReqNo          = ISNULL(POReqNo        , ''),
            @POReqEmpSeq      = ISNULL(POReqEmpSeq    ,  0),
            @DelvDateFr       = ISNULL(DelvDateFr     , ''),
            @DelvDateTo       = ISNULL(DelvDateTo     , ''),
            @SMDelvInType     = ISNULL(SMDelvInType   ,  0),   
            @TopUnitName      = ISNULL(TopUnitName    , ''),                    
            @TopUnitNo        = ISNULL(TopUnitNo      , ''),
            @WHSeq            = ISNULL(WHSeq          ,  0), -- 20100325 �ڼҿ� �߰�
            @Spec             = ISNULL(Spec           , ''),
            @ApproReqSeq      = ISNULL(ApproReqSeq    , ''), -- ���� ��ȣ�ڵ�
            @POReqSeq      = ISNULL(POReqSeq       , ''), -- ���� ��ȣ�ڵ�
            @ApproReqEmpSeq   = ISNULL(ApproReqEmpSeq ,  0), --  11.06.10 �輼ȣ �߰�                          
            @ApproReqDeptSeq  = ISNULL(ApproReqDeptSeq,  0), --  11.07.14 �輼ȣ �߰� 
            @PurGroupDeptSeq  = ISNULL(PurGroupDeptSeq,  0),
            @IsPJTPur   = ISNULL(IsPJTPur,   0),
            @UMPOReqType   = ISNULL(UMPOReqType,   0)
          
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH ( PODateFr           NCHAR(8)     ,
            PODateTo           NCHAR(8)     ,
            PONo               NVARCHAR(24) ,
            ApproReqNo         NVARCHAR(12) ,
            CustName           NVARCHAR(100),
            CustSeq            INT          ,
            DeptSeq            INT          ,
            EmpSeq             INT          ,
            ItemName           NVARCHAR(100),
            ItemNo             NVARCHAR(100),
            SMAssetType        INT          ,
            SMImpType          INT          ,
            SMCurrStatus       INT          ,
            PJTName            NVARCHAR(60) ,
            PJTNo              NVARCHAR(40) ,
            IsDiv              NCHAR(1)     ,
            UMSupplyType       INT          ,
            POReqNo            NVARCHAR(12) ,
            POReqEmpSeq        INT          ,
            DelvDateFr         NCHAR(8)     ,
            DelvDateTo         NCHAR(8)     ,
            SMDelvInType       INT          ,  
            TopUnitName        NVARCHAR(200),  
            TopUnitNo          NVARCHAR(200),
            WHSeq              INT          ,    -- 20100325 �ڼҿ� �߰�
            Spec               NVARCHAR(200),
            ApproReqSeq        INT          ,
            POReqSeq           INT          ,
            ApproReqEmpSeq     INT          ,
            ApproReqDeptSeq    INT          ,
            PurGroupDeptSeq    INT          ,
            IsPJTPur           INT          ,
            UMPOReqType        INT )
     
     --================================================================================================--
     ---- 2014.09.30 ����� �߰� ��񽺰��� ���Ź����� ���ֺμ��� ����ι� �������� ���� ���� ������ ----
     --================================================================================================--
     DECLARE @SiteInitialName NVARCHAR(100), @SPName NVARCHAR(100)        
         
     SELECT @SiteInitialName = EnvValue FROM _TCOMEnv WHERE EnvSeq = 2 AND CompanySeq = @CompanySeq        
         
     IF EXISTS (SELECT * FROM sysobjects WHERE name like @SiteInitialName +'_SPUORDPOItemListQuery')        
     BEGIN        
         SELECT @SPName = @SiteInitialName +'_SPUORDPOItemListQuery'        
                 
           EXEC @SPName @xmlDocument,@xmlFlags,@ServiceSeq,@WorkingTag,@CompanySeq,@LanguageSeq,@UserSeq,@PgmSeq        
           RETURN              
         
     END   
            
     IF @PODateFr = '' SET @PODateFr = '11110101'
     IF @PODateTo = '' SET @PODateTo = '99991231'
      IF @DelvDateFr = '' SET @DelvDateFr = '11110101'
     IF @DelvDateTo = '' SET @DelvDateTo = '99991231' 
    
    
  
     --===================================================
     -- ���ű׷� ���� �������� ����!
     --===================================================
     CREATE TABLE #PurGroupInfo
     (
         IDX_NO      INT,
         DeptSeq     INT,
         UMItemClass INT,
         ItemSeq     INT
     )
     
      --EXEC _SPUBasePurGroupInfo @CompanySeq, @PurGroupDeptSeq
     --===================================================
     -- ���ű׷� ���� �������� ��!
     --===================================================     
     
 
      -------------------
     --��ǰ���࿩��-----
     -------------------
     CREATE TABLE #TMP_PROGRESSTABLE
     (
   IDOrder INT, 
   TABLENAME   NVARCHAR(100)
  )    
       
     CREATE TABLE #Temp_POProgress
     (
   IDX_NO          INT IDENTITY, 
   POSeq           INT, 
   POSerl          INT, 
   Qty             DECIMAL(19, 5), 
   IsDelv          NCHAR(1), 
   IsStop          NCHAR(1), 
   SMCurrStatus    INT, 
   CurAmt          DECIMAL(19, 5), 
   CurVAT          DECIMAL(19, 5), 
   DelvSeq         INT, 
   DelvSerl        INT, 
   DelvAmt         DECIMAL(19, 5), 
   DelvVAT         DECIMAL(19, 5), 
   DelvQty         DECIMAL(19, 5), 
   DelvInSeq       INT, 
   DelvInSerl      INT, 
   DelvInAmt       DECIMAL(19, 5), 
   DelvInVAT       DECIMAL(19, 5), 
   DelvInQty       DECIMAL(19, 5), 
   DelvDate        NCHAR(8), 
   DelvInDate      NCHAR(8), 
   DelvExRate      DECIMAL(19, 5), 
   DelvInExRate    DECIMAL(19, 5), 
   CompleteCHECK   INT, 
   ApproReqNo      NCHAR(12), 
   POReqNO         NCHAR(12), 
   ReqEmpSeq       INT,
         ApproReqEmpSeq  INT,
         ApproReqDeptSeq INT,
         DelvDomAmt      DECIMAL(19, 5),         -- 12.04.13 �輼ȣ �߰�
         DelvInDomAmt    DECIMAL(19, 5),          -- 12.04.13 �輼ȣ �߰�
         UMPOReqType     INT
  )    
      CREATE TABLE #TCOMProgressTracking
     (
   IDX_NO      INT, 
   IDOrder     INT, 
   Seq         INT,
   Serl        INT, 
   SubSerl     INT,
   Qty         DECIMAL(19, 5), 
   StdQty      DECIMAL(19,5) , 
   Amt         DECIMAL(19, 5),
   VAT         DECIMAL(19,5)
  )      
      CREATE TABLE #OrderTracking
     (
   IDX_NO  INT, 
   IDOrder INT,
   Qty     DECIMAL(19,5), 
   Amt     DECIMAL(19,5), 
   VAT     DECIMAL(19,5)
  )
      CREATE TABLE #TMP_SOURCETABLE          
     (          
         IDOrder     INT,          
         TABLENAME   NVARCHAR(100)          
     )   
     
     CREATE TABLE #TCOMSourceTracking          
     (           
         IDX_NO      INT,          
         IDOrder     INT,          
         Seq         INT,          
         Serl        INT,          
         SubSerl     INT,          
         Qty         DECIMAL(19, 5),          
         STDQty      DECIMAL(19, 5),          
         Amt         DECIMAL(19, 5),          
         VAT         DECIMAL(19, 5)          
     )   
     CREATE TABLE #TMP_SOURCEITEM    
     (          
         IDX_NO     INT IDENTITY,          
         SourceSeq  INT,          
         SourceSerl INT,          
         Qty        DECIMAL(19, 5)    
     )
     CREATE TABLE #TMP_EXPENSE    
     (          
         IDX_NO     INT,          
         SourceSeq  INT,          
         SourceSerl INT,          
         ExpenseSeq INT    
     ) 
   DECLARE @DelvWH TABLE
 (
         POSeq    INT,
         POSerl   INT,
         WHSeq    INT
     )
     
  ---------- �������� ��ȣ�� ������ ���(���ſ�û, ǰ��) ------------------------------------------------------------------------------        
  CREATE TABLE #ParamKeyInput 
  (
   IDX_NO INT IDENTITY,   
   Seq INT
  )
  
  CREATE TABLE #TMP_ReturnKey_POReq
  (
   Seq INT
  )
  
  CREATE TABLE #TMP_ReturnKey_Delv
  (
   Seq INT
  )
  
  --DECLARE @ProgToPO TABLE  -- ���ſ�û, ����ǰ�ǹ�ȣ�� ��ȸ���ǿ� �ɾ��� ��� �ش� POSeq�� �ɷ��ֱ� ���� ���̺�
  --(
  -- POSeq INT
  --) 
     -- ���ſ�û��ȣ�� ǰ�� ��ȣ�� ��ȸ���ǿ� �� ���
     IF (@POReqNo <> '' OR @POReqSeq <> '')
     BEGIN
   --CREATE TABLE #Temp_POReq
   --(
   -- IDX_NO INT IDENTITY,   
   -- POReqSeq INT
   --)
   --INSERT INTO #Temp_POReq(POReqSeq)
   --SELECT POReqSeq
   --  FROM _TPUORDPOReq  AS A
   -- WHERE A.CompanySeq = @CompanySeq
   --   AND A.POReqSeq = @POReqSeq
   --   AND A.POReqNo LIKE @POReqNo  + '%'
  
   --TRUNCATE TABLE #TMP_PROGRESSTABLE
   --TRUNCATE TABLE #TCOMProgressTracking
   
   --INSERT #TMP_PROGRESSTABLE
   --SELECT 1, '_TPUORDPOItem'
    --EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOReqItem', '#Temp_POReq', 'POReqSeq', '', ''      
   
   --INSERT INTO @ProgToPO
   --SELECT Seq 
   --  FROM #TCOMProgressTracking 
   -- GROUP BY Seq
   
   INSERT INTO #ParamKeyInput(Seq)
   SELECT POReqSeq
     FROM _TPUORDPOReq  AS A
    WHERE A.CompanySeq = @CompanySeq
      AND A.POReqSeq = @POReqSeq
      AND A.POReqNo LIKE @POReqNo  + '%'
      
   EXEC _SCOMMainKeyTracking @CompanySeq = @CompanySeq, @FromTableName = '_TPUORDPOReqItem', @ToTableName = '_TPUORDPOItem', @ReturnTable = '#TMP_ReturnKey_POReq', @Flag = '1' -- Progress
   
     END
     
     IF (@ApproReqNo <> '' OR @ApproReqSeq <> '')
     BEGIN
   --CREATE TABLE #Temp_ApproReq
   --(
   -- IDX_NO  INT IDENTITY,   
   -- ApproReqSeq INT
   --)
   --INSERT INTO #Temp_ApproReq(ApproReqSeq)
   --SELECT ApproReqSeq
   --  FROM _TPUORDApprovalReq  AS A
   -- WHERE A.CompanySeq = @CompanySeq
   --   AND A.ApproReqSeq = @ApproReqSeq
   --   AND A.ApproReqNo LIKE @ApproReqNo  + '%'
   
   --TRUNCATE TABLE #TMP_PROGRESSTABLE
   --TRUNCATE TABLE #TCOMProgressTracking
   
   --INSERT #TMP_PROGRESSTABLE
   --SELECT 1, '_TPUORDPOItem'
    --EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDApprovalReqItem', '#Temp_ApproReq', 'ApproReqSeq', '', ''      
   
   --INSERT INTO @ProgToPO
   --SELECT Seq 
   --  FROM #TCOMProgressTracking 
   -- WHERE Seq NOT IN (SELECT POSeq FROM @ProgToPO) 
   -- GROUP BY Seq 
   TRUNCATE TABLE #ParamKeyInput
   
   INSERT INTO #ParamKeyInput(Seq)
   SELECT ApproReqSeq
     FROM _TPUORDApprovalReq  AS A
    WHERE A.CompanySeq = @CompanySeq
      AND A.ApproReqSeq = @ApproReqSeq
      AND A.ApproReqNo LIKE @ApproReqNo  + '%'
      
   EXEC _SCOMMainKeyTracking @CompanySeq = @CompanySeq, @FromTableName = '_TPUORDApprovalReqItem', @ToTableName = '_TPUORDPOItem', @ReturnTable = '#TMP_ReturnKey_Delv', @Flag = '1'  -- Source
   
     END           
    
  SELECT @Cnt_POReq = COUNT(1) FROM #TMP_ReturnKey_POReq
  SELECT @Cnt_Delv  = COUNT(1) FROM #TMP_ReturnKey_Delv    
  
     -- ���Ź��� ǰ�� ���
     --IF (@POReqNo <> '' OR @ApproReqNo <> '' OR @POReqSeq <> '' OR @ApproReqSeq <> '')  -- ���ſ�û��ȣ, ����ǰ�� ��ȣ�� ��ȸ�������� �ɷ��� ���
     --BEGIN
     IF (SELECT COUNT(*) FROM #PurGroupInfo) > 0 -- ���ű׷������� �����Ұ��
     BEGIN  
   INSERT INTO #Temp_POProgress(POSeq, POSerl, Qty, IsDelv, IsStop, SMCurrStatus, CurAmt, CurVAT, DelvSeq, DelvSerl, DelvAmt, DelvVAT, DelvQty, DelvInSeq, DelvInSerl, DelvInAmt, DelvInVAT, DelvInQty, DelvExRate, DelvInExRate, CompleteCHECK, DelvDomAmt, DelvInDomAmt, UMPOReqType)    
   SELECT A.POSeq, B.POSerl, B.Qty, '1', B.IsStop, 6036001, ISNULL(SUM(B.CurAmt), 0), ISNULL(SUM(B.CurVAT), 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0 -- �̳����� ����    
     FROM _TPUORDPO                     AS A WITH(NOLOCK)     
                     JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                              AND A.POSeq      = B.POSeq  
          --         JOIN @ProgToPO  AS G ON A.POSeq = G.POSeq              
                     JOIN _TDAItem      AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                              AND B.ItemSeq    = D.ItemSeq 
          LEFT OUTER JOIN _TPJTBOM      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                           AND B.PJTSeq     = C.PJTSeq
                              AND B.WBSSeq     = C.BOMSerl  
          LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                        AND A.CustSeq    = E.CustSeq
          LEFT OUTER JOIN _TPJTProject  AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq
                     AND B.PJTSeq    = F.PJTSeq 
                LEFT OUTER JOIN _TDAItemClass AS G              ON A.CompanySeq = G.CompanySeq
                                                               AND B.ItemSeq    = G.ItemSeq
                                                               AND G.UMajorItemClass IN (2001, 2004)                                                
    WHERE A.CompanySeq   = @CompanySeq  
      AND (A.PODate      BETWEEN @PODateFr AND @PODateTo)  
      AND (@DeptSeq      = 0  OR A.DeptSeq      = @DeptSeq)
      AND (@EmpSeq       = 0  OR A.EmpSeq       = @EmpSeq)
      AND (@PONo         = '' OR A.PONo         LIKE @PONo + '%' )
      AND (A.SMImpType   IN (8008001, 8008002, 8008003))
      AND (@UMSupplyType = 0  OR C.UMSupplyType = @UMSupplyType)
      AND (@ItemName     = '' OR D.ItemName     LIKE @ItemName+'%')
      AND (@ItemNo       = '' OR D.ItemNo       LIKE @ItemNo+'%')
      AND (@CustSeq      = 0  OR A.CustSeq      = @CustSeq)
      AND (@CustName     = '' OR E.CustName     LIKE @CustName + '%')
      AND (@Spec         = '' OR D.Spec         LIKE @Spec + '%')
      AND (@PJTNo        = '' OR F.PJTNo        LIKE @PJTNo + '%')
      AND (@PJTName      = '' OR F.PJTName      LIKE @PJTName + '%')
            AND (@SMImpType    = 0  OR A.SMImpType    = @SMImpType )
            AND (@SMAssetType  = 0  OR D.AssetSeq     = @SMAssetType)
            AND (B.DelvDate    = '' OR B.DelvDate     IS NULL OR B.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)
      AND ( @Cnt_POReq   = 0  OR (@Cnt_POReq    > 0 AND A.POSeq IN (SELECT Seq FROM #TMP_ReturnKey_POReq)))
      AND ( @Cnt_Delv    = 0  OR (@Cnt_Delv     > 0 AND A.POSeq IN (SELECT Seq FROM #TMP_ReturnKey_Delv)))
            AND (EXISTS   (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq     = A.DeptSeq AND UMItemClass = G.UMItemClass AND ItemSeq = B.ItemSeq)  
                OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq     = A.DeptSeq AND UMItemClass = G.UMItemClass AND ItemSeq = 0)  
                OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq     = 0         AND UMItemClass = G.UMItemClass AND ItemSeq = B.ItemSeq)  
                OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq     = 0         AND UMItemClass = G.UMItemClass AND ItemSeq = 0)  
                OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq     = A.DeptSeq AND UMItemClass = 0             AND ItemSeq = 0))    
    GROUP BY A.POSeq, B.POSerl, B.Qty, B.IsStop   
     END
     ELSE 
     BEGIN
   INSERT INTO #Temp_POProgress(POSeq, POSerl, Qty, IsDelv, IsStop, SMCurrStatus, CurAmt, CurVAT, DelvSeq, DelvSerl, DelvAmt, DelvVAT, DelvQty, DelvInSeq, DelvInSerl, DelvInAmt, DelvInVAT, DelvInQty, DelvExRate, DelvInExRate, CompleteCHECK,  DelvDomAmt, DelvInDomAmt, UMPOReqType)    
   SELECT A.POSeq, B.POSerl, B.Qty, '1', B.IsStop, 6036001, ISNULL(SUM(B.CurAmt), 0), ISNULL(SUM(B.CurVAT), 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0-- �̳����� ����    
     FROM _TPUORDPO                     AS A WITH(NOLOCK)     
                     JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                              AND A.POSeq      = B.POSeq  
          --         JOIN @ProgToPO  AS G ON A.POSeq = G.POSeq              
                     JOIN _TDAItem      AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                              AND B.ItemSeq    = D.ItemSeq 
          LEFT OUTER JOIN _TPJTBOM      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                           AND B.PJTSeq     = C.PJTSeq
                              AND B.WBSSeq     = C.BOMSerl  
          LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                        AND A.CustSeq    = E.CustSeq
          LEFT OUTER JOIN _TPJTProject  AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq
                     AND B.PJTSeq    = F.PJTSeq                                                
    WHERE A.CompanySeq   = @CompanySeq  
      AND (A.PODate      BETWEEN @PODateFr AND @PODateTo)  
      AND (@DeptSeq      = 0  OR A.DeptSeq      = @DeptSeq)
      AND (@EmpSeq       = 0  OR A.EmpSeq       = @EmpSeq)
      AND (@PONo         = '' OR A.PONo         LIKE @PONo + '%' )
      AND (A.SMImpType   IN (8008001, 8008002, 8008003))
      AND (@UMSupplyType = 0  OR C.UMSupplyType = @UMSupplyType)
      AND (@ItemName     = '' OR D.ItemName     LIKE @ItemName+'%')
      AND (@ItemNo       = '' OR D.ItemNo       LIKE @ItemNo+'%')
      AND (@CustSeq      = 0  OR A.CustSeq      = @CustSeq)
      AND (@CustName     = '' OR E.CustName     LIKE @CustName + '%')
      AND (@Spec         = '' OR D.Spec         LIKE @Spec + '%')
      AND (@PJTNo        = '' OR F.PJTNo        LIKE @PJTNo + '%')
      AND (@PJTName      = '' OR F.PJTName      LIKE @PJTName + '%')
            AND (@SMImpType    = 0  OR A.SMImpType    = @SMImpType )
            AND (@SMAssetType  = 0  OR D.AssetSeq     = @SMAssetType)
            AND (B.DelvDate    = '' OR B.DelvDate     IS NULL OR B.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)
      AND ( @Cnt_POReq   = 0  OR (@Cnt_POReq    > 0 AND A.POSeq IN (SELECT Seq FROM #TMP_ReturnKey_POReq)))
      AND ( @Cnt_Delv    = 0  OR (@Cnt_Delv     > 0 AND A.POSeq IN (SELECT Seq FROM #TMP_ReturnKey_Delv)))
    GROUP BY A.POSeq, B.POSerl, B.Qty, B.IsStop   
     END 
  --   END
  --   ELSE          -- ���ſ�û��ȣ, ����ǰ�� ��ȣ�� ��ȸ�������� �ɸ��� �ʾ��� ���
  --   BEGIN
  -- INSERT INTO #Temp_POProgress(POSeq, POSerl, Qty, IsDelv, IsStop, SMCurrStatus, CurAmt, CurVAT, DelvSeq, DelvSerl, DelvAmt, DelvVAT, DelvQty, DelvInSeq, DelvInSerl, DelvInAmt, DelvInVAT, DelvInQty, DelvExRate, DelvInExRate, CompleteCHECK)    
  -- SELECT  A.POSeq, B.POSerl, B.Qty, '1', B.IsStop, 6036001, ISNULL(SUM(B.CurAmt), 0), ISNULL(SUM(B.CurVAT), 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 -- �̳����� ����    
  --   FROM _TPUORDPO     AS A WITH(NOLOCK)     
  --   JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
  --             AND A.POSeq    = B.POSeq  
  --   JOIN _TDAItem      AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
  --             AND B.ItemSeq    = D.ItemSeq 
  --   LEFT OUTER JOIN _TPJTBOM AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
  --            AND B.PJTSeq = C.PJTSeq
  --            AND B.WBSSeq = C.BOMSerl  
  --   LEFT OUTER JOIN _TDACust AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
  --            AND A.CustSeq = E.CustSeq
  --   LEFT OUTER JOIN _TPJTProject AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq
  --             AND B.PJTSeq  = F.PJTSeq                                                
  --  WHERE A.CompanySeq   = @CompanySeq  
  --    AND (A.PODate BETWEEN @PODateFr AND @PODateTo)  
  --    AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq    )
  --    AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq     )
  --    AND (@PONo  = '' OR A.PONo LIKE @PONo + '%' )
  --    AND (A.SMImpType IN (8008001, 8008002, 8008003))
  --    AND (@UMSupplyType = 0 OR C.UMSupplyType = @UMSupplyType)
  --    AND (@ItemName = '' OR D.ItemName like @ItemName+'%')
  --    AND (@ItemNo = '' OR D.ItemNo like @ItemNo+'%')
  --    AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
  --    AND (@CustName = '' OR E.CustName like @CustName + '%')
  --    AND (@Spec = '' OR D.Spec LIKE @Spec + '%')
  --    AND (@PJTNo = '' OR F.PJTNo LIKE @PJTNo + '%')
  --    AND (@PJTName = '' OR F.PJTName LIKE @PJTName + '%')
  --          AND (@SMImpType   = 0  OR A.SMImpType = @SMImpType )
  --          AND (@SMAssetType = 0  OR D.AssetSeq = @SMAssetType)
  --          AND (B.DelvDate = '' OR B.DelvDate IS NULL OR B.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)
  --  GROUP BY A.POSeq, B.POSerl, B.Qty, B.IsStop  
  --END   
   -- ������� üũ   
     EXEC _SCOMProgStatus @CompanySeq, '_TPUORDPOItem', 1036002, '#Temp_POProgress', 'POSeq', 'POSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'StdUnitQty', 'CurAmt', '', 'POSeq', 'POSerl', '', '_TPUORDPOItem', @PgmSeq 
      UPDATE #Temp_POProgress     
        SET SMCurrStatus = (SELECT CASE WHEN A.CompleteCHECK = '5'  OR B.MinorSeq = 1037009 THEN 6036007 -- ���������� 2014.07.03 ������߰�
                                        WHEN A.IsStop = '1'         OR B.MinorSeq = 1037005 THEN 6036005 -- �ߴ�    
                                        WHEN A.CompleteCHECK = '40' OR B.MinorSeq = 1037008 THEN 6036004 -- �Ϸ�
                                        WHEN A.CompleteCHECK = 1    OR B.MinorSeq = 1037003 THEN 6036002 -- Ȯ��(����)  
                                        WHEN A.CompleteCHECK = '20' OR B.MinorSeq = 1037006 THEN 6036003 -- ����
                                        ELSE 6036001 END)                                                -- �ۼ�(��Ȯ��)        
       FROM #Temp_POProgress AS A 
            LEFT OUTER JOIN _TDASMinor AS B ON B.MajorSeq = 1037 AND A.CompleteCHECK = B.MinorValue    
   TRUNCATE TABLE #TMP_PROGRESSTABLE
  TRUNCATE TABLE #TCOMProgressTracking
  
     INSERT #TMP_PROGRESSTABLE     
     SELECT 1, '_TPUDelvItem'               -- ���ų�ǰ
  UNION ALL
  SELECT 2, '_TPUDelvInItem'      -- �����԰�
     
     EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_POProgress', 'POSeq', 'POSerl', ''    
     
  -- ��ǰ, �԰� �ݾ� ��������
  INSERT INTO #OrderTracking
  SELECT IDX_NO,
      IDOrder,
      SUM(Qty), 
      SUM(Amt),
      SUM(VAT)
    FROM #TCOMProgressTracking    
      GROUP BY IDX_NO, IDOrder
   -- ���ų�ǰ ������ ������Ʈ
     UPDATE #Temp_POProgress 
       SET  DelvSeq      = B.Seq  ,
            DelvSerl     = B.Serl ,
            DelvAmt      = D.Amt  ,
            DelvVAT      = D.VAT  ,
            DelvQty      = D.Qty  ,
      DelvDate     = C.DelvDate,
      DelvExRate = C.ExRate,
            DelvDomAmt   = E.DomAmt              -- 12.04.13 �輼ȣ �߰�     
      FROM  #Temp_POProgress                AS A  
      JOIN #TCOMProgressTracking AS B ON A.IDX_No     = B.IDX_No AND B.IDOrder = 1
         JOIN _TPUDelv           AS C ON C.CompanySeq = @CompanySeq
                   AND B.Seq     = C.DelvSeq
            JOIN #OrderTracking        AS D ON A.IDX_No     = D.IDX_No
            JOIN _TPUDelvItem          AS E ON B.Seq        = E.DelvSeq
                                           AND B.Serl      = E.DelvSerl
                                           AND E.CompanySeq = @CompanySeq
   WHERE D.IDOrder = 1 -- ���ų�ǰ
   
     UPDATE #Temp_POProgress 
       SET  DelvInSeq      = B.Seq  ,
            DelvInSerl     = B.Serl ,
            DelvInAmt      = D.Amt  ,
            DelvInVAT      = D.VAT  ,
            DelvInQty      = D.Qty  ,
      DelvInDate   = C.DelvInDate,
      DelvInExRate   = C.ExRate,
            DelvInDomAmt   = E.DomAmt           -- 12.04.13 �輼ȣ �߰�     
      FROM  #Temp_POProgress                AS A  
      JOIN #TCOMProgressTracking AS B ON A.IDX_No     = B.IDX_No AND B.IDOrder = 2
         JOIN _TPUDelvIn           AS C ON C.CompanySeq = @CompanySeq
                   AND B.Seq     = C.DelvInSeq
            JOIN #OrderTracking        AS D ON A.IDX_No     = D.IDX_No
            JOIN _TPUDelvInItem          AS E ON B.Seq        = E.DelvInSeq
                                            AND B.Serl      = E.DelvInSerl
                                            AND E.CompanySeq = @CompanySeq
   WHERE D.IDOrder = 2 -- �����԰�
     -------------------
     --ǰ�ǹ�ȣ ���� ---
     -------------------
     INSERT #TMP_SOURCETABLE    
     SELECT '1','_TPUORDApprovalReqItem'    
      INSERT #TMP_SOURCETABLE    
     SELECT '2','_TPUORDPOReqItem'
      INSERT #TMP_SOURCEITEM
          ( SourceSeq    , SourceSerl    , Qty)
  SELECT POSeq, POSerl, Qty
    FROM #Temp_POProgress
      EXEC _SCOMSourceTracking @CompanySeq, '_TPUORDPOItem', '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''
           
     -- ǰ�ǹ�ȣ ������Ʈ
     UPDATE #Temp_POProgress
        SET ApproReqNo = ISNULL(D.ApproReqNo, ''),
            ApproReqEmpSeq = ISNULL(D.EmpSeq, 0),              -- 11.06.10 �輼ȣ �߰�
            ApproReqDeptSeq = ISNULL(D.DeptSeq, 0)              -- 11.07.14 �輼ȣ �߰�
        FROM #Temp_POProgress                 AS A
            JOIN #TMP_SOURCEITEM               AS B              ON A.POSeq   = B.SourceSeq
                                                                AND A.POSerl  = B.SourceSerl
            JOIN #TCOMSourceTracking           AS C              ON B.IDX_NO     = C.IDX_NO
                                                                AND C.IDOrder    = '1'
            LEFT OUTER JOIN _TPUORDApprovalReq AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                                AND C.Seq        = D.ApproReqSeq
       -- ���ſ�û��ȣ ������Ʈ
     UPDATE #Temp_POProgress
        SET POReqNo   = ISNULL(D.POReqNo, ''),
            ReqEmpSeq = ISNULL(D.EmpSeq ,  0),
            UMPOReqType =ISNULL(D.UMPOReqType,0)
       FROM #Temp_POProgress                 AS A
            JOIN #TMP_SOURCEITEM               AS B              ON A.POSeq   = B.SourceSeq
                                                                AND A.POSerl  = B.SourceSerl
            JOIN #TCOMSourceTracking           AS C              ON B.IDX_NO     = C.IDX_NO
                                                                AND C.IDOrder    = '2'
            LEFT OUTER JOIN _TPUORDPOReq       AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                                AND C.Seq        = D.POReqSeq
    ------------------------
     --ǰ�ǹ�ȣ ���� ��  ----
     ------------------------
  
  CREATE INDEX IDX_#Temp_POProgress ON #Temp_POProgress(POSeq, POSerl)  
  
     SELECT   
            A.POSeq        ,  
            A.POSerl       ,  
            A.Qty          ,  
            B.PONo         ,  
            B.SMImpType    ,  
            B.PODate       ,  
            G.DeptName     ,  
            B.DeptSeq      ,  
            H.EmpName      ,  
            B.EmpSeq       ,  
            F.CustName     ,  
            B.CustSeq      ,  
            E.CurrName     ,  
            B.CurrSeq      ,  
            B.ExRate       ,  
            D.ItemName     ,  
            D.ItemNo       ,  
            D.Spec         ,  
            A.ItemSeq      ,  
            CASE WHEN A.DelvDate >  (CASE WHEN ISNULL(DelvDate2,'') = '' THEN A.DelvDate ELSE DelvDate2 END)
                 THEN  CASE WHEN ISNULL(DelvDate2,'') = '' THEN A.DelvDate ELSE DelvDate2 END -- 2����ǰ���� ���̸� 1����ǰ�ϰ� �����ϴٰ� ����
                 ELSE  A.DelvDate END  AS DelvDate,   -- 14.10.02 ������ �߰�       
            A.Remark1      ,  
            A.Remark2      ,  
            I.PJTName      ,  
            I.PJTNo        ,  
            A.PJTSeq       ,  
            A.WBSSeq       ,  
            '' AS WBSName      ,  
            A.UnitSeq      ,  
            N.UnitName     ,  
            A.IsStop       ,  
            Z.ApproReqNo   ,    
            ISNULL(ch1.MinorName, '') AS SMImpTypeName,       
            ISNULL(ch2.MinorName, '') AS SMCurrStatusName ,      
            ISNULL(A.Price , 0)        AS Price,  
            ISNULL(A.CurAmt, 0)        AS CurAmt,  
            ISNULL(A.CurVAT, 0)        AS CurVAT,  
            ISNULL(A.DomPrice, 0)      AS DomPrice,  
            ISNULL(A.DomAmt, 0)        AS DomAmt,  
            ISNULL(A.DomVAT, 0)        AS DomVAT,  
            ISNULL(A.CurAmt, 0) + ISNULL(A.CurVAT, 0) AS TotCurAmt,  
       ISNULL(A.DomAmt, 0) + ISNULL(A.DomVAT, 0) AS TotDomAmt,  
            Z.SMCurrStatus,  
            ISNULL(Z.DelvAmt, 0) AS DelvCurAmt,--ISNULL(Z.CurAmt, 0) AS DelvCurAmt,  
            ISNULL(Z.DelvDomAmt, 0) AS DelvDomAmt,
            --Z.CurAmt,Z.CurVAT,Z.DelvExRate,  
            Z.DelvQty      AS DelvQty     ,  
            Z.DelvInQty    AS DelvInQty  ,  
            ISNULL(Z.DelvInAmt, 0) AS DelvInCurAmt,  
            iSNULL(Z.DelvInDomAmt, 0) AS DelvInDomAmt,  
            L.SMAssetGrp        AS SMAssetType,  
            L.AssetName         AS SMAssetTypeName,  
            Z.DelvDate    AS DelvedDate,  
            Z.DelvInDate    AS DelvInDate,  
            CASE ISNULL(A.IsStop, '0') WHEN '0' THEN CASE WHEN ISNULL(A.Qty, 0) - ISNULL(Z.DelvQty, 0) < 0 THEN 0 ELSE ISNULL(A.Qty, 0) - ISNULL(Z.DelvQty, 0) END ELSE 0 END AS RemainQty,  -- 2012. 1. 19 hkim ����
            B.IsPJT AS IsPJT,  
            M.UMSupplyType AS UMSupplyType,  
            P.MinorName AS UMSupplyTypeName,  
            Z.POReqNo    ,  
            Q.EmpName    AS POReqEmpName,  
            Q.EmpSeq     AS POReqEmpSeq,    
            M2.ItemNo AS UpperUnitNo, M2.ItemName AS UpperUnitName,     
            M4.ItemName AS TopUnitName, M4.ItemNo AS TopUnitNo,  
            M.UMMatQuality AS UMMatQuality,  
            M5.MinorName AS UMMatQualityName,  
            CASE ISNULL(A.IsStop, '0') WHEN '0' THEN 0 ELSE CASE WHEN ISNULL(A.Qty, 0) - ISNULL(Z.DelvQty, 0) < 0 THEN 0 ELSE ISNULL(A.Qty, 0) - ISNULL(Z.DelvQty, 0) END END AS StopQty,  
            CASE ISNULL(A.WHSeq, 0) WHEN 0 THEN R.WHSeq ELSE A.WHSeq END AS WHSeq,   -- 20100325 �ڼҿ� �߰�  
            CASE ISNULL(A.WHSeq, 0) WHEN 0 THEN T.WHName ELSE S.WHName END AS WHName, -- 20100325 �ڼҿ� �߰�  
            A.StopDate,                              --�ߴ��� : �̼��� 20110112  
            A.StopEmpSeq,                            --�ߴ�ó���� : �̼��� 20110112  
            SU.UserName         AS StopEmpName,      --�ߴ�ó���ڸ� : �̼��� 20110112  
            A.StopRemark,                            --�ߴܻ��� : �̼��� 20110112  
            Z.ApproReqEmpSeq    AS ApproReqEmpSeq,   -- ǰ�Ǵ����  
            Q1.EmpName          AS ApproReqEmpName,  -- ǰ�Ǵ���ڸ�  
            Z.ApproReqDeptSeq   AS ApproReqDeptSeq,  -- ǰ�Ǵ����  
            G1.DeptName         AS ApproReqDeptName, -- ǰ�Ǵ���ڸ�
            CONVERT(NVARCHAR(300), '')                   AS DivDelvDateInfo, 
            F.CustNo            AS CustNo,           -- �ŷ�ó��ȣ
            JY.CustName         AS MakerName,         -- ����ó: 20120530 ������ �߰�
            ISNULL(QC.IsInQC, '0') AS IsQCItem,       -- �˻�ǰ����     12.07.19 �輼ȣ �߰�
            ISNULL(QC1.IsNotAutoIn,0) AS IsNotAutoIn,
            A.Memo1, A.Memo2, A.Memo3, A.Memo4/*, A.Memo5, A.Memo6*/, A.Memo7, A.Memo8,
            A.SMPriceType AS SMPriceType,
            (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMPriceType) AS SMPriceTypeName,
            ISNULL(II.MinorName, '') AS UMPOReqTypeName,  -- 20141104 �̻� �߰�  
            ISNULL(A.DelvDate2,'')   AS DelvDate2,      -- 20141106 �̻� �߰�  
      ISNULL(WHI.Location, '') AS WHLocation        -- 20141126 ����ȯ(2014) �߰�
             ,ZZ5.MinorName AS Memo5
             ,ZZ6.MinorName AS Memo6
       INTO  #TMP_TPUORDPOItem
       FROM _TPUORDPOItem      AS A WITH(NOLOCK)  
                       JOIN #Temp_POProgress  AS Z ON A.POSeq  = Z.POSeq  
                                                  AND  A.POSerl = Z.POSerl  
                       JOIN _TPUORDPO   AS B WITH(NOLOCK)   ON A.CompanySeq  = B.CompanySeq  
                                                                    AND A.POSeq   = B.POSeq  
            LEFT OUTER JOIN _TDAItem    AS D WITH(NOLOCK)   ON A.CompanySeq  = D.CompanySeq   
                                                                    AND A.ItemSeq  = D.ItemSeq  
            LEFT OUTER JOIN _TDACurr       AS E WITH(NOLOCK)   ON B.CompanySeq  = E.CompanySeq   
                                   AND B.CurrSeq  = E.CurrSeq  
            LEFT OUTER JOIN _TDACust       AS F WITH(NOLOCK)   ON B.CompanySeq  = F.CompanySeq   
                                   AND B.CustSeq  = F.CustSeq  
            LEFT OUTER JOIN _TDADept       AS G WITH(NOLOCK)   ON B.CompanySeq  = G.CompanySeq   
                                   AND B.DeptSeq  = G.DeptSeq  
            LEFT OUTER JOIN _TDADept       AS G1 WITH(NOLOCK)  ON @CompanySeq  = G1.CompanySeq      -- 11.07.14 �輼ȣ �߰�  
                                   AND Z.ApproReqDeptSeq = G1.DeptSeq  
            LEFT OUTER JOIN _TDAEmp       AS H WITH(NOLOCK)   ON B.CompanySeq  = H.CompanySeq   
                                   AND B.EmpSeq   = H.EmpSeq   
            LEFT OUTER JOIN _TPJTProject      AS I WITH(NOLOCK)   ON A.CompanySeq  = I.CompanySeq   
                                   AND A.PJTSeq   = I.PJTSeq  
            LEFT OUTER JOIN _TDAItemAsset     AS L WITH(NOLOCK)   ON D.CompanySeq  = L.CompanySeq   
                                   AND D.AssetSeq  = L.AssetSeq  
            LEFT OUTER JOIN _TDAUnit       AS N WITH(NOLOCK)   ON A.CompanySeq  = N.CompanySeq  
                                   AND A.UnitSeq  = N.UnitSeq  
            LEFT OUTER JOIN _TPJTBOM       AS M WITH(NOLOCK)   ON A.CompanySeq  = M.CompanySEq    
                    AND A.PJTSeq   = M.PJTSeq    
                    AND A.WBSSeq   = M.BOMSerl    
            LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK)  ON A.CompanySeq  = M1.CompanySeq    
                       AND A.PJTSeq   = M1.PJTSeq 
                      AND M1.BOMSerl  <> -1 
                      AND M.UpperBOMSerl = M1.BOMSerl 
                      AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- ���� BOM    
            LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON A.CompanySEq  = M2.CompanySeq    
                    AND M1.ItemSeq  = M2.ItemSeq    
            LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK)  ON A.CompanySeq  = M3.CompanySeq    
                       AND A.PJTSeq   = M3.PJTSeq    
                       AND M3.BOMSerl  <> -1    
                       AND ISNULL(M3.BeforeBOMSerl,0) = 0    
                       AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- �ֻ���    
                       AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1   
            LEFT OUTER JOIN _TDAItem    AS M4 WITH(NOLOCK)  ON A.CompanySeq  = M4.CompanySeq    
                    AND M3.ItemSeq  = M4.ItemSeq    
            LEFT OUTER JOIN _TDAUMinor   AS M5 WITH(NOLOCK)  ON A.CompanySeq  = M5.CompanySeq  
                    AND M.UMMatQuality = M5.MinorSeq  
            LEFT OUTER JOIN _TDAUMinor   AS P WITH(NOLOCK)   ON A.CompanySeq  = P.CompanySeq  
                                   AND M.UMSupplyType = P.MinorSeq  
            LEFT OUTER JOIN _TDAEmp    AS Q WITH(NOLOCK)   ON Q.CompanySeq  = @CompanySeq  
                                   AND Z.ReqEmpSeq  = Q.EmpSeq  
            LEFT OUTER JOIN _TDAEmp       AS Q1 WITH(NOLOCK)  ON Q1.CompanySeq    = @CompanySeq   -- 11.06.10 �輼ȣ �߰�  
                                                  AND Z.ApproReqEmpSeq = Q1.EmpSeq  
            LEFT OUTER JOIN @DelvWH       AS R       ON A.POSeq   = R.POSeq       -- 20100325 �ڼҿ� �߰�  
                       AND A.POSerl   = R.POSerl    
            LEFT OUTER JOIN _TDAWH       AS S WITH(NOLOCK)   ON S.CompanySeq  = @CompanySeq -- 20100325 �ڼҿ� �߰�  
                    AND A.WHSeq   = S.WHSeq     
            LEFT OUTER JOIN _TDAWH       AS T WITH(NOLOCK)   ON T.CompanySeq  = @CompanySeq -- 20100325 �ڼҿ� �߰�  
                    AND R.WHSeq   = T.WHSeq     
            LEFT OUTER JOIN _TCAUser       AS SU WITH(NOLOCK)  ON SU.UserSeq  = A.StopEmpSeq   
            LEFT OUTER JOIN _TDASMinor      AS ch1 WITH(NOLOCK) ON ch1.CompanySeq = @CompanySeq   
                    AND ch1.MajorSeq  = 8008           
                    AND ch1.MinorSeq  = B.SMImpType     
            LEFT OUTEr JOIN _TDASMinor   AS ch2 WITH(NOLOCK) ON ch2.CompanySeq = @CompanySeq   
                    AND ch2.MajorSeq  = 6036           
                    AND ch2.MinorSeq  = Z.SMCurrStatus    
            LEFT OUTER JOIN _TDACust    AS JY WITH(NOLOCK)  ON A.CompanySeq  = JY.CompanySeq   -- 20120530 ������ �߰�
                    AND A.MakerSeq  = JY.CustSeq      -- 20120530 ������ �߰�
            LEFT OUTER JOIN _TPDBaseItemQCType   AS QC WITH(NOLOCK)  ON A.CompanySeq  = QC.CompanySeq
                    AND A.ItemSeq  = QC.ItemSeq
                                                                    AND QC.IsInQC  = '1'
            LEFT OUTER JOIN _TPDBaseItemQCType   AS QC1 WITH(NOLOCK) ON A.CompanySeq  = QC1.CompanySeq
                                                                    AND A.ItemSeq  = QC1.ItemSeq            
            LEFT OUTER JOIN _TDAUMinor   AS II WITH(NOLOCK)  ON II.CompanySeq = @CompanySeq   
                                                                    AND Z.UMPOReqType = II.MinorSeq   -- 20141104 �̻� �߰�                                                                        
      LEFT OUTER JOIN _TDAWHItem      AS WHI WITH(NOLOCK) ON WHI.CompanySeq = A.CompanySeq 
                    AND WHI.WHseq  = A.WHseq 
                    AND WHI.Itemseq  = A.Itemseq    -- â��Location �߰� :: 20141126 ����ȯ(2014) 
            LEFT OUTER JOIN _TDAUMinor       AS ZZ5 WITH(NOLOCK)ON A.CompanySeq = ZZ5.CompanySeq AND A.Memo5 = ZZ5.MinorSeq
            LEFT OUTER JOIN _TDAUMinor       AS ZZ6 WITH(NOLOCK)ON A.CompanySeq = ZZ6.CompanySeq AND A.Memo6 = ZZ6.MinorSeq
          WHERE A.CompanySeq   = @CompanySeq  
            AND (@ApproReqno  = '' OR Z.ApproReqNo LIKE @ApproReqno + '%')  
            AND (@SMCurrStatus  = 0     
                OR (Z.SMCurrStatus  = @SMCurrStatus AND @SMCurrStatus <> 6036006)     
                OR ( @SMCurrStatus = 6036006 AND Z.SMCurrStatus IN (6036001, 6036002, 6036003)  ))    
            AND (@POReqEmpSeq   = 0 OR Z.ReqEmpSeq = @POReqEmpSeq)  
            AND (@POReqNo     = '' OR Z.POReqNo LIKE @POReqNo + '%')  
            AND (@TopUnitName = '' OR M4.ItemName LIKE @TopUnitName + '%')         
            AND (@TopUnitNo = '' OR M4.ItemNo LIKE @TopUnitNo + '%')    
            AND (@SMDelvInType = 0   
                 OR (@SMDelvInType = 6062001 AND Z.DelvInQty = 0)  
                 OR (@SMDelvInType = 6062002 AND Z.DelvInQty <> 0 AND Z.DelvQty <> Z.DelvInQty)  
                 OR (@SMDelvInType = 6062003 AND Z.DelvInQty <> 0 AND Z.DelvQty = Z.DelvInQty) 
     OR (@SMDelvInType = 6062007 AND (Z.DelvInQty = 0 OR (Z.DelvInQty <> 0 AND Z.DelvQty <> Z.DelvInQty))))
            AND (@WHSeq = 0 OR A.WHSeq = @WHSeq OR @WHSeq = 0 OR R.WHSeq = @WHSeq)  -- 20100325 �ڼҿ� �߰�  
            AND (@ApproReqEmpSeq = 0 OR Z.ApproReqEmpSeq = @ApproReqEmpSeq)      -- 11.06.10 �輼ȣ �߰�  
            AND (@ApproReqDeptSeq = 0 OR Z.ApproReqDeptSeq = @ApproReqDeptSeq)      -- 11.07.14 �輼ȣ �߰�
            AND (@IsPJTPur = 0 OR (ISNULL(I.PJTSeq,0) =  0 AND @IsPJTPur = 7063001)--�Ϲݱ���  
             OR (ISNULL(I.PJTSeq,0) <> 0 AND @IsPJTPur = 7063002))--������Ʈ����  
            AND (@UMPOReqType = 0 OR @UMPOReqType = II.MinorSeq)             
  
  
        UPDATE A
           SET DivDelvDateInfo = REPLACE((SELECT CONVERT(NVARCHAR(300), STUFF((SELECT ' ' +
                                                               SUBSTRING(PODelvDate, 0, 5) + '-' + SUBSTRING(PODelvDate, 5, 2) + '-' + SUBSTRING(PODelvDate, 7, 2)   
                                                               + '(' + CONVERT(NVARCHAR(300), PODelvQty) + ')' + CHAR(10)   AS [text()]   
                                                             FROM _TPUORDPODelvDate 
                                                            WHERE @CompanySeq = CompanySeq  
                                                              AND A.POSeq = POSeq
                                                              AND A.POSerl = POSerl
                                                            for xml path('')),1,1,' '))), ' ', '')
          FROM #TMP_TPUORDPOItem AS A
          JOIN _TPUORDPODelvDate AS B ON @CompanySeq = B.CompanySeq
                                     AND A.POSeq  = B.POSeq
                                     AND A.POSerl = B.POSerl
         SELECT * FROM #TMP_TPUORDPOItem ORDER BY PODate
  
     RETURN    
 /***************************************************************************************************************/
 
 go
 exec KPXCM_SPUORDPOItemListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PODateFr>20150701</PODateFr>
    <PODateTo>20150709</PODateTo>
    <PONo />
    <ApproReqNo />
    <DeptSeq />
    <EmpSeq />
    <POReqNo />
    <ItemNo />
    <ItemName />
    <Spec />
    <SMImpType />
    <CustSeq />
    <CustName />
    <ApproReqSeq />
    <ApproReqDeptSeq />
    <UMSupplyType />
    <ApproReqEmpSeq />
    <POReqSeq />
    <POReqEmpSeq />
    <SMCurrStatus />
    <SMAssetType />
    <WHSeq />
    <PJTName />
    <DelvDateFr />
    <PJTNo />
    <DelvDateTo />
    <SMDelvInType />
    <TopUnitNo />
    <TopUnitName />
    <IsPJTPur />
    <PurGroupDeptSeq>0</PurGroupDeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=2135,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1133