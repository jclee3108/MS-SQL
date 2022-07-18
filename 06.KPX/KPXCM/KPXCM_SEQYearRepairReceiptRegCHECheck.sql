  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHECheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHECheck  
GO  
  
-- v2015.07.15  
  
-- ���������������-üũ by ����õ   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHECheck  
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
      
    CREATE TABLE #KPXCM_TEQYearRepairReceiptRegCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairReceiptRegCHE'   
    IF @@ERROR <> 0 RETURN     
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQYearRepairReceiptRegCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQYearRepairReceiptRegCHE', 'ReceiptRegSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXCM_TEQYearRepairReceiptRegCHE  
           SET ReceiptRegSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQYearRepairReceiptRegCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQYearRepairReceiptRegCHE  
     WHERE Status = 0  
       AND ( ReceiptRegSeq = 0 OR ReceiptRegSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TEQYearRepairReceiptRegCHE   
      
    RETURN  
GO
begin tran 
exec KPXCM_SEQYearRepairReceiptRegCHECheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>1300</DeptSeq>
    <DeptName>���������2</DeptName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>����õ</EmpName>
    <ReceiptRegSeq>0</ReceiptRegSeq>
    <ReceiptRegDate>20150721</ReceiptRegDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743
rollback 