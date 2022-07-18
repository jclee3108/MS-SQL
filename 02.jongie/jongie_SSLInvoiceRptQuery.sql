
IF OBJECT_ID('jongie_SSLInvoiceRptQuery') IS NOT NULL
    DROP PROC jongie_SSLInvoiceRptQuery 
GO

-- v2013.08.07 

-- �ŷ�����(��¹�)_jongie by����õ
 CREATE PROC jongie_SSLInvoiceRptQuery    
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS 
    
    DECLARE @docHandle    INT,    
            @InvoiceSeq   INT,   
            @TotCurAmt    DECIMAL(19,5),  
            @TotVAT       DECIMAL(19,5),   
            @TotAmt       DECIMAL(19,5),     -- 20101224 ���ؽ� �߰�
            @TotDomAmt    DECIMAL(19,5),     -- 20101224 ���ؽ� �߰�
            @InvoiceDate  NCHAR(8),
            @HapAmt       Money,
            @ABSHapAmt    Money,
            @HanAmt       NVARCHAR(100),
            @HapDomAmt    Money,            -- 20101224 ���ؽ� �߰�
            @ABSHapDomAmt Money,            -- 20101224 ���ؽ� �߰�         
            @HanDomAmt    NVARCHAR(100),    -- 20101224 ���ؽ� �߰�
            -- �������
            @Seq            INT, 
            @OrderSeq       INT, 
            @OrderSerl      INT, 
            @SubSeq         INT, 
            @SpecName       NVARCHAR(200),   
            @SpecValue      NVARCHAR(200),
            @CustSeq        INT    
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
   
     -- Temp�� INSERT      
   
     SELECT  @InvoiceSeq  = InvoiceSeq,
             @InvoiceDate = InvoiceDate  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
     WITH (InvoiceSeq INT,
           InvoiceDate NCHAR(8))   
           
     -- �ŷ�óǰ���Ī�� ������������ �ŷ�ó�ڵ� ��ȸ  
     SELECT @CustSeq = CustSeq  
       FROM _TSLInvoice 
      WHERE CompanySeq = @CompanySeq
        AND InvoiceSeq = @InvoiceSeq                            
   
   
 /***********************************************************************************************************************************************/  
     CREATE TABLE #Tmp_InvoiceProg(IDX_NO INT IDENTITY, InvoiceSeq INT, InvoiceSerl INT, OrderSeq   INT NULL,   OrderSerl INT NULL)     
      -- ��õ���̺�
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))        
      -- ��õ ������ ���̺�
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))    
      -- ������ �׸�  
     CREATE TABLE #TempSOSpec(Seq INT IDENTITY, OrderSeq INT, OrderSerl INT,  SpecName  NVARCHAR(100), SpecValue NVARCHAR(100))  
     
     -- �ŷ�óǰ���Ī��������
     CREATE TABLE #TempCustItem(InvoiceSeq   INT,           InvoiceSerl INT,           ItemSeq INT, 
                                CustItemName NVARCHAR(100), CustItemNo  NVARCHAR(100), CustItemSpec NVARCHAR(100))                               
      --/**************************************************************************
     -- ������Data                                                                
     --**************************************************************************/ 
     INSERT INTO #Tmp_InvoiceProg(InvoiceSeq, InvoiceSerl, OrderSeq, OrderSerl)
     SELECT InvoiceSeq, InvoiceSerl, 0, 0
       FROM _TSLInvoiceItem 
      WHERE CompanySeq = @CompanySeq
        AND InvoiceSeq = @InvoiceSeq
      INSERT #TMP_SOURCETABLE
     SELECT 1, '_TSLOrderItem'
      -- ����Dataã��(��õ)
     EXEC _SCOMSourceTracking @CompanySeq, '_TSLInvoiceItem', '#Tmp_InvoiceProg', 'InvoiceSeq', 'InvoiceSerl', ''     
      UPDATE #Tmp_InvoiceProg
        SET OrderSeq  = Seq,
            OrderSerl = Serl
       FROM #Tmp_InvoiceProg AS A
             JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
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
               FROM _TSLOrderItemspecItem  
              WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl > @SubSeq AND CompanySeq = @CompanySeq  
              ORDER BY OrderSpecSerl  
   
             IF @@Rowcount = 0 BREAK  
   
             SET ROWCOUNT 0  
   
             IF ISNULL(@SpecName,'') = ''  
             BEGIN  
                 SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN (SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue)   
                                                                                             ELSE A.SpecItemValue END)  
                   FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND B.CompanySeq = @CompanySeq  
                  WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq  
             END  
             ELSE  
             BEGIN  
                 SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN (SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue)   
                                                                                             ELSE A.SpecItemValue END)  
                   FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND B.CompanySeq = @CompanySeq  
                  WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq  
             END  
   
             UPDATE #TempSOSpec  
                SET SpecName = @SpecName, SpecValue = @SpecValue  
              WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl  
   
         END  
   
     END  
     SET ROWCOUNT 0  
      --/**************************************************************************
     -- �ݾ�                                                                
     --**************************************************************************/ 
     SELECT @TotCurAmt = SUM(CurAmt),   
            @TotVAT    = SUM(CurVAT),   
            @TotAmt    = ISNULL(SUM(CurAmt), 0) + ISNULL(SUM(CurVAT), 0),
            @TotDomAmt = ISNULL(SUM(DomAmt), 0) + ISNULL(SUM(DomVAT), 0)     -- 20101224 ���ؽ� �߰�
      FROM _TSLInvoiceItem  
     WHERE CompanySeq = @CompanySeq  
       AND InvoiceSeq = @InvoiceSeq  
    
     /* �հ�ݾ��� �ѱ۷� ��ȯ */   
     -- �ݾ��� �ѱ۷� ��ȯ     
     SELECT @ABSHapAmt = ABS(@TotAmt)  
     EXEC _SDAGetAmtHan @ABSHapAmt , @HanAmt OUTPUT
      -- ��ȭ�ݾ��� �ѱ۷� ��ȯ
     SELECT @ABSHapDomAmt = ABS(@TotDomAmt)                      -- 20101224 ���ؽ� �߰�
     EXEC _SDAGetAmtHan @ABSHapDomAmt , @HanDomAmt OUTPUT        -- 20101224 ���ؽ� �߰�
       
     -- �ŷ�óǰ�� ã��
     INSERT INTO #TempCustItem(InvoiceSeq, InvoiceSerl, ItemSeq, CustItemName, CustItemNo, CustItemSpec)
     SELECT A.InvoiceSeq, A.InvoiceSerl, A.ItemSeq, 
            ISNULL(CASE ISNULL(B.CustItemName, '') WHEN '' THEN (SELECT ISNULL(CI.CustItemName, '') FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)
                                                   ELSE ISNULL(B.CustItemName, '') END, ''), 
            ISNULL(CASE ISNULL(B.CustItemNo, '') WHEN '' THEN (SELECT ISNULL(CI.CustItemNo, '') FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)
                                                 ELSE ISNULL(B.CustItemNo, '') END, ''), 
            ISNULL(CASE ISNULL(B.CustItemSpec,  '') WHEN '' THEN (SELECT ISNULL(CI.CustItemSpec, '') FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)
                                                   ELSE ISNULL(B.CustItemSpec, '') END, '')
       FROM _TSLInvoiceItem AS A
             LEFT OUTER JOIN _TSLCustItem AS B ON A.CompanySeq = B.CompanySeq
                                              AND B.CustSeq    = @CustSeq
                                              AND A.ItemSeq    = B.ItemSeq
                                              AND A.UnitSeq    = B.UnitSeq
      WHERE A.CompanySeq = @CompanySeq
        AND A.InvoiceSeq = @InvoiceSeq                                             
      
  -------------------------------------------------------------------  
     -- ������̷� START
     -------------------------------------------------------------------  
     SELECT TaxUnit, TaxNo, TaxSerial, '' AS TaxNoSerl,  
            FrDate,   
            ToDate,    
            TaxName, Owner, BizType, BizItem,   
            Zip,     Addr1, Addr2,   Addr3,   VATRptAddr,  
            TelNo,   FaxNo  
       INTO #TTaxUnit  
       FROM _TDATaxUnitHist   
      WHERE CompanySeq = @CompanySeq  
      UNION ALL  
     SELECT TaxUnit, TaxNo, TaxSerial, TaxNoSerl,   
            ISNULL((SELECT CONVERT(NCHAR(8),DATEADD(DD,1,MAX(ToDate)),112) FROM _TDATaxUnitHist WHERE CompanySeq = A.CompanySeq AND TaxUnit = A.TaxUnit),'19000101'),  
            '99991231',   
            TaxName, Owner, BizType, BizItem,   
            Zip,     Addr1, Addr2,   Addr3,  VATRptAddr,  
            TelNo,   FaxNo  
       FROM _TDATaxUnit A  
      WHERE CompanySeq = @CompanySeq  
      ORDER BY TaxUnit, ToDate 
  
       
     DECLARE @pIsAccTax        INT,  -- ����ڴ���������������  
             @pIsAccTaxDate    NCHAR(8),  -- ����ڴ����������� �������  
             @pIsAccTaxUnit    NCHAR(15) -- ����ڴ����������� �ֻ���� ��ȣ 
             
     SELECT @pIsAccTax     = ISNULL((SELECT EnvValue FROM _TCOMEnv WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = '4016'),'0')  
     SELECT @pIsAccTaxDate = ISNULL((SELECT EnvValue FROM _TCOMEnv WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = '4017'),'19000101')  
     SELECT @pIsAccTaxUnit = ISNULL((SELECT TOP 1 TaxUnit FROM _TDATaxUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SMTaxationType = '4128001'),0)  
  -------------------------------------------------------------------  
     -- ������̷� END 
     -------------------------------------------------------------------  
     
     CREATE TABLE #TSLInvoice
     (
         InvoiceNo      NVARCHAR(20),
         HapAmt         Money,
         HanAmt         NVARCHAR(100),
         HapDomAmt      Money,                  -- 20101224 ���ؽ� �߰�
         HanDomAmt      NVARCHAR(100),          -- 20101224 ���ؽ� �߰�
         My_TaxNo       NVARCHAR(100),  
         My_TaxName     NVARCHAR(100),     
         My_TaxOwner    NVARCHAR(100),  
         My_VatAddr     NVARCHAR(100),
         My_VatBizType  NVARCHAR(200),   -- 20100908 �ֹμ� �߰�
         My_VatBizItem  NVARCHAR(200),   -- 20100908 �ֹμ� �߰�
         InvoiceDate    NCHAR(8),
         YY             NCHAR(4), 
         MM             NCHAR(2), 
         DD             NCHAR(2),  
         BKCustName     NVARCHAR(200),    
         CustName       NVARCHAR(200),
         BizType        NVARCHAR(200),   -- 20100908 �ֹμ� �߰�
         BizKind        NVARCHAR(200),   -- 20100908 �ֹμ� �߰�
         CurrName       NVARCHAR(100),          -- 20120709 �̼��� �߰�
         Remark         NVARCHAR(1000),         -- 20120709 �̼��� �߰�
         Memo           NVARCHAR(1000),         -- 20120709 �̼��� �߰�
         CurAmt         Money, 
         CurVAT         Money,
         DomAmt         Money,           -- 20101224 ���ؽ� �߰�
         DomVAT         Money,           -- 20101224 ���ؽ� �߰�
         Qty            DECIMAL(19, 5), 
         Price          Money,
         DomPrice       Money,           -- 20101224 ���ؽ� �߰�
         ItemName       NVARCHAR(100), 
         ItemNo         NVARCHAR(200), 
         Spec           NVARCHAR(100), 
         UnitName       NVARCHAR(100),
         SpecName       NVARCHAR(200),          -- �������׸�
         SpecValue      NVARCHAR(200),          -- �������׸�
         LotNo          NVARCHAR(60),   -- 20091208 ���游 �߰�
         ValiDate       NVARCHAR(60),   -- 20091208 ���游 �߰�
         BizNo          NVARCHAR(40),
         ItemRemark     NVARCHAR(500),
         Owner          NVARCHAR(60),
         Addr           NVARCHAR(300),
         ItemClassSName NVARCHAR(200), -- ǰ��Һз� 
         ItemSName      NVARCHAR(100), -- ǰ����
         Dummy1         NVARCHAR(100),
         Dummy2         NVARCHAR(100),
         Dummy3         NVARCHAR(100),
         Dummy4         NVARCHAR(100),
         Dummy5         NVARCHAR(100),
         Dummy6         INT,
         Dummy7         INT,
         Dummy8         NVARCHAR(100),
         Dummy9         NVARCHAR(100),
         Dummy10        NVARCHAR(100),
         InvoiceSerl    INT, 
         InvoiceNo2     NVARCHAR(4), 
         MngItemName    NVARCHAR(100), -- ���ڵ�(ǰ��)
         MngBoxName     NVARCHAR(100), -- ���ڵ�(�ӹڽ�)
         UMDVConditionName NVARCHAR(100), -- �ε�����
         DVPlaceName    NVARCHAR(100), -- ��ǰó
         BoxQty         DECIMAL(19,5), -- �ڽ�����
         CustNo         NVARCHAR(100)
     )

    INSERT #TSLInvoice
    SELECT A.InvoiceNo,
           @TotAmt                       AS HapAmt,
           @HanAmt                       AS HanAmt,
           @TotDomAmt                    AS HapDomAmt,          -- 20101224 ���ؽ� �߰�
           @HanDomAmt                    AS HanDomAmt,          -- 20101224 ���ؽ� �߰�
           SUBSTRING( Z.TaxNo, 1, 3 ) + '-' + SUBSTRING( Z.TaxNo, 4, 2 ) + '-' + SUBSTRING( Z.TaxNo, 6, 5 ), -- ����ڵ�Ϲ�ȣ
           Z.TaxName, -- ����ڻ�ȣ
           Z.Owner, -- ����ڴ�ǥ��
           CASE WHEN ISNULL( Z.VatRptAddr, '' ) = '' THEN CONVERT(VARCHAR(150), LTRIM(RTRIM(Z.Addr1)) + LTRIM(RTRIM(Z.Addr2)) + LTRIM(RTRIM(Z.Addr3)) ) 
                                                     ELSE Z.VatRptAddr END, -- ������ּ� 
           CONVERT( VARCHAR(50), LTRIM(RTRIM( Z.BizType )) ), -- ����ھ���
           CONVERT( VARCHAR(50), LTRIM(RTRIM( Z.BizItem )) ), -- ��������� 
           A.InvoiceDate     AS InvoiceDate,   -- �ŷ�������
           LEFT(@InvoiceDate, 4)         AS YY,     --�ŷ�������  
           SUBSTRING(@InvoiceDate, 5, 2) AS MM, 
           RIGHT(@InvoiceDate, 2)        AS DD,
           I.CustName                    AS BKCustName,   --�߰���
           E.CustName                    AS CustName,   --�ŷ�ó 
           E.BizType      AS BizType,   -- ����
           E.BizKind      AS BizKind,   -- ����
           ISNULL(Cu.CurrName,'')        AS CurrName,        -- ��ȭ
           ISNULL(A.Remark,'')           AS Remark,           -- ���
           ISNULL(A.Memo,'')             AS Memo,             -- �޸�
           B.CurAmt                      AS CurAmt, 
           B.CurVAT                      AS CurVAT,
           B.DomAmt                AS DomAmt,             -- 20101224 ���ؽ� �߰�
           B.DomVAT                AS DomVAT,             -- 20101224 ���ؽ� �߰� 
           B.Qty                         AS Qty,        
           CASE WHEN B.Price IS NOT NULL
                THEN B.Price
                ELSE (CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN (ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)      
                                                                                                 ELSE ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0) 
                                                                                                 END) 
                                                           END) 
                END AS Price, -- �ǸŴܰ�  
           CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN (ISNULL(B.DomAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)      
                                                                                      ELSE ISNULL(B.DomAmt,0) / ISNULL(B.Qty,0) END) END AS DomPrice,   -- 20101224 ���ؽ� �߰�
           CASE K.CustItemName WHEN '' THEN B1.ItemName ELSE K.CustItemName END  AS ItemName, -- �ŷ�óǰ��    
           CASE K.CustItemNo WHEN '' THEN B1.ItemNo ELSE K.CustItemNo END        AS ItemNo,   -- �ŷ�óǰ��    
           CASE K.CustItemSpec WHEN '' THEN B1.Spec ELSE K.CustItemSpec END AS Spec,  -- �ŷ�óǰ��԰�   
           B2.UnitName AS UnitName,            
           S.SpecName, 
           S.SpecValue,
           B.LotNo,           -- LotNo 20091208 ���游 �߰�
           ISNULL((SELECT ValiDate FROM _TLGLotMaster WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND LotNo = B.LotNo AND ItemSeq = B.ItemSeq),'') AS ValiDate, -- ��ȿ���� 20091208 ���游 �߰�
           CASE WHEN E.BizNo = '' THEN '' ELSE ISNULL(SUBSTRING(E.BizNo,1,3) + '-' +SUBSTRING(E.BizNo,4,2) + '-' + SUBSTRING(E.BizNo, 6,LEN(E.BizNo)) ,'') END    AS BizNo        ,
           ISNULL(B.Remark, '')     AS ItemRemark   ,
           ISNULL(E.Owner, '')      AS Owner        ,
           ISNULL(RTRIM(L.KorAddr1) + RTRIM(L.KorAddr2) + RTRIM(L.KorAddr3), '') AS Addr,
           Y.MinorName AS ItemClassSName, -- ǰ��Һз� 
           B1.ItemSName, -- ǰ���� 
           B.Dummy1,
           B.Dummy2,
           B.Dummy3,
           B.Dummy4,
           B.Dummy5,
           B.Dummy6,
           B.Dummy7,
           B.Dummy8,
           B.Dummy9,
           B.Dummy10,
           B.InvoiceSerl,
           RIGHT(A.InvoiceNo,4), 
           F.MngValText, 
           G.MngValText, 
           H.MinorName, 
           CASE WHEN M.DVPlaceName <> E.CustName THEN M.DVPlaceName ELSE NULL END, 
           ( 
           SELECT (B.STDQty) / (P.ConvNum) / (P.ConvDen)
             FROM jongie_TCOMEnv AS O WITH(NOLOCK) 
             JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = B.ItemSeq ) 
            WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1 
           ),
           E.CustNo
      FROM _TSLInvoice              AS A  WITH(NOLOCK)
      JOIN _TSLInvoiceItem          AS B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq= B.InvoiceSeq
      LEFT OUTER JOIN _TDAItem      AS B1 WITH(NOLOCK) ON B.CompanySeq = B1.CompanySeq AND B.ItemSeq= B1.ItemSeq 
      LEFT OUTER JOIN _TDAItemClass AS X  WITH(NOLOCK) ON ( B.CompanySeq = X.CompanySeq AND B.ItemSeq = X.ItemSeq AND X.UMajorItemClass IN (2001,2004) ) 
      LEFT OUTER JOIN _TDAUMinor    AS Y  WITH(NOLOCK) ON ( X.UMItemClass = Y.MinorSeq AND X.CompanySeq = Y.CompanySeq AND Y.IsUse = '1' )
      LEFT OUTER JOIN _TDAUnit      AS B2 WITH(NOLOCK) ON B.CompanySeq = B2.CompanySeq AND B.UnitSeq= B2.UnitSeq
      LEFT OUTER JOIN _TDADept      AS C  WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DeptSeq   = C.DeptSeq  
      LEFT OUTER JOIN _TDACurr      AS Cu WITH(NOLOCK) ON Cu.CompanySeq = A.CompanySeq AND Cu.CurrSeq = A.CurrSeq
      LEFT OUTER JOIN #TTaxUnit     AS Z  WITH(NOLOCK) ON Z.TaxUnit  = ( CASE WHEN ( @pIsAccTax = 4125002 ) AND ( A.InvoiceDate >= @pIsAccTaxDate )  
                                                                              THEN @pIsAccTaxUnit 
                                                                              ELSE C.TaxUnit
                                                                              END ) AND A.InvoiceDate BETWEEN Z.FrDate AND Z.ToDate 
       LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.EmpSeq    = D.EmpSeq  
       LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.CustSeq   = E.CustSeq
       LEFT OUTER JOIN _TDACust      AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.BKCustSeq = I.CustSeq 
       LEFT OUTER JOIN #TempCustItem AS K WITH(NOLOCK) ON B.InvoiceSeq = K.InvoiceSeq AND B.InvoiceSerl = K.InvoiceSerl
       LEFT OUTER JOIN #Tmp_InvoiceProg AS J           ON B.InvoiceSeq   = J.InvoiceSeq AND B.InvoiceSerl  = J.InvoiceSerl
       LEFT OUTER JOIN #TempSOSpec   AS S              ON J.OrderSeq     = S.OrderSeq AND J.OrderSerl    = S.OrderSerl    
       LEFT OUTER JOIN _TDACustAdd   AS L WITH(NOLOCK) ON L.CompanySeq = @CompanySeq  AND E.CustSeq = L.CustSeq 
       LEFT OUTER JOIN _TDAItemUserDefine AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = B.ItemSeq AND F.MngSerl = 1000003 ) 
       LEFT OUTER JOIN _TDAItemUserDefine AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = B.ItemSeq AND G.MngSerl = 1000004 ) 
       LEFT OUTER JOIN _TDAUMinor         AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMDVConditionSeq ) 
       LEFT OUTER JOIN _TSLDeliveryCust   AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.DVPlaceSeq = A.DVPlaceSeq ) 
 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.InvoiceSeq = @InvoiceSeq  
     ORDER BY B.InvoiceSerl
    
    SELECT * FROM #TSLInvoice ORDER BY InvoiceSerl
    
    RETURN
    
GO
exec jongie_SSLInvoiceRptQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InvoiceSeq>1000732</InvoiceSeq>
    <InvoiceDate>20130808</InvoiceDate>
    <CustSeq>42522</CustSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017055,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1275