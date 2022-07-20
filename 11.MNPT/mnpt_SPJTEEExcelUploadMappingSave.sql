  
IF OBJECT_ID('mnpt_SPJTEEExcelUploadMappingSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEEExcelUploadMappingSave  
GO  
    

-- v2017.11.20
  
-- ���ֿ��ȿ������ε����_mnpt-���� by ����õ   
CREATE PROC mnpt_SPJTEEExcelUploadMappingSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS    
       
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEEExcelUploadMapping')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEEExcelUploadMapping'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺��        
                  'MappingSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTEEExcelUploadMapping AS B ON ( B.CompanySeq = @CompanySeq AND A.MappingSeq = B.MappingSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PJTSeq         = A.PJTSeq,  
               B.TextPJTType    = A.TextPJTType,  
               B.ItemSeq        = A.ItemSeq,  
               B.TextItemKind   = A.TextItemKind,  
               B.Remark         = A.Remark,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
                 
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTEEExcelUploadMapping AS B ON ( B.CompanySeq = @CompanySeq AND A.MappingSeq = B.MappingSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTEEExcelUploadMapping  
        (   
            CompanySeq, MappingSeq, PJTSeq, TextPJTType, ItemSeq, 
            TextItemKind, Remark, FirstUserSeq, FirstDateTime, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, MappingSeq, PJTSeq, TextPJTType, ItemSeq, 
               TextItemKind, Remark, @UserSeq, GETDATE(), @UserSeq, 
               GETDATE(), @PgmSeq   
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    RETURN  
