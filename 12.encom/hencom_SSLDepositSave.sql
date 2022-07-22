  
IF OBJECT_ID('hencom_SSLDepositSave') IS NOT NULL   
    DROP PROC hencom_SSLDepositSave  
GO  
    
-- v2017.07.24
  
-- ��Ź����-���� by ����õ   
CREATE PROC hencom_SSLDepositSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TSLDeposit (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLDeposit'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TSLDeposit')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_TSLDeposit'    , -- ���̺��        
                  '#hencom_TSLDeposit'    , -- �ӽ� ���̺��        
                  'DepositSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TSLDeposit WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hencom_TSLDeposit AS A   
          JOIN hencom_TSLDeposit AS B ON ( B.CompanySeq = @CompanySeq AND A.DepositSeq = B.DepositSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TSLDeposit WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.DepositNo      = A.DepositNo      ,  
               B.DepositDate    = A.DepositDate    ,  
               B.DepositAmt     = A.DepositAmt     ,  
               B.InterestAmt    = A.InterestAmt    ,  
               B.ReturnDate     = A.ReturnDate     ,  
               B.DepositAccSeq  = A.DepositAccSeq  ,  
               B.InterestAccSeq = A.InterestAccSeq ,  
               B.TotAccSeq      = A.TotAccSeq      ,  
               B.SlipSeq        = A.SlipSeq        ,  
               B.Remark         = A.Remark         ,  
               B.LastUserSeq    = @UserSeq         ,  
               B.LastDateTime   = GETDATE()        ,  
               B.PgmSeq         = @PgmSeq    
                 
          FROM #hencom_TSLDeposit AS A   
          JOIN hencom_TSLDeposit AS B ON ( B.CompanySeq = @CompanySeq AND A.DepositSeq = B.DepositSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TSLDeposit WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        INSERT INTO hencom_TSLDeposit  
        (   
            CompanySeq, DepositSeq, DepositNo, DepositDate, DepositAmt, 
            InterestAmt, ReturnDate, DepositAccSeq, InterestAccSeq, TotAccSeq, 
            SlipSeq, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, DepositSeq, DepositNo, DepositDate, DepositAmt, 
               InterestAmt, ReturnDate, DepositAccSeq, InterestAccSeq, TotAccSeq, 
               SlipSeq, Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #hencom_TSLDeposit AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_TSLDeposit   
      
    RETURN  
GO 