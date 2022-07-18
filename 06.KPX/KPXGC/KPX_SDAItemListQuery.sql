
IF OBJECT_ID('KPX_SDAItemListQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemListQuery
GO 

-- v2014.11.05 

-- ǰ������ ��ȸ by����õ 

-- Ver.20140417
  /*************************************************************************************************        
  ��  �� - ǰ������ ��ȸ    
  �ۼ��� - 2009. 7.  : CREATED BY ���ظ�
  ������ - 2010. 8. 27 : Modify By �ֿ��� : �����÷� TempTable ���鶧 ORDER BY ���ϰ� ���� TempTable ���� ORDER BY ��(�ӵ�����)
     2011.09.02 by ��ö��
   1) Ʃ��: MinorSeq�� �����ϰ� MajorSeq�� �������� �ʾƼ� �Ϻ� �ӵ������� �߻��Ͽ��� - ����  
 *************************************************************************************************/        
  -- ǰ����ȸ / ������ȸ - ��ȸ 
 CREATE PROC KPX_SDAItemListQuery      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',  -- I : ǰ�� , M : ����    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS  
  --DECLARE @CLOCK DATETIME
  --SELECT @CLOCK = GETDATE()
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE   @docHandle      INT,      
              @ItemSeq        INT,  
              @UMItemClass    INT,  
              @UMItemClassM   INT, 
              @UMItemClassL   INT, 
              @ItemName       NVARCHAR(200),    
              @ItemNo         NVARCHAR(100),  
              @Spec           NVARCHAR(100),  
              @AssetSeq       INT,  
              @UnitSeq        INT,  
              @DeptSeq        INT,  
              @EmpSeq         INT,  
              @SMABC          INT,  
              @SMStatus       INT,  
              @SMInOutKind    INT,  
              @UMItemClassS   INT,  
              @ModelSeq       INT, 
              @MakerSeq       INT, 
              @IsOption       NCHAR(1),  
              @IsSet          NCHAR(1),  
              @IsVessel       NCHAR(1),  
              @FromDate       NCHAR(8),
              @ToDate         NCHAR(8), 
              @IsCfmSeq       INT, 
              @IsPurSeq       INT, 
              @IsProdSeq      INT 
    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    SELECT  @ItemSeq      = ISNULL(ItemSeq, 0),  
            @ItemName     = ISNULL(ItemName, ''),  
            @ItemNo       = ISNULL(ItemNo, ''),  
            @Spec         = ISNULL(Spec, ''),  
            @AssetSeq     = ISNULL(AssetSeq, 0),  
            @UnitSeq      = ISNULL(UnitSeq, 0),  
            @DeptSeq      = ISNULL(DeptSeq, 0),  
            @EmpSeq       = ISNULL(EmpSeq, 0),  
            @SMABC        = ISNULL(SMABC, 0),  
            @SMStatus     = ISNULL(SMStatus, 0),  
            @SMInOutKind  = ISNULL(SMInOutKind, 0),  
            @UMItemClassS = ISNULL(UMItemClassS, 0), 
            @UMItemClassM = ISNULL(UMItemClassM, 0), 
            @UMItemClassL = ISNULL(UMItemClassL, 0), 
            @ModelSeq     = ISNULL(ModelSeq, 0), 
            @MakerSeq     = ISNULL(MakerSeq, 0), 
            @IsOption     = ISNULL(IsOption, '0'),  
            @IsSet        = ISNULL(IsSet, '0'),  
            @IsVessel     = ISNULL(IsVessel, '0'),  
            @FromDate     = ISNULL(FromDate, ''),  
            @ToDate       = ISNULL(ToDate, ''), 
            @IsCfmSeq     = ISNULL(IsCfmSeq, 0), 
            @IsPurSeq     = ISNULL(IsPurSeq, 0), 
            @IsProdSeq    = ISNULL(IsProdSeq, 0) 
    
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
      WITH(ItemSeq      INT,  
           ItemName     NVARCHAR(200),  
           ItemNo       NVARCHAR(100),  
           Spec         NVARCHAR(100),  
           AssetSeq     INT,  
           UnitSeq      INT,  
           DeptSeq      INT,  
           EmpSeq       INT,  
           SMABC        INT,  
           SMStatus     INT,  
           SMInOutKind  INT,  
           UMItemClassS INT,   
           UMItemClassM INT,  
           UMItemClassL INT, 
           ModelSeq     INT, 
           MakerSeq     INT, 
           IsOption     NCHAR(1),  
           IsSet        NCHAR(1),  
           IsVessel     NCHAR(1),
           FromDate     NCHAR(8),
           ToDate       NCHAR(8),
           IsCfmSeq     INT, 
           IsPurSeq     INT, 
           IsProdSeq    INT 
           )  
    CREATE TABLE #Temp_ItemUserDefineData(TitleSerl INT, Title NVARCHAR(50), MngValName NVARCHAR(200), SMInputType INT, Seq INT, 
                                           MngValText NVARCHAR(200), CodeHelpSeq INT, CodeHelpParams NVARCHAR(100), Mask NVARCHAR(50), 
                                           IsNON NCHAR(1), ItemSeq INT)
    CREATE TABLE #Temp_ItemUserDefine
    (
        ColIDX      INT IDENTITY(0,1),
        Title       NVARCHAR(50),
        TitleSeq    INT,
        InputType   NVARCHAR(50)
    )
  
    -- �߰����� Title    
    -- 2010.08.03 ������ : ǰ��з��� ���̳��ͺο� ��ȸ�ǵ��� ����. 
    
    -- ǰ��з� 
    INSERT #Temp_ItemUserDefine( Title, TitleSeq, InputType )
    SELECT A.MajorName, A.MajorSeq, 'ItemClass'
      FROM _TDAUMajor AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TDADefineItemClass AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.MajorSeq = B.UMajorItemClass )
     WHERE A.CompanySeq = @CompanySeq
       AND ((@WorkingTag <> 'M' AND B.IsItem = '1') OR (@WorkingTag = 'M' AND B.IsMaterial = '1')) -- ����ǰ / ���� 
       AND EXISTS (SELECT 1 FROM KPX_TDAItemClass WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND UMajorItemClass = A.MajorSeq AND (UMajorItemClass < 2001 OR UMajorItemClass > 2006))
     ORDER BY B.Priority, A.MajorSeq
    
    --select * from _TDADefineItemClass where CompanySeq = 1
    
    
    -- �߰����� 
    INSERT #Temp_ItemUserDefine( Title, TitleSeq, InputType )
    SELECT A.Title, A.TitleSerl, ( CASE SMInputType WHEN 1027006 THEN 'enCheck' 
                                                    WHEN 1027007 THEN 'enDate' 
                                                    ELSE 'enText' 
                                                    END )
      FROM _TCOMUserDefine AS A WITH(NOLOCK)
     WHERE A.CompanySeq    = @CompanySeq    
       AND A.TableName     = '_TDAItem'    
       AND ((@WorkingTag <> 'M' AND A.DefineUnitSeq = 8010001) OR (@WorkingTag = 'M' AND A.DefineUnitSeq = 8010002)) -- ����ǰ / ���� 
  
  
    SELECT X.CompanySeq, X.ModelSeq, ISNULL(Y.ItemName, '') as STDItemName  
      INTO #TEMP_ModelItem
      FROM _TDAModelItem  AS X WITH(NOLOCK)   
      LEFT OUTER JOIN KPX_TDAItem AS Y WITH(NOLOCK) ON ( X.CompanySeq = Y.CompanySeq AND X.ItemSeq = Y.ItemSeq ) 
     WHERE X.CompanySeq = @CompanySeq  
       AND X.IsStandard = '1' 
    
    
    
    CREATE TABLE #Temp_Prod
    (
        ItemSeq         INT, 
        LastDateTime    DATETIME
    )
    CREATE TABLE #Temp_Pur
    (
        ItemSeq         INT, 
        LastDateTime    DATETIME
    )
    
    INSERT INTO #Temp_Prod (ItemSeq, LastDateTime)
    SELECT ItemSeq,  LastDateTime 
      FROM _TDAItemProduct 
     WHERE CompanySeq = @CompanySeq 
       AND PgmSeq = 1021312
     UNION ALL 
    SELECT ItemSeq,  LastDateTime 
      FROM _TDAItemProductLog 
     WHERE CompanySeq = @CompanySeq 
       AND PgmSeq = 1021312
    
    INSERT INTO #Temp_Pur (ItemSeq,  LastDateTime)
    SELECT ItemSeq,  LastDateTime 
      FROM _TDAItemPurchase 
     WHERE CompanySeq = @CompanySeq  
       AND PgmSeq = 1021313
    UNION ALL 
    SELECT ItemSeq,  LastDateTime 
      FROM _TDAItemPurchaseLog 
     WHERE CompanySeq = @CompanySeq 
       AND PgmSeq = 1021313
    
    
    -- ǰ������ (�����÷�)     
    SELECT IDENTITY(INT, 0, 1)   AS RowIDX,
           ISNULL(A.ItemSeq,0)          AS ItemSeq, -- ǰ���ڵ�  
           ISNULL(A.ItemName,'')        AS ItemName, -- ǰ���  
           ISNULL(A.ItemNo,'')          AS ItemNo, -- ǰ���ȣ  
           ISNULL(A.Spec,'')            AS Spec, -- �԰�  
           ISNULL(A.TrunName,'')        AS TrunName, -- TrunName  
           ISNULL(C.AssetName,'')       AS AssetName, -- ǰ���ڻ�з�  
           ISNULL(A.AssetSeq,0)         AS AssetSeq, -- ǰ���ڻ�з��ڵ�  
           ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND UnitSeq = A.UnitSeq), '') AS UnitName, -- ���ش���  
           ISNULL(A.UnitSeq,0)          AS UnitSeq, -- ���ش����ڵ�  
           ISNULL(A.SMABC,0)            AS SMABC, -- �߿䵵  
           ISNULL(A.SMStatus,0)         AS SMStatus, -- ǰ�� ����  
           ISNULL(A.SMInOutKind,0)      AS SMInOutKind, -- �����ڱ���  
           ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq), '') AS DeptName, -- �μ�  
           ISNULL(A.DeptSeq,0)          AS DeptSeq, -- �μ��ڵ�  
           ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND EmpSeq = A.EmpSeq), '') AS EmpName, -- ������  
           ISNULL(A.EmpSeq,0)           AS EmpSeq, -- ������ڵ�  
           CASE WHEN ISNULL(G.SMModelKind,0) = 1 THEN ISNULL(G.ModelName,'') ELSE '' END AS ModelName, -- �𵨸�  
           ISNULL(A.ModelSeq,0)         AS ModelSeq, -- ���ڵ�  
           ISNULL(I.STDItemName,'')     AS STDItemName, -- ��ǥǰ���  
           ISNULL(A.ItemSName,'')       AS ItemSName, -- ǰ����  
           ISNULL(A.ItemEngName,'')     AS ItemEngName, -- ������  
           ISNULL(A.ItemEngSName,'')    AS ItemEngSName, -- �������  
           CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' ELSE ( SELECT ISNULL(MinorName,'') 
                                                               FROM _TDAUMinor WITH(NOLOCK)   
                                                              WHERE CompanySeq = L.CompanySeq AND MinorSeq = L.ValueSeq 
                                                           ) END AS ItemClassLName,  -- ǰ���з�  
           CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' ELSE ( SELECT ISNULL(MinorName,'')   
                                                               FROM _TDAUMinor WITH(NOLOCK)   
                                                              WHERE CompanySeq = K.CompanySeq AND MinorSeq = K.ValueSeq 
                                                           ) END AS ItemClassMName,  -- ǰ���ߺз�
           ISNULL(H.MinorName,'')       AS ItemClassSName, -- ǰ��Һз�  
           ISNULL(B.UMItemClass,0)      AS UMItemClassS, -- ǰ��Һз��ڵ�  select * from _TDASMinor where MinorName = '����'
           CASE WHEN ISNULL(A.SMABC,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND MajorSeq = 2002 AND MinorSeq = A.SMABC) END AS ABC, -- �߿䵵  
           CASE WHEN ISNULL(A.SMStatus,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND MajorSeq = 2001 AND MinorSeq = A.SMStatus) END AS ItemStatus, -- ǰ�� ����  
           CASE WHEN ISNULL(A.SMInOutKind,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND MajorSeq = 8007 AND MinorSeq = A.SMInOutKind) END AS InOutKind, -- �����ڱ���  
           ISNULL(A.IsInherit,'0')      AS IsInherit,  
           CASE WHEN ISNULL(A.RegUserSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(UserName,'') FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND UserSeq = A.RegUserSeq) END AS RegUser,  
           CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE (SELECT ISNULL(UserName,'') FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND UserSeq = A.LastUserSeq) END AS LastUser,  
           CONVERT(NCHAR(8), A.RegDateTime, 112) AS RegDate,  
           CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE CONVERT(NCHAR(8), A.LastDateTime, 112) END AS LastDate,  
           ISNULL(D.IsOption,'0')       AS IsOption,  
           ISNULL(D.IsSet, '0')         AS IsSet,
           ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = E.CompanySeq AND MinorSeq = E.SMOutKind),'') AS SMOutKindName,
           ( case when exists ( select 1 from _TPDBOM where CompanySeq = A.CompanySeq and ItemSeq = A.ItemSeq ) then '1' else '0' end ) as IsBOMReg,
           ( case when exists ( select 1 from _TPDROUItemProcMat where CompanySeq = A.CompanySeq and ItemSeq = A.ItemSeq ) then '1' else '0' end ) as IsProcMat,
      
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = ST.CompanySeq AND MinorSeq = ST.SMLimitTermKind), '') AS SMLimitTermKindName, 
           ST.LimitTerm     AS LimitTerm, 
           ST.IsLotMng      AS IsLotMng,    -- Lot����
           ST.IsSerialMng   AS IsSerialMng,  -- Serial����
           ISNULL((SELECT CustName FROM _TDACust WHERE CompanySeq = IP.CompanySeq AND CustSeq = IP.MkCustSeq) , '') AS MakerName,
           C.SMAssetGrp     AS SMAssetGrp,   -- 2010. 12. 17 hkim ��ǰ(6008001)�� BOM ������ ���� ����
           ISNULL((SELECT CustName FROM _TDACust WHERE CompanySeq = IP.CompanySeq AND CustSeq = IP.PurCustSeq), '') AS PurCustName, 
           LTRIM(RTRIM(ISNULL(M.ItemRemark, ''))) AS Remark, -- ��� 2011.03.02 ������ 
           ISNULL(SM.MinorName,'')                AS VatType, -- �ΰ������� 2012.05.14 ���ؽ�
           ISNULL(D.IsVat,'')                     AS PriceInVat, --�ǸŴܰ����ΰ������� 2012.05.14 ���ؽ�
           CASE WHEN ISNULL(F.FileSeq, 0) <> 0 THEN '1' ELSE '0' END AS IsFileCheck,  -- ����÷�ο���, 2012.09.17 ������
           (SELECT ISNULL(MinorName, '') FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = E.SMMrpKind   ) AS SMMrpKindName   , --  �ҿ䷮�����     
           (SELECT ISNULL(MinorName, '') FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = E.SMProdMethod) AS SMProdMethodName, --  ������������ 
           (SELECT ISNULL(MinorName, '') FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = E.SMProdSpec  ) AS SMProdSpecName,    --  ������
           ISNULL(N.CfmCode,'0') AS IsCfm, 
           O.LastDateTime AS ProdLastDate, 
           P.LastDateTime AS PurLastDate
      INTO #Temp_TDAItemInfo_New
      FROM KPX_TDAItem      AS A WITH(NOLOCK)   
      LEFT OUTER JOIN KPX_TDAItemClass  AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND  B.UMajorItemClass IN (2001,2004) ) 
      LEFT OUTER JOIN _TDAItemAsset  AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN KPX_TDAItemSales  AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemProduct AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.ItemSeq = E.ItemSeq )
      LEFT OUTER JOIN _TDAModel   AS G WITH(NOLOCK) ON ( A.CompanySeq = G.CompanySeq AND A.ModelSeq = G.ModelSeq ) 
      LEFT OUTER JOIN _TDAUMinor  AS H WITH(NOLOCK) ON ( B.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( B.UMItemClass, 4 ) AND B.UMItemClass = H.MinorSeq ) 
      LEFT OUTER JOIN _TDASMinor  AS J WITH(NOLOCK) ON ( C.CompanySeq = J.CompanySeq AND J.MajorSeq = 6008 AND C.SMAssetGrp = J.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) ) 
      LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )
      LEFT OUTER JOIN KPX_TDAItemRemark AS M WITH(NOLOCK) ON ( A.CompanySeq = M.CompanySeq AND A.ItemSeq = M.ItemSeq )
      LEFT OUTER JOIN #TEMP_ModelItem AS I ON ( A.CompanySeq = I.CompanySeq AND A.ModelSeq = I.ModelSeq )
      LEFT OUTER JOIN _TDAItemStock  AS ST WITH(NOLOCK) ON ( A.CompanySeq = ST.CompanySeq AND A.ItemSeq = ST.ItemSeq )
      LEFT OUTER JOIN _TDAItemPurchase AS IP WITH(NOLOCK) ON ( A.CompanySeq = IP.CompanySeq AND A.ItemSeq = IP.ItemSeq )
      LEFT OUTER JOIN _TDASMinor        AS SM WITH(NOLOCK) ON ( D.CompanySeq = SM.CompanySeq AND D.SMVatKind = SM.MinorSeq )
      LEFT OUTER JOIN KPX_TDAItemFile      AS F  WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq  AND A.ItemSeq = F.ItemSeq ) 
      LEFT OUTER JOIN KPX_TDAItem_Confirm  AS N WITH(NOLOCK) ON ( N.CompanySeq = A.CompanySeq AND N.CfmSeq = A.ItemSeq ) 
      OUTER APPLY (SELECT ItemSeq, CONVERT(NCHAR(8),MAX(LastDateTime),112) AS LastDateTime 
                     FROM #Temp_Prod AS Z 
                    WHERE Z.ItemSeq = A.ItemSeq 
                    GROUP BY ItemSeq 
                  ) AS O 
      OUTER APPLY (SELECT ItemSeq, CONVERT(NCHAR(8),MAX(LastDateTime),112) AS LastDateTime 
                     FROM #Temp_Pur AS Z 
                    WHERE Z.ItemSeq = A.ItemSeq 
                    GROUP BY ItemSeq 
                  ) AS P
     WHERE (A.CompanySeq  = @CompanySeq)  
       AND (@ItemSeq  = 0 OR A.ItemSeq = @ItemSeq)  
       AND (@ItemName = '' OR A.ItemName like @ItemName + '%')  
       AND (@ItemNo   = '' OR A.ItemNo   like @ItemNo   + '%')  
       AND (@Spec   = '' OR A.Spec   like @Spec   + '%')  
       AND (@AssetSeq = 0  OR A.AssetSeq = @AssetSeq)  
       AND (@UnitSeq = 0   OR A.UnitSeq = @UnitSeq)  
       AND (@DeptSeq = 0   OR A.DeptSeq = @DeptSeq)  
       AND (@EmpSeq = 0    OR A.EmpSeq = @EmpSeq)  
       AND (@SMABC = 0     OR A.SMABC = @SMABC)  
       AND (@SMStatus = 0  OR A.SMStatus = @SMStatus)  
       AND (@SMInOutKind = 0  OR A.SMInOutKind = @SMInOutKind)  
       AND (@ModelSeq = 0     OR A.ModelSeq = @ModelSeq)  
       AND (@UMItemClassS = 0 OR B.UMItemClass = @UMItemClassS)
       AND (@UMItemClassM = 0 OR K.ValueSeq = @UMItemClassM) 
       AND (@UMItemClassL = 0 OR L.ValueSeq = @UMItemClassL) 
       AND (@WorkingTag = '' OR (@WorkingTag = 'I' AND J.MinORValue = 0) OR (@WorkingTag = 'M' AND J.MinorValue = 1))  
       --AND (@IsOption = '0' OR D.IsOption = @IsOption)  
       --AND (@IsSet = '0' OR D.IsSet = @IsSet)  
       AND (C.IsVessel = @IsVessel)  
       AND (@FromDate = '' OR @FromDate <= CONVERT(NCHAR(8), A.RegDateTime, 112)) 
       AND (@ToDate = '' OR  @ToDate >= CONVERT(NCHAR(8), A.RegDateTime, 112)) 
       AND (@MakerSeq = 0 OR IP.MkCustSeq = @MakerSeq) 
       AND (@IsCfmSeq = 0 OR ISNULL(N.CfmCode,0) = CASE WHEN @IsCfmSeq = 1 THEN 1 ELSE 0 END) 
       AND (@IsProdSeq = 0 OR @IsProdSeq = CASE WHEN ISNULL(O.LastDateTime,'') = '' THEN 2 ELSE 1 END)
       AND (@IsPurSeq = 0 OR @IsPurSeq = CASE WHEN ISNULL(P.LastDateTime,'') = '' THEN 2 ELSE 1 END)
     ORDER BY A.ItemNo, A.ItemName, A.ItemSeq  
    
    
    -- �߰����� (����Data)       
    INSERT INTO #Temp_ItemUserDefineData  
    SELECT A.TitleSerl          AS TitleSerl,    
           A.Title              AS Title,    
           ''                   AS MngValName,    
           A.SMInputType        AS SMInputType,    
           ISNULL(B.MngValSeq,0)   AS Seq,    
           B.MngValText         AS MngValText,    
           A.CodeHelpConst      AS CodeHelpSeq,    
           A.CodeHelpParams     AS CodeHelpParams,    
           A.MaskAndCaption     AS Mask,  
           A.IsEss              AS IsNON, 
           C.ItemSeq            AS ItemSeq 
      FROM _TCOMUserDefine     AS A WITH(NOLOCK)
      LEFT OUTER JOIN KPX_TDAItemUserDefine AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND A.TitleSerl = B.MngSerl )
                 JOIN #Temp_TDAItemInfo_New AS C              ON ( B.ItemSeq = C.ItemSeq )
     WHERE A.CompanySeq    = @CompanySeq    
       AND A.TableName     = '_TDAItem'    
       AND ((@WorkingTag = 'I' AND A.DefineUnitSeq = 8010001)  -- ����ǰ  
             OR (@WorkingTag = 'M' AND A.DefineUnitSeq = 8010002)) -- ���� 
    EXEC _SCOMGetCodeHelpDataName @CompanySeq, @LanguageSeq, '#Temp_ItemUserDefineData'  
    UPDATE #Temp_ItemUserDefineData
    
        SET MngValName = ( CASE WHEN SMInputType IN (1027003, 1027005) THEN ISNULL(ValueName,'') ELSE ISNULL(MngValText,'') END ) -- �ڵ�����, �޺�
      -- ���� ������ ��ȸ 
     
    SELECT * FROM #Temp_ItemUserDefine ORDER BY ColIDX 
    SELECT * FROM #Temp_TDAItemInfo_New ORDER BY RowIDX 
    SELECT A.RowIDX        AS RowIDX,        
           C.ColIDX        AS ColIDX,   
           B.MngValName    AS AddInfoName
      FROM #Temp_TDAItemInfo_New  AS A --����Data Table
      JOIN #Temp_ItemUserDefineData  AS B ON ( A.ItemSeq = B.ItemSeq )     -- ����Data Table
      JOIN #Temp_ItemUserDefine   AS C ON ( B.TitleSerl = C.TitleSeq )    -- Title Table
     WHERE C.InputType <> 'ItemClass'
    UNION 
    SELECT A.RowIDX        AS RowIDX,               -- 2010.08.03 ������ : ǰ��з��� ���̳��ͺο� ��ȸ�ǵ��� ����. 
            C.ColIDX        AS ColIDX,   
            D.MinorName     AS AddInfoName
      FROM #Temp_TDAItemInfo_New   AS A 
      JOIN KPX_TDAItemClass           AS B WITH(NOLOCK) ON ( A.ItemSeq = B.ItemSeq AND B.CompanySeq = @CompanySeq )
      JOIN #Temp_ItemUserDefine    AS C              ON ( B.UMajorItemClass = C.TitleSeq ) 
      JOIN _TDAUMinor              AS D WITH(NOLOCK) ON ( B.UMItemClass = D.MinorSeq AND D.CompanySeq = @CompanySeq )
     WHERE C.InputType = 'ItemClass'
     ORDER BY 1,2
    
    RETURN
GO 
exec KPX_SDAItemListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>I</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsOption>0</IsOption>
    <IsSet>0</IsSet>
    <IsCfmSeq />
    <IsProdSeq>1</IsProdSeq>
    <IsPurSeq />
    <AssetSeq />
    <UMItemClassL />
    <UMItemClassM />
    <UMItemClassS />
    <SMInOutKind />
    <SMStatus />
    <SMABC />
    <UnitSeq />
    <DeptSeq />
    <EmpSeq />
    <ModelSeq />
    <FromDate />
    <ToDate />
    <ItemName />
    <ItemNo />
    <Spec />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025622,@WorkingTag=N'I',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021311