  
IF OBJECT_ID('KPX_SEQTaskOrderCHECheck') IS NOT NULL   
    DROP PROC KPX_SEQTaskOrderCHECheck  
GO  
  
-- v2014.12.08  
  
-- ������������-üũ by ����õ   
CREATE PROC KPX_SEQTaskOrderCHECheck  
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
    
    CREATE TABLE #KPX_TEQTaskOrderCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQTaskOrderCHE'   
    IF @@ERROR <> 0 RETURN     
    
    
    ------------------------------------------------------------------------
    -- ��ȣ+�ڵ� ���� :           
    ------------------------------------------------------------------------
    DECLARE @Count  INT,  
            @Seq    INT   
    
    SELECT @Count = COUNT(1) FROM #KPX_TEQTaskOrderCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
    
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TEQTaskOrderCHE', 'TaskOrderSeq', @Count  
        
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TEQTaskOrderCHE  
           SET TaskOrderSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TEQTaskOrderCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TEQTaskOrderCHE  
     WHERE Status = 0  
       AND ( TaskOrderSeq = 0 OR TaskOrderSeq IS NULL )  
      
    SELECT * FROM #KPX_TEQTaskOrderCHE   
      
    RETURN  