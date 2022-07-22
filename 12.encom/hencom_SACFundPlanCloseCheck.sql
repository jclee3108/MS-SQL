  
IF OBJECT_ID('hencom_SACFundPlanCloseCheck') IS NOT NULL   
    DROP PROC hencom_SACFundPlanCloseCheck  
GO  
    
-- v2017.07.10
  
-- �ڱݰ�ȹ����-üũ by ����õ 
CREATE PROC hencom_SACFundPlanCloseCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #hencom_TACFundPlanClose( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACFundPlanClose'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, ����д�����ް�ȹ�� �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.
    UPDATE A
       SET Result = '����д�����ް�ȹ�� �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACPaymentPricePlan WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check1 = '1' 
    -- üũ1, END 

    -- üũ2, �ڱ���ü��ȹ������ �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.
    UPDATE A
       SET Result = '�ڱ���ü��ȹ������ �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACFundSendPlan WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check2 = '1' 
    -- üũ2, END 

    -- üũ3, ���޺����޳����� �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.
    UPDATE A
       SET Result = '���޺����޳����� �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACSubContrAmtList WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check3 = '1' 
    -- üũ3, END 

    -- üũ4, �����ݳ����� �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.
    UPDATE A
       SET Result = '�����ݳ����� �������� �ʽ��ϴ�. �ٽ� ��ȸ �� ó���Ͻñ�ٸ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACSendAmtList WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check4 = '1' 
    -- üũ4, END 

    SELECT * FROM #hencom_TACFundPlanClose   
      
    RETURN  
    GO
begin tran 
exec hencom_SACFundPlanCloseCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdDate>20170710</StdDate>
    <Check1>1</Check1>
    <Check2>0</Check2>
    <Check3>0</Check3>
    <Check4>0</Check4>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033922
rollback 