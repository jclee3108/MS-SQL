  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceSave') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceSave  
GO  
    
-- v2017.09.28
  
-- �������Ӵܰ��Է�-SS1���� by ����õ
CREATE PROC mnpt_SPJTUnionWagePriceSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePrice')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTUnionWagePrice'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺��        
                  'StdSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTUnionWagePrice      AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTUnionWagePriceItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePriceItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTUnionWagePriceItem'    , -- ���̺��        
                      '#ItemLog'    , -- �ӽ� ���̺��        
                      'StdSeq,StdSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, End
        --------------------------------------------------------------
        
        DELETE B 
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTUnionWagePriceItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl, 
               B.TitleSeq 
          INTO #ValueLog
          FROM #BIZ_OUT_DataBlock1              AS A 
          JOIN mnpt_TPJTUnionWagePriceValue     AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePriceValue')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTUnionWagePriceValue'    , -- ���̺��        
                      '#ValueLog'    , -- �ӽ� ���̺��        
                      'StdSeq,StdSerl,TitleSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, End
        --------------------------------------------------------------
        
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTUnionWagePriceValue AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.StdDate        = A.StdDate ,  
               B.Remark         = A.Remark  ,  
               B.LastUserSeq    = @UserSeq  ,  
               B.LastDateTime   = GETDATE() ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTUnionWagePrice  AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTUnionWagePrice  
        (   
            Companyseq, StdSeq, StdDate, Remark, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @Companyseq, StdSeq, StdDate, Remark, @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    
    RETURN  
 
