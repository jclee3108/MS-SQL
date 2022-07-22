  
IF OBJECT_ID('hencom_SACBankAccMoveCheck') IS NOT NULL   
    DROP PROC hencom_SACBankAccMoveCheck 
GO  
  
-- v2017.05.15
  
-- ���°��̵��Է�-üũ by ����õ
CREATE PROC hencom_SACBankAccMoveCheck  
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
    
    CREATE TABLE #hencom_TACBankAccMove( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACBankAccMove'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, ��ǥ�� ���� �� ������ ����/���� �� �� �����ϴ�. 
    UPDATE A
       SET Result = '��ǥ�� ���� �� ������ ����/���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACBankAccMove           AS A 
      LEFT OUTER JOIN hencom_TACBankAccMove AS B ON ( B.CompanySeq = @CompanySeq AND B.MoveSeq = A.MoveSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND ISNULL(B.SlipSeq,0) <> 0
    -- üũ1, END 

    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_TACBankAccMove WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TACBankAccMove', 'MoveSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #hencom_TACBankAccMove  
           SET MoveSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_TACBankAccMove   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_TACBankAccMove  
     WHERE Status = 0  
       AND ( MoveSeq = 0 OR MoveSeq IS NULL )  
      
    SELECT * FROM #hencom_TACBankAccMove   
      
    RETURN  
