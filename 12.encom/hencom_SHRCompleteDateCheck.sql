  
IF OBJECT_ID('hencom_SHRCompleteDateCheck') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateCheck  
GO  
    
-- v2017.07.26
  
-- �Ϸ��ϰ���-üũ by ����õ   
CREATE PROC hencom_SHRCompleteDateCheck  
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
      
    CREATE TABLE #hencom_THRCompleteDate( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_THRCompleteDate'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_THRCompleteDate WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_THRCompleteDate', 'CompleteSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #hencom_THRCompleteDate  
           SET CompleteSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_THRCompleteDate   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_THRCompleteDate  
     WHERE Status = 0  
       AND ( CompleteSeq = 0 OR CompleteSeq IS NULL )  
      
    SELECT * FROM #hencom_THRCompleteDate   
      
    RETURN  
    GO
begin tran 

exec hencom_SHRCompleteDateCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UMCompleteType>1015529001</UMCompleteType>
    <UMCompleteTypeName>����(��ü)</UMCompleteTypeName>
    <DpetSeq>66</DpetSeq>
    <DpetName>�濵������� �����</DpetName>
    <SrtDate>20170701</SrtDate>
    <EndDate>20170703</EndDate>
    <ManagementAmt>0</ManagementAmt>
    <AlarmDay>0</AlarmDay>
    <Remark>dfdf</Remark>
    <CompleteSeq>0</CompleteSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512703,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033993

rollback 