
IF OBJECT_ID('DTI_SSLReceiptConsignBillCheck') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignBillCheck
GO

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź���ݰ�꼭üũ) by����õ
CREATE PROC DTI_SSLReceiptConsignBillCheck  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    
    DECLARE @Count       INT,    
            @Seq         INT,    
            @MessageType INT,    
            @Status      INT,    
            @Results     NVARCHAR(250)    
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #DTI_TSLReceiptConsignBill (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TSLReceiptConsignBill'    
    
    -------------------------------------------    
    -- �ݾ��ʰ�üũ    
    -------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          106                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 106)    
                          @LanguageSeq       ,     
                          1923,'',      -- SELECT * FROM _TCADictionary WHERE Word like '%�Աݾ�%'   
                          15045, '',    -- SELECT * FROM _TCADictionary WHERE Word like '%���ݰ�꼭%'   
                          290, ''       -- SELECT * FROM _TCADictionary WHERE Word like '%�ݾ�%'   
    
    UPDATE #DTI_TSLReceiptConsignBill    
       SET Result        = @Results, --REPLACE(REPLACE(@Results,'@2','���ݰ�꼭'),'@3','�ݾ�'),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsignBill AS A   
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.Amt + X.VAT) AS CurAmt, SUM(X.Amt + X.VAT) AS DomAmt -- ���ݰ�꼭�ݾ�  
                         FROM DTI_TSLBillConsign            AS X 
                         JOIN #DTI_TSLReceiptConsignBill    AS Y ON X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq  
                        GROUP BY X.BillSeq
                      ) AS C ON ( A.BillSeq = C.BillSeq ) 
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt -- �������  
                         FROM DTI_TSLReceiptConsignBill     AS X 
                         JOIN #DTI_TSLReceiptConsignBill    AS Y ON ( X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq AND X.ReceiptSeq <> Y.ReceiptSeq ) 
                         GROUP BY X.BillSeq
                      ) AS D ON ( A.BillSeq = D.BillSeq ) 
     WHERE (ABS(C.CurAmt) < ABS(ISNULL(D.CurAmt,0) + A.CurAmt) OR ABS(C.DomAmt) < ABS(ISNULL(D.DomAmt,0) + A.DomAmt))  
       AND @WorkingTag <> 'D'    
    
    SELECT * FROM #DTI_TSLReceiptConsignBill  
    
    RETURN    
GO
exec DTI_SSLReceiptConsignBillCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BillSeq>3</BillSeq>
    <BillNo>140518000002</BillNo>
    <BillDate>20140502</BillDate>
    <BillCurAmt>330000</BillCurAmt>
    <BillDomAmt>330000</BillDomAmt>
    <PreBillCurAmt>330000</PreBillCurAmt>
    <PreBillDomAmt>330000</PreBillDomAmt>
    <CurAmt>100</CurAmt>
    <DomAmt>100</DomAmt>
    <ExRate>1</ExRate>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <ReceiptSeq>31</ReceiptSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1019203