IF OBJECT_ID('hencom_SACPJTPayListCheck') IS NOT NULL 
    DROP PROC hencom_SACPJTPayListCheck
GO 

-- v2017.05.10 
/************************************************************
  ��  �� - ������-���庰�ӱݴ���_hencom : üũ
  �ۼ��� - 20160119
  �ۼ��� - ������
 ************************************************************/
 CREATE PROC dbo.hencom_SACPJTPayListCheck
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
      @Status    INT,
      @Results   NVARCHAR(250)
        
   CREATE TABLE #hencom_TACPJTPayList (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACPJTPayList'
   
  -----------------------------
  ---- �ʼ��Է� üũ
  -----------------------------
  
  ---- �ʼ��Է� Message �޾ƿ���
  --EXEC dbo._SCOMMessage @MessageType OUTPUT,
  --       @Status      OUTPUT,
  --       @Results     OUTPUT,
  --       1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')
  --       @LanguageSeq       , 
  --       0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
   ---- �ʼ��Է� Check 
  --UPDATE #hencom_TACPJTPayList
  --   SET Result        = @Results,
  --    MessageType   = @MessageType,
  --    Status        = @Status
  --  FROM #hencom_TACPJTPayList AS A
  -- WHERE A.WorkingTag IN ('A','U')
  --   AND A.Status = 0
  ---- guide : �̰��� �ʼ��Է� üũ �� �׸��� �������� ��������.
  ---- e.g.   :
  ---- AND (A.DBPatchSeq           = 0
  ----      OR A.DBWorkSeq          = 0
  ----      OR A.DBPatchListName    = '')
         
    ------------------------------------------------------------
    -- üũ1, ��ǥó�� �� �����ʹ� ����/���� �� �� �����ϴ�. 
    ------------------------------------------------------------
    UPDATE A
       SET Result = '��ǥó�� �� �����ʹ� ����/���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACPJTPayList    AS A 
      JOIN hencom_TACPJTPayList     AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTPayRegSeq = A.PJTPayRegSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND ISNULL(B.SlipSeq,0) <> 0 
    ------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------


  ---------------------------
  -- �ߺ����� üũ
  ---------------------------  
  -- �ߺ�üũ Message �޾ƿ���    
  EXEC dbo._SCOMMessage @MessageType OUTPUT,    
         @Status      OUTPUT,    
         @Results     OUTPUT,    
         6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
         @LanguageSeq       ,     
         0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    
       
  -- �ߺ����� Check
  UPDATE #hencom_TACPJTPayList 
     SET Status = 6,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
      result = @Results      
    FROM #hencom_TACPJTPayList A      
   WHERE A.WorkingTag IN ('A', 'U')
     AND A.Status = 0
    AND EXISTS (SELECT 1  FROM hencom_TACPJTPayList   
                              WHERE CompanySeq = @CompanySeq   
                                AND payym = a.payym
                                and EmpCustSeq = a.EmpCustSeq
                                and PJTPayRegSeq <> a.PJTPayRegSeq  
                                AND PJTSeq = A.PJTSeq )    
  
   --��Ʈ�� �ߺ��� ������ üũ  
     UPDATE #hencom_TACPJTPayList   
     SET Status = 6,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.        
      result = '�ߺ��� �����Ͱ� �����մϴ�. Ȯ�� �� �۾��ϼ���'        
    FROM #hencom_TACPJTPayList AS A        
   WHERE A.WorkingTag IN ('A', 'U')  
     AND A.Status = 0  
     AND EXISTS (SELECT 1 FROM #hencom_TACPJTPayList WHERE IDX_NO <> A.IDX_NO   
                                                         AND payym = A.payym  
                                                         AND EmpCustSeq = A.EmpCustSeq  
                                                         AND PJTSeq = A.PJTSeq
                                                         ) 
           
   -- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
    DECLARE @MaxSeq INT,    
             @Count  INT     
     SELECT @Count = Count(1) FROM #hencom_TACPJTPayList WHERE WorkingTag = 'A' AND Status = 0    
     IF @Count >0     
     BEGIN    
     EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TACPJTPayList','PJTPayRegSeq',@Count --rowcount      
           UPDATE #hencom_TACPJTPayList                 
              SET PJTPayRegSeq  = @MaxSeq + DataSeq    
            WHERE WorkingTag = 'A'                
              AND Status = 0     
     END     
   SELECT * FROM #hencom_TACPJTPayList 
  RETURN
