  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHECheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHECheck  
GO  
  
-- v2015.07.17  
  
-- ���������������-üũ by ����õ   
CREATE PROC KPXCM_SEQYearRepairResultRegCHECheck  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairResultRegCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairResultRegCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQYearRepairResultRegCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN    
    
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQYearRepairResultRegCHE', 'ResultSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXCM_TEQYearRepairResultRegCHE  
           SET ResultSeq = @Seq + DataSeq 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQYearRepairResultRegCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQYearRepairResultRegCHE  
     WHERE Status = 0  
       AND ( ResultSeq = 0 OR ResultSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TEQYearRepairResultRegCHE   
    
    RETURN  