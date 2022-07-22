IF OBJECT_ID('hencom_SCACodeHelpPUProdDistrict') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpPUProdDistrict
GO 

-- v2017.03.24 

-- �μ��� ���� ����(����Һ����Ŵܰ������ ����)
CREATE PROCEDURE hencom_SCACodeHelpPUProdDistrict
    @WorkingTag     NVARCHAR(1),
    @LanguageSeq    INT,
    @CodeHelpSeq    INT,
    @DefQueryOption INT, -- 2: direct search
    @CodeHelpType   TINYINT,
    @PageCount      INT = 20,
    @CompanySeq     INT = 0,
    @Keyword        NVARCHAR(50) = '',
    @Param1         NVARCHAR(50) = '',  -- �ڱ���ȭ ���Կ���(1=����, 0=����)
    @Param2         NVARCHAR(50) = '',
    @Param3         NVARCHAR(50) = '',
    @Param4         NVARCHAR(50) = ''
AS
    
    SET ROWCOUNT @PageCount
    
	SELECT DISTINCT A.ProdDistrictSeq, C.ProdDistirct AS ProdDistrictName, C.Location--,B.DispSeq--, D.DeptName AS Name
      FROM hencom_TPUBASEBuyPriceItem           AS A WITH(NOLOCK)
      LEFT OUTER JOIN hencom_TDADeptAdd         AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq  
      LEFT OUTER JOIN hencom_TPUPurchaseArea    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.ProdDistrictSeq = C.ProdDistrictSeq
      LEFT OUTER JOIN _TDADept                  AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.DeptSeq = D.DeptSeq  
	
     WHERE A.CompanySeq = @CompanySeq 
       AND ISNULL(A.ProdDistrictSeq,0) <> 0 
       AND C.ProdDistirct LIKE '%' + @Keyword + '%'
       AND (@Param1 = 0 OR A.DeptSeq = @Param1 )
	ORDER BY C.ProdDistirct
 
    SET ROWCOUNT 0
    
    RETURN
/**********************************************************************************************************/