go
begin tran 
exec hencom_SACPJTPayListCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTPayRegSeq>3</PJTPayRegSeq>
    <PayYM>201601</PayYM>
    <PJTSeq>1</PJTSeq>
    <PJTName>�׽�Ʈ��</PJTName>
    <DeptSeq>58</DeptSeq>
    <DeptName>�濵�������</DeptName>
    <EmpCustSeq>70853</EmpCustSeq>
    <EmpCustName>(��)�λ�Ĵ�</EmpCustName>
    <PersonId />
    <SlipSeq>0</SlipSeq>
    <SlipID />
    <WorkingDay>3</WorkingDay>
    <Price>1200</Price>
    <TotalPay>256000</TotalPay>
    <IncomTax>200</IncomTax>
    <ResidenceTax>120</ResidenceTax>
    <TaxSum>320</TaxSum>
    <HealthIns>100</HealthIns>
    <NationalPension>200</NationalPension>
    <InsSum>300</InsSum>
    <DepSum>620</DepSum>
    <UnemployIns>210</UnemployIns>
    <DeductionAmt>830</DeductionAmt>
    <RealAmt>255170</RealAmt>
    <ContributionAmt>200</ContributionAmt>
    <UMBankHQ>4003021</UMBankHQ>
    <BankAccNo>111</BankAccNo>
    <Owner>������������</Owner>
    <TelNo />
    <SubcCustSeq>70853</SubcCustSeq>
    <SubcCustName>(��)�λ�Ĵ�</SubcCustName>
    <Addr>�泲 ���� �Ϻϸ� ���긮 4-4 </Addr>
    <Remark>���</Remark>
    <SubsAccSeq>102</SubsAccSeq>
    <SubsAccName>�ܻ���Ա�_�����</SubsAccName>
    <CalcAccSeq>0</CalcAccSeq>
    <CalcAccName />
    <PrepaidExpenseAccSeq>1266</PrepaidExpenseAccSeq>
    <PrepaidExpenseAccName>���޺��_��Ÿ</PrepaidExpenseAccName>
    <PayAccSeq>107</PayAccSeq>
    <PayAccName>�����ޱ�_��ü</PayAccName>
    <Calc2AccSeq>372</Calc2AccSeq>
    <Calc2AccName>�������_�ܻ�����</Calc2AccName>
    <CashDate>20170501</CashDate>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTPayRegSeq>4</PJTPayRegSeq>
    <PayYM>201601</PayYM>
    <PJTSeq>1</PJTSeq>
    <PJTName>�׽�Ʈ��</PJTName>
    <DeptSeq>58</DeptSeq>
    <DeptName>�濵�������</DeptName>
    <EmpCustSeq>4203</EmpCustSeq>
    <EmpCustName>(��)�븲��ũ</EmpCustName>
    <PersonId />
    <SlipSeq>3305</SlipSeq>
    <SlipID>A0-S1-20160125-0002-004</SlipID>
    <WorkingDay>2</WorkingDay>
    <Price>23000</Price>
    <TotalPay>29000</TotalPay>
    <IncomTax>300</IncomTax>
    <ResidenceTax>100</ResidenceTax>
    <TaxSum>400</TaxSum>
    <HealthIns>200</HealthIns>
    <NationalPension>100</NationalPension>
    <InsSum>300</InsSum>
    <DepSum>700</DepSum>
    <UnemployIns>200</UnemployIns>
    <DeductionAmt>900</DeductionAmt>
    <RealAmt>28100</RealAmt>
    <ContributionAmt>100</ContributionAmt>
    <UMBankHQ>4003013</UMBankHQ>
    <BankAccNo>444</BankAccNo>
    <Owner>�븲��ũ������</Owner>
    <TelNo />
    <SubcCustSeq>4782</SubcCustSeq>
    <SubcCustName>(��)��ֵ��ȿ������</SubcCustName>
    <Addr xml:space="preserve">  </Addr>
    <Remark />
    <SubsAccSeq>5</SubsAccSeq>
    <SubsAccName>����</SubsAccName>
    <CalcAccSeq>5</CalcAccSeq>
    <CalcAccName>����</CalcAccName>
    <PrepaidExpenseAccSeq>1266</PrepaidExpenseAccSeq>
    <PrepaidExpenseAccName>���޺��_��Ÿ</PrepaidExpenseAccName>
    <PayAccSeq>107</PayAccSeq>
    <PayAccName>�����ޱ�_��ü</PayAccName>
    <Calc2AccSeq>372</Calc2AccSeq>
    <Calc2AccName>�������_�ܻ�����</Calc2AccName>
    <CashDate>20170502</CashDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034419,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028494
rollback 