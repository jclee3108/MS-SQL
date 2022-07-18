IF OBJECT_ID('KPXLS_SSLImpDelvItemListQuery') IS NOT NULL 
    DROP PROC KPXLS_SSLImpDelvItemListQuery
GO 

-- Ver.20140630
  /************************************************************
  ��  �� - ������-�����԰�(��ȸ) : ǰ����Ȳ��ȸ
  �ۼ��� - 20090525
  �ۼ��� - �̼���
  ������ - 2009.12.02 �ڼҿ�
          :: ��õ����(SourceTable)/��õ������ȣ(SourceNo)/��õ��ȣ(SourceRefNo) ��ȸ ���� �߰� �� Field�߰�
          2010.06.22 LotNo �÷��߰� - ������
           2011.03.11 �̻�ȭ
          :: �԰�(Spec) ��ȸ ���� �߰�
          2012.08.16 ������
          :: ǰ����߼Һз� ��ȸ���� �߰�, ǰ����߼Һз� �並 �̿��� ���������� ����
 ************************************************************/
 CREATE PROC KPXLS_SSLImpDelvItemListQuery                
  @xmlDocument    NVARCHAR(MAX) ,            
  @xmlFlags     INT  = 0,            
  @ServiceSeq     INT  = 0,            
  @WorkingTag     NVARCHAR(10)= '',                  
  @CompanySeq     INT  = 1,            
  @LanguageSeq INT  = 1,            
  @UserSeq     INT  = 0,            
  @PgmSeq         INT  = 0         
     
 AS        
     DECLARE @docHandle           INT,
             @DelvNo              NVARCHAR(100),
             @DelvDateFr          NCHAR(8),
             @DelvDateTo          NCHAR(8),
             @BizUnit             INT,
             @DeptSeq             INT,
             @CustSeq             INT,
             @EmpSeq              INT,
             @SMProgressType      INT, 
             @ItemName            NVARCHAR(100),
             @ItemNo              NVARCHAR(100),
             @PJTName             NVARCHAR(200),
             @PJTNo               NVARCHAR(100),    
             @UMSupplyType        INT            ,    
             @TopUnitName         NVARCHAR(200)  ,    
             @TopUnitNo           NVARCHAR(200)  ,
             @SMAssetKind         INT          ,                
             @Spec     NVARCHAR(100),   -- 20110311 �̻�ȭ (�԰� ��ȸ���� �߰�)
             @ItemClassLSeq       INT,             -- 20120816 ������ (ǰ����߼Һз� �߰�)
             @ItemClassMSeq       INT,
             @ItemClassSSeq       INT,
             @LotNo               NVARCHAR(100) -- 20140709 �ڼ�ȣ �߰�
      -- �߰����� 20091202 �ڼҿ� 
     DECLARE @SourceTableSeq      INT,  
             @SourceNo            NVARCHAR(30),  
             @SourceRefNo         NVARCHAR(30),  
             @TableName           NVARCHAR(100),  
             @TableSeq            INT,  
             @SQL                 NVARCHAR(MAX),
    @SMImpKind    INT    --20091207 ���游 �߰� (���Ա��� �˻����� �߰�)
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
      SELECT @DelvNo          = ISNULL(DelvNo,''),
            @DelvDateFr      = ISNULL(DelvDateFr,''),
            @DelvDateTo      = ISNULL(DelvDateTo,''),
            @BizUnit         = ISNULL(BizUnit,0),
            @DeptSeq         = ISNULL(DeptSeq,0),
            @CustSeq         = ISNULL(CustSeq,0),
            @EmpSeq          = ISNULL(EmpSeq,0),
            @SMProgressType  = ISNULL(SMProgressType, 0),
            @ItemName        = ISNULL(ItemName,''),
            @ItemNo          = ISNULL(ItemNo,''),
            @PJTName         = ISNULL(PJTName, ''),
            @PJTNo           = ISNULL(PJTNo,''),  
            @SourceTableSeq  = ISNULL(SourceTableSeq, 0), -- �߰� 20091202 �ڼҿ� 
            @SourceNo        = ISNULL(SourceNo, ''),   -- �߰� 20091202 �ڼҿ� 
            @SourceRefNo     = ISNULL(SourceRefNo, ''),  -- �߰� 20091202 �ڼҿ� 
      @SMImpKind  = ISNULL(SMImpKind,0),       -- �߰� 20091207 ���游 
            @UMSupplyType    = ISNULL(UMSupplyType ,  0),    
            @TopUnitName     = ISNULL(TopUnitName  , ''),                        
            @TopUnitNo       = ISNULL(TopUnitNo    , ''),
            @SMAssetKind     = ISNULL(SMAssetKind    ,  0),                 
            @Spec   = ISNULL(Spec    , ''),     -- 20110311 �̻�ȭ (�԰� ��ȸ���� �߰�)
            @ItemClassLSeq   = ISNULL(ItemClassLSeq, 0),      -- 20120816 ������ (ǰ����߼Һз� �߰�)
            @ItemClassMSeq   = ISNULL(ItemClassMSeq, 0),  
            @ItemClassSSeq   = ISNULL(ItemClassSSeq, 0),
            @LotNo           = ISNULL(LotNo, '')  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
     WITH (  DelvNo              NVARCHAR(100),
             DelvDateFr          NCHAR(8),
             DelvDateTo          NCHAR(8),
             BizUnit             INT,
             DeptSeq             INT,
             CustSeq             INT,
             EmpSeq              INT,
             SMProgressType      INT,
             ItemName            NVARCHAR(100),
             ItemNo              NVARCHAR(100),
             PJTName             NVARCHAR(200),
             PJTNo               NVARCHAR(100),  
             SourceTableSeq      INT,            -- �߰� 20091202 �ڼҿ� 
             SourceNo            NVARCHAR(30),   -- �߰� 20091202 �ڼҿ� 
             SourceRefNo         NVARCHAR(30), -- �߰� 20091202 �ڼҿ�
    SMImpKind   INT ,           -- �߰� 20091207 ���游
             UMSupplyType   INT          ,    
             TopUnitName    NVARCHAR(200),    
             TopUnitNo      NVARCHAR(200),
             SMAssetKind         INT,
             Spec     NVARCHAR(100),  -- 20110311 �̻�ȭ (�԰� ��ȸ���� �߰�) 
             ItemClassLSeq       INT,            -- 20120816 ������ (ǰ����߼Һз� �߰�)
             ItemClassMSeq       INT,        
             ItemClassSSeq       INT,
             LotNo               NVARCHAR(100) )   
      IF @DelvDateFr = '' SELECT @DelvDateFr = '00010101'
     IF @DelvDateTo = '' SELECT @DelvDateTo = '99991231'
  
     -- ���ʵ��������̺�
     CREATE TABLE #TMP (IDX_NO    INT identity,  Seq       INT, Serl      INT) 
      --  ���� �������̺�  
     CREATE TABLE #TEMPTUIImpDelvProg(IDX_NO INT IDENTITY, CompanySeq INT, DelvSeq INT, DelvSerl INT, CompleteCHECK INT, SMProgressType INT, IsStop NCHAR(1)) 
      -- �߰蹫�� ����������� (�������� ����)
     CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT,  TABLENAME   NVARCHAR(100))      
      -- ���೻�� ������
     CREATE TABLE #TCOMProgressTracking(IDX_NO  INT,            IDOrder INT,             Seq  INT,               Serl INT,           SubSerl     INT,      
                                        Qty     DECIMAL(19, 5), STDQty  DECIMAL(19, 5),  Amt  DECIMAL(19, 5)   , VAT  DECIMAL(19, 5))      
      CREATE TABLE #TempDelvProg(DelvSeq  INT, DelvSerl  INT, Qty DECIMAL(19,5), STDQty DECIMAL(19,5))
      -- ��õ���̺�
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))        
      -- ��õ ������ ���̺�
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5)) 
      CREATE TABLE #TMP_DelvSource(DelvSeq INT, DelvSerl INT, BLSeq INT, BLSerl INT, BLNo NVARCHAR(20))
  -------------------------------------------------------------------------------------------------------------------------------------------------------------
      -- ���ʵ�����                                                         
     INSERT INTO #TMP(Seq, Serl)
     SELECT DISTINCT B.DelvSeq, B.DelvSerl
       FROM _TUIImpDelv AS A WITH(NOLOCK)
             JOIN _TUIImpDelvItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq
             LEFT OUTER JOIN _TDAItem       AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq AND B.ItemSeq = L.ItemSeq
             LEFT OUTER JOIN _TPJTProject   AS P WITH(NOLOCK) ON A.CompanySeq = P.CompanySeq AND B.PJTSeq = P.PJTSeq
             LEFT OUTER JOIN _TDAItemClass  AS T WITH(NOLOCK) ON L.CompanySeq = T.CompanySeq AND B.ItemSeq = T.ItemSeq    --20120326 ������ �߰�
      WHERE A.CompanySeq = @CompanySeq
       AND (@DelvNo = '' OR A.DelvNo LIKE @DelvNo + '%')
       AND (@BizUnit = 0 OR @BizUnit = A.BizUnit)
       AND (@DeptSeq = 0 OR @DeptSeq = A.DeptSeq)
       AND (@CustSeq = 0 OR @CustSeq = A.CustSeq)
       AND (@EmpSeq = 0 OR @EmpSeq = A.EmpSeq)
       AND (A.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)
       AND (L.ItemName = '' OR L.ItemName LIKE @ItemName + '%')
       AND (L.ItemNo = '' OR L.ItemNo LIKE @ItemNo + '%')
       AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')
       AND (@PJTNo = '' OR P.PJTNo LIKE @PJTNo + '%')
       AND (@Spec  = '' OR L.Spec  LIKE @Spec   + '%') -- 20110311 �̻�ȭ (�԰� ��ȸ���� �߰�)
      -- ������µ�����
     INSERT INTO #TEMPTUIImpDelvProg(CompanySeq, DelvSeq, DelvSerl, CompleteCHECK, IsStop)    
     SELECT @CompanySeq, A.Seq, A.Serl, -1, NULL  
       FROM #TMP  AS A 
  
     EXEC _SCOMProgStatus @CompanySeq, '_TUIImpDelvItem', 1036009, '#TEMPTUIImpDelvProg', 'DelvSeq', 'DelvSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', '', 'DelvSeq', 'DelvSerl', '', '_TUIImpDelv', @PgmSeq
   
     UPDATE #TEMPTUIImpDelvProg     
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --�����ߴ�    
                                          WHEN B.MinorSeq = 1037009 THEN 1037009 -- �Ϸ�    
                                          WHEN A.IsStop = '1' THEN 1037005       -- �ߴ�    
                                          WHEN A.CompleteCHECK = 1 THEN 1037003  -- Ȯ��(����)  
                                          ELSE B.MinorSeq END)    
       FROM #TEMPTUIImpDelvProg AS A WITH(NOLOCK)    
           LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND B.MajorSeq = 1037    
                                                       AND A.CompleteCHECK = B.Minorvalue  
  
     -- Invoice ������
     INSERT #TMP_PROGRESSTABLE      
     SELECT 1,'_TSLInvoiceItem'    
      EXEC _SCOMProgressTracking @CompanySeq, '_TUIImpDelvItem', '#TMP', 'Seq', 'Serl', ''
      INSERT INTO #TempDelvProg(DelvSeq, DelvSerl, Qty, STDQty)
     SELECT A.Seq, A.Serl, SUM(ISNULL(B.Qty,0)), SUM(ISNULL(B.STDQty,0))
       FROM #TMP AS A
             JOIN #TCOMProgressTracking AS B ON A.IDX_NO = B.IDX_NO
       GROUP BY A.Seq, A.Serl
  --
 --    -- BL(��õ) ������
 --    -- ��õ���̺�
 --    INSERT #TMP_SOURCETABLE  
 --    SELECT 1,'_TUIImpBLItem'   -- BL
 --
 --    -- ��õ������ BL
 --    EXEC _SCOMSourceTracking @CompanySeq, '_TUIImpDelvItem', '#TMP', 'Seq', 'Serl', ''    
 --
 --    INSERT INTO #TMP_DelvSource(DelvSeq, DelvSerl, BLSeq, BLSerl, BLNo)
 --    SELECT B.Seq, B.Serl, C.Seq, C.Serl, D.BLNo
 --      FROM #TMP AS B 
 --            LEFT OUTER JOIN #TCOMSourceTracking AS C ON B.IDX_NO = C.IDX_NO
 --            LEFT OUTER JOIN _TUIImpBL AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND C.Seq = D.BLSeq
      -------------------------------------------        
     -- ��õ���� ��ȸ   20091202 �ڼҿ� �߰�
     -------------------------------------------     
     CREATE TABLE #TempResult  
     (  
         InOutSeq  INT,  -- ���೻�ι�ȣ  
         InOutSerl  INT,  -- �������  
         InOutSubSerl    INT,  
         SourceRefNo     NVARCHAR(30),  
         SourceNo        NVARCHAR(30)  
     )  
   
      DELETE FROM #TMP_SOURCETABLE
     DELETE FROM #TCOMSourceTracking
      IF ISNULL(@SourceTableSeq, 0) <> 0  
     BEGIN  
          
         CREATE TABLE #TMP_SOURCEITEM  
         (        
             IDX_NO        INT IDENTITY,        
             SourceSeq     INT,        
             SourceSerl    INT,        
             SourceSubSerl INT  
         )           
   
   
         IF ISNULL(@TableName, '') <> ''  
         BEGIN  
             SELECT @TableSeq = ProgTableSeq      
               FROM _TCOMProgTable WITH(NOLOCK)--���������̺�      
              WHERE ProgTableName = @TableName    
         END  
   
         IF ISNULL(@TableSeq,0) = 0  
         BEGIN  
             SELECT @TableSeq = ISNULL(ProgTableSeq, 0)  
               FROM _TCAPgmDev  
              WHERE PgmSeq = @PgmSeq  
   
             SELECT @TableName = ISNULL(ProgTableName, '')  
               FROM _TCOMProgTable  
              WHERE ProgTableSeq = @TableSeq  
         END  
  
   
         INSERT INTO #TMP_SOURCETABLE(IDOrder, TABLENAME)      
         SELECT 1, ISNULL(ProgTableName,'')  
           FROM _TCOMProgTable  
          WHERE ProgTableSeq = @SourceTableSeq  
  
         -- ����  
         INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(����), 2(������)      
         SELECT A.Seq, A.Serl, 0      
           FROM #TMP     AS A WITH(NOLOCK)           
   
   
         EXEC _SCOMSourceTracking @CompanySeq, @TableName, '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''        
   
   
   -- ��������
         SELECT @SQL = 'INSERT INTO #TempResult '
         SELECT @SQL = @SQL + 'SELECT C.SourceSeq, C.SourceSerl, C.SourceSubSerl, ' +
                              CASE WHEN ISNULL(A.ProgMasterTableName,'') = '' THEN ''''' AS InOutRefNo, '''' AS InOutNo ' 
                                                                              ELSE (CASE WHEN ISNULL(A.ProgTableRefNoColumn,'') = '' THEN ''''' AS InOutNo, ' ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableRefNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutNo, ' END) +
                                                                                   (CASE WHEN ISNULL(A.ProgTableNoColumn,'') = '' THEN ''''' AS InOutRefNo ' ELSE (CASE WHEN ISNULL(A.ProgMasterSubTableName,'') = '' THEN 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo '                                                                                                                                                                                                                          
                                                                                                                                                                                                                    ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterSubTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo  ' END) END) END + 
                             ' FROM #TCOMSourceTracking AS A  ' +
                             ' JOIN #TMP_SOURCETABLE AS B ON A.IDOrder = B.IDOrder ' +
                             ' JOIN #TMP_SOURCEITEM AS  C ON A.IDX_NO  = C.IDX_NO ' +
                             ' JOIN _TCOMProgTable AS D WITH(NOLOCK) ON B.TableName = D.ProgTableName  '
           FROM _TCOMProgTable AS A WITH(NOLOCK) 
          WHERE A.ProgTableSeq = @SourceTableSeq
 -- ��������
   
          EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT', @CompanySeq  
   
         SELECT @SQL = ''
     END
 /************************************************************************************************************************************************************************/
      /**********************************************************
         ������ȸ������                                         
     **********************************************************/
     SELECT A.BizUnit,                                  --����ι��ڵ�
            A.DelvNo,                                   --Delv��ȣ
            A.DelvDate,                                 --Delv����
            A.DeptSeq,                                  --�μ��ڵ�
            A.EmpSeq,                                   --����ڵ�
            A.CustSeq,                                  --�ŷ�ó�ڵ�
            A.CurrSeq,                                  --��ȭ�ڵ�
            A.ExRate,                                   --ȯ��
            B.DelvSeq,
            B.DelvSerl,
            B.ItemSeq,                                  --ǰ���ڵ�
            B.UnitSeq,                                  --�����ڵ�
            B.Price,                                    --��ȭ�ܰ�
            B.Qty,                                      --����
            B.CurAmt,                                   --��ȭ�ݾ�
            B.DomAmt,                                   --��ȭ�ݾ�
            CASE WHEN ISNULL(C.BasicAmt,0) = 0
                 THEN (A.ExRate*B.Price)
                 ELSE ((A.ExRate / C.BasicAmt) * B.Price) END AS DomPrice,            --��ȭ�ܰ�
            B.WHSeq,                                    --�԰�â���ڵ�
            B.STDUnitSeq,                               --���ش����ڵ�
            B.STDQty,                                    --���ش�������
            (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)      AS BizUnitName,         --����ι�
            (SELECT DeptName    FROM _TDADept    WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)      AS DeptName,            --�μ�
            (SELECT EmpName     FROM _TDAEmp     WHERE CompanySeq = @CompanySeq AND A.EmpSeq  = EmpSeq)       AS EmpName,             --���
            (SELECT CustName    FROM _TDACust    WHERE CompanySeq = @CompanySeq AND A.CustSeq = CustSeq)      AS CustName,            --�ŷ�ó  
            (SELECT CurrName    FROM _TDACurr    WHERE CompanySeq = @CompanySeq AND A.CurrSeq = CurrSeq)      AS CurrName,            --��ȭ
            L.ItemNo            AS ItemNo,              --ǰ���ȣ
            L.ItemName          AS ItemName,            --ǰ���
            L.Spec              AS Spec,                --�԰�
            (SELECT UnitName    FROM _TDAUnit    WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)      AS UnitName,            --����
            (SELECT WHName      FROM _TDAWH      WHERE CompanySeq = @CompanySeq AND B.WHSeq   = WHSeq)        AS WHName,              --�԰�â��
            (SELECT UnitName    FROM _TDAUnit    WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq)   AS STDUnitName,         --���ش���
            B.OKCurAmt          AS OKCurAmt,
            B.OKDomAmt          AS OKDomAmt,
            A.SMImpKind         AS SMImpKind,
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMImpKind),'') AS SMImpKindName,
            B.LotNo             AS LotNo,
            Z.MinorName         AS SMProgressTypeName, -- �������
            O.BLNo              AS BLNo, 
            O.BLSerl            AS BLSerl,
            B.PJTSeq,
            P.PJTName, P.PJTNo,
            A.IsPJT,
            J.Qty    AS ExpInvoiceQty,
            J.STDQty AS ExpInvoiceSTDQty,  
            ISNULL(AW.SourceNo,'') AS SourceNo,         -- �߰� 20091201 �ڼҿ� 
            ISNULL(AW.SourceRefNo, '') AS SourceRefNo,  -- �߰� 20091201 �ڼҿ�
            M2.ItemNo    AS UpperUnitNo,   
            M2.ItemName  AS UpperUnitName,     
            M4.ItemName  AS TopUnitName,   
            M4.ItemNo    AS TopUnitNo,
            M5.UMMatQuality AS UMMatQuality,
            M6.MinorName AS UMMatQualityName,
            CASE WHEN ISNULL(IH.SlipSeq,0) <> 0 THEN '1' ELSE '0' END AS IsCostSlip,
            CASE WHEN ISNULL(IH.DelvCostSeq,0) <> 0 THEN '1' ELSE '0' END AS IsCostCalc, 
            IA.SMAssetGrp                AS SMAssetKind      ,     -- 2012.02.24 �̼��� �߰� 
            IA.AssetName                 AS SMAssetKindName  ,     -- 2012.02.24 �̼��� �߰� 
            B.Remark     AS RemarkS,    -- ǰ����
            
            -- 2015.09.30 �ڼ��� ::CONVERT ó��
            CASE WHEN ISNULL(B.STDQty, 0) <> 0
                 THEN CONVERT(DECIMAL(19,5), B.OKDomAmt / B.STDQty)
                 ELSE 0 END AS OKDomPrice, -- ��ȭ�԰�ܰ�(���ش���)
            CASE WHEN ISNULL(B.Qty, 0) <> 0
                 THEN CONVERT(DECIMAL(19,5),B.OKDomAmt / B.Qty)
                 ELSE 0 END AS PUDomPrice, -- ��ȭ�԰�ܰ�(���Ŵ���)
            
            T1.ItemClassSName         AS ItemClassSName,    --ǰ��Һз�  2012.08.16 by ������  
            T1.ItemClassMName         AS ItemClassMName,    --ǰ���ߺз�                               
            T1.ItemClassLName         AS ItemClassLName,    --ǰ���з�  
            B.Memo1                   AS Memo1,
            B.Memo2                   AS Memo2,
            B.Memo3                   AS IsPass,
            B.Memo4                   AS Memo4,
            B.Memo5               AS Memo5,
            B.Memo6                   AS Memo6,
            B.Memo7                   AS Memo7,
            B.Memo8                   AS Memo8,
            ISNULL(WHI.Location, '')  AS WHLocation,         -- 20141126 ����ȯ(2014) �߰�     
            G.OKQty, 
            G.BadQty, 
            LL.TestDate AS QCDate, 
            CONVERT(NCHAR(8),LL.CfmDateTime,112) AS CfmDate, 
            CONVERT(INT,0) AS SMTestResult, 
            CONVERT(NVARCHAR(200),'') AS SMTestResultName, 
            E.ReqSeq, 
            E.ReqSerl, 
            CASE WHEN E.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsRequest 
       INTO #Result 
       FROM #TMP AS D 
        JOIN _TUIImpDelv                 AS A WITH(NOLOCK)  ON D.Seq = A.DelvSeq
        JOIN _TUIImpDelvItem             AS B WITH(NOLOCK)  ON A.CompanySeq = B.CompanySeq AND D.Seq = B.DelvSeq AND D.Serl = B.DelvSerl
        LEFT OUTER JOIN _TDACurr         AS C WITH(NOLOCK)  ON A.CompanySeq = C.CompanySeq AND A.CurrSeq = C.CurrSeq
        LEFT OUTER JOIN _TDAItem         AS L WITH(NOLOCK)  ON A.CompanySeq = L.CompanySeq AND B.ItemSeq = L.ItemSeq
        LEFT OUTER JOIN _TPJTProject     AS P WITH(NOLOCK)  ON A.CompanySeq = P.CompanySeq AND B.PJTSeq = P.PJTSeq
        LEFT OUTER JOIN #TempDelvProg    AS J WITH(NOLOCK)  ON B.DelvSeq = J.DelvSeq AND B.DelvSerl = J.DelvSerl
        LEFT OUTER JOIN #TEMPTUIImpDelvProg AS K WITH(NOLOCK) ON B.DelvSeq = K.DelvSeq AND B.DelvSerl = K.DelvSerl
        LEFT OUTER JOIN _TDASMinor       AS Z WITH(NOLOCK)  ON Z.CompanySeq      = @CompanySeq  
                                                           AND K.SMProgressType  = MinorSeq
        LEFT OUTER JOIN #TMP_DelvSource  AS O               ON D.Seq             = O.DelvSeq 
                                                           AND D.Serl            = O.DelvSerl  
        LEFT OUTER JOIN #TempResult      AS AW WITH(NOLOCK) ON A.CompanySeq      = @CompanySeq  -- �߰� 20091202 �ڼҿ� 
                                                           AND B.DelvSeq         = AW.InOutSeq     -- �߰� 20091202 �ڼҿ� 
                                                           AND B.DelvSerl        = AW.InOutSerl   -- �߰� 20091202 �ڼҿ�
        LEFT OUTER JOIN _TPJTBOM         AS M5 WITH(NOLOCK) ON A.CompanySeq      = M5.CompanySEq    
                                                           AND B.PJTSeq          = M5.PJTSeq    
                                                           AND B.WBSSeq          = M5.BOMSerl    
        LEFT OUTER JOIN _TPJTBOM         AS M1 WITH(NOLOCK) ON B.CompanySeq      = M1.CompanySeq    
                                                           AND B.PJTSeq          = M1.PJTSeq 
                                                           AND M1.BOMSerl        <> -1 
                                                           AND M5.UpperBOMSerl   = M1.BOMSerl 
                                                           AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- ���� BOM    
        LEFT OUTER JOIN _TDAItem         AS M2 WITH(NOLOCK) ON B.CompanySEq      = M2.CompanySeq    
                                                           AND M1.ItemSeq        = M2.ItemSeq    
        LEFT OUTER JOIN _TPJTBOM         AS M3 WITH(NOLOCK) ON B.CompanySeq      = M3.CompanySeq    
                                                           AND B.PJTSeq          = M3.PJTSeq    
                                                           AND M3.BOMSerl        <> -1    
                                                           AND ISNULL(M3.BeforeBOMSerl,0) = 0    
                                                           AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- �ֻ���   
                                                           AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1  
        LEFT OUTER JOIN _TDAItem         AS M4 WITH(NOLOCK) ON B.CompanySeq      = M4.CompanySeq    
                                                           AND M3.ItemSeq        = M4.ItemSeq    
        LEFT OUTER JOIN _TDAUMinor       AS M6 WITH(NOLOCK) ON B.CompanySeq      = M5.CompanySeq
                                                           AND M5.UMMatQuality   = M6.MinorSeq
        LEFT OUTER JOIN _TUIImpDelvCostDiv AS IH WITH(NOLOCK) ON A.CompanySeq    = IH.CompanySeq 
                                                           AND A.DelvSeq         = IH.DelvSeq
        LEFT OUTER JOIN _TDAItemAsset    AS IA WITH(NOLOCK) ON L.CompanySEq      = IA.CompanySeq    
                                                           AND IA.AssetSeq       = L.AssetSeq  
        LEFT OUTER JOIN _TDAItemClass    AS T WITH(NOLOCK)  ON B.ItemSeq         = T.ItemSeq   -- ǰ����߼Һз� �߰�, 2012.08.16 by ������  
                                                           AND T.UMajorItemClass IN (2001, 2004)    
                                         AND B.CompanySeq      = T.CompanySeq    
        LEFT OUTER JOIN _VDAItemClass    AS T1 WITH(NOLOCK) ON T.CompanySeq      = T1.CompanySeq    
                                                           AND T.UMItemClass     = T1.ItemClassSSeq    
        LEFT OUTER JOIN _TDAWHItem       AS WHI WITH(NOLOCK) ON WHI.CompanySeq   = B.CompanySeq
                                                            AND WHI.WHseq        = B.WHseq   
                                                            AND WHI.Itemseq      = B.Itemseq  -- â��Location �߰� :: 20141126 ����ȯ(2014)  
        LEFT OUTER JOIN KPXLS_TQCRequestItem    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.SourceSeq = B.DelvSeq AND E.SourceSerl = B.DelvSerl ) 
        LEFT OUTER JOIN KPXLS_TQCRequest        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = E.ReqSeq AND F.SMSourceType = 1000522007 AND F.PgmSeq = CASE WHEN B.Memo3 = '1' THEN 1027881 ELSE 1027845 END ) 
        LEFT OUTER JOIN KPX_TQCTestResult       AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ReqSeq = E.ReqSeq AND G.ReqSerl = E.ReqSerl ) 
        LEFT OUTER JOIN KPXLS_TQCTestResultAdd  AS LL WITH(NOLOCK) ON ( LL.CompanySeq = @CompanySeq AND LL.QCSeq = G.QCSeq ) 
       WHERE A.CompanySeq = @CompanySeq
         AND (@SMProgressType = 0 OR K.SMProgressType = @SMProgressType) 
         AND (@SourceNo = '' OR AW.SourceNo LIKE @SourceNo + '%')           -- �߰� 20091202 �ڼҿ�
         AND (@SourceRefNo = '' OR AW.SourceRefNo LIKE @SourceRefNo + '%')  -- �߰� 20091202 �ڼҿ�
         AND (@SMImpKind = 0 OR A.SMImpKind = @SMImpKind)
         AND (@UMSupplyType = 0  OR M5.UMSupplyType = @UMSupplyType)    
         AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')         
         AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%') 
         AND (@SMAssetKind= 0  OR IA.AssetSeq  = RIGHT(@SMAssetKind, 2))  
         AND (@ItemClassSSeq = 0  OR T1.ItemClassSSeq = @ItemClassSSeq)      -- 2012.08.16 by ������ �߰� 
         AND (@ItemClassMSeq = 0  OR T1.ItemClassMSeq = @ItemClassMSeq)       
         AND (@ItemClassLSeq = 0  OR T1.ItemClassLSeq = @ItemClassLSeq)
         AND ISNULL(B.LotNo, '') LIKE @LotNo + '%'     
    ORDER BY A.DelvDate
    


    UPDATE A  
       SET A.SMTestResult    = CASE WHEN A.IsPass = '1' THEN 1010418001 ELSE 1010418004 END   --�̰˻�  
      FROM #Result AS A   
                                            LEFT OUTER JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                               AND C.ReqSeq = A.ReqSeq  
                                                                                               AND C.ReqSerl    = A.ReqSerl  
                                            LEFT OUTER JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                               AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(B.CompanySeq,0) = 0    -- ��� ����       
    
    UPDATE A  
       SET A.SMTestResult    = 1010418002  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.SMTestResult,0) = 0  
      AND ISNULL(B.SMTestResult ,0) = 6035004   --���հ�  
      AND ISNULL(B.IsSpecial, '') <> '1'  
  
    UPDATE A  
       SET A.SMTestResult    = 1010418003   --Ưä  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.SMTestResult,0) = 0  
      AND ISNULL(B.IsSpecial, '') = '1'  
  
    
    UPDATE A  
       SET A.SMTestResult    = CASE B.SMTestResult WHEN 6035001 /*���˻�*/ THEN 1010418005 --���˻�  
                                                   WHEN 6035003            THEN 1010418001 END  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.SMTestResult,0) = 0  
  
    UPDATE A  
       SET A.SMTestResultName   = B.MinorName  
      FROM #Result AS A JOIN _TDAUMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.SMTestResult = B.MinorSeq  
    
    SELECT * FROM #Result 
    
    RETURN
    go
    exec KPXLS_SSLImpDelvItemListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <UMSupplyType />
    <PJTName />
    <PJTNo />
    <SMProgressType />
    <TopUnitNo />
    <TopUnitName />
    <BizUnit>1</BizUnit>
    <DelvDateFr>20140101</DelvDateFr>
    <DelvDateTo>20151218</DelvDateTo>
    <CustSeq />
    <SMImpKind />
    <SMImpKindName />
    <DelvNo />
    <DeptSeq />
    <EmpSeq />
    <SMAssetKind />
    <ItemName />
    <ItemNo />
    <Spec />
    <LotNo />
    <SourceTableSeq />
    <SourceNo />
    <SourceRefNo />
    <ItemClassLSeq />
    <ItemClassLName />
    <ItemClassMSeq />
    <ItemClassMName />
    <ItemClassSSeq />
    <ItemClassSName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033919,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028086