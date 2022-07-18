
IF OBJECT_ID('DTI_SSLBillCollectRateSubQuery') IS NOT NULL
    DROP PROC DTI_SSLBillCollectRateSubQuery
GO

-- v2014.02.12 

-- ä��ȸ����(�����)_DTI-��ȸ by����õ 
CREATE PROC DTI_SSLBillCollectRateSubQuery    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    DECLARE @docHandle          INT        ,    
            -- ��ȸ����     
            @BizUnit            INT        ,  
            @FundArrangeDateFr  NVARCHAR(8),    
            @FundArrangeDateTo  NVARCHAR(8),  
            @STDDate            NVARCHAR(8),  
            @BillDateFr         NVARCHAR(8),  
            @BillDateTo         NVARCHAR(8),  
            @DeptSeq            INT        ,  
            @EmpSeq             INT             
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @BizUnit           = ISNULL( BizUnit          , 0  ),            
           @FundArrangeDateFr = ISNULL( FundArrangeDateFr, '' ),  
           @FundArrangeDateTo = ISNULL( FundArrangeDateTo, 0  ),  
           @STDDate           = ISNULL( STDDate          , '' ),  
           @BillDateFr        = ISNULL( BillDateFr       , '' ),  
           @BillDateTo        = ISNULL( BillDateTo       , '' ),  
           @DeptSeq           = ISNULL( DeptSeq          , 0  ),  
           @EmpSeq            = ISNULL( EmpSeq           , 0  )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (BizUnit            INT        ,  
            FundArrangeDateFr  NVARCHAR(8),  
            FundArrangeDateTo  NVARCHAR(8),  
            STDDate            NVARCHAR(8),  
            BillDateFr         NVARCHAR(8),  
            BillDateTo         NVARCHAR(8),  
            DeptSeq            INT        ,  
            EmpSeq             INT          
           )  
    
    -- �ڱݿ�����To�� ������ ���      
    IF @FundArrangeDateTo = '' SELECT @FundArrangeDateTo = '99991231'  
    
    -- �ӽ� ���̺� 
    CREATE TABLE #Temp_TSLBill  
    (   
        IDX_NO          INT IDENTITY,  
        SalesSeq        INT,
        SalesSerl       INT,
        BillSeq         INT, 
        Qty             DECIMAL(19,5),
        SalesDomAmt     DECIMAL(19,5),
        BizUnit         INT,
        CustSeq         INT,
        DeptSeq         INT,
        EmpSeq          INT,
        FundArrangeDate NVARCHAR(8),
        BillDate        NVARCHAR(8),
        DelvInAmt       DECIMAL(19,5)
    )
    
    -- ���� ���̺�� ���̺� 
    CREATE TABLE #TMP_SOURCETABLE( IDOrder INT IDENTITY, TableName NVARCHAR(100) )        
    
    -- ��õ ���̺� 
    CREATE TABLE #TCOMSourceTracking( IDX_NO INT, IDOrder INT, Seq INT, Serl INT, SubSerl INT, 
	                                  Qty DECIMAL(19, 5), STDQty DECIMAL(19, 5), Amt DECIMAL(19, 5), VAT DECIMAL(19, 5) )        
	
    INSERT INTO #Temp_TSLBill  
    (
        SalesSeq, SalesSerl, BillSeq, Qty, SalesDomAmt,
        BizUnit, CustSeq, DeptSeq, EmpSeq, FundArrangeDate, 
        BillDate
    )                
    SELECT B.SalesSeq, B.SalesSerl, A.BillSeq, ISNULL(C.Qty,0), ISNULL(C.DomAmt,0) AS SalesDomAmt,
           A.BizUnit, A.CustSeq, A.DeptSeq, A.EmpSeq, A.FundArrangeDate, 
           A.BillDate
           
      FROM _TSLBill AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TSLSalesBillRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.BillSeq = B.BillSeq ) 
      LEFT OUTER JOIN _TSLSalesItem         AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND B.SalesSeq = C.SalesSeq AND B.SalesSerl = C.SalesSerl )
      
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND A.FundArrangeDate BETWEEN @FundArrangeDateFr AND @FundArrangeDateTo 
       AND A.BillDate BETWEEN @BillDateFr AND @BillDateTo 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq )              
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq )               
    
    INSERT #TMP_SOURCETABLE(TableName)
    SELECT '_TSLInvoiceItem'  
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLSalesItem', '#Temp_TSLBill', 'SalesSeq', 'SalesSerl', '' -- ��õ
    
    -- �����԰�ݾ� Update
    UPDATE Z 
       SET Z.DelvInAmt   = ISNULL(C.DomAmt,0) + ISNULL(C.DomVAT,0)
      FROM #Temp_TSLBill AS Z
      LEFT OUTER JOIN #TCOMSourceTracking AS A WITH(NOLOCK) ON ( A.IDX_NO = Z.IDX_NO )
      LEFT OUTER JOIN _TSLInvoiceItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl AND A.IDOrder = 1 )
      LEFT OUTER JOIN _TPUDelvinItem      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.LotNo = B.LotNo )
    
    -- ���ݰ�꼭 �Ǻ� ����
    -- ���GP�� (���ݰ�꼭 ����)
    SELECT A.BillSeq,
           CONVERT(DECIMAL(19,5),0) AS TotDomAmt,-- ä���Ѿ�
           ISNULL((SUM(A.SalesDomAmt) - SUM(A.DelvInAmt)) / NULLIF(SUM(A.SalesDomAmt),0),0) * 100 AS AvgGPRate,
           MAX(A.BizUnit) AS BizUnit, 
           MAX(A.CustSeq) AS CustSeq, 
           MAX(A.DeptSeq) AS DeptSeq, 
           MAX(A.EmpSeq) AS EmpSeq, 
           MAX(A.FundArrangeDate) AS FundArrangeDate, 
           MAX(A.BillDate) AS BillDate,
           CONVERT(DECIMAL(19,5),0) AS AvgCollectDate,
           CONVERT(DECIMAL(19,5),0) AS TotNoReceiptAmt, -- �̼��Ѿ�
           CONVERT(DECIMAL(19,5),0) AS TotOverdueAmt,   -- ��ü�Ѿ�
           CONVERT(DECIMAL(19,5),0) AS TotMortageAmt   -- �㺸�Ѿ�
    
      INTO #TSLBill  
      FROM #Temp_TSLBill AS A
     GROUP BY A.BillSeq
    
    -- ä���Ѿ�(=���ݰ�꼭�Ѿ�), ���ȸ����, �̼��ݾ�, �㺸�ݾ� Update                     
    UPDATE A
       SET A.AvgCollectDate  = ISNULL(B.AvgCollectDate,0), 
           A.TotNoReceiptAmt = ISNULL(Z.TotDomAmt,0) - ISNULL(B.TotNoReceiptAmt,0),
           A.TotOverdueAmt   = (CASE WHEN @STDDate <= A.FundArrangeDate THEN 0 ELSE ISNULL(Z.TotDomAmt,0) - ISNULL(B.TotNoReceiptAmt,0) END), 
           A.TotMortageAmt   = ISNULL(C.SpecCreditAmt,0),
           A.TotDomAmt       = ISNULL(Z.TotDomAmt,0)
           
      FROM #TSLBill AS A 
           LEFT OUTER JOIN (SELECT A.BillSeq, SUM(ISNULL(B.DomAmt,0)+ISNULL(B.DomVAT,0)) AS TotDomAmt
                              FROM #TSLBill AS A
                              JOIN _TSLBillItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq )
                             GROUP BY A.BillSeq
                           )  AS Z ON ( Z.BillSeq = A.BillSeq )
                           
           LEFT OUTER JOIN (SELECT A.BillSeq,
                                   AVG(DATEDIFF(DAY, A.BillDate, E.ReceiptDate)) AS AvgCollectDate, -- ȸ���� = �Ա��� - ���ݰ�꼭��
                                   SUM(ISNULL(C.DomAmt,0)+ISNULL(D.DomAmt,0)) AS TotNoReceiptAmt
                              FROM #TSLBill AS A
                              LEFT OUTER JOIN _TSLReceiptBill     AS C WITH(NOLOCK) ON ( C.companySeq = @CompanySeq AND C.BillSeq = A.BillSeq ) -- �Ա� 
                              LEFT OUTER JOIN _TSLPreReceiptBill  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.BillSeq = A.BillSeq ) -- ������ 
                              LEFT OUTER JOIN _TSLReceipt         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ReceiptSeq = C.ReceiptSeq )
                             WHERE E.ReceiptDate <= @STDDate
                             GROUP BY A.BillSeq
                           )  AS B ON ( B.BillSeq = A.BillSeq )
 
           LEFT OUTER JOIN (SELECT A.BillSeq, SUM(ISNULL(B.SpecCreditAmt,0)) AS SpecCreditAmt
                              FROM #TSLBill AS A
                              JOIN _TSLCustSpecCredit  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq )
                             WHERE @STDDate BETWEEN B.SDate AND B.EDate
                             GROUP BY A.BillSeq
                           )  AS C ON ( A.BillSeq = C.BillSeq )
    
    -- ������ȸ(�μ�����ں�)  
    SELECT A.DeptSeq,
           MAX(B.DeptName) AS DeptName,
           A.EmpSeq,  
           MAX(C.EmpName) AS EmpName,
           SUM(A.TotDomAmt) AS TotBondAmt, -- ä���Ѿ�  
           SUM(A.TotNoReceiptAmt) AS TotNoReceiptAmt, -- �̼��Ѿ� (���ݰ�꼭��ȸ ȭ����� ����)
           SUM(A.TotOverdueAmt) AS TotOverdueAmt, -- ��ü�Ѿ� : �ڱݿ������� �������� ���� �̼���  
           SUM(A.TotMortageAmt) AS TotMortageAmt, -- �㺸�ݾ�   
           AVG(A.AvgCollectDate) AS AvgCollectDate,  -- ���ȸ����  
           AVG(A.AvgGPRate) AS AvgGPRate, -- ���GP�� (���ݰ�꼭����) 
           ISNULL(SUM(A.TotMortageAmt)/NULLIF(SUM(A.TotDomAmt),0),0)*100 AS MortageRate, -- �㺸���� : �㺸�ݾ�/ä���Ѿ�*100  
           ISNULL(SUM(A.TotOverdueAmt)/NULLIF(SUM(A.TotDomAmt),0),0)*100 AS OverdueRate  -- ��ü���� : ��üä��/ä���Ѿ�*100
           
       FROM #TSLBill AS A  
      JOIN _TDADept AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq )
      JOIN _TDAEmp  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq )
     GROUP BY A.DeptSeq, A.EmpSeq  
    
    RETURN 
GO
exec DTI_SSLBillCollectRateSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FundArrangeDateFr />
    <FundArrangeDateTo />
    <STDDate>20140212</STDDate>
    <BillDateFr>20140201</BillDateFr>
    <BillDateTo>20140212</BillDateTo>
    <BizUnit>1</BizUnit>
    <DeptSeq/>
    <EmpSeq/>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1014863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1012960
