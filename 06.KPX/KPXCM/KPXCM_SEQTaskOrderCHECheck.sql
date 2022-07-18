
IF OBJECT_ID('KPXCM_SEQTaskOrderCHECheck') IS NOT NULL 
    DROP PROC KPXCM_SEQTaskOrderCHECheck
GO 
    
-- v2015.06.11    
    
-- ������������-üũ by ����õ    
CREATE PROC KPXCM_SEQTaskOrderCHECheck    
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
      
    CREATE TABLE #KPXCM_TEQTaskOrderCHE( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQTaskOrderCHE'     
    IF @@ERROR <> 0 RETURN       
    
    -- üũ1, ���� �� �����ʹ� ����/���� �� �� �����ϴ�.   
      UPDATE A   
         SET Result = '���� �� �����ʹ� ����/���� �� �� �����ϴ�.',   
             Status = 1234,   
             MessageType = 1234    
        FROM #KPXCM_TEQTaskOrderCHE AS A   
       WHERE A.WorkingTag IN ( 'U', 'D' )   
         AND A.Status = 0   
         AND EXISTS (SELECT 1 FROM KPXCM_TEQChangeFinalReport WHERE CompanySeq = @CompanySeq AND ChangeRequestSeq = A.ChangeRequestSeq )   
    -- üũ1, END   
    
    ------------------------------------------------------------------------  
    -- ��ȣ+�ڵ� ���� :             
    ------------------------------------------------------------------------  
    DECLARE @Count  INT,    
            @Seq    INT     
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQTaskOrderCHE WHERE WorkingTag = 'A' AND Status = 0    
        
    IF @Count > 0    
    BEGIN    
      
        -- Ű�������ڵ�κ� ����    
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQTaskOrderCHE', 'TaskOrderSeq', @Count    
          
        -- Temp Talbe �� ������ Ű�� UPDATE    
        UPDATE #KPXCM_TEQTaskOrderCHE    
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
        
    UPDATE A      
       SET Result        = @Results,        
           MessageType   = @MessageType,        
           Status        = @Status        
      FROM #KPXCM_TEQTaskOrderCHE AS A 
     WHERE Status = 0    
       AND ( TaskOrderSeq = 0 OR TaskOrderSeq IS NULL )    
        
    SELECT * FROM #KPXCM_TEQTaskOrderCHE     
        
      RETURN   