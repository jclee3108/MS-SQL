  
IF OBJECT_ID('KPXCM_SEQYearRepairPeriodRegCHECheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairPeriodRegCHECheck  
GO  
  
-- v2015.07.13  
  
-- ���������Ⱓ���-üũ by ����õ   
CREATE PROC KPXCM_SEQYearRepairPeriodRegCHECheck  
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
      
    CREATE TABLE #KPXCM_TEQYearRepairPeriodCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairPeriodCHE'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------------
    -- üũ1, ����� �����ʹ� ����,���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '����� �����ʹ� ����,���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairPeriodCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U','D' ) 
       AND EXISTS (SELECT 1 FROM KPXCM_TEQYearRepairReqRegCHE WHERE CompanySeq = @CompanySeq AND RepairSeq = A.RepairSeq ) 
    ------------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------------
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQYearRepairPeriodCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQYearRepairPeriodCHE', 'RepairSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXCM_TEQYearRepairPeriodCHE  
           SET RepairSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQYearRepairPeriodCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQYearRepairPeriodCHE  
     WHERE Status = 0  
       AND ( RepairSeq = 0 OR RepairSeq IS NULL )  
    
    SELECT * FROM #KPXCM_TEQYearRepairPeriodCHE   
      
    RETURN  
GO
begin tran 

exec KPXCM_SEQYearRepairPeriodRegCHECheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RepairYear>2015</RepairYear>
    <Amd>3</Amd>
    <RepairName>124124</RepairName>
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairCfmYn>0</RepairCfmYn>
    <ReceiptCfmyn>0</ReceiptCfmyn>
    <Remark>134234</Remark>
    <FactUnit>1</FactUnit>
    <FactUnitName>�ƻ����</FactUnitName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>����õ</EmpName>
    <DeptSeq>1300</DeptSeq>
    <DeptName>���������2</DeptName>
    <RepairSeq>4</RepairSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030822,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025712

rollback 