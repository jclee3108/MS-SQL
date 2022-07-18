
IF OBJECT_ID('KPX_SHRWelConAmtQuery') IS NOT NULL 
    DROP PROC KPX_SHRWelConAmtQuery
GO 

-- v2014.11.27 

-- ���������ޱ��ص��(��ȸ) by����õ 
CREATE PROCEDURE KPX_SHRWelConAmtQuery        
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS             
    DECLARE @docHandle      INT      
          , @SMConMutual     INT       
          , @IsNoUseInclude NCHAR(1)       
          , @UMConClass     INT       
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
      
  
    SELECT  @SMConMutual     = ISNULL(SMConMutual, 0)         -- �������ޱ���(����/����)  
        , @IsNoUseInclude   = ISNULL(IsNoUseInclude,'')     -- ����������  
        , @UMConClass       = ISNULL(UMConClass,0)          -- ������з�  
             
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH (SMConMutual        INT  
        , IsNoUseInclude    NCHAR(1)  
        , UMConClass        INT)        
      
    SELECT @SMConMutual     = ISNULL(@SMConMutual, 0)         -- �������ޱ���(����/����)  
        , @IsNoUseInclude   = ISNULL(@IsNoUseInclude,'')     -- ����������  
        , @UMConClass       = ISNULL(@UMConClass,0)          -- ������з�  
    
    -- ������ȸ 
    SELECT A.ConSeq   AS ConSeq        -- �������ڵ�  
        , A.ConName         AS ConName       -- �������  
        , A.UMConClass      AS UMConClass    -- ������з��ڵ�  
        , A.IsFlower        AS IsFlower      -- ����ȭ����  
        , A.HoliDays        AS HoliDays      -- �ް��ϼ�  
        , A.WkItemSeq       AS WkItemSeq     -- �����׸��ڵ�  
        , A.IsConAmt        AS IsConAmt      -- ����������  
        , A.IsMutualAmt     AS IsMutualAmt   -- ����������  
        , A.SMConPayMth     AS SMConPayMth   -- ���������ޱ����ڵ�  
        , A.SMMutualPayMth  AS SMMutualPayMth-- ���������ޱ����ڵ�  
        , A.UMConType       AS UMConType     -- �����ݺ����Ļ�����  
        , A.UMMutualType    AS UMMutualType  -- �����ݺ����Ļ�����  
        , A.IsNoUse         AS IsNoUse       -- ������  
        , B.WkItemName      AS WkItemName       -- �����׸��  
        , C.MinorName       AS SMConPayMthName  -- ���������ޱ��ظ�  
        , D.MinorName       AS SMMutualPayMthName   -- ���������ޱ��ظ�  
        , E.MinorName       AS UMConTypeName   -- �����ݺ����Ļ����и�  
        , F.MinorName       AS UMMutualTypeName   -- �����ݺ����Ļ�����  
        , CASE @SMConMutual WHEN 3236001 THEN A.SMConPayMth ELSE A.SMMutualPayMth END AS SMPayMth   -- ���������ڵ�  
        , G.MinorName   AS SMPayMth -- ���ޱ��ظ�  
        , A.EvidPaper AS EvidPaper -- 20101129������ :: �������� �ʵ��߰�  
        , A.Remark  AS Remark  -- 20101129������ :: ��� �ʵ��߰�  
        
      FROM _THRWelCon               AS A   
      LEFT OUTER JOIN _TPRWkItem    AS B ON A.CompanySeq = B.CompanySeq AND A.WkItemSeq = B.WkItemSeq  
      LEFT OUTER JOIN _TDAUMinor    AS C ON A.CompanySeq = C.CompanySeq AND A.SMConPayMth = C.MinorSeq  
      LEFT OUTER JOIN _TDASMinor    AS D ON A.CompanySeq = D.CompanySeq AND A.SMMutualPayMth = D.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor    AS E ON A.CompanySeq = E.CompanySeq AND A.UMConType = E.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor    AS F ON A.CompanySeq = F.CompanySeq AND A.UMMutualType = F.MinorSeq  
      LEFT OUTER JOIN _TDASMinor    AS G ON A.CompanySeq = G.CompanySeq AND CASE @SMConMutual WHEN 3236001 THEN A.SMConPayMth ELSE A.SMMutualPayMth END = G.MinorSeq  
    
     WHERE A.CompanySeq = @CompanySeq  
       AND (@SMConMutual = 0 OR (@SMConMutual = 3236001 AND A.IsConAmt = '1') OR (@SMConMutual = 3236002 AND A.IsMutualAmt = '1'))   
       AND (@IsNoUseInclude = '' OR @IsNoUseInclude = '1' OR (@IsNoUseInclude = '0' AND A.IsNoUse <> '1'))  
       AND (@UMConClass = 0 OR A.UMConClass = @UMConClass)  
       AND (@SMConMutual <> 3236001  OR A.SMConPayMth <> 0)  
       AND (@SMConMutual <> 3236002  OR A.SMMutualPayMth <> 0)  
       AND (@SMConMutual = 3236001 AND A.SMConPayMth = 3235999) OR (@SMConMutual = 3236002 AND A.SMMutualPayMth = 3235999)
    RETURN        
  