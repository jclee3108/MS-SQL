
IF OBJECT_ID('yw_SSLBillTotalSave') IS NOT NULL
    DROP PROC yw_SSLBillTotalSave
GO

-- 2013.08.26 

-- �Ǻ����ݰ�꼭 �������_YW(����) By����õ
CREATE PROC yw_SSLBillTotalSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
	CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoiceItem'     
	IF @@ERROR <> 0 RETURN  
    
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
    EXEC _SCOMLog @CompanySeq   ,
                  @UserSeq      ,
                  '_TSLInvoiceItem', -- �����̺��
                  '#TSLInvoiceItem', -- �������̺��
                  'InvoiceSeq, InvoiceSerl' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                  'CompanySeq, InvoiceSeq, InvoiceSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT,
                   STDUnitSeq, STDQty, WHSeq, Remark, UMEtcOutKind, TrustCustSeq, LotNo, SerialNo, PJTSeq, WBSSeq, CCtrSeq, LastUserSeq, LastDateTime,Price,PgmSeq,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy7,Dummy8,Dummy9,Dummy10',
                  '', @PgmSeq 
    
    -- UPDATE    
	IF EXISTS (SELECT 1 FROM #TSLInvoiceItem WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE B
			   SET Price = A.Price, 
			       CurAmt = A.InvoiceCurAmt, 
			       CurVAT = A.InvoiceCurVAT, 
			       DomAmt = A.InvoiceDomAmt, 
			       DomVAT = A.InvoiceDomVAT, 
                   LastUserSeq = @UserSeq, 
			       LastDateTime = GetDate()
			  FROM #TSLInvoiceItem AS A 
              JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq AND A.InvoiceSerl = B.InvoiceSerl ) 
             WHERE A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
    
    SELECT * FROM #TSLInvoiceItem 
    
    RETURN    

GO

exec yw_SSLBillTotalSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnitNameBizUnitName />
    <BizUnit>1</BizUnit>
    <InvoiceSeq>1000747</InvoiceSeq>
    <InvoiceNo>Invoice201308190004</InvoiceNo>
    <InvoiceSerl>1</InvoiceSerl>
    <InvoiceDate>20130819</InvoiceDate>
    <ExpKindName>����</ExpKindName>
    <SMExpKind>8009001</SMExpKind>
    <OutKindName>�ǸŹ�ǰ</OutKindName>
    <UMOutKind>8020004</UMOutKind>
    <InvDeptName>���������</InvDeptName>
    <InvDeptSeq>147</InvDeptSeq>
    <InvEmpName>�չ̳�</InvEmpName>
    <InvEmpSeq>2026</InvEmpSeq>
    <InvoiceCustName>mn_�ŷ�ó</InvoiceCustName>
    <InvoiceCustSeq>1000057</InvoiceCustSeq>
    <CustName>mn_�ŷ�ó</CustName>
    <CustSeq>1000057</CustSeq>
    <BKCustSeq>0</BKCustSeq>
    <CurrName>KRW</CurrName>
    <CurrSeq>1</CurrSeq>
    <ExRate>1</ExRate>
    <IsStockSales>0</IsStockSales>
    <Remark />
    <ItemName>mn_�׽�Ʈ��Ʈ</ItemName>
    <ItemSeq>1000573</ItemSeq>
    <ItemNo>mn_�׽�Ʈ��Ʈ</ItemNo>
    <Spec />
    <BizUnitName>���������</BizUnitName>
    <UnitSeq>3</UnitSeq>
    <ItemPrice>0</ItemPrice>
    <CustPrice>0</CustPrice>
    <Price>600</Price>
    <InvoiceQty>-50</InvoiceQty>
    <IsInclusedVAT>0</IsInclusedVAT>
    <VATRate>10</VATRate>
    <InvoiceCurAmt>-30000</InvoiceCurAmt>
    <InvoiceCurVAT>-3000</InvoiceCurVAT>
    <InvoiceCurAmtTotal>-33000</InvoiceCurAmtTotal>
    <InvoiceDomAmt>-30000</InvoiceDomAmt>
    <InvoiceDomVAT>-3000</InvoiceDomVAT>
    <InvoiceDomAmtTotal>-33000</InvoiceDomAmtTotal>
    <Qty>-50</Qty>
    <CurAmt>-30000</CurAmt>
    <CurVAT>-3000</CurVAT>
    <CurAmtTotal>-33000</CurAmtTotal>
    <DomAmt>-30000</DomAmt>
    <DomVAT>-3000</DomVAT>
    <DomAmtTotal>-33000</DomAmtTotal>
    <STDUnitName>BOX</STDUnitName>
    <STDUnitSeq>3</STDUnitSeq>
    <STDQty>-50</STDQty>
    <WHName>mn_����ǰâ��</WHName>
    <WHSeq>1000164</WHSeq>
    <IsQtyChange />
    <TrustCustName />
    <TrustCustSeq />
    <LotNo />
    <SerialNo />
    <IsOverCredit>0</IsOverCredit>
    <IsMinAmt>0</IsMinAmt>
    <IsSalesWith />
    <SMSalesCrtKindName>���ݰ�꼭����</SMSalesCrtKindName>
    <SMSalesCrtKind>8017002</SMSalesCrtKind>
    <AccName>��ǰ����(����)</AccName>
    <AccSeq>410</AccSeq>
    <DeptName>���������</DeptName>
    <DeptSeq>147</DeptSeq>
    <EmpName>�չ̳�</EmpName>
    <EmpSeq>2026</EmpSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017309,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014801