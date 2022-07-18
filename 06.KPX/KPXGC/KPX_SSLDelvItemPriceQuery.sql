  
IF OBJECT_ID('KPX_SSLDelvItemPriceQuery') IS NOT NULL   
    DROP PROC KPX_SSLDelvItemPriceQuery  
GO  
  
-- v2014.11.12  
  
-- �ŷ�ó����ǰó�ܰ����-��ȸ by ����õ   
CREATE PROC KPX_SSLDelvItemPriceQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,  
            -- ��ȸ����   
            @BizUnit        INT,  
            @CustName       NVARCHAR(100), 
            @CustNo         NVARCHAR(100), 
            @DVPlaceName    NVARCHAR(100), 
            @IsExists       NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ), 
           @CustName    = ISNULL( CustName, '' ), 
           @CustNo      = ISNULL( CustNo, '' ), 
           @DVPlaceName = ISNULL( DVPlaceName, '' ), 
           @IsExists    = ISNULL( IsExists, '0' )
    
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit         INT, 
            CustName        NVARCHAR(100),
            CustNo          NVARCHAR(100),
            DVPlaceName     NVARCHAR(100), 
            IsExists        NCHAR(1) 
           )    
    
    -- ������ȸ   
    SELECT E.BizUnitName, 
           E.BizUnit, 
           B.UMCustClass AS UMChannel, 
           C.MinorName AS UMChannelName,                        -- ���뱸�� 
           A.CustSeq, 
           F.CustName, 
           F.CustNo, 
           A.DVPlaceSeq,                                        -- ��ǰó�ڵ� 
           G.DVPlaceName,                                       -- ��ǰó 
           A.DelvRegSeq AS DelvRegSeq,                          -- ��������ڵ�  
           ISNULL(H.MinorName,'') AS DelvRegName,               -- �������
           ISNULL(A.Addr1,'') + ISNULL(A.Addr2,'') AS Addr,     -- �ּ� 
           --A.ClientInfoSeq AS ClientInfoSeq,                  -- ������ڵ�
           --ISNULL(M.FamilyName, '') + 
           --ISNULL(M.ClientName, '') AS ClientInfoName,        -- �����
           A.ClientName AS ClientInfoName, 
           ISNULL(A.TelNo,'') AS TelNo,                         -- ��ȭ��ȣ 
           ISNULL(A.MobileNo,'') AS MobileNo,                   -- �޴���ȭ��ȣ  
           ISNULL(A.Remark,'') AS Remark,                       -- ���  
           A.UMCourse AS UMCourse,                              -- ��ٱ����ڵ�  
           ISNULL(L.MinorName,'') AS UMCourseName,              -- ��ٱ��� 
           I.EmpSeq AS SalesEmpSeq,                             -- ����������ڵ�  
           J.EmpName AS SalesEmpName                            -- ���������
      FROM _TSLDeliveryCust             AS A  
      LEFT OUTER JOIN _TDACustClass     AS B ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq AND B.UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMCustClass ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1001 ) 
      LEFT OUTER JOIN _TDABizUnit       AS E ON ( E.CompanySeq = @CompanySeq AND E.BizUnit = D.ValueSeq ) 
      LEFT OUTER JOIN _TDACust          AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TSLDeliveryCust  AS G ON ( G.CompanySeq = @CompanySeq AND G.DVPlaceSeq = A.DVPlaceSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.DelvRegSeq ) 
      LEFT OUTER JOIN _TSLCustSalesEmp  AS I ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = I.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = A.UMCourse ) 
      LEFT OUTER JOIN _TSIASClientInfo  AS M ON ( M.CompanySeq = @CompanySeq AND M.ClientInfoSeq = A.ClientInfoSeq ) 
      CROSS APPLY ( SELECT CustSeq  
                     FROM _TDACustKind AS Z 
                    WHERE Z.CompanySeq = @CompanySeq  
                      AND Z.UMCustKind IN ( SELECT Q.UMCustKind
                                              FROM _TDACustHelpGroup                AS O WITH(NOLOCK)    
                                              LEFT OUTER JOIN _TCACodeHelpData      AS P WITH(NOLOCK) ON O.NameCodeHelp = P.CodeHelpSeq  
                                              LEFT OUTER JOIN _TDACustKindCodeHelp  AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.CustCodeHelpSeq = O.CustCodeHelpSeq ) 
                                                         JOIN _TDAUMinor            AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.MajorSeq = 1004 AND T.IsUse = '1' AND T.MinorSeq = Q.UMCustKind ) 
                                             WHERE O.CompanySeq = @CompanySeq     
                                               AND O.CustCodeHelpSeq = 0 
                                          ) 
                      AND Z.CustSeq = A.CustSeq 
                  ) AS K 

     WHERE A.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR E.BizUnit = @BizUnit) 
       AND (@CustName = '' OR F.CustName LIKE @CustName + '%') 
       AND (@CustNo = '' OR F.CustNo LIKE @CustNo + '%') 
       AND (@DVPlaceName = '' OR G.DVPlaceName LIKE @DVPlaceName + '%') 
       AND (@IsExists = '0' OR (@IsExists = '1' AND EXISTS (SELECT 1 FROM KPX_TSLDelvItemPrice WHERE CompanySeq = A.CompanySeq AND CustSeq = A.CustSeq AND DVPlaceSeq = A.DVPlaceSeq)))
    
    RETURN  
GO 
exec KPX_SSLDelvItemPriceQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit />
    <CustName />
    <CustNo />
    <DVPlaceName />
    <IsExists>0</IsExists>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025779,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021314
