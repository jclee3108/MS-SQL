  
IF OBJECT_ID('mnpt_SPJTEERentToolContractItemSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractItemSave  
GO  
    
-- v2017.09.28
  
-- �ܺ������������Է�-SS2���� by ����õ
CREATE PROC mnpt_SPJTEERentToolContractItemSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolContractItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEERentToolContractItem'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock2'    , -- �ӽ� ���̺��        
                  'ContractSeq,ContractSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock2                AS A   
          JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq AND A.ContractSerl = B.ContractSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMRentKind     = A.UMRentKind,  
               B.RentToolSeq    = A.RentToolSeq,  
               B.UMRentType     = A.UMRentType,  
               B.Qty            = A.Qty,  
               B.Price          = A.Price,  
               B.Amt            = A.Amt,  
               B.PJTSeq         = A.PJTSeq,  
               B.Remark         = A.Remark,
               B.LastUserSeq    = @UserSeq    ,  
               B.LastDateTime   = GETDATE()   ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock2                AS A   
          JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl )
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTEERentToolContractItem  
        (   
            CompanySeq, ContractSeq, ContractSerl, UMRentKind, RentToolSeq, 
            TextRentToolName, UMRentType, Qty, Price, Amt, 
            PJTSeq, Remark, FirstUserSeq, FirstDateTime, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ContractSeq, ContractSerl, UMRentKind, RentToolSeq, 
               TextRentToolName, UMRentType, Qty, Price, Amt, 
               PJTSeq, Remark, @UserSeq, GETDATE(), @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock2 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
 
go

