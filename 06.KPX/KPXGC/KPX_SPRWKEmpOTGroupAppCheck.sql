  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppCheck') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppCheck  
GO  
  
-- v2014.12.17  
  
-- OT�ϰ���û-üũ by ����õ   
CREATE PROC KPX_SPRWKEmpOTGroupAppCheck  
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
    
    CREATE TABLE #KPX_TPRWKEmpOTGroupApp( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRWKEmpOTGroupApp'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = ISNULL( MAX(BaseDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
          FROM #KPX_TPRWKEmpOTGroupApp   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
        EXEC dbo._SCOMCreateNo 'HR', 'KPX_TPRWKEmpOTGroupApp', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPRWKEmpOTGroupApp', 'GroupAppSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TPRWKEmpOTGroupApp  
           SET GroupAppSeq = @Seq + DataSeq,
               GroupAppNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TPRWKEmpOTGroupApp   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TPRWKEmpOTGroupApp  
     WHERE Status = 0  
       AND ( GroupAppSeq = 0 OR GroupAppSeq IS NULL )  
    
    SELECT * FROM #KPX_TPRWKEmpOTGroupApp   
    
    RETURN  
GO 
begin tran 
exec KPX_SPRWKEmpOTGroupAppCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026866,@WorkingTag=N'Del',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022469
rollback 