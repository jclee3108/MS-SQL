
IF OBJECT_ID('DTI_SSLReceiptConsignBillQuery') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignBillQuery
GO 

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź���ݰ�꼭������ȸ) by����õ
CREATE PROCEDURE DTI_SSLReceiptConsignBillQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    
    DECLARE @docHandle    INT,  
            @ReceiptSeq   INT,  
            @ReceiptSerl   INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    SELECT  @ReceiptSeq  = ISNULL(ReceiptSeq,0)  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)         
    WITH (  ReceiptSeq     INT)     
    
    CREATE TABLE #TempBill  
    (  
        ReceiptSeq    INT,  
        BillSeq      INT,  
        CurAmt       DECIMAL(19,5),  
        DomAmt       DECIMAL(19,5)  
    )  
    
    INSERT INTO #TempBill  
    SELECT ReceiptSeq, BillSeq, SUM(CurAmt) AS CurAmt, SUM(DomAmt) AS DomAmt  
      FROM DTI_TSLReceiptConsignBill 
     WHERE CompanySeq = @CompanySeq  
       AND ReceiptSeq = @ReceiptSeq  
     GROUP BY ReceiptSeq, BillSeq  
    
    
    SELECT A.ReceiptSeq AS ReceiptSeq, -- �����ݴ�ü���ι�ȣ  
           A.BillSeq    AS BillSeq,  
           B.BillNo     AS BillNo,  
           B.BillDate   AS BillDate,  
           C.CurAmt AS BillCurAmt, -- ���ݰ�꼭�ݾ�  
           C.DomAmt AS BillDomAmt, -- ���ݰ�꼭��ȭ�ݾ�  
           ISNULL(D.CurAmt,0) AS PreBillCurAmt, -- �����Աݾ�  
           ISNULL(D.DomAmt,0) AS PreBillDomAmt, -- �����Աݿ�ȭ�ݾ�  
           A.CurAmt AS CurAmt, -- ��ȸ�Աݾ�  
           A.DomAmt AS DomAmt, -- ��ȸ�Աݿ�ȭ�ݾ�  
           
           E.RemValueName AS RemName, -- ��ȭ��
           B.RemSeq, 
           B.MyCustSeq, 
           B.CustSeq, 
           F.CustName AS MyCustName, -- ������ 
           G.CustName AS CustName -- ���޹޴���
           
        
      FROM  #TempBill AS A   
      LEFT OUTER JOIN DTI_TSLBillConsign AS B ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.Amt + X.VAT) AS CurAmt, SUM(X.Amt + X.Vat) AS DomAmt -- ���ݰ�꼭�ݾ�  
                         FROM DTI_TSLBillConsign AS X WITH (NOLOCK)  
                         JOIN #TempBill AS Y ON ( X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq ) 
                        GROUP BY X.BillSeq
                      ) AS C ON ( A.BillSeq = C.BillSeq )
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt -- �������  
                         FROM DTI_TSLReceiptConsignBill AS X WITH (NOLOCK)  
                         JOIN #TempBill AS Y ON ( X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq ) 
                        GROUP BY X.BillSeq
                      ) AS D ON ( A.BillSeq = D.BillSeq ) 
      LEFT OUTER JOIN _TDAAccountRemValue AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.RemValueSerl = B.RemSeq )   
      LEFT OUTER JOIN _TDACust            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.MyCustSeq ) 
      LEFT OUTER JOIN _TDACust            AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = B.CustSeq ) 
     WHERE A.ReceiptSeq   = @ReceiptSeq  
     ORDER BY A.ReceiptSeq, B.BillNo  
    
    RETURN 
GO
exec DTI_SSLReceiptConsignBillQuery @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReceiptSeq>24</ReceiptSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019203