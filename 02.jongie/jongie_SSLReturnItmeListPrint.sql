
IF OBJECT_ID('jongie_SSLReturnItemListPrint')IS NOT NULL 
    DROP PROC jongie_SSLReturnItemListPrint
GO 

-- v2013.10.02 
  
-- �ǸŹ�ǰǰ����Ȳ(���)_jongie by����õ  
CREATE PROC jongie_SSLReturnItemListPrint                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
AS          
      
    DECLARE @docHandle      INT,   
            @CustSeq        INT,   
            @DeptSeq        INT,   
            @InvoiceDateTo  NVARCHAR(8),   
            @EmpSeq         INT,   
            @InvoiceDateFr  NVARCHAR(8)   
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
      
    SELECT @CustSeq = CustSeq,   
           @DeptSeq = DeptSeq,   
           @InvoiceDateTo = InvoiceDateTo,   
           @EmpSeq = EmpSeq,   
           @InvoiceDateFr = InvoiceDateFr   
      
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      
      WITH (  
            CustSeq         INT,   
            DeptSeq         INT,   
            InvoiceDateTo   NVARCHAR(8),   
            EmpSeq          INT,   
            InvoiceDateFr   NVARCHAR(8)  
           )  
      
    SELECT A.InvoiceDate, 
           STUFF(RIGHT(A.InvoiceDate,4),3,0,'-') AS InvoiceDateMD, 
           C.EmpName,   
           @InvoiceDateFr AS InvoiceDateFr,   
           @InvoiceDateTo AS InvoiceDateTo,   
           CASE WHEN ISNULL(A.DVPlaceSeq,0) = 0 THEN H.CustName ELSE D.DVPlaceName END AS DelvCustName, 
           ISNULL(B.Qty, 0) AS Qty, 
           ISNULL(B.Price,0) AS Price,  
           ISNULL(B.CurAmt,0) AS CurAmt, 
           ISNULL(B.CurVAT,0) AS CurVAT, 
           ISNULL(B.CurAmt,0) + ISNULL(B.CurVAT,0) AS TotCurAmt,  
           E.ItemName,   
           E.ItemNo,   
           ISNULL((  
                   SELECT (B.Qty) % (P.ConvNum) / (P.ConvDen)  
                     FROM jongie_TCOMEnv AS O WITH(NOLOCK)   
                     JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = B.ItemSeq )   
                    WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1  
                  ),0
                 ) AS Rest, -- ��  
           CASE WHEN (SELECT (B.Qty) / (P.ConvNum) / (P.ConvDen)  
                       FROM jongie_TCOMEnv AS O WITH(NOLOCK)   
                       JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = B.ItemSeq )   
                      WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1) > 0   
                THEN FLOOR(  
                           (  
                               SELECT (B.Qty) / (P.ConvNum) / (P.ConvDen)  
                                 FROM jongie_TCOMEnv AS O WITH(NOLOCK)   
                                 JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = B.ItemSeq )   
                                WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1  
                           )  
                          )  
                ELSE 0   
                END AS BoxQty -- �ڽ�  

             
      FROM _TSLInvoice                 AS A WITH(NOLOCK)   
      JOIN _TSLInvoiceItem             AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq )   
      LEFT OUTER JOIN _TDAEmp          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq )   
      LEFT OUTER JOIN _TSLDeliveryCust AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DVPlaceSeq = A.DVPlaceSeq )   
      LEFT OUTER JOIN _TDAItem         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq ) 
                 JOIN _TDAUMinor       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMOutKind ) 
                 JOIN _TDAUMinorValue  AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 2002 AND G.ValueText = '1' ) 
      LEFT OUTER JOIN _TDACust         AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = A.CustSeq ) 
  
     WHERE A.CompanySeq = @CompanySeq  
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)   
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)   
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)   
       AND (A.InvoiceDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo)   
    
     ORDER BY C.EmpName, A.InvoiceDate, DelvCustName, ItemNo, ItemName  
      
    RETURN  
GO
exec jongie_SSLReturnItemListPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <InvoiceDateFr>20130101</InvoiceDateFr>
    <InvoiceDateTo>20131002</InvoiceDateTo>
    <DeptSeq />
    <EmpSeq />
    <CustSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018292,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1276

