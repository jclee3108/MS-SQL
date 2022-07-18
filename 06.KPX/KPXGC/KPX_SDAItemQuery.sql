
IF OBJECT_ID('KPX_SDAItemQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemQuery
GO 

-- v2014.11.04 

-- ǰ����(�⺻_��������)��ȸ by����õ
/*************************************************************************************************        
 ��  �� - ǰ��⺻ ��ȸ    
 �ۼ��� - 2008.6.  : CREATED BY ���ظ�    
 ������ - 2009.9.8 ��³�  
 �������� - _TDAItem ���̺� LaunchDate(�������) �÷��߰�  
            ���翩���߰� (ǰ�������ϰ�����ȭ�鿡�� ����ϱ�����..) - 2010.09.28 ������  
*************************************************************************************************/        
CREATE PROCEDURE KPX_SDAItemQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE   @docHandle      INT,      
              @ItemSeq        INT,  
              @UMItemClass    INT,  
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
              @IsOption       NCHAR(1),  
              @IsSet          NCHAR(1),  
              @IsVessel       NCHAR(1)  
  
    
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
            @ModelSeq     = ISNULL(ModelSeq, 0),  
            @IsOption     = ISNULL(IsOption, '0'),  
            @IsSet        = ISNULL(IsSet, '0'),  
            @IsVessel     = ISNULL(IsVessel, '0')  
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
           ModelSeq     INT,  
           IsOption     NCHAR(1),  
           IsSet        NCHAR(1),  
           IsVessel     NCHAR(1))  
  
  
    SELECT @ItemSeq      = ISNULL(LTRIM(RTRIM(@ItemSeq)),     0),  
           @ItemName     = ISNULL(LTRIM(RTRIM(@ItemName)),   ''),  
           @ItemNo       = ISNULL(LTRIM(RTRIM(@ItemNo)),     ''),  
           @Spec         = ISNULL(LTRIM(RTRIM(@Spec)),       ''),  
           @AssetSeq     = ISNULL(LTRIM(RTRIM(@AssetSeq)),    0),  
           @UnitSeq      = ISNULL(LTRIM(RTRIM(@UnitSeq)),     0),  
           @DeptSeq      = ISNULL(LTRIM(RTRIM(@DeptSeq)),     0),  
           @EmpSeq       = ISNULL(LTRIM(RTRIM(@EmpSeq)),      0),  
           @SMABC        = ISNULL(LTRIM(RTRIM(@SMABC)),       0),  
           @SMStatus     = ISNULL(LTRIM(RTRIM(@SMStatus)),    0),  
           @SMInOutKind  = ISNULL(LTRIM(RTRIM(@SMInOutKind)), 0),  
           @UMItemClassS = ISNULL(LTRIM(RTRIM(@UMItemClassS)),0),  
           @ModelSeq     = ISNULL(LTRIM(RTRIM(@ModelSeq)),    0),  
           @IsOption     = ISNULL(LTRIM(RTRIM(@IsOption)),  '0'),  
           @IsSet        = ISNULL(LTRIM(RTRIM(@IsSet)),     '0'),  
           @IsVessel     = ISNULL(LTRIM(RTRIM(@IsVessel)),  '0')  
  
  
  
      SELECT  ISNULL(A.ItemSeq,0) AS ItemSeq, -- ǰ���ڵ�  
            ISNULL(A.ItemName,'') AS ItemName, -- ǰ���  
            ISNULL(A.ItemNo,'') AS ItemNo, -- ǰ���ȣ  
            ISNULL(A.Spec,'') AS Spec, -- �԰�  
            ISNULL(A.TrunName,'') AS TrunName, -- TrunName  
            ISNULL(C.AssetName,'') AS AssetName, -- ǰ���ڻ�з�  
            ISNULL(A.AssetSeq,0) AS AssetSeq, -- ǰ���ڻ�з��ڵ�  
            ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq), '') AS UnitName, -- ���ش���  
            ISNULL(A.UnitSeq,0) AS UnitSeq, -- ���ش����ڵ�  
            ISNULL(A.SMABC,0) AS SMABC, -- �߿䵵  
            ISNULL(A.SMStatus,0) AS SMStatus, -- ǰ�� ����  
            ISNULL(A.SMInOutKind,0) AS SMInOutKind, -- �����ڱ���  
            ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq), '') AS DeptName, -- �μ�  
            ISNULL(A.DeptSeq,0) AS DeptSeq, -- �μ��ڵ�  
            ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq), '') AS EmpName, -- ������  
            ISNULL(A.EmpSeq,0) AS EmpSeq, -- ������ڵ�  
            CASE WHEN ISNULL(G.SMModelKind,0) = 1 THEN ISNULL(G.ModelName,'') ELSE '' END AS ModelName, -- �𵨸�  
            ISNULL(A.ModelSeq,0) AS ModelSeq, -- ���ڵ�  
            ISNULL(I.STDItemName,'') AS STDItemName, -- ��ǥǰ���  
            ISNULL(A.ItemSName,'') AS ItemSName, -- ǰ����  
            ISNULL(A.ItemEngName,'') AS ItemEngName, -- ������  
            ISNULL(A.ItemEngSName,'') AS ItemEngSName, -- �������  
            CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')   
                                                               FROM _TDAUMinor WITH(NOLOCK)   
                                                              WHERE CompanySeq = @CompanySeq   
                                                                AND MinorSeq = L.ValueSeq) END AS ItemClassLName,  
            CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')   
                                                               FROM _TDAUMinor WITH(NOLOCK)   
                                                              WHERE CompanySeq = @CompanySeq   
                                                                AND MinorSeq = K.ValueSeq) END AS ItemClassMName,  
            ISNULL(H.MinorName,'') AS ItemClassSName, -- ǰ��Һз�  
            ISNULL(B.UMItemClass,0) AS UMItemClassS, -- ǰ��Һз��ڵ�  
            CASE WHEN ISNULL(A.SMABC,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMABC) END AS ABC, -- �߿䵵  
            CASE WHEN ISNULL(A.SMStatus,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMStatus) END AS ItemStatus, -- ǰ�� ����  
            CASE WHEN ISNULL(A.SMInOutKind,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMInOutKind) END AS InOutKind, -- �����ڱ���  
            ISNULL(A.IsInherit,'0') AS IsInherit,  
            CASE WHEN ISNULL(A.RegUserSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(UserName,'') FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UserSeq = A.RegUserSeq) END AS RegUser,  
            CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE (SELECT ISNULL(UserName,'') FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UserSeq = A.LastUserSeq) END AS LastUser,  
            CONVERT(NCHAR(8), A.RegDateTime, 112) AS RegDate,  
            CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE CONVERT(NCHAR(8), A.LastDateTime, 112) END AS LastDate,  
            ISNULL(D.IsOption,'0') AS IsOption,  
            ISNULL(D.IsSet, '0') AS IsSet,  
            ISNULL(A.LaunchDate, '') AS LaunchDate,    --�������  
            ISNULL(A.ItemSeq, 0) AS ItemSeqOLD,  
            LEFT(B.UMItemClass,4) AS UMajorItemClass,   
            CASE J.MinorValue WHEN 0 THEN '0' ELSE '1' END AS IsMaterial, -- ���翩��(ǰ�������ϰ��������� ���������� ���)  
            E.CfmCode AS IsCfm   
      FROM KPX_TDAItem AS A WITH(NOLOCK)   
           LEFT OUTER JOIN KPX_TDAItemClass AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                          AND A.ItemSeq    = B.ItemSeq  
                                                          AND B.UMajorItemClass IN (2001,2004)  
           LEFT OUTER JOIN _TDAItemAsset AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                          AND A.AssetSeq   = C.AssetSeq  
           LEFT OUTER JOIN KPX_TDAItemSales AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                          AND A.ItemSeq   = D.ItemSeq  
           LEFT OUTER JOIN _TDAModel AS G WITH(NOLOCK)     ON A.CompanySeq = G.CompanySeq  
                                                          AND A.ModelSeq   = G.ModelSeq  
           LEFT OUTER JOIN _TDAUMinor AS H WITH(NOLOCK)    ON B.CompanySeq  = H.CompanySeq  
                                                          AND B.UMItemClass = H.MinorSeq  
           LEFT OUTER JOIN _TDASMinor AS J WITH(NOLOCK)    ON C.CompanySeq = J.CompanySeq  
                                                          AND C.SMAssetGrp   = J.MinorSeq  
           LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON H.CompanySeq = K.CompanySeq   
                                                            AND H.MinorSeq   = K.MinorSeq   
                                                            AND K.MajorSeq IN (2001,2004)  
                                                            AND K.Serl IN (1001, 2001)  
           LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON K.CompanySeq = L.CompanySeq   
                                                            AND K.ValueSeq   = L.MinorSeq   
                                                            AND L.MajorSeq IN (2002,2005)  
                                                            AND L.Serl = 2001  
           LEFT OUTER JOIN (SELECT X.CompanySeq, X.ModelSeq, ISNULL(Y.ItemName, '') as STDItemName  
                              FROM _TDAModelItem AS X WITH(NOLOCK)   
                                   LEFT OUTER JOIN KPX_TDAItem AS Y WITH(NOLOCK) ON X.CompanySeq = Y.CompanySeq  
                                                                             AND X.ItemSeq    = Y.ItemSeq  
                             WHERE X.CompanySeq = @CompanySeq  
                               AND X.IsStandard = '1' ) AS I ON A.CompanySeq = I.CompanySeq  
                                                            AND A.ModelSeq = I.ModelSeq  
           LEFT OUTER JOIN KPX_TDAItem_Confirm AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = A.ItemSeq ) 
     WHERE (A.CompanySeq  = @CompanySeq)  
       AND ((@WorkingTag = 'A' AND @ItemSeq = 0) OR A.ItemSeq = @ItemSeq)  
        AND (@ItemName = '' Or A.ItemName like @ItemName + '%')  
        AND (@ItemNo   = '' Or A.ItemNo   like @ItemNo   + '%')  
        AND (@Spec   = '' Or A.Spec   like @Spec   + '%')  
        AND (@AssetSeq = 0  Or A.AssetSeq = @AssetSeq)  
        AND (@UnitSeq = 0   Or A.UnitSeq = @UnitSeq)  
        AND (@DeptSeq = 0   Or A.DeptSeq = @DeptSeq)  
        AND (@EmpSeq = 0    Or A.EmpSeq = @EmpSeq)  
        AND (@SMABC = 0     Or A.SMABC = @SMABC)  
        AND (@SMStatus = 0  Or A.SMStatus = @SMStatus)  
        AND (@SMInOutKind = 0  Or A.SMInOutKind = @SMInOutKind)  
        AND (@ModelSeq = 0     Or A.ModelSeq = @ModelSeq)  
        AND (@UMItemClassS = 0 Or B.UMItemClass = @UMItemClassS)  
--        AND (@WorkingTag = 'A' Or (@WorkingTag = 'I' AND J.MinorValue = 0) Or (@WorkingTag = 'M' AND J.MinorValue = 1))  
        AND (@IsOption = '0' OR D.IsOption = @IsOption)  
        AND (@IsSet = '0' OR D.IsSet = @IsSet)  
        AND (C.IsVessel = @IsVessel)  
     ORDER BY A.ItemSeq  
  
RETURN      
  