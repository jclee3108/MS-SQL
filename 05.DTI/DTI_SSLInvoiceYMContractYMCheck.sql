
IF OBJECT_ID('DTI_SSLInvoiceYMContractYMCheck') IS NOT NULL
    DROP PROC DTI_SSLInvoiceYMContractYMCheck 
GO

-- v2014.02.28 

-- �ŷ������Է�_DTI(���� �ŷ������� üũ) by����õ
CREATE PROC dbo.DTI_SSLInvoiceYMContractYMCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS 
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #TSLInvoice (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoice'
    
    CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLInvoiceItem'
    
    UPDATE A
       SET Result        = N'����� ���� �ŷ������� ���� �ٸ��ϴ�.', 
           MessageType   = 1234,  
           Status        = 1234 
      FROM #TSLInvoice AS A 
     WHERE LEFT(A.InvoiceDate,6) <> ( SELECT TOP 1 D.SalesYM
                                        FROM #TSLInvoiceItem          AS A 
                                        JOIN _TSLOrderItem            AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OrderSeq = A.FromSeq AND C.OrderSerl = A.FromSerl ) 
                                        JOIN DTI_TSLContractMngItem   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq 
                                                                                         AND D.ContractSeq = CONVERT(INT,C.Dummy6) 
                                                                                         AND D.ContractSerl = CONVERT(INT,C.Dummy7) 
                                                                                           )
                                    ) 
       AND A.WorkingTag = 'A' 
       AND A.Status = 0 
       
    UPDATE A
       SET Result        = N'����� ���� �ŷ������� ���� �ٸ��ϴ�.', 
           MessageType   = 1234,  
           Status        = 1234 
      FROM #TSLInvoice AS A 
     WHERE LEFT(A.InvoiceDate,6) <> ( SELECT TOP 1 D.SalesYM
                                        FROM #TSLInvoice              AS A 
                                        JOIN _TSLInvoiceItem          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
                                        JOIN _TSLOrderItem            AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OrderSeq = B.ProgFromSeq AND C.OrderSerl = B.ProgFromSerl ) 
                                        JOIN DTI_TSLContractMngItem   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq 
                                                                                         AND D.ContractSeq = CONVERT(INT,C.Dummy6) 
                                                                                         AND D.ContractSerl = CONVERT(INT,C.Dummy7) 
                                                                                           )
                                    ) 
       AND A.WorkingTag = 'U' 
       AND A.Status = 0 
    
    SELECT * FROM #TSLInvoice 
    
RETURN    
GO
exec DTI_SSLInvoiceYMContractYMCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FromTableSeq>19</FromTableSeq>
    <FromSeq>1000622</FromSeq>
    <FromSerl>1</FromSerl>
    <FromSubSerl>0</FromSubSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <InvoiceSeq>1001304</InvoiceSeq>
    <ItemPrice>0.00000</ItemPrice>
    <CustPrice>0.00000</CustPrice>
    <Qty>400.00000</Qty>
    <IsInclusedVAT>0</IsInclusedVAT>
    <VATRate>10.00000</VATRate>
    <CurAmt>80000.00000</CurAmt>
    <CurVAT>8000.00000</CurVAT>
    <DomAmt>80000.00000</DomAmt>
    <DomVAT>8000.00000</DomVAT>
    <STDUnitSeq>2</STDUnitSeq>
    <STDQty>400.00000</STDQty>
    <WHSeq>7</WHSeq>
    <Remark />
    <ItemName>������_��ǰ_LOT2</ItemName>
    <ItemNo>������_��ǰ_LOT2</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <STDUnitName>EA</STDUnitName>
    <WHName>������ũ</WHName>
    <InvoiceSerl>1</InvoiceSerl>
    <ItemSeq>21937</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <UMEtcOutKind>0</UMEtcOutKind>
    <TrustCustSeq>0</TrustCustSeq>
    <LotNo />
    <SerialNo />
    <UMEtcOutKindName />
    <TrustCustName />
    <STDItemSeq>0</STDItemSeq>
    <Price>200.00000</Price>
    <IsQtyChange>0</IsQtyChange>
    <AccName>��ǰ����(����)</AccName>
    <AccSeq>410</AccSeq>
    <WBSSeq>0</WBSSeq>
    <PJTSeq>0</PJTSeq>
    <EmpSeq>2028</EmpSeq>
    <CCtrName />
    <CCtrSeq>0</CCtrSeq>
  </DataBlock2>
  <DataBlock1>
    <IDX_NO>1</IDX_NO>
    <WorkingTag>A</WorkingTag>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <InvoiceSeq>1001304</InvoiceSeq>
    <BizUnit>1</BizUnit>
    <SMExpKind>8009001</SMExpKind>
    <InvoiceNo>Invoice201402280020</InvoiceNo>
    <InvoiceDate>20140228</InvoiceDate>
    <UMOutKind>8020001</UMOutKind>
    <DeptSeq>147</DeptSeq>
    <EmpSeq>2028</EmpSeq>
    <CustSeq>37606</CustSeq>
    <BKCustSeq>29910</BKCustSeq>
    <AGCustSeq>0</AGCustSeq>
    <DVPlaceSeq>0</DVPlaceSeq>
    <CurrSeq>1</CurrSeq>
    <ExRate>1.000000</ExRate>
    <IsOverCredit>0</IsOverCredit>
    <IsMinAmt>0</IsMinAmt>
    <IsStockSales>0</IsStockSales>
    <Remark />
    <Memo />
    <ArrivalDate xml:space="preserve">        </ArrivalDate>
    <ArrivalTime xml:space="preserve">    </ArrivalTime>
    <BizUnitName>�ƻ����</BizUnitName>
    <SMExpKindName>����</SMExpKindName>
    <UMOutKindName>�����Ǹ�</UMOutKindName>
    <DeptName>���������</DeptName>
    <EmpName>����õ</EmpName>
    <CustName>(��)���Ѱ����򰡹���</CustName>
    <CustNo>135963213</CustNo>
    <BKCustName>(��)��ȿ��������������ȸ</BKCustName>
    <AGCustName />
    <DVPlaceName />
    <CurrName>KRW</CurrName>
    <IsSalesWith>0</IsSalesWith>
    <SMSalesCrtKind>8017001</SMSalesCrtKind>
    <SMSalesCrtKindName>������</SMSalesCrtKindName>
    <IsPJT>0</IsPJT>
    <SMConsignKind>8060001</SMConsignKind>
    <SMConsignKindName>�Ϲ�</SMConsignKindName>
    <SMTransKind>0</SMTransKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016111,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001633