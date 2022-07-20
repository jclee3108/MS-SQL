  
IF OBJECT_ID('mnpt_SPJTEEExcelUploadMappingCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEEExcelUploadMappingCheck  
GO  
    

-- v2017.11.20
  
-- ���ֿ��ȿ������ε����_mnpt-üũ by ����õ   
CREATE PROC mnpt_SPJTEEExcelUploadMappingCheck   
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results + ' (������Ʈ, û���׸�)',
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.PJTSeq, S.ItemSeq   
              FROM (SELECT A1.PJTSeq, A1.ItemSeq  
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PJTSeq, A1.ItemSeq  
                      FROM mnpt_TPJTEEExcelUploadMapping AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND MappingSeq = A1.MappingSeq  
                                      )  
                   ) AS S  
             GROUP BY S.PJTSeq, S.ItemSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PJTSeq = B.PJTSeq AND A.ItemSeq = B.ItemSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    -- �ߺ����� üũ :   
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results + ' (�׸�(Text), ����(Text))',
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.TextPJTType, S.TextItemKind   
              FROM (SELECT A1.TextPJTType, A1.TextItemKind  
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.TextPJTType, A1.TextItemKind
                      FROM mnpt_TPJTEEExcelUploadMapping AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND MappingSeq = A1.MappingSeq  
                                      )  
                   ) AS S  
             GROUP BY S.TextPJTType, S.TextItemKind 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.TextPJTType = B.TextPJTType AND A.TextItemKind = B.TextItemKind )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
      


    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEEExcelUploadMapping', 'MappingSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET MappingSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( MappingSeq = 0 OR MappingSeq IS NULL )  
      
      
    RETURN  
