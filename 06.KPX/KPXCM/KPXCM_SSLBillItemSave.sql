IF OBJECT_ID('KPXCM_SSLBillItemSave') IS NOT NULL 
    DROP PROC KPXCM_SSLBillItemSave
GO 

-- v2015.10.15 
/*********************************************************************************************************************
     ȭ��� : ���ݰ�꼭_��������
     SP Name: _SSLBillItemSave
     �ۼ��� : 2008.08.13 : CREATEd by ������    
     ������ : 
 ********************************************************************************************************************/
 CREATE PROC KPXCM_SSLBillItemSave  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS       
     DECLARE @docHandle      INT 
      CREATE TABLE #TSLBillItem (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TSLBillItem' 
    
    --IF @PgmSeq = 4801 
    --BEGIN 
    --    -- ��ȭ�ݾ� ���� ��ȭ�ݾ׿� ����ó��
    --    DECLARE @DiffAmt DECIMAL(19,5) 
        
    --    SELECT @DiffAmt = FLOOR(SUM(A.CurAmt + A.CurVAT) * MAX(B.ExRate)) - SUM(A.DomAmt + A.DomVAT)               
    --      from #TSLBillItem    AS A 
    --      JOIN _TSLBill        AS B ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
    --     WHERE A.WorkingTag IN ( 'A', 'U' ) 
        
    --    UPDATE A 
    --       SET DomAmt = A.DomAmt + @DiffAmt 
    --      FROM #TSLBillItem AS A 
    --      JOIN ( 
    --            SELECT TOP 1 IDX_NO 
    --              FROM #TSLBillItem AS Z 
    --             ORDER BY Z.DomAmt DESC 
    --           ) AS B ON ( B.IDX_NO = A.IDX_NO ) 
        
    --     --��ȭ�ݾ� ���� ��ȭ�ݾ׿� ����ó��, END 
    --END 
        
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSLBillItem', -- �����̺��
                    '#TSLBillItem', -- �������̺��
                    'BillSeq, BillSerl' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                    'CompanySeq, BillSeq, BillSerl, BillPrtDate, ItemName, Spec, Qty, Price, CurAmt, CurVAT, KorPrice, DomAmt, DomVAT, Remark, LastUserSeq, LastDateTime, PgmSeq',
                    '', @PgmSeq 
  
  DECLARE @Word1 NVARCHAR(50),
    @Word2 NVARCHAR(50),
    @Word3 NVARCHAR(50),
    @MessageType  INT,
             @Status       INT,
             @Results      NVARCHAR(250)
  
  SELECT @Word3 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2377
  IF @@ROWCOUNT = 0 OR ISNULL( @Word3, '' ) = '' SELECT @Word3 = N'����'
  
  SELECT @Word1 = Word + @Word3 FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 18247
  IF @@ROWCOUNT = 0 OR ISNULL( @Word1, '' ) = '' SELECT @Word1 = N'��¿�'
  
  SELECT @Word2 = Word + @Word3 FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2609
  IF @@ROWCOUNT = 0 OR ISNULL( @Word2, '' ) = '' SELECT @Word2 = N'��꼭'
  
  EXEC dbo._SCOMMessage @MessageType OUTPUT,
                           @Status      OUTPUT,
                           @Results     OUTPUT,
                           1200, -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%Ů%')
                           @LanguageSeq, 
                           '', ''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'   
  
  UPDATE C
     SET C.Result   = REPLACE( REPLACE( @Results, '@1', @Word1 ), '@2', @Word2 ),
      C.MessageType = @MessageType,
      C.Status   = @Status
       FROM #TSLBillItem AS C 
       JOIN _TSLBill  AS A ON ( A.CompanySeq = @CompanySeq AND A.BillSeq = C.BillSeq AND A.BillDate < C.BillPrtDate )
   WHERE C.WorkingTag <> 'D' 
     AND C.Status = 0 
      
 -- DELETE                                                                                                
     IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE WorkingTag = 'D' AND Status = 0 )  
     BEGIN  
         DELETE _TSLBillItem  
           FROM _TSLBillItem AS A 
                  JOIN #TSLBillItem AS B  ON  A.BillSeq = B.BillSeq AND A.BillSerl = B.BillSerl
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'D' 
            AND B.Status = 0    
     END   
  -- Update                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE WorkingTag = 'U' AND Status = 0 )  
     BEGIN   
         UPDATE _TSLBillItem   
            SET BillPrtDate  = ISNULL(B.BillPrtDate, ''), 
                ItemName     = ISNULL(B.ItemName, ''), 
                Spec         = ISNULL(B.Spec, ''), 
                Qty          = ISNULL(B.Qty, 0), 
                Price        = ISNULL(B.Price, 0), 
                CurAmt       = ISNULL(B.CurAmt, 0), 
                CurVAT       = ISNULL(B.CurVAT, 0), 
                KorPrice     = ISNULL(B.KorPrice, 0), 
   DomAmt       = ISNULL(B.DomAmt, 0), 
                DomVAT       = ISNULL(B.DomVAT, 0), 
       Remark       = ISNULL(B.Remark, ''),
                LastUserSeq  = @UserSeq,
                LastDateTime = GETDATE(),
                PgmSeq       = @PgmSeq
           FROM _TSLBillItem AS A  
                  JOIN #TSLBillItem AS B ON A.BillSeq = B.BillSeq AND A.BillSerl = B.BillSerl
          WHERE B.WorkingTag = 'U' 
            AND B.Status = 0
            AND A.CompanySeq = @CompanySeq
   
         IF @@ERROR <> 0 RETURN   
     END 
  -- INSERT                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE WorkingTag = 'A' AND Status = 0 )  
    BEGIN          
         -- ���� INSERT  
         INSERT INTO _TSLBillItem (CompanySeq,   BillSeq,    BillSerl,   BillPrtDate,    ItemName, 
                                   Spec,         Qty,        Price,      CurAmt,         CurVAT, 
                                   KorPrice,     DomAmt,     DomVAT,     Remark,         LastUserSeq, 
                                   LastDateTime, PgmSeq)    
             SELECT @CompanySeq,             ISNULL(BillSeq, 0),    ISNULL(BillSerl, 0),   ISNULL(BillPrtDate, ''),   ISNULL(ItemName, ''), 
                    ISNULL(Spec, ''),        ISNULL(Qty, 0),        ISNULL(Price, 0),      ISNULL(CurAmt, 0),         ISNULL(CurVAT, 0), 
                    ISNULL(KorPrice, 0),     ISNULL(DomAmt, 0),     ISNULL(DomVAT, 0),     ISNULL(Remark, ''),         @UserSeq,      
                    GETDATE() ,              @PgmSeq  
               FROM #TSLBillItem  
              WHERE WorkingTag = 'A' AND Status = 0  
          IF @@ERROR <> 0 RETURN     
    END   
    
    
    SELECT * FROM #TSLBillItem 
    
  RETURN
  go
  begin tran 
  
  exec _SSLBillSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <IDX_NO>1</IDX_NO>
    <WorkingTag>A</WorkingTag>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BillSeq>1650</BillSeq>
    <BillNo>991231003</BillNo>
    <SMBillType>8026001</SMBillType>
    <UMBillKind>8027001</UMBillKind>
    <Gwon />
    <Ho />
    <FundArrangeDate xml:space="preserve">        </FundArrangeDate>
    <PrnReqDate xml:space="preserve">        </PrnReqDate>
    <SMBilling>8027002</SMBilling>
    <IsPrint>0</IsPrint>
    <IsDate>0</IsDate>
    <IsCust>0</IsCust>
    <TaxName>KPX�ɹ�Į(��) ������</TaxName>
    <TaxUnit>3</TaxUnit>
    <EvidSeq>0</EvidSeq>
    <Remark />
    <VatAccSeq>115</VatAccSeq>
    <SMBillTypeName>��꼭(�Ϲ�)</SMBillTypeName>
    <UMBillKindName>�Ϲݸ���</UMBillKindName>
    <EvidName />
    <VatAccName>�ΰ���������</VatAccName>
    <IsPJT>0</IsPJT>
    <WBSSeq>0</WBSSeq>
    <PJTSeq>0</PJTSeq>
    <BizUnit>1</BizUnit>
    <SMExpKind>8009001</SMExpKind>
    <BillDate>99991231</BillDate>
    <DeptSeq>224</DeptSeq>
    <EmpSeq>1</EmpSeq>
    <CustSeq>7982</CustSeq>
    <CurrSeq>16</CurrSeq>
    <ExRate>1.000000</ExRate>
    <OppAccSeq>18</OppAccSeq>
    <BizUnitName>�췹ź�ι�</BizUnitName>
    <SMExpKindName>����</SMExpKindName>
    <DeptName>�渮��</DeptName>
    <EmpName>������</EmpName>
    <CustName>������ȭ���غ�</CustName>
    <CurrName>KRW</CurrName>
    <OppAccName>�ܻ�����</OppAccName>
    <BillID>2</BillID>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=2637,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3569

exec KPXCM_SSLBillItemSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <Status>0</Status>
    <IDX_NO>1</IDX_NO>
    <BillSeq>1650</BillSeq>
    <BillSerl>1</BillSerl>
    <BillPrtDate>99991231</BillPrtDate>
    <ItemName>GHPP-1000</ItemName>
    <Spec />
    <Qty>2.00000</Qty>
    <Price>0.00000</Price>
    <CurAmt>193248.00000</CurAmt>
    <CurVAT>19324.80000</CurVAT>
    <KorPrice>0.00000</KorPrice>
    <DomAmt>193248.00000</DomAmt>
    <DomVAT>19325.00000</DomVAT>
    <Remark />
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=2637,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3569

rollback 