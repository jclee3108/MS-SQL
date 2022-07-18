  
IF OBJECT_ID('KPX_SACComCostDivSlipSave') IS NOT NULL   
    DROP PROC KPX_SACComCostDivSlipSave  
GO  
  
-- v2014.11.10  
  
-- ����Ȱ������ ����� ��ü��ǥó��-���� by ����õ   
CREATE PROC KPX_SACComCostDivSlipSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TACComCostDivSlip (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACComCostDivSlip'   
    IF @@ERROR <> 0 RETURN    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACComCostDivSlip WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        INSERT INTO KPX_TACComCostDivSlip  
        (   
            CompanySeq,CostYM,SMCostMng,SendCCtrSeq,RevCCtrSeq,  
            CostAccSeq,Amt,SlipMstSeq,LastUserSeq,LastDateTime  
               
     )   
        SELECT @CompanySeq,A.CostYM,A.SMCostMng,A.SendCCtrSeq,A.RecvCCtrSeq,  
               A.CostAccSeq,A.RevAmt,A.SlipMstSeq,@UserSeq,GETDATE()  
        
          FROM #KPX_TACComCostDivSlip AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPX_TACComCostDivSlip   
      
    RETURN  
GO 
/*
begin tran 
exec KPX_SACComCostDivSlipSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccUnitName>���������</AccUnitName>
    <AccUnitSeq>1</AccUnitSeq>
    <CCtrName2>������</CCtrName2>
    <CCtrSeq2>14</CCtrSeq2>
    <CostAccName>�Ҹ���ⱸ��-(����)(�������)</CostAccName>
    <CostAccName2>�Ҹ���ⱸ��-(����)(�������)</CostAccName2>
    <CostAccSeq>471</CostAccSeq>
    <CostAccSeq2>471</CostAccSeq2>
    <CostYM>201410</CostYM>
    <CrAmt>-2000.00000</CrAmt>
    <CrAmt2>2000.00000</CrAmt2>
    <DrAmt>-2000.00000</DrAmt>
    <DrAmt2>2000.00000</DrAmt2>
    <RecvAccName>DMC �����</RecvAccName>
    <RecvAccSeq>2</RecvAccSeq>
    <RecvAccUnit2>0</RecvAccUnit2>
    <RecvAccUnitName2>DMC �����</RecvAccUnitName2>
    <RecvCCtrName>������_DMC</RecvCCtrName>
    <RecvCCtrSeq>0</RecvCCtrSeq>
    <RevAmt>2000.00000</RevAmt>
    <RevAmt2>2000.00000</RevAmt2>
    <SendAccUnitName2>���������</SendAccUnitName2>
    <SendAccUnitSeq2>0</SendAccUnitSeq2>
    <SendCCtrName>������</SendCCtrName>
    <SendCCtrSeq>14</SendCCtrSeq>
    <SlipID />
    <SlipID2 />
    <SlipSeq>0</SlipSeq>
    <SlipSeq2>0</SlipSeq2>
    <TgtAmt>10000.00000</TgtAmt>
    <SMCostMng>5512001</SMCostMng>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccUnitName>���������</AccUnitName>
    <AccUnitSeq>1</AccUnitSeq>
    <CCtrName2>������</CCtrName2>
    <CCtrSeq2>14</CCtrSeq2>
    <CostAccName>�Ҹ���ⱸ��-(����)(�������)</CostAccName>
    <CostAccName2>�Ҹ���ⱸ��-(����)(�������)</CostAccName2>
    <CostAccSeq>471</CostAccSeq>
    <CostAccSeq2>471</CostAccSeq2>
    <CostYM>201410</CostYM>
    <CrAmt>-2000.00000</CrAmt>
    <CrAmt2>2000.00000</CrAmt2>
    <DrAmt>-2000.00000</DrAmt>
    <DrAmt2>2000.00000</DrAmt2>
    <RecvAccName>AM �����</RecvAccName>
    <RecvAccSeq>3</RecvAccSeq>
    <RecvAccUnit2>0</RecvAccUnit2>
    <RecvAccUnitName2>AM �����</RecvAccUnitName2>
    <RecvCCtrName>������_AM</RecvCCtrName>
    <RecvCCtrSeq>0</RecvCCtrSeq>
    <RevAmt>2000.00000</RevAmt>
    <RevAmt2>2000.00000</RevAmt2>
    <SendAccUnitName2>���������</SendAccUnitName2>
    <SendAccUnitSeq2>0</SendAccUnitSeq2>
    <SendCCtrName>������</SendCCtrName>
    <SendCCtrSeq>14</SendCCtrSeq>
    <SlipID />
    <SlipID2 />
    <SlipSeq>0</SlipSeq>
    <SlipSeq2>0</SlipSeq2>
    <TgtAmt>10000.00000</TgtAmt>
    <SMCostMng>5512001</SMCostMng>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccUnitName>���������</AccUnitName>
    <AccUnitSeq>1</AccUnitSeq>
    <CCtrName2>������</CCtrName2>
    <CCtrSeq2>14</CCtrSeq2>
    <CostAccName>�Ҹ���ⱸ��-(����)(�������)</CostAccName>
    <CostAccName2>�Ҹ���ⱸ��-(����)(�������)</CostAccName2>
    <CostAccSeq>471</CostAccSeq>
    <CostAccSeq2>471</CostAccSeq2>
    <CostYM>201410</CostYM>
    <CrAmt>-6000.00000</CrAmt>
    <CrAmt2>6000.00000</CrAmt2>
    <DrAmt>-6000.00000</DrAmt>
    <DrAmt2>6000.00000</DrAmt2>
    <RecvAccName>���������</RecvAccName>
    <RecvAccSeq>1</RecvAccSeq>
    <RecvAccUnit2>0</RecvAccUnit2>
    <RecvAccUnitName2>���������</RecvAccUnitName2>
    <RecvCCtrName>������_�������</RecvCCtrName>
    <RecvCCtrSeq>0</RecvCCtrSeq>
    <RevAmt>6000.00000</RevAmt>
    <RevAmt2>6000.00000</RevAmt2>
    <SendAccUnitName2>���������</SendAccUnitName2>
    <SendAccUnitSeq2>0</SendAccUnitSeq2>
    <SendCCtrName>������</SendCCtrName>
    <SendCCtrSeq>14</SendCCtrSeq>
    <SlipID />
    <SlipID2 />
    <SlipSeq>0</SlipSeq>
    <SlipSeq2>0</SlipSeq2>
    <TgtAmt>10000.00000</TgtAmt>
    <SMCostMng>5512001</SMCostMng>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025697,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1021304

rollback 
*/