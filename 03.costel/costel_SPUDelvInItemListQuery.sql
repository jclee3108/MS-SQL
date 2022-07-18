
IF OBJECT_ID('costel_SPUDelvInItemListQuery') IS NOT NULL 
    DROP PROC costel_SPUDelvInItemListQuery
GO 

-- v2013.11.14 
  
-- ���Ź׼����԰�ǰ����ȸ_costel by����õ
 CREATE PROCEDURE costel_SPUDelvInItemListQuery 
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
    
    DECLARE @docHandle          INT          ,                
            @DelvInDateFr       NCHAR(8)     ,                
            @DelvInDateTo       NCHAR(8)     ,                
            @CustSeq            INT          ,                
            @ItemNo             NVARCHAR(100),                
            @SMAssetKind        INT          ,                
            @SMImpType          INT          ,            
            @DelvInNo           NCHAR(12)    ,            
            @ItemName           NVARCHAR(200),             
            @WHSeq              INT          ,          
            @PJTName            NVARCHAR(60) ,          
            @PJTNo              NVARCHAR(40) ,      
            @BizUnit            INT          ,      
            @DeptSeq            INT          ,      
            @EmpSeq             INT          ,      
            @SMDelvInType       INT          ,      
            @TopUnitName        NVARCHAR(200),            
            @TopUnitNo          NVARCHAR(200),  
            @Spec               NVARCHAR(200),  
            @LOTNo              NVARCHAR(20) ,       -- 20100716 �ڼҿ� �߰�   
            @PurGroupDeptSeq    INT,  
            @UMItemClassL  INT,    --20120827 ������ �߰�       
            @UMItemClassM  INT,  
            @UMItemClassS  INT       
    
    DECLARE @Word1 NVARCHAR(50),  
            @Word2 NVARCHAR(50)  
    
    SELECT @Word1 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 22755  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word1, '' ) = '' SELECT @Word1 = '��ǰ'  
      
    SELECT @Word2 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 13570  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word2, '' ) = '' SELECT @Word2 = '��ǰ' 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                    
            
    SELECT @DelvInDateFr      = ISNULL(DelvInDateFr   , ''),                
           @DelvInDateTo      = ISNULL(DelvInDateTo   , ''),                
           @CustSeq           = ISNULL(CustSeq         ,  0),              
           @ItemNo            = ISNULL(ItemNo         , ''),                
           @SMAssetKind       = ISNULL(SMAssetKind    ,  0),                
           @SMImpType         = ISNULL(SMImpType      ,  0),            
           @DelvInNo          = ISNULL(DelvInNo       , ''),            
           @ItemName          = ISNULL(ItemName       , ''),            
           @WHSeq             = ISNULL(WHSeq          ,  0),          
           @PJTName           = ISNULL(PJTName        , ''),          
           @PJTNo             = ISNULL(PJTNo          , ''),      
           @BizUnit           = ISNULL(BizUnit        ,  0),              
           @DeptSeq           = ISNULL(DeptSeq        ,  0),              
           @EmpSeq            = ISNULL(EmpSeq         ,  0),      
           @SMDelvInType      = ISNULL(SMDelvInType   ,  0),      
           @TopUnitName       = ISNULL(TopUnitName    , ''),                                
           @TopUnitNo         = ISNULL(TopUnitNo      , ''),  
           @Spec              = ISNULL(Spec           , ''),  
           @LOTNo             = ISNULL(LOTNo          , ''),   -- 20100716 �ڼҿ� �߰�  
           @PurGroupDeptSeq   = ISNULL(PurGroupDeptSeq,  0),  
           @UMItemClassL      = ISNULL(UMItemClassL,  0),  
           @UMItemClassM      = ISNULL(UMItemClassM,  0),  
           @UMItemClassS      = ISNULL(UMItemClassS,  0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                
      WITH (  
            DelvInDateFr        NCHAR(8), 
            DelvInDateTo        NCHAR(8), 
            CustSeq             INT, 
            ItemNo              NVARCHAR(100), 
            SMAssetKind         INT, 
            SMImpType           INT, 
            DelvInNo            NCHAR(12), 
            ItemName            NVARCHAR(200), 
            WHSeq               INT, 
            PJTName             NVARCHAR(60), 
            PJTNo               NVARCHAR(40), 
            BizUnit             INT, 
            DeptSeq             INT, 
            EmpSeq              INT, 
            SMDelvInType        INT, 
            TopUnitName         NVARCHAR(200), 
            TopUnitNo           NVARCHAR(200), 
            Spec                NVARCHAR(200), 
            LOTNo               NVARCHAR(20) , -- 20100716 �ڼҿ� �߰�  
            PurGroupDeptSeq     INT, 
            UMItemClassL        INT, 
            UMItemClassM        INT, 
            UMItemClassS        INT 
           )                             
    
    IF @DelvInDateFr = '' SET @DelvInDateFr = '10000101'            
    IF @DelvInDateTo = '' SET @DelvInDateTo = '99991231'       
      
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
   
    EXEC _SPUBasePurGroupInfo @CompanySeq, @PurGroupDeptSeq  
    --===================================================  
      -- ���ű׷� ���� �������� ��!  
    --===================================================                                
      
    CREATE TABLE #TEMP_DelvInItem      
    (      
        IDX_NO     INT IDENTITY(1,1) ,  
        DelvSeq    INT NULL,      
        DelvNo     NVARCHAR(20) NULL,      
        DelvInSeq  INT,      
        DelvInSerl INT,      
        DeptSeq    INT,                -- 20100112 �ڼҿ� �߰�      
        EmpSeq     INT,                -- 20100112 �ڼҿ� �߰�      
        SourceQty  DECIMAL(19,5) NULL, -- 20091231 �ڼҿ� �߰�    
        POSeq      INT NULL,  
        PONO       NVARCHAR(20) NULL,  
        POEmpName  NVARCHAR(200) NULL,          -- 20110328 �輼ȣ �߰�  
        POReqSeq    INT NULL,                   -- 20100726 �������߰�  
        POReqNo     NVARCHAR(30) NULL,          -- 20100726 �������߰�  
        POReqEmpName    NVARCHAR(200) NULL,     -- 20100726 �������߰�  
        CompanySeq INT     
    )        
    
    -- ǰ���� ���  
    IF (SELECT COUNT(*) FROM #PurGroupInfo) > 0 -- ���ű׷������� �����Ұ��  
    BEGIN     
        INSERT INTO #TEMP_DelvInItem   
                    (DelvInSeq, DelvInSerl, DeptSeq, EmpSeq, CompanySeq)  
        SELECT D.DelvInSeq, D.DelvInSerl, M.DeptSeq, M.EmpSeq, M.CompanySeq  
          FROM _TPUDelvInItem            AS D             
                     JOIN _TPUDelvIn     AS M WITH(NOLOCK) ON ( D.CompanySeq = M.CompanySeq AND D.DelvInSeq = M.DelvInSeq ) 
                     JOIN _TDAItem       AS I WITH(NOLOCK) ON ( D.CompanySeq = I.CompanySeq AND D.ItemSeq = I.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemClass  AS C              ON ( D.CompanySeq = C.CompanySeq AND D.ItemSeq = C.ItemSeq AND C.UMajorItemClass IN (2001, 2004) ) 
         WHERE D.CompanySeq   = @CompanySeq      
           AND M.DelvInDate  BETWEEN @DelvInDateFr  AND @DelvInDateTo            
           AND ( @DelvInNo    = '' OR M.DelvInNo     LIKE RTRIM(LTRIM(@DelvInNo)) + '%')          
           AND ( @BizUnit     = 0  OR M.BizUnit      = @BizUnit )       
           AND ( @DeptSeq     = 0  OR M.DeptSeq      = @DeptSeq )      
           AND ( @EmpSeq      = 0  OR M.EmpSeq       = @EmpSeq  )        
           AND ( @SMImpType   = 0  OR M.SMImpType    = @SMImpType)            
           AND ( M.SMImpType  IN (8008001, 8008002, 8008003))   
           AND ( @ItemName    = '' OR I.ItemName     LIKE @ItemName + '%')  
           AND ( @ItemNo      = '' OR I.ItemNo       LIKE @ItemNo   + '%')  
           AND ( @Spec        = '' OR I.Spec         LIKE @Spec     + '%')  
           AND ( @LOTNo       = '' OR D.LOTNo        LIKE @LOTNo + '%') -- 20100716 �ڼҿ� �߰�   
           AND (EXISTS   (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = M.DeptSeq AND UMItemClass = C.UMItemClass AND ItemSeq = D.ItemSeq)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = M.DeptSeq AND UMItemClass = C.UMItemClass AND ItemSeq = 0)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = 0         AND UMItemClass = C.UMItemClass AND ItemSeq = D.ItemSeq)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = 0         AND UMItemClass = C.UMItemClass AND ItemSeq = 0)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = M.DeptSeq AND UMItemClass = 0             AND ItemSeq = 0))              
     END  
     ELSE   
     BEGIN   
        INSERT INTO #TEMP_DelvInItem   
                    (DelvInSeq, DelvInSerl, DeptSeq, EmpSeq, CompanySeq)  
        SELECT D.DelvInSeq, D.DelvInSerl, M.DeptSeq, M.EmpSeq, M.CompanySeq  
           FROM _TPUDelvInItem  AS D             
           JOIN _TPUDelvIn      AS M WITH(NOLOCK) ON ( D.CompanySeq = M.CompanySeq AND D.DelvInSeq  = M.DelvInSeq ) 
           JOIN _TDAItem        AS I WITH(NOLOCK) ON ( D.CompanySeq = I.CompanySeq AND D.ItemSeq = I.ItemSeq ) 
         WHERE D.CompanySeq   = @CompanySeq      
           AND  M.DelvInDate  BETWEEN @DelvInDateFr  AND @DelvInDateTo            
           AND ( @DelvInNo    = '' OR M.DelvInNo     LIKE RTRIM(LTRIM(@DelvInNo)) + '%')          
           AND ( @BizUnit     = 0  OR M.BizUnit      = @BizUnit )       
           AND ( @DeptSeq     = 0  OR M.DeptSeq      = @DeptSeq )      
           AND ( @EmpSeq      = 0  OR M.EmpSeq       = @EmpSeq  )        
           AND ( @SMImpType   = 0  OR M.SMImpType    = @SMImpType)            
           AND ( M.SMImpType  IN (8008001, 8008002, 8008003))   
           AND ( @ItemName    = '' OR I.ItemName     LIKE @ItemName + '%')  
           AND ( @ItemNo      = '' OR I.ItemNo       LIKE @ItemNo   + '%')  
           AND ( @Spec        = '' OR I.Spec         LIKE @Spec     + '%')   
           AND ( @LOTNo       = '' OR D.LOTNo        LIKE @LOTNo + '%') -- 20100716 �ڼҿ� �߰�                       
     END 
    
    CREATE INDEX IDX_#TEMP_DelvInItem ON #TEMP_DelvInItem(DelvInSeq, DelvInSerl)     
    
    SELECT D.DelvInSeq, 
           D.DelvInSerl, 
           O.BizUnitName, 
           O.BizUnit, 
           M.DelvInNo AS DelvInNo, 
           M.DelvInDate, 
           S.CustName, 
           S.CustSeq, 
           RR.MinorName AS SMImpTypeName, 
           ISNULL(D.SMImpType, '') AS SMImpType, 
           CASE ISNULL(D.IsReturn, '') WHEN '1' THEN 6209002 ELSE 6209001 END AS SMDelvInType,      
           CASE ISNULL(D.IsReturn, '') WHEN '1' THEN @Word2  ELSE @Word1  END AS SMDelvInTypeName, 
           I.ItemName, 
           I.ItemNo, 
           I.Spec, 
           D.ItemSeq, 
           U.UnitName, 
           D.UnitSeq, 
           
           ISNULL(D.Price,0) AS Price, -- �԰�ܰ� 
           ISNULL(D.Qty,0) AS Qty,     -- ��ȸ�԰����                   
           ISNULL(D.IsVAT,'') AS IsVAT, -- �ΰ������Կ���    
           ISNULL(AA.VATRAte,0) AS VATRate, -- �ΰ�����  
           ISNULL(D.CurAmt,0) AS CurAmt, -- �԰�ݾ�     
           ISNULL(D.CurVAT,0) AS CurVAT, -- �ΰ��� 
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0) AS TotCurAmt, -- �ݾװ� 
           ISNULL(C.CurrName,'') AS CurrName, -- ��ȭ 
           M.CurrSeq, 
           M.ExRate AS ExRate, -- ȯ�� 
           ISNULL(D.DomPrice,0) AS DomPrice, -- �԰��ȭ�ܰ� 
           ISNULL(D.DomAmt,0) AS DomAmt,     -- �԰��ȭ�ݾ�             
           ISNULL(D.DomVAT,0) AS DomVAT,     -- �ΰ���(��ȭ)             
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0) AS TotDomAmt, -- �ݾװ�(��ȭ) 
           ISNULL(L.WHName,'') AS WHName, -- â�� 
           D.WHSeq, 
           T.AssetName AS SMAssetKindName, -- ǰ���ڻ�з� 
           I.AssetSeq AS SMAssetKind, 
           ISNULL(E.UnitName,'') AS STDUnitName, -- ����(���ش���) 
           D.StdUnitSeq AS STDUnitSeq, 
           ISNULL(D.stdUnitQty,0) AS STDUnitQty, -- ���ش������� 
           ISNULL(D.LOTNo,'') AS LOTNo, -- LotNo 
           ISNULL(D.Remark,'') AS Remark, -- ���   
           ISNULL(QC.IsInQC, '0') AS IsQCItem, -- �˻�ǰ����
           AB.EmpName AS EmpName, -- �԰�����  
           M.CustSeq,     
           AC.DeptName AS DeptName, -- �԰�μ� 
           M.DeptSeq, 
           T5.MinorName AS ItemClassLName,   -- ǰ���з�  
           T5.MinorSeq  AS ItemClassLSeq, 
           T3.MinorName AS ItemClassMName,   -- ǰ���ߺз�  
           T3.MinorSeq  AS ItemClassMSeq, 
           T1.MinorName AS ItemClassSName,  -- ǰ��Һз�   
           T1.MinorSeq  AS ItemClassNSeq, 
           ISNULL(S.CustNo, '') AS CustNo,   -- �ŷ�ó��ȣ 
           '_TPUDelvInItem' AS TableName, 
           1 AS Kind
    
      FROM _TPUDelvInItem   AS D             
      JOIN _TPUDelvIn       AS M WITH(NOLOCK) ON ( D.CompanySeq = M.CompanySeq AND D.DelvInSeq = M.DelvInSeq ) 
      JOIN #TEMP_DelvInItem AS Z              ON ( D.DelvInSeq = Z.DelvInSeq AND D.DelvInSerl = Z.DelvInSerl ) 
      LEFT OUTER JOIN _TDACurr         AS C  WITH(NOLOCK) ON M.CompanySeq = C.CompanySeq AND M.CurrSeq = C.CurrSeq            
      LEFT OUTER JOIN _TDAItem         AS I  WITH(NOLOCK) ON D.CompanySeq = I.CompanySeq AND D.ItemSeq = I.ItemSeq              
      LEFT OUTER JOIN _TDAUnit         AS U  WITH(NOLOCK) ON D.CompanySeq = U.CompanySeq AND D.UnitSeq = U.UnitSeq              
      LEFT OUTER JOIN _TDAUnit         AS E  WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq AND D.StdUnitSeq = E.UnitSeq -- ���ش���(������)            
      LEFT OUTER JOIN _TDAItemUnit     AS F  WITH(NOLOCK) ON I.CompanySeq = F.CompanySeq AND I.ItemSeq = F.ItemSeq AND D.UnitSeq = F.UnitSeq --  ȯ�����(���ش���)                     
      LEFT OUTER JOIN _TDACust         AS H  WITH(NOLOCK) ON D.CompanySeq = H.CompanySeq AND D.SalesCustSeq = H.CustSeq --  �����ŷ�ó            
      LEFT OUTER JOIN _TDAItemStock    AS J  WITH(NOLOCK) ON D.CompanySeq = J.CompanySeq AND D.ItemSeq = J.ItemSeq --              
      LEFT OUTER JOIN _TDAEvid         AS K  WITH(NOLOCK) ON D.CompanySeq = K.CompanySeq AND D.EvidSeq = K.EvidSeq -- ���ش���(������)            
      LEFT OUTER JOIN _TDAWH           AS L  WITH(NOLOCK) ON D.CompanySeq = L.CompanySeq AND D.WHSeq = L.WHSeq -- ���ش���(������)            
      LEFT OUTER JOIN _TDABizUnit      AS O  WITH(NOLOCK) ON M.CompanySeq = O.CompanySeq AND M.BizUnit = O.BizUnit -- ����ι�           
      LEFT OUTER JOIN _TDACust         AS N  WITH(NOLOCK) ON D.CompanySeq = N.CompanySeq AND D.DelvCustSeq = N.CustSeq --  �����ŷ�ó            
      LEFT OUTER JOIN _TDASMinor       AS P  WITH(NOLOCK) ON D.CompanySeq = p.CompanySeq AND D.SMPayType = p.MinorSeq --  ���ޱ���            
      LEFT OUTER JOIN _TDASMinor       AS Q  WITH(NOLOCK) ON D.CompanySeq = Q.CompanySeq AND D.SMDelvType = Q.MinorSeq --  ���۱���            
      LEFT OUTER JOIN _TDASMinor       AS R  WITH(NOLOCK) ON D.CompanySeq = R.CompanySeq AND D.SMStkType = R.MinorSeq --  ��������            
      LEFT OUTER JOIN _TDASMinor       AS RR WITH(NOLOCK) ON D.CompanySeq = RR.CompanySeq AND D.SMImpType = RR.MinorSeq --  �����ڱ���            
      LEFT OUTER JOIN _TDACust         AS S  WITH(NOLOCK) ON M.CompanySeq = S.CompanySeq AND M.CustSeq = S.CustSeq --  �����ŷ�ó            
      LEFT OUTER JOIN _TPJTProject     AS X  WITH(NOLOCK) ON D.CompanySeq = X.CompanySeq AND D.PJTSeq = X.PJTSeq                        
      LEFT OUTER JOIN _TDAItemAsset    AS T  WITH(NOLOCK) ON I.CompanySeq = T.CompanySeq AND I.AssetSeq = T.AssetSeq              
      LEFT OUTER JOIN _TDAItemSales    AS BB WITH(NOLOCK) ON BB.CompanySeq = @CompanySeq AND D.ItemSeq = BB.ItemSeq   
      LEFT OUTER JOIN _TDAVatRate      AS AA WITH(NOLOCK) ON AA.CompanySeq = BB.CompanySeq 
                                                         AND AA.SMVatType    = BB.SMVatType        
                                                         AND BB.SMVatKind    <> 2003002  -- �鼼 ����      
                                                         AND ISNULL(M.DelvInDate,CONVERT(NVARCHAR(8),getdate(),112))      
                                                         BETWEEN AA.SDate    AND AA.EDate      
      LEFT OUTER JOIN _TPJTBOM         AS M5 WITH(NOLOCK) ON D.CompanySeq = M5.CompanySeq AND D.PJTSeq = M5.PJTSeq AND D.WBSSeq = M5.BOMSerl     
      LEFT OUTER JOIN _TPJTBOM         AS M1 WITH(NOLOCK) ON D.CompanySeq = M1.CompanySeq            
                                                         AND D.PJTSeq        = M1.PJTSeq         
                                                         AND M1.BOMSerl      <> -1 
                                                         AND M5.UpperBOMSerl = M1.BOMSerl 
                                                         AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- ���� BOM            
      LEFT OUTER JOIN _TDAItem         AS M2 WITH(NOLOCK) ON D.CompanySEq = M2.CompanySeq AND M1.ItemSeq = M2.ItemSeq            
      LEFT OUTER JOIN _TPJTBOM         AS M3 WITH(NOLOCK) ON D.CompanySeq = M3.CompanySeq            
                                                         AND D.PJTSeq = M3.PJTSeq            
                                                         AND M3.BOMSerl <> -1            
                                                         AND ISNULL(M3.BeforeBOMSerl,0) = 0            
                                                         AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- �ֻ���    
                                                         AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1
      LEFT OUTER JOIN _TDAItem         AS M4 WITH(NOLOCK) ON D.CompanySeq = M4.CompanySeq AND M3.ItemSeq = M4.ItemSeq            
      LEFT OUTER JOIN _TDAUMinor       AS M6 WITH(NOLOCK) ON D.CompanySeq = M6.CompanySeq AND M5.UMMatQuality = M6.MinorSeq      
      LEFT OUTER JOIN _TDAEmp          AS AB WITH(NOLOCK) ON AB.CompanySeq = @CompanySeq  AND Z.EmpSeq = AB.EmpSeq -- 20100112 �ڼҿ� �߰�   
      LEFT OUTER JOIN _TDADept         AS AC WITH(NOLOCK) ON AC.CompanySeq   = @CompanySeq AND Z.DeptSeq = AC.DeptSeq -- 20100112 �ڼҿ� �߰�      
      
      --�߰� 2012.03.26 ������   
      LEFT OUTER JOIN _TDAItemClass    AS TT WITH(NOLOCK) ON I.CompanySeq = TT.CompanySeq  AND I.ItemSeq = TT.ItemSeq AND TT.UMajorItemClass IN (2001,2004)                       
      LEFT OUTER JOIN _TDAUMinor       AS T1 WITH(NOLOCK) ON TT.CompanySeq = T1.CompanySeq AND TT.UMItemClass = T1.MinorSeq                
      LEFT OUTER JOIN _TDAUMinorValue  AS T2 WITH(NOLOCK) ON T1.CompanySeq = T2.CompanySeq AND T1.MinorSeq = T2.MinorSeq AND T2.Serl IN (1001, 2001)             
      LEFT OUTER JOIN _TDAUMinor       AS T3 WITH(NOLOCK) ON T2.CompanySeq = T3.CompanySeq AND T2.ValueSeq = T3.MinorSeq                 
      LEFT OUTER JOIN _TDAUMinorValue  AS T4 WITH(NOLOCK) ON T3.CompanySeq = T4.CompanySeq AND T3.MinorSeq = T4.MinorSeq AND T4.Serl = 2001                 
      LEFT OUTER JOIN _TDAUMinor       AS T5 WITH(NOLOCK) ON T4.CompanySeq = T5.CompanySeq AND T4.ValueSeq = T5.MinorSeq    
      LEFT OUTER JOIN _TPDBaseItemQCType AS QC WITH(NOLOCK) ON D.CompanySeq = QC.CompanySeq AND D.ItemSeq = QC.ItemSeq AND QC.IsInQC = '1'   
    
     WHERE D.CompanySeq  = @CompanySeq            
       AND (@CustSeq    = 0  OR M.CustSeq   = @CustSeq)                
       AND (@WHSeq      = 0  OR D.WHSeq     = @WHSeq)            
       AND (@SMAssetKind= 0  OR I.AssetSeq  = RIGHT(@SMAssetKind, 2))      
       AND (@SMDelvInType=0  OR ( RIGHT(@SMDelvInType, 1) = '1' AND ISNULL(D.IsReturn, '') = '') OR ( RIGHT(@SMDelvInType, 1) = '2' AND ISNULL(D.IsReturn, '') = '1'))      
       AND (@PJTName = ''    OR X.PJTName   LIKE RTRIM(LTRIM(@PJTName)) + '%')            
       AND (@PJTNo = ''      OR X.PJTNo     LIKE RTRIM(LTRIM(@PJTNo)) + '%')        
       AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')                 
       AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')  
       AND (@UMItemClassL = 0 OR T5.MinorSeq = @UMItemClassL) --ǰ���з�    
       AND (@UMItemClassM = 0 OR T3.MinorSeq = @UMItemClassM) --ǰ���ߺз�  
       AND (@UMItemClassS = 0 OR T1.MinorSeq = @UMItemClassS) --ǰ��Һз�   
  
    UNION ALL
 
    SELECT A.DelvSeq AS DelvInSeq, 
           B.DelvSerl AS DelvInSerl, 
           (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit) AS BizUnitName, -- ����ι� 
           A.BizUnit, 
           A.DelvNo AS DelvInNo, 
           A.DelvDate AS DelvInDate, 
           (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND A.CustSeq = CustSeq) AS CustName, -- �ŷ�ó  
           A.CustSeq, 
           ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMImpKind),'') AS SMImpTypeName, 
           A.SMImpKind AS SMImpType,
           6209001 AS SMDelvInType, 
           @Word1 AS SMDelvInTypeName, 
           L.ItemName, 
           L.ItemNo, 
           L.Spec, 
           B.ItemSeq, 
           (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq) AS UnitName, -- ���� 
           B.UnitSeq, 
           ISNULL(B.Price,0) AS Price, 
           ISNULL(B.Qty,0) AS Qty, 
           0 AS IsVAT, 
           0 AS VATRate, 
           ISNULL(B.CurAmt,0) AS CurAmt, 
           0 AS CurVAT, 
           ISNULL(B.CurAmt,0) AS TotCurAmt, 
           (SELECT CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND A.CurrSeq = CurrSeq) AS CurrName, -- ��ȭ 
           A.CurrSeq, 
           A.ExRate AS ExRate, -- ȯ�� 
           CASE WHEN ISNULL(C.BasicAmt,0) = 0
                THEN (A.ExRate*B.Price)
                ELSE ((A.ExRate / C.BasicAmt) * B.Price) END AS DomPrice,            -- ��ȭ�ܰ�
           ISNULL(B.DomAmt,0) AS DomAmt, 
           0 AS DomVAT, 
           ISNULL(B.DomAmt,0) AS TotDomAmt, 
           (SELECT WHName FROM _TDAWH WHERE CompanySeq = @CompanySeq AND B.WHSeq = WHSeq) AS WHName, -- �԰�â�� 
           B.WHSeq, 
           IA.AssetName AS SMAssetKindName, -- ǰ���ڻ�з� 
           L.AssetSeq AS SMAssetKind, 
           (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq) AS STDUnitName, -- ���ش��� 
           B.STDUnitSeq, 
           ISNULL(B.STDQty,0) AS STDQty, 
           ISNULL(B.LotNo,'') AS LotNo, 
           ISNULL(B.Remark,'') AS Remark, 
           ISNULL(QC.IsInQC, '0') AS IsQCItem, -- �˻�ǰ����
           (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND A.EmpSeq  = EmpSeq) AS EmpName, -- ���
           A.EmpSeq, 
           (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq) AS DeptName, -- �μ�
           A.DeptSeq, 
           T1.ItemClassLName AS ItemClassLName,    --ǰ���з�  
           T1.ItemClassLSeq  AS ItemClassLSeq, 
           T1.ItemClassMName AS ItemClassMName,    --ǰ���ߺз�  
           T1.ItemClassMSeq  AS ItemClassMSeq, 
           T1.ItemClassSName AS ItemClassSName,    --ǰ��Һз� 
           T1.ItemClassSSeq  AS ItemClassSName, 
           (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND A.CustSeq = CustSeq) AS CustNo, -- �ŷ�ó��ȣ
           '_TUIImpDelvItem' AS TableName, 
           2 AS Kind
        
      FROM _TUIImpDelv         AS A WITH(NOLOCK) 
      JOIN _TUIImpDelvItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TDACurr AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CurrSeq = A.CurrSeq ) 
      LEFT OUTER JOIN _TDAItem AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND B.ItemSeq = L.ItemSeq ) 
      LEFT OUTER JOIN _TPJTProject     AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND B.PJTSeq = P.PJTSeq ) 
      LEFT OUTER JOIN _TPJTBOM       AS M5 WITH(NOLOCK) ON A.CompanySeq = M5.CompanySEq    
                                                     AND B.PJTSeq = M5.PJTSeq    
                                                     AND B.WBSSeq = M5.BOMSerl    
      LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON B.CompanySeq = M1.CompanySeq    
                                                     AND B.PJTSeq = M1.PJTSeq AND M1.BOMSerl <> -1 AND M5.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- ���� BOM    
      LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON B.CompanySEq = M2.CompanySeq    
                                                     AND M1.ItemSeq = M2.ItemSeq    
      LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON B.CompanySeq = M3.CompanySeq    
                                                     AND B.PJTSeq = M3.PJTSeq    
                                                     AND M3.BOMSerl <> -1    
                                                     AND ISNULL(M3.BeforeBOMSerl,0) = 0    
                                                     AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- �ֻ���   
                                                     AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1  
      LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON B.CompanySeq = M4.CompanySeq    
                                                       AND M3.ItemSeq = M4.ItemSeq    
      LEFT OUTER JOIN _TDAUMinor     AS M6 WITH(NOLOCK) ON B.CompanySeq = M5.CompanySeq
                                                       AND M5.UMMatQuality = M6.MinorSeq
      LEFT OUTER JOIN _TUIImpDelvCostDiv AS IH WITH(NOLOCK) ON A.CompanySeq = IH.CompanySeq 
                                                           AND A.DelvSeq    = IH.DelvSeq
      LEFT OUTER JOIN _TDAItemAsset    AS IA WITH(NOLOCK) ON L.CompanySEq = IA.CompanySeq    
                                                         AND IA.AssetSeq = L.AssetSeq  
      LEFT OUTER JOIN _TDAItemClass AS T WITH(NOLOCK) ON B.ItemSeq = T.ItemSeq                 -- ǰ����߼Һз� �߰�, 2012.08.16 by ������  
                                                     AND T.UMajorItemClass IN (2001, 2004)    
                                                     AND B.CompanySeq = T.CompanySeq    
      LEFT OUTER JOIN _VDAItemClass AS T1 WITH(NOLOCK) ON T.CompanySeq = T1.CompanySeq    
                                                      AND T.UMItemClass = T1.ItemClassSSeq    
      LEFT OUTER JOIN _TPDBaseItemQCType AS QC WITH(NOLOCK) ON B.CompanySeq = QC.CompanySeq AND B.ItemSeq = QC.ItemSeq AND QC.IsInQC = '1' 
        
     WHERE A.CompanySeq = @CompanySeq
       AND A.DelvDate BETWEEN @DelvInDateFr AND @DelvInDateTo 
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
       AND (@ItemNo = '' OR L.ItemNo LIKE @ItemNo + '%') 
       AND (@SMAssetKind = 0 OR IA.SMAssetGrp = @SMAssetKind) 
       AND (@SMImpType = 0 OR A.SMImpKind = @SMImpType) 
       AND (@DelvInNo = '' OR A.DelvNo LIKE @DelvInNo + '%') 
       AND (@ItemName = '' OR L.ItemName LIKE @ItemName + '%') 
       AND (@WHSeq = 0 OR B.WHSeq = @WHSeq) 
       AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%') 
       AND (@PJTNo = '' OR P.PJTNo LIKE @PJTNo + '%') 
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (@SMDelvInType = 0 OR @SMDelvInType = 6209001)
       AND (@Spec = '' OR L.Spec LIKE @Spec + '%') 
       AND (@LotNo = '' OR B.LotNo LIKE @LotNo + '%') 
       AND (@UMItemClassL = 0 OR T1.ItemClassLSeq = @UMItemClassL)  
       AND (@UMItemClassM = 0 OR T1.ItemClassMSeq = @UMItemClassM) 
       AND (@UMItemClassS = 0 OR T1.ItemClassSSeq = @UMItemClassS) 
    
     ORDER BY DelvInDate          
    
    RETURN