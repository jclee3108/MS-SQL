  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterAmtUploadCheck') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterAmtUploadCheck  
GO  
  
-- v2015.04.21  
  
-- �ְ� �򰡼��͸����� ���ε�-üũ by ����õ   
CREATE PROC KPX_SACEvalProfitItemMasterAmtUploadCheck  
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
    
    CREATE TABLE #KPX_TACEvalProfitItemMasterAmtUpload( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMasterAmtUpload'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TACEvalProfitItemMasterAmtUpload WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TACEvalProfitItemMasterAmtUpload', 'Seq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TACEvalProfitItemMasterAmtUpload  
           SET Seq = @Seq + DataSeq--,  
               --SampleNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TACEvalProfitItemMasterAmtUpload   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TACEvalProfitItemMasterAmtUpload  
     WHERE Status = 0  
       AND ( Seq = 0 OR Seq IS NULL )  
    
    SELECT * FROM #KPX_TACEvalProfitItemMasterAmtUpload   
    
    RETURN  