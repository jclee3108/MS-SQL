  
IF OBJECT_ID('mnpt_SPJTEERentToolContractSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractSave  
GO  
    
-- v2017.11.21
  
-- �ܺ������������Է�-SS1���� by ����õ
CREATE PROC mnpt_SPJTEERentToolContractSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolContract')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEERentToolContract'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺��        
                  'ContractSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTEERentToolContract      AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.ContractSeq, 
               B.ContractSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTEERentToolContractItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolContractItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTEERentToolContractItem'    , -- ���̺��        
                      '#ItemLog'    , -- �ӽ� ���̺��        
                      'ContractSeq,ContractSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, End
        --------------------------------------------------------------
        
        DELETE B 
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTEERentToolContractItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.BizUnit        = A.BizUnit ,  
               B.ContractDate   = A.ContractDate ,  
               B.ContractNo     = A.ContractNo ,  
               B.RentCustSeq    = A.RentCustSeq ,  
               B.RentSrtDate    = A.RentSrtDate ,  
               B.RentEndDate    = A.RentEndDate ,  
               B.EmpSeq         = A.EmpSeq ,  
               B.DeptSeq        = A.DeptSeq ,  
               B.Remark         = A.Remark ,  
               B.LastUserSeq    = @UserSeq  ,  
               B.LastDateTime   = GETDATE() ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEERentToolContract  AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTEERentToolContract  
        (   
            CompanySeq, ContractSeq, BizUnit, ContractDate, ContractNo, 
            RentCustSeq, RentSrtDate, RentEndDate, EmpSeq, DeptSeq, 
            Remark, FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, 
            PgmSeq
        )   
        SELECT @CompanySeq, ContractSeq, BizUnit, ContractDate, ContractNo, 
               RentCustSeq, RentSrtDate, RentEndDate, EmpSeq, DeptSeq, 
               Remark, @UserSeq, GETDATE(), @UserSeq, GETDATE(), 
               @PgmSeq
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    
    RETURN  
 
